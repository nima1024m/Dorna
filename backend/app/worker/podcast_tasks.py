import asyncio
import json
import os
import logging
import time
from dataclasses import dataclass
from typing import Optional
from contextlib import asynccontextmanager

from celery import chain
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import func, select, update

import struct

from app.worker.celery_app import celery_app
from app.core.config import settings
from app.core.database import PodcastJobStatus
from app.models import PodcastJob
from app.core.agents.gc_renderer import render_service_account_json
from app.services.token_usage import TokenUsageService
import app.core.ai as AI


logger = logging.getLogger(__name__)

# Max number of audio segments to synthesize concurrently within a single Celery task.
# Keep this conservative to avoid exhausting GCP quotas / worker resources.
DEFAULT_AUDIO_CONCURRENCY = 3
JOB_HEARTBEAT_INTERVAL_S = 10

# Voice mapping: Alex -> Charon, Sarah -> Zephyr
VOICE_MAP = {
    "Alex": "Charon",
    "Sarah": "Zephyr",
}




@dataclass(frozen=True)
class _RetryCfg:
    countdown_s: int = 3
    max_retries: int = 3  # total attempts = 1 + max_retries


RETRY_CFG = _RetryCfg()


@asynccontextmanager
async def _session_scope():
    engine = create_async_engine(settings.DB_URL, echo=False, future=True)
    session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session() as db:
        try:
            yield db
        finally:
            await db.close()
            await engine.dispose()


async def _get_job(db: AsyncSession, job_id) -> Optional[PodcastJob]:
    res = await db.execute(select(PodcastJob).where(PodcastJob.id == job_id))
    return res.scalar_one_or_none()


async def _set_retry_step(
    job_id,
    *,
    status: PodcastJobStatus,
    stage_label: str,
    attempt: int,
    total_attempts: int,
) -> None:
    """
    Update job status/current_step before a Celery retry.

    attempt is 1-based (e.g. 2 means "second attempt about to run").
    """
    async with _session_scope() as db:
        await db.execute(
            update(PodcastJob)
            .where(PodcastJob.id == job_id)
            .values(
                status=status,
                current_step=(
                    f"Retrying {stage_label} in {RETRY_CFG.countdown_s}s "
                    f"(attempt {attempt}/{total_attempts})"
                ),
                updated_at=func.now(),
            )
        )
        await db.commit()


async def _mark_failed(job_id, *, stage_label: str, error: Exception) -> None:
    async with _session_scope() as db:
        prefix = "Script generation failed" if stage_label == "script" else "Audio generation failed"
        await db.execute(
            update(PodcastJob)
            .where(PodcastJob.id == job_id)
            .values(
                status=PodcastJobStatus.FAILED,
                error_message=f"{prefix}: {str(error)}",
                current_step=f"Failed during {stage_label} generation",
                updated_at=func.now(),
            )
        )
        await db.commit()


@celery_app.task(
    name="app.worker.podcast_tasks.script_stage",
    bind=True,
    max_retries=RETRY_CFG.max_retries,
)
def script_stage(self, job_id):
    """Generate the full podcast script."""
    try:
        asyncio.run(_script_stage(job_id))
        return job_id
    except Exception as e:
        # Celery retries is how many times this task has already retried (0 on first failure).
        retries_so_far = int(getattr(self.request, "retries", 0) or 0)
        if retries_so_far < RETRY_CFG.max_retries:
            # attempt number is 1-based for humans: initial=1, first retry run=2, ...
            next_attempt = retries_so_far + 2
            total_attempts = RETRY_CFG.max_retries + 1
            asyncio.run(
                _set_retry_step(
                    job_id,
                    status=PodcastJobStatus.GENERATING_SCRIPT,
                    stage_label="script generation",
                    attempt=next_attempt,
                    total_attempts=total_attempts,
                )
            )
            raise self.retry(exc=e, countdown=RETRY_CFG.countdown_s)

        # Out of retries: mark as failed once and propagate the exception.
        asyncio.run(_mark_failed(job_id, stage_label="script", error=e))
        raise


