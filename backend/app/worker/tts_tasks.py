import asyncio
import json
from typing import Optional
from contextlib import asynccontextmanager

from celery import chain
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import select, update, and_

from app.worker.celery_app import celery_app
from app.core.config import settings
from app.core.database import TaskStatus
from app.models import Task, TaskImage
from app.core.agents.gemini import GeminiAgent
from app.services.token_usage import TokenUsageService
from app.core.config import settings


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


async def _get_task(db: AsyncSession, task_id) -> Optional[Task]:
    res = await db.execute(select(Task).where(Task.id == task_id))
    return res.scalar_one_or_none()


@celery_app.task(name="app.worker.tts_tasks.ocr_stage")
def ocr_stage(task_id):
    asyncio.run(_ocr_stage(task_id))
    return task_id


async def _ocr_stage(task_id):
    async with _session_scope() as db:
        try:
            await db.execute(
                update(Task).where(Task.id == task_id).values(status=TaskStatus.IN_PROGRESS)
            )
            await db.commit()

            res = await db.execute(
                select(TaskImage.address).where(and_(TaskImage.task_id == task_id, TaskImage.is_cover == False))
            )
            image_paths = [row[0] for row in res.fetchall()]

            if not image_paths:
                await db.execute(
                    update(Task).where(Task.id == task_id).values(ocr_text='{"status":"OK","extractions":[]}')
                )
                await db.commit()
                return

            agent = GeminiAgent()
            ocr_json = await agent.ocr_images(image_paths)

            # Record token usage for OCR
            usage = ocr_json.get("_usage")
            if usage:
                await TokenUsageService.record_usage(
                    db,
                    user_id=None,
                    source="tts",
                    model_name=usage.get("model") or settings.TTS_OCR_MODEL,
                    prompt_tokens=usage.get("prompt_tokens", 0),
                    completion_tokens=usage.get("completion_tokens", 0),
                    total_tokens=usage.get("total_tokens", 0),
                )

            ocr_text_str = json.dumps(ocr_json, ensure_ascii=False)
            await db.execute(
                update(Task).where(Task.id == task_id).values(ocr_text=ocr_text_str)
            )
            await db.commit()
        except Exception:
            await db.execute(
                update(Task).where(Task.id == task_id).values(status=TaskStatus.FAILED)
            )
            await db.commit()
            raise


@celery_app.task(name="app.worker.tts_tasks.text_processing_stage")
def text_processing_stage(task_id):
    asyncio.run(_text_processing_stage(task_id))
    return task_id


async def _text_processing_stage(task_id):
    async with _session_scope() as db:
        try:
            task = await _get_task(db, task_id)
            if not task or not task.ocr_text:
                # await asyncio.sleep(1)
                # await db.commit()
                return

            ocr_obj = json.loads(task.ocr_text)
            texts = []
            for item in ocr_obj.get("extractions", []):
                t = (item or {}).get("text", "")
                if t:
                    texts.append(t)
            raw_text = "\n".join(texts).strip()

            agent = GeminiAgent()
            spec = await agent.dialogue_spec_from_text(f'Title: {task.cover_title}\nText: {raw_text}')

            # Record token usage for text processing
            usage = spec.get("_usage")
            if usage:
                await TokenUsageService.record_usage(
                    db,
                    user_id=None,
                    source="tts",
                    model_name=usage.get("model") or settings.TTS_PROCESS_MODEL,
                    prompt_tokens=usage.get("prompt_tokens", 0),
                    completion_tokens=usage.get("completion_tokens", 0),
                    total_tokens=usage.get("total_tokens", 0),
                )

            spec_str = json.dumps(spec, ensure_ascii=False)
            await db.execute(
                update(Task).where(Task.id == task_id).values(ocr_text=spec_str)
            )
            await db.commit()
        except Exception:
            await db.execute(
                update(Task).where(Task.id == task_id).values(status=TaskStatus.FAILED)
            )
            await db.commit()
            raise


@celery_app.task(name="app.worker.tts_tasks.tts_stage")
def tts_stage(task_id):
    asyncio.run(_tts_stage(task_id))
    return task_id


async def _tts_stage(task_id):
    async with _session_scope() as db:
        try:
            res = await db.execute(select(Task).where(Task.id == task_id))
            task = res.scalar_one_or_none()

            spec = {}
            try:
                if task and task.ocr_text:
                    spec = json.loads(task.ocr_text)
            except Exception:
                spec = {}

            voice_path = f"app/files/voices/tts/{task_id}.wav"

            agent = GeminiAgent()
            await agent.synthesize_multispeaker(spec, voice_path)

            await db.execute(
                update(Task).where(Task.id == task_id).values(voice_address=voice_path)
            )
            await db.commit()

            await db.execute(
                update(Task).where(Task.id == task_id).values(status=TaskStatus.COMPLETED)
            )
            await db.commit()

        except Exception:
            await db.execute(
                update(Task).where(Task.id == task_id).values(status=TaskStatus.FAILED)
            )
            await db.commit()
            raise


def enqueue_pipeline(task_id):
    c = chain(
        ocr_stage.s(task_id),
        text_processing_stage.si(task_id),
        tts_stage.si(task_id),
    )
    c.apply_async(queue="tts")
