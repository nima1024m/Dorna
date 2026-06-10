import uuid
import app.core.ai as AI
from app.core.config import settings


class SystemService:
    @staticmethod
    async def ai_health() -> bool:
        return await AI.ai_health()

    @staticmethod
    async def tts_health() -> bool:
        if not settings.TTS_VOICE_MODEL:
            return False
        if not settings.TTS_COVER_MODEL or not settings.TTS_OCR_MODEL or not settings.TTS_PROCESS_MODEL:
            return False
        if settings.GOOGLE_APPLICATION_CREDENTIALS:
            return True
        if settings.GOOGLE_APPLICATION_CREDENTIALS_CLIENT_EMAIL and settings.GOOGLE_APPLICATION_CREDENTIALS_PRIVATE_KEY:
            return True
        return False