async def _script_stage(job_id):
    async with _session_scope() as db:
        # Get the job to check if script already exists
        job = await _get_job(db, job_id)
        if not job:
            raise Exception(f"Job {job_id} not found")

        # IDEMPOTENCY: Skip if script already generated
        if job.script_json and job.total_segments:
            # Script exists, just update status and skip generation
            await db.execute(
                update(PodcastJob).where(PodcastJob.id == job_id).values(
                    current_step="Script already generated, skipping...",
                    progress=20,
                    updated_at=func.now(),
                )
            )
            await db.commit()
            return

        # Update status to GENERATING_SCRIPT
        await db.execute(
            update(PodcastJob).where(PodcastJob.id == job_id).values(
                status=PodcastJobStatus.GENERATING_SCRIPT,
                current_step="Generating podcast script...",
                progress=5,
                updated_at=func.now(),
            )
        )
        await db.commit()

        topic = job.topic

        # Generate the full script via AI facade
        llm_res = await AI.generate_podcast_script(topic=topic)
        script = llm_res.get("script", [])
        script_json_str = json.dumps(script, ensure_ascii=False)
        total_segments = len(script)

        # Record token usage (extracted by GeminiAgent.__agenerate_json)
        usage = llm_res.get("_usage")
        if usage:
            await TokenUsageService.record_usage(
                db,
                user_id=job.user_id,
                source="gemini",
                model_name=usage.get("model", ""),
                prompt_tokens=int(usage.get("prompt_tokens", 0)),
                completion_tokens=int(usage.get("completion_tokens", 0)),
                total_tokens=int(usage.get("total_tokens", 0)),
            )

        # Save script to database
        await db.execute(
            update(PodcastJob).where(PodcastJob.id == job_id).values(
                script_json=script_json_str,
                total_segments=total_segments,
                current_step="Script generated successfully",
                progress=20,
                updated_at=func.now(),
            )
        )
        await db.commit()


@celery_app.task(
    name="app.worker.podcast_tasks.audio_stage",
    bind=True,
    max_retries=RETRY_CFG.max_retries,
)
def audio_stage(self, job_id):
    """Generate audio for each script segment."""
    try:
        asyncio.run(_audio_stage(job_id))
        return job_id
    except Exception as e:
        retries_so_far = int(getattr(self.request, "retries", 0) or 0)
        if retries_so_far < RETRY_CFG.max_retries:
            next_attempt = retries_so_far + 2
            total_attempts = RETRY_CFG.max_retries + 1
            asyncio.run(
                _set_retry_step(
                    job_id,
                    status=PodcastJobStatus.GENERATING_AUDIO,
                    stage_label="audio generation",
                    attempt=next_attempt,
                    total_attempts=total_attempts,
                )
            )
            raise self.retry(exc=e, countdown=RETRY_CFG.countdown_s)

        asyncio.run(_mark_failed(job_id, stage_label="audio", error=e))
        raise


