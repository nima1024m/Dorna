from __future__ import annotations
import json
import re
import mimetypes
from pathlib import Path
from typing import List, Optional

from jinja2 import Environment, FileSystemLoader

from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
)

import logging

from google import genai
from google.genai import types

from app.core.config import settings
from app.core.agents.gc_renderer import render_service_account_json


logger = logging.getLogger(__name__)

class GeminiRetryableModelError(Exception):
    """
    Raised when Gemini returns a syntactically valid response (e.g. JSON) but the
    payload indicates an application-level failure (e.g. {"status":"ERROR"}).

    This is intentionally an Exception so Tenacity can retry it.
    """

class GeminiAgent:
    def __init__(self):
        self.__client = genai.Client(api_key=settings.GEMINI_API_KEY)

        self.__prompt_dir = 'app/files/prompt'
        self.__grammar_prompt = 'grammar_system_prompt.txt'
        self.__punctuation_prompt = 'punctuation_system_prompt.txt'
        self.__grammar_fix_prompt = 'grammar_fix_system_prompt.txt'
        self.__tone_prompt = 'tone_system_prompt.txt'
        self.__translate_prompt = 'translate_system_prompt.txt'
        self.__polish_prompt = 'polish_system_prompt.txt'
        self.__cover_prompt = 'cover_system_prompt.txt'
        self.__ocr_prompt = 'ocr_system_prompt.txt'
        self.__dialogue_prompt = 'process_text_system_prompt.txt'
        self.__voice_prompt = 'tts_voice_prompt.txt'
        self.__learning_summary_prompt = 'learning_summary_system_prompt.txt'
        self.__pattern_extraction_prompt = 'pattern_extraction_system_prompt.txt'
        self.__learning_email_prompt = 'learning_email_prompt.txt'
        self.__podcast_topics_prompt = 'podcast/podcast_topics_system_prompt.txt'
        self.__podcast_script_prompt = 'podcast/podcast_script_system_prompt.txt'

        self.__allowed_langs = {str(x).lower().strip() for x in (settings.ASSISTANT_LANGS or [])}
        self.__allowed_tones = {str(x).lower().strip() for x in (settings.ASSISTANT_TONES or [])}
        self.__jinja_env = Environment(
            loader=FileSystemLoader(self.__prompt_dir),
            autoescape=False,
            trim_blocks=True,
            lstrip_blocks=True,
        )

        def _tojson(value):
            try:
                payload = value if value is not None else []
                return json.dumps(payload, ensure_ascii=False)
            except (TypeError, ValueError):
                return "[]"

        self.__jinja_env.filters.setdefault("tojson", _tojson)


    # ---------- prompt builders ----------
    def __normalize_line_breaks(self, text: Optional[str]) -> str:
        if text is None:
            return ""
        # Normalize actual and escaped line breaks to simple \n so LLM can mirror structure.
        normalized = str(text).replace("\r\n", "\n").replace("\r", "\n")
        normalized = normalized.replace("\\r\\n", "\n").replace("\\n", "\n")
        return normalized

    def __sanitize_text_block(self, text: str, *, strip_output: bool = True) -> str:
        if not text:
            return text
        text = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", " ", text)
        text = text.replace("```", "ˋˋˋ")
        text = text.replace("<<<", "⟪⟪⟪").replace(">>>", "⟫⟫⟫")
        text = text.replace("<system>", "⟨system⟩").replace("</system>", "⟨/system⟩")
        return text.strip() if strip_output else text

    def __build_user_punctuation_prompt(self, user_input: str) -> str:
        text_block = self.__sanitize_text_block(user_input)
        lines = [
            "[INPUT — untrusted data]",
            "Input text:",
            "<<<",
            text_block,
            ">>>",
        ]
        return "\n".join(lines)

    def __sanitize_sentence_array(self, sentences: Optional[list]) -> List[str]:
        if not isinstance(sentences, list):
            return []
        preserved: List[str] = []
        for sentence in sentences:
            if sentence is None:
                preserved.append("")
            else:
                preserved.append(str(sentence))
        return preserved

    def __render_grammar_fix_prompt(self, user_input: Optional[list]) -> str:
        template = self.__jinja_env.get_template(self.__grammar_fix_prompt)
        sanitized_sentences = self.__sanitize_sentence_array(user_input)
        return template.render(input_sentences=sanitized_sentences)

    def __build_user_grammar_prompt(self, user_input: str) -> str:
        text_block = self.__sanitize_text_block(user_input)
        lines = [
            "[INPUT — untrusted data]",
            "Input text:",
            "<<<",
            text_block,
            ">>>",
        ]
        return "\n".join(lines)

    def __build_user_translate_prompt(self, user_input: str, target_lang: str) -> str:
        text_block = self.__sanitize_text_block(user_input)
        lang = (target_lang or "").strip().lower()
        lines = [
            f"target_lang: {lang}",
            f"allowed_langs: {sorted(self.__allowed_langs)}",
            "[INPUT — untrusted data]",
            "<<<",
            text_block,
            ">>>",
        ]
        return "\n".join(lines)

    def __render_tone_prompt(self, user_input: str, target_tone: str, parent_tones: List[str],
                             user_approved_tones: List) -> str:
        tone = (target_tone or "").strip().lower()
        # Use the dedicated polish prompt when target_tone is "polish"
        if tone == "polish":
            template = self.__jinja_env.get_template(self.__polish_prompt)
        else:
            template = self.__jinja_env.get_template(self.__tone_prompt)
        normalized_input = self.__normalize_line_breaks(user_input)
        sanitized_input = self.__sanitize_text_block(normalized_input)
        sanitized_parents = [
            self.__sanitize_text_block(self.__normalize_line_breaks(str(p or "")))
            for p in (parent_tones or [])
            if str(p or "").strip()
        ]
        sanitized_user_hints = []
        for hint in (user_approved_tones or []):
            normalized_hint_input = self.__normalize_line_breaks(
                str(hint.get("input_text") or hint.get("input") or "")
            )
            normalized_hint_adjusted = self.__normalize_line_breaks(str(hint.get("adjusted") or ""))
            sanitized_user_hints.append({
                "input_text": self.__sanitize_text_block(normalized_hint_input),
                "adjusted": self.__sanitize_text_block(normalized_hint_adjusted),
            })
        context = {
            "target_tone": tone,
            "parent_tones": sanitized_parents,
            "user_approved_tones": sanitized_user_hints,
            "allowed_tones": sorted(self.__allowed_tones),
            "input_text": sanitized_input,
        }
        return template.render(**context)

    # ---------- utils ----------
    def __safe_parse_json(self, s: str) -> dict:
        try:
            return json.loads(s)
        except Exception:
            start = s.find("{")
            end = s.rfind("}")
            if start == -1 or end == -1 or end < start:
                raise ValueError("Model did not return a valid JSON object.")
            snippet = s[start:end + 1]
            return json.loads(snippet)

    def __guess_mime_type_by_path(self, path: str) -> str:
        default = "image/png"
        if not path:
            return default
        mt, _ = mimetypes.guess_type(path)
        if mt and mt.startswith("image/"):
            return mt
        ext = Path(path).suffix.lower()
        return {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png",
            ".webp": "image/webp",
        }.get(ext, default)

    # ---------- JSON Schemas ----------
    def __punctuation_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "sentences": types.Schema(type=types.Type.STRING),
            },
            required=["status"],
        )

    def __grammar_fix_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "corrections": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "changed": types.Schema(type=types.Type.BOOLEAN),
                            "suggestion": types.Schema(type=types.Type.STRING),
                            "explanation": types.Schema(type=types.Type.STRING),
                        },
                        required=["changed", "suggestion"],
                    ),
                ),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status", "corrections"],
        )

    def __grammar_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "corrections": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "changed": types.Schema(type=types.Type.BOOLEAN),
                            "suggestion": types.Schema(type=types.Type.STRING),
                            "explanation": types.Schema(type=types.Type.STRING),
                            "original": types.Schema(type=types.Type.STRING),
                        },
                        required=["changed", "suggestion", "original"],
                    ),
                ),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status", "corrections"],
        )

    def __translate_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "translated": types.Schema(type=types.Type.STRING),
                "correct_input": types.Schema(type=types.Type.STRING),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status"],
        )

    def __tone_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "adjusted": types.Schema(type=types.Type.STRING),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status"],
        )


    def __cover_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "extractions": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "index": types.Schema(type=types.Type.INTEGER),
                            "path": types.Schema(type=types.Type.STRING),
                            "text": types.Schema(type=types.Type.STRING),
                        },
                        required=["text"],
                    ),
                ),
            },
            required=["status", "extractions"],
        )

    def __ocr_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "extractions": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "index": types.Schema(type=types.Type.INTEGER),
                            "path": types.Schema(type=types.Type.STRING),
                            "text": types.Schema(type=types.Type.STRING),
                        },
                        required=["text"],
                    ),
                ),
            },
            required=["status", "extractions"],
        )

    def __dialogue_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "speakers": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "id": types.Schema(type=types.Type.STRING),
                            "name": types.Schema(type=types.Type.STRING),
                            "voice": types.Schema(type=types.Type.STRING),
                            "lang": types.Schema(type=types.Type.STRING),
                        },
                        required=["id", "voice"],
                    ),
                ),
                "turns": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "speaker": types.Schema(type=types.Type.STRING),
                            "text": types.Schema(type=types.Type.STRING),
                        },
                        required=["speaker", "text"],
                    ),
                ),
                "tts_prompt": types.Schema(type=types.Type.STRING),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status", "speakers", "turns"],
        )

    def __gen_config(self, schema: types.Schema) -> types.GenerateContentConfig:
        return types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=schema,
            temperature=0.1,
        )

    def __extract_usage(self, response, model: str) -> dict | None:
        usage = getattr(response, "usage_metadata", None) or getattr(response, "usageMetadata", None)
        if not usage:
            return None

        prompt_tokens = getattr(usage, "prompt_token_count", None) or getattr(usage, "promptTokenCount", None)
        completion_tokens = getattr(usage, "candidates_token_count", None) or getattr(usage, "candidatesTokenCount", None)
        total_tokens = getattr(usage, "total_token_count", None) or getattr(usage, "totalTokenCount", None)

        if total_tokens is None and (prompt_tokens is not None or completion_tokens is not None):
            total_tokens = (prompt_tokens or 0) + (completion_tokens or 0)

        if total_tokens is None:
            return None

        return {
            "model": model,
            "prompt_tokens": int(prompt_tokens or 0),
            "completion_tokens": int(completion_tokens or 0),
            "total_tokens": int(total_tokens or 0),
        }

    def __raise_if_error_status(self, payload: dict) -> None:
        """
        Decide whether the model's JSON payload represents an application-level failure.

        Important: different prompts may use different "status" vocabularies (e.g. OK/ERROR vs SUCCESS/...).
        We only treat explicit failure statuses as retryable errors.
        """
        status = str((payload or {}).get("status") or "").strip().upper()
        if not status:
            return

        # Keep this conservative: only explicit failures trigger retry.
        # (e.g. TTS dialogue processing can legitimately return SUCCESS / NO_DIALOGUE_DETECTED.)
        error_statuses = {"ERROR", "FAILED"}
        if status in error_statuses:
            msg = (payload or {}).get("message")
            raise GeminiRetryableModelError(f"Gemini returned status={status}. message={msg!r}")

    # ---------- LLM calls ----------
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )
    async def __agenerate(self, model: str, full_prompt: str, schema: types.Schema):
        response = await self.__client.aio.models.generate_content(
            model=model,
            contents=full_prompt,
            config=self.__gen_config(schema),
        )
        return response

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )
    async def __agenerate_json(self, model: str, full_prompt: str, schema: types.Schema) -> dict:
        """
        Generate content and return parsed JSON (dict).

        Key difference vs __agenerate(): parsing + error-status validation happen inside
        the retry wrapper so we can retry on:
        - Transport/SDK exceptions
        - Invalid/garbled JSON
        - Model-level failures signaled in the payload (status in {"ERROR","FAILED"})
        """
        response = await self.__client.aio.models.generate_content(
            model=model,
            contents=full_prompt,
            config=self.__gen_config(schema),
        )
        payload = self.__safe_parse_json(getattr(response, "text", "") or "")
        if not isinstance(payload, dict):
            raise ValueError("Model did not return a JSON object.")
        self.__raise_if_error_status(payload)
        usage = self.__extract_usage(response, model)
        if usage:
            payload["_usage"] = usage
        return payload
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )
    async def __agenerate_images(self, model: str, prompt_text: str, image_parts: List[types.Part],
                                 schema: types.Schema):
        contents = [prompt_text] + image_parts
        response = await self.__client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=self.__gen_config(schema),
        )
        return response

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )
    async def __agenerate_images_json(
        self,
        model: str,
        prompt_text: str,
        image_parts: List[types.Part],
        schema: types.Schema,
    ) -> dict:
        contents = [prompt_text] + image_parts
        response = await self.__client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=self.__gen_config(schema),
        )
        payload = self.__safe_parse_json(getattr(response, "text", "") or "")
        if not isinstance(payload, dict):
            raise ValueError("Model did not return a JSON object.")
        self.__raise_if_error_status(payload)
        usage = self.__extract_usage(response, model)
        if usage:
            payload["_usage"] = usage
        return payload

    async def ai_health(self) -> bool:
        try:
            model = settings.GRAMMAR_MODEL['seperator']
            _ = self.__client.models.count_tokens(
                model=model,
                contents="ping"
            )
            return True
        except Exception:
            return False

    # ---------- tasks ----------
    async def sentence_seperator(self, user_input: str) -> dict:
        model = settings.GRAMMAR_MODEL['seperator']
        punctuation_system_prompt = open(
            f"{self.__prompt_dir}/{self.__punctuation_prompt}", encoding="utf-8"
        ).read().strip()

        user_prompt_punctuation = self.__build_user_punctuation_prompt(user_input=user_input)
        full_prompt = f"{punctuation_system_prompt}\n\n{user_prompt_punctuation}"

        return await self.__agenerate_json(model, full_prompt, self.__punctuation_schema())

    async def grammar_fix(self, user_input: list) -> dict:
        model = settings.GRAMMAR_MODEL['grammar_fix']
        full_prompt = self.__render_grammar_fix_prompt(user_input=user_input)

        return await self.__agenerate_json(model, full_prompt, self.__grammar_fix_schema())

    async def grammar_correction(self, user_input: str) -> dict:
        model = settings.GRAMMAR_MODEL
        grammar_system_prompt = open(
            f"{self.__prompt_dir}/{self.__grammar_prompt}", encoding="utf-8"
        ).read().strip()

        user_prompt_grammar = self.__build_user_grammar_prompt(user_input=user_input)
        full_prompt = f"{grammar_system_prompt}\n\n{user_prompt_grammar}"

        return await self.__agenerate_json(model, full_prompt, self.__grammar_schema())

    async def translate_text(self, user_input: str, target_lang: str) -> dict:
        model = settings.TRANSLATE_MODEL
        translate_system_prompt = open(
            f"{self.__prompt_dir}/{self.__translate_prompt}", encoding="utf-8"
        ).read().strip()

        user_prompt_translate = self.__build_user_translate_prompt(
            user_input=user_input,
            target_lang=target_lang
        )
        full_prompt = f"{translate_system_prompt}\n\n{user_prompt_translate}"

        return await self.__agenerate_json(model, full_prompt, self.__translate_schema())

    async def tone_adjustment(self, user_input: str, target_tone: str, parent_tones: List[str],
                              user_approved_tones: List) -> dict:
        model = settings.TONE_MODEL
        full_prompt = self.__render_tone_prompt(
            user_input=user_input,
            target_tone=target_tone,
            parent_tones=parent_tones,
            user_approved_tones=user_approved_tones
        )

        return await self.__agenerate_json(model, full_prompt, self.__tone_schema())

    # ---------- Podcast ----------
    def __podcast_topics_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "topics": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "query": types.Schema(type=types.Type.STRING),
                            "title": types.Schema(type=types.Type.STRING),
                            "description": types.Schema(type=types.Type.STRING),
                            "category": types.Schema(type=types.Type.STRING),
                        },
                        required=["query"],
                    ),
                ),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status", "topics"],
        )

    def __podcast_script_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "status": types.Schema(type=types.Type.STRING),
                "script": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "speaker": types.Schema(type=types.Type.STRING),
                            "text": types.Schema(type=types.Type.STRING),
                        },
                        required=["speaker", "text"],
                    ),
                ),
                "message": types.Schema(type=types.Type.STRING),
            },
            required=["status", "script"],
        )

    def __render_podcast_topics_prompt(self, interests: str, already_covered: str, count: int) -> str:
        template = self.__jinja_env.get_template(self.__podcast_topics_prompt)
        return template.render(
            interests=self.__sanitize_text_block(interests or ""),
            already_covered=self.__sanitize_text_block(already_covered or ""),
            count=int(count),
        )

    def __render_podcast_script_prompt(self, topic: str) -> str:
        template = self.__jinja_env.get_template(self.__podcast_script_prompt)
        return template.render(
            topic=self.__sanitize_text_block(topic or ""),
        )

    async def suggest_podcast_topics(self, interests: str, already_covered: str, count: int) -> dict:
        model = settings.PODCAST_GENERATE_MODEL
        full_prompt = self.__render_podcast_topics_prompt(
            interests=interests,
            already_covered=already_covered,
            count=count,
        )
        return await self.__agenerate_json(model, full_prompt, self.__podcast_topics_schema())

    async def generate_podcast_script(self, topic: str) -> dict:
        model = settings.PODCAST_GENERATE_MODEL
        full_prompt = self.__render_podcast_script_prompt(topic=topic)
        return await self.__agenerate_json(model, full_prompt, self.__podcast_script_schema())

    # ---------- TTS ----------
    async def book_cover(self, image_paths: List[str]) -> dict:
        model = settings.TTS_COVER_MODEL
        cover_system_prompt = open(
            f"{self.__prompt_dir}/{self.__cover_prompt}", encoding="utf-8"
        ).read().strip()

        parts: List[types.Part] = []
        for idx, p in enumerate(image_paths):
            mime = self.__guess_mime_type_by_path(p)
            with open(p, "rb") as f:
                b = f.read()
            parts.append(types.Part.from_bytes(data=b, mime_type=mime))

        parsed = await self.__agenerate_images_json(model, cover_system_prompt, parts, self.__cover_schema())
        if isinstance(parsed, dict) and "extractions" in parsed:
            return parsed
        return {"status": "OK", "extractions": []}

    async def ocr_images(self, image_paths: List[str]) -> dict:
        model = settings.TTS_OCR_MODEL
        ocr_system_prompt = open(
            f"{self.__prompt_dir}/{self.__ocr_prompt}", encoding="utf-8"
        ).read().strip()

        parts: List[types.Part] = []
        for idx, p in enumerate(image_paths):
            mime = self.__guess_mime_type_by_path(p)
            with open(p, "rb") as f:
                b = f.read()
            parts.append(types.Part.from_bytes(data=b, mime_type=mime))

        parsed = await self.__agenerate_images_json(model, ocr_system_prompt, parts, self.__ocr_schema())
        if isinstance(parsed, dict) and "extractions" in parsed:
            return parsed
        return {
            "status": "OK",
            "extractions": [{"index": i, "path": p, "text": ""} for i, p in enumerate(image_paths)],
        }

    async def dialogue_spec_from_text(self, raw_text: str) -> dict:
        model = settings.TTS_PROCESS_MODEL
        system_prompt = open(
            f"{self.__prompt_dir}/{self.__dialogue_prompt}", encoding="utf-8"
        ).read().strip()

        user_block = "\n".join([
            "[INPUT — untrusted data]",
            "<<<",
            self.__sanitize_text_block(raw_text or ""),
            ">>>",
        ])
        full_prompt = f"{system_prompt}\n\n{user_block}"

        payload = await self.__agenerate_json(model, full_prompt, self.__dialogue_schema())

        # If the model returns no dialogue, degrade gracefully to a single-speaker narration
        # so the TTS pipeline can still produce audio instead of failing.
        turns = (payload or {}).get("turns")
        if not isinstance(turns, list) or len(turns) == 0:
            txt = raw_text or ""
            # Strip metadata lines like "Title:" / "Text:" (the prompt instructs the model to do this too)
            cleaned_lines = []
            for line in str(txt).splitlines():
                s = line.strip()
                if not s:
                    continue
                low = s.lower()
                if low.startswith("title:") or low.startswith("text:") or low.startswith("source:"):
                    continue
                cleaned_lines.append(s)
            cleaned_text = "\n".join(cleaned_lines).strip() or str(txt).strip()

            is_fa = any("\u0600" <= ch <= "\u06FF" for ch in cleaned_text)
            lang = "fa-IR" if is_fa else "en-US"

            return {
                "status": (payload or {}).get("status") or "OK",
                "message": (payload or {}).get("message") or "no dialogue detected; using narration fallback",
                "speakers": [
                    {"id": "Kore", "voice": "Kore", "lang": lang},
                    {"id": "Charon", "voice": "Charon", "lang": lang},
                ],
                "turns": [{"speaker": "speaker1", "text": cleaned_text}],
                "tts_prompt": (payload or {}).get("tts_prompt") or "",
            }

        return payload

    async def synthesize_multispeaker(self, spec: dict, out_path: str) -> None:
        try:
            from google.cloud import texttospeech as tts
            from google.oauth2 import service_account

            service_account_info = render_service_account_json()
            credentials = service_account.Credentials.from_service_account_info(service_account_info)
            client = tts.TextToSpeechClient(credentials=credentials)

            speakers_spec = (spec or {}).get("speakers") or []
            turns_in = (spec or {}).get("turns") or []

            prompt = open(
                f"{self.__prompt_dir}/{self.__voice_prompt}", encoding="utf-8"
            ).read().strip()
            model_name = settings.TTS_VOICE_MODEL
            speaking_rate = float((spec or {}).get("speaking_rate") or 1.0)
            pitch = float((spec or {}).get("pitch") or 0.0)
            sample_rate = int((spec or {}).get("sample_rate_hz") or 24000)

            lang = "en-US"
            if isinstance(speakers_spec, list) and speakers_spec:
                s0 = speakers_spec[0] or {}
                lang = (s0.get("lang") or "en-US").strip() or "en-US"

            def _alias_for(s: str) -> str:
                if not s:
                    return "Speaker1"
                s = s.strip().lower()
                if s.startswith("speaker2") or s.startswith("b"):
                    return "Speaker2"
                return "Speaker1"

            turns = []
            for item in turns_in:
                if not item:
                    continue
                text = (item.get("text") or "").strip()
                if not text:
                    continue
                alias = _alias_for(item.get("speaker") or "")
                turns.append(tts.MultiSpeakerMarkup.Turn(speaker=alias, text=text))

            if not turns:
                turns = [tts.MultiSpeakerMarkup.Turn(speaker="Speaker1", text=(prompt or " "))]

            synthesis_input = tts.SynthesisInput(
                multi_speaker_markup=tts.MultiSpeakerMarkup(turns=turns),
                prompt=prompt,
            )

            voice_cfg_items = []
            if isinstance(speakers_spec, list):
                for sp in speakers_spec:
                    if not isinstance(sp, dict):
                        continue
                    alias = (sp.get("alias") or sp.get("speaker_alias") or "").strip() or None
                    sid = (sp.get("speaker_id") or sp.get("id") or "").strip() or None
                    if alias in ("Speaker1", "Speaker2") and sid:
                        voice_cfg_items.append(
                            tts.MultispeakerPrebuiltVoice(speaker_alias=alias, speaker_id=sid)
                        )

            if not voice_cfg_items:
                voice_cfg_items = [
                    tts.MultispeakerPrebuiltVoice(speaker_alias="Speaker1", speaker_id="Kore"),
                    tts.MultispeakerPrebuiltVoice(speaker_alias="Speaker2", speaker_id="Charon"),
                ]

            multi_cfg = tts.MultiSpeakerVoiceConfig(speaker_voice_configs=voice_cfg_items)

            voice = tts.VoiceSelectionParams(
                language_code=lang,
                model_name=model_name,
                multi_speaker_voice_config=multi_cfg,
            )

            audio_config = tts.AudioConfig(
                audio_encoding=tts.AudioEncoding.LINEAR16,  # WAV
                sample_rate_hertz=sample_rate,
                speaking_rate=speaking_rate,
                pitch=pitch,
            )

            response = client.synthesize_speech(
                input=synthesis_input, voice=voice, audio_config=audio_config
            )

            with open(out_path, "wb") as f:
                f.write(response.audio_content)
            return

        except Exception as e:
            raise

    def __learning_summary_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "summary": types.Schema(type=types.Type.STRING),
            },
            required=["summary"],
        )

    async def user_learning_summary(self, grammar_issues: dict, misspelled_words: dict) -> dict:
        model = settings.TONE_MODEL  # Using TONE_MODEL for generic text tasks
        template = self.__jinja_env.get_template(self.__learning_summary_prompt)
        
        full_prompt = template.render(
            grammar_issues=json.dumps(grammar_issues),
            misspelled_words=json.dumps(misspelled_words)
        )

        return await self.__agenerate_json(model, full_prompt, self.__learning_summary_schema())

    def __pattern_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "estimated_clb_level": types.Schema(type=types.Type.STRING),
                "language_development_grammar": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "topic": types.Schema(type=types.Type.STRING),
                            "rationale": types.Schema(type=types.Type.STRING),
                        },
                        required=["topic", "rationale"]
                    )
                ),
                "vocabulary_improvement": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "current": types.Schema(type=types.Type.STRING),
                            "target": types.Schema(type=types.Type.STRING),
                        },
                        required=["current", "target"]
                    )
                ),
                "misspelled_words": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "word": types.Schema(type=types.Type.STRING),
                            "correction": types.Schema(type=types.Type.STRING),
                        },
                        required=["word", "correction"]
                    )
                ),
                "patterns": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "structure": types.Schema(type=types.Type.STRING),
                            "observation": types.Schema(type=types.Type.STRING),
                            "example_original": types.Schema(type=types.Type.STRING),
                        },
                        required=["structure", "observation"]
                    )
                ),
                "summary": types.Schema(type=types.Type.STRING),
            },
            required=["estimated_clb_level", "language_development_grammar", "vocabulary_improvement", "misspelled_words", "patterns"],
        )

    async def extract_linguistic_patterns(self, corrections: List[dict]) -> dict:
        model = settings.TONE_MODEL
        template = self.__jinja_env.get_template(self.__pattern_extraction_prompt)
        
        full_prompt = template.render(
            corrections_json=json.dumps(corrections, ensure_ascii=False)
        )

        return await self.__agenerate_json(model, full_prompt, self.__pattern_schema())

    def __email_content_schema(self) -> types.Schema:
        return types.Schema(
            type=types.Type.OBJECT,
            properties={
                "subject": types.Schema(type=types.Type.STRING),
                "html_content": types.Schema(type=types.Type.STRING),
            },
            required=["subject", "html_content"],
        )

    async def generate_learning_email_content(self, learning_profile: dict, user_name: str = "Dorna Achiever") -> dict:
        model = settings.TONE_MODEL
        template = self.__jinja_env.get_template(self.__learning_email_prompt)
        
        full_prompt = template.render(
            user_name=user_name,
            learning_profile_json=json.dumps(learning_profile, ensure_ascii=False)
        )

        return await self.__agenerate_json(model, full_prompt, self.__email_content_schema())