async def _audio_stage(job_id):
    async with _session_scope() as db:
        db_lock = asyncio.Lock()

        async def _db_update(**values) -> None:
            # AsyncSession isn't concurrency-safe; ensure only one DB op at a time.
            async with db_lock:
                await db.execute(
                    update(PodcastJob).where(PodcastJob.id == job_id).values(
                        **values,
                        updated_at=func.now(),
                    )
                )
                await db.commit()

        # Update status to GENERATING_AUDIO
        await _db_update(
            status=PodcastJobStatus.GENERATING_AUDIO,
            current_step="Starting audio generation...",
        )

        # Get the job
        job = await _get_job(db, job_id)
        if not job or not job.script_json:
            raise Exception(f"Job {job_id} not found or has no script")

        script = json.loads(job.script_json)
        total_segments = len(script)

        # Create audio folder
        audio_folder = f"app/files/voices/podcast/{job_id}"
        os.makedirs(audio_folder, exist_ok=True)

        # Update job with audio folder path
        await _db_update(audio_folder=audio_folder)

        # Google Cloud Text-to-Speech client (service account from our Jinja template/env)
        from google.cloud import texttospeech as tts
        from google.oauth2 import service_account

        service_account_info = render_service_account_json()
        credentials = service_account.Credentials.from_service_account_info(service_account_info)
        # Prefer the async client so we can synthesize multiple segments concurrently.
        # Falls back to the sync client + executor if needed.
        tts_async_client = getattr(tts, "TextToSpeechAsyncClient", None)
        tts_client = tts_async_client(credentials=credentials) if tts_async_client else tts.TextToSpeechClient(credentials=credentials)

        tts_model_name = settings.TTS_VOICE_MODEL
        sample_rate = 24000
        num_channels = 1
        bits_per_sample = 16
        byte_rate = sample_rate * num_channels * bits_per_sample // 8
        block_align = num_channels * bits_per_sample // 8
        language_code = "en-US"

        # Keep a stable speaker mapping across the whole podcast:
        # Speaker1 = Alex, Speaker2 = Sarah.
        speaker1_id = VOICE_MAP.get("Alex", "Charon")
        speaker2_id = VOICE_MAP.get("Sarah", "Zephyr")
        if speaker2_id == speaker1_id:
            # Ensure two distinct speakers (GCP requirement)
            speaker2_id = "Zephyr" if speaker1_id != "Zephyr" else "Charon"

        multi_cfg = tts.MultiSpeakerVoiceConfig(
            speaker_voice_configs=[
                tts.MultispeakerPrebuiltVoice(
                    speaker_alias="Speaker1",
                    speaker_id=speaker1_id,
                ),
                tts.MultispeakerPrebuiltVoice(
                    speaker_alias="Speaker2",
                    speaker_id=speaker2_id,
                ),
            ]
        )

        voice = tts.VoiceSelectionParams(
            language_code=language_code,
            model_name=tts_model_name,
            multi_speaker_voice_config=multi_cfg,
        )

        audio_config = tts.AudioConfig(
            audio_encoding=tts.AudioEncoding.LINEAR16,
            sample_rate_hertz=sample_rate,
        )

        def _segment_ready(idx: int) -> bool:
            p = f"{audio_folder}/segment_{idx}.wav"
            return os.path.exists(p) and os.path.getsize(p) > 0

        def _count_ready() -> int:
            return sum(1 for i in range(total_segments) if _segment_ready(i))

        # Initial progress (handles resumes where some files already exist)
        initial_done = _count_ready()
        if total_segments > 0:
            initial_progress = 20 + int(80 * initial_done / total_segments)
        else:
            initial_progress = 20
        await _db_update(
            completed_segments=initial_done,
            progress=initial_progress,
            current_step=f"Audio generation started ({initial_done}/{total_segments} ready)",
        )

        # Build list of missing segments to synthesize
        to_generate: list[tuple[int, dict]] = [
            (i, turn) for i, turn in enumerate(script) if not _segment_ready(i)
        ]

        # Nothing to do (resume case)
        if not to_generate:
            await _db_update(
                status=PodcastJobStatus.COMPLETED,
                current_step="Podcast generation completed",
                progress=100,
            )
            return

        # Concurrency (env override); keep bounded
        try:
            concurrency = int(os.getenv("PODCAST_AUDIO_CONCURRENCY", str(DEFAULT_AUDIO_CONCURRENCY)))
        except Exception:
            concurrency = DEFAULT_AUDIO_CONCURRENCY
        concurrency = max(1, min(concurrency, 8))
        sem = asyncio.Semaphore(concurrency)

        async def _synthesize_one(index: int, turn: dict) -> None:
            audio_path = f"{audio_folder}/segment_{index}.wav"

            # Double-check idempotency inside the worker (another attempt might have written it)
            if os.path.exists(audio_path) and os.path.getsize(audio_path) > 0:
                return

            speaker = (turn or {}).get("speaker", "Alex")
            text = (turn or {}).get("text", "")

            # Map script speakers to multi-speaker aliases
            speaker_alias = "Speaker1" if speaker == "Alex" else "Speaker2"
            voice_name = speaker1_id if speaker_alias == "Speaker1" else speaker2_id

            turns = [
                tts.MultiSpeakerMarkup.Turn(
                    speaker=speaker_alias,
                    text=(text or "").strip() or " ",
                )
            ]
            synthesis_input = tts.SynthesisInput(
                multi_speaker_markup=tts.MultiSpeakerMarkup(turns=turns),
            )

            async with sem:
                llm_t0 = time.perf_counter()
                llm_err: Exception | None = None
                try:
                    if tts_async_client:
                        response = await tts_client.synthesize_speech(
                            input=synthesis_input, voice=voice, audio_config=audio_config
                        )
                    else:
                        # Sync client fallback: run in a thread so we can still overlap calls.
                        response = await asyncio.to_thread(
                            tts_client.synthesize_speech,
                            input=synthesis_input,
                            voice=voice,
                            audio_config=audio_config,
                        )
                except Exception as e:
                    llm_err = e
                    raise
                finally:
                    llm_dt = time.perf_counter() - llm_t0
                    logger.info(
                        "podcast_audio_stage_llm_timing job_id=%s segment=%s/%s model=%s voice=%s chars=%s duration_s=%.3f success=%s",
                        job_id,
                        index + 1,
                        total_segments,
                        tts_model_name,
                        voice_name,
                        len(text),
                        llm_dt,
                        llm_err is None,
                    )

            audio_bytes = getattr(response, "audio_content", None)
            if not audio_bytes:
                raise Exception(f"No audio data returned for segment {index}")

            # Some providers return raw PCM; ensure we persist a valid WAV file.
            if not audio_bytes.startswith(b"RIFF"):
                data_size = len(audio_bytes)
                wav_header = struct.pack(
                    "<4sI4s4sIHHIIHH4sI",
                    b"RIFF",
                    36 + data_size,  # File size - 8
                    b"WAVE",
                    b"fmt ",
                    16,  # fmt chunk size
                    1,  # Audio format (1 = PCM)
                    num_channels,
                    sample_rate,
                    byte_rate,
                    block_align,
                    bits_per_sample,
                    b"data",
                    data_size,
                )
                audio_bytes = wav_header + audio_bytes

            # Atomic write to avoid corruption if overlapping retries run concurrently.
            def _write_atomic():
                tmp_path = f"{audio_path}.tmp-{os.getpid()}"
                with open(tmp_path, "wb") as f:
                    f.write(audio_bytes)
                os.replace(tmp_path, audio_path)

            await asyncio.to_thread(_write_atomic)

        # Kick off synthesis tasks
        tasks = [asyncio.create_task(_synthesize_one(i, turn)) for i, turn in to_generate]

        stop_heartbeat = asyncio.Event()

        async def _heartbeat() -> None:
            # Keep updated_at fresh so API-side "stale job" detection doesn't spuriously re-enqueue.
            while not stop_heartbeat.is_set():
                try:
                    await asyncio.wait_for(stop_heartbeat.wait(), timeout=JOB_HEARTBEAT_INTERVAL_S)
                except TimeoutError:
                    done = _count_ready()
                    progress = 20 + int(80 * done / total_segments) if total_segments else 20
                    await _db_update(
                        completed_segments=done,
                        progress=progress,
                        current_step=f"Generating audio segments ({done}/{total_segments})",
                    )

        heartbeat_task = asyncio.create_task(_heartbeat())

        # Process completions sequentially for DB updates (AsyncSession is not concurrency-safe)
        first_err: Exception | None = None
        try:
            for t in asyncio.as_completed(tasks):
                try:
                    await t
                except Exception as e:
                    # Keep going so one bad segment doesn't waste work; retries will fill gaps.
                    if first_err is None:
                        first_err = e

                done = _count_ready()
                progress = 20 + int(80 * done / total_segments) if total_segments else 20
                await _db_update(
                    completed_segments=done,
                    progress=progress,
                    current_step=f"Generated audio segments ({done}/{total_segments})",
                )
        finally:
            stop_heartbeat.set()
            await heartbeat_task

        # If anything failed, raise to trigger Celery retry (idempotency will skip existing files)
        if first_err is not None:
            raise first_err

        # Mark as completed
        await _db_update(
            status=PodcastJobStatus.COMPLETED,
            current_step="Podcast generation completed",
            progress=100,
        )

        # Record token usage for audio generation (TTS)
        # We charge per character synthesized
        total_chars = 0
        for turn in script:
            text = (turn or {}).get("text", "") or ""
            total_chars += len(text)
        
        if total_chars > 0:
            await TokenUsageService.record_usage(
                db,
                user_id=job.user_id,
                source="tts",
                model_name=settings.TTS_VOICE_MODEL,
                prompt_tokens=0,
                completion_tokens=0,
                total_tokens=total_chars, # Reuse total_tokens field for char count
            )


def enqueue_podcast_job(job_id):
    """Enqueue a podcast generation job with script and audio stages."""
    c = chain(
        script_stage.s(str(job_id)),
        audio_stage.si(str(job_id)),
    )
    c.apply_async(queue="podcast")
