from __future__ import annotations
from pathlib import Path
from typing import Optional
import importlib.util
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator


def get_app_dir() -> Path:
    spec = importlib.util.find_spec("app")
    if spec and spec.origin:
        return Path(spec.origin).resolve().parent
    return (Path.cwd() / "app").resolve()


class Settings(BaseSettings):
    APP_NAME: str = "Dorna AI Keyboard Backend"
    API_BASE_URL: Optional[str] = None
    APP_BASE_URL: Optional[str] = None
    DB_URL: Optional[str] = None
    JWT_SECRET: Optional[str] = None
    JWT_ALGO: Optional[str] = None
    ACCESS_TTL_MIN: Optional[int] = None
    REFRESH_TTL_DAYS: Optional[int] = None
    PRE_AUTH_TTL_MIN: Optional[int] = None
    RATE_PRE_AUTH_PER_MIN: Optional[int] = None
    SIGNUP_TOKEN_TTL_MIN: Optional[int] = None
    GOOGLE_OAUTH_CLIENT_ID: Optional[str] = None
    APPLE_CLIENT_ID: Optional[str] = None
    # --- Google Calendar (auth-code flow, offline access) ---
    GOOGLE_OAUTH_CLIENT_SECRET: Optional[str] = None
    GOOGLE_TOKEN_URI: Optional[str] = "https://oauth2.googleapis.com/token"
    CALENDAR_TOKEN_ENC_KEY: Optional[str] = None  # Fernet key for token-at-rest
    VERIFY_TOKEN_TTL_MIN: Optional[int] = None
    RATE_SIGNIN_PER_MIN: Optional[int] = None
    RATE_SIGNUP_PER_MIN: Optional[int] = None
    RATE_RESEND_ACTIVE_PER_MIN: Optional[int] = None
    AVATAR_MAX_MB: Optional[int] = None
    LLM_AGENT: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    # When set, all google-genai calls are routed to this base URL instead of
    # Google's servers (e.g. a claude-gateway instance speaking the Gemini wire
    # protocol). Leave unset to call Gemini directly. Do NOT include "/v1beta" —
    # the SDK appends the version path itself. In gateway mode GEMINI_API_KEY must
    # hold the gateway's API key (sent as the x-goog-api-key header).
    GEMINI_BASE_URL: Optional[str] = None
    # Real Google Gemini API key used only by flows that must bypass the gateway
    # (Google Search grounding in news/topics — see make_genai_client(force_direct=True)).
    # In gateway mode GEMINI_API_KEY is the gateway's key, so those flows need this
    # separate Google key. Leave unset when not using the gateway; the direct path
    # then falls back to GEMINI_API_KEY, which is already the real Google key.
    GEMINI_DIRECT_API_KEY: Optional[str] = None
    GRAMMAR_MODEL: Optional[dict] = None
    TRANSLATE_MODEL: Optional[str] = None
    TONE_MODEL: Optional[str] = None
    TTS_COVER_MODEL: Optional[str] = None
    TTS_OCR_MODEL: Optional[str] = None
    TTS_PROCESS_MODEL: Optional[str] = None
    TTS_VOICE_MODEL: Optional[str] = None
    PODCAST_GENERATE_MODEL: Optional[str] = None
    PDOCAST_TTS_MODEL: Optional[str] = None
    ARTICLE_REFRESH_RETRY_DELAY_SEC: Optional[int] = None
    ARTICLE_REFRESH_MAX_RETRIES: Optional[int] = None
    USER_APPROVED_TONE_LIMIT: Optional[int] = None
    ASSISTANT_TONES: Optional[list] = None
    ASSISTANT_LANGS: Optional[list] = None
    CORS_ORIGINS: Optional[list] = None
    TTS_MAX_UPLOAD_IMAGES: Optional[int] = None
    GEMINI_COST_PER_1K_USD: Optional[float] = None
    TTS_COST_PER_1K_USD: Optional[float] = None
    SYSTEM_COST_PER_1K_USD: Optional[float] = None
    MODEL_PRICING: Optional[dict] = None
    REDIS_URL: Optional[str] = None
    CELERY_BROKER_URL: Optional[str] = None
    CELERY_RESULT_BACKEND: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_TYPE: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_PROJECT_ID: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_PRIVATE_KEY_ID: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_PRIVATE_KEY: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_CLIENT_EMAIL: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_CLIENT_ID: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_AUTH_URI: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_TOKEN_URI: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_AUTH_PROVIDER_X509_CERT_URL: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_CLIENT_X509_CERT_URL: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS_UNIVERSE_DOMAIN: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    # FCM push: reuses the Google service account above; falls back to its project id.
    FCM_PROJECT_ID: Optional[str] = None
    RESET_TTL_MIN: Optional[int] = None
    BREVO_API_KEY: Optional[str] = None
    BREVO_DORNA_FORGET_PASS_TEMPLATE_ID: Optional[int] = None
    BREVO_DORNA_SIGNUP_TEMPLATE_ID: Optional[int] = None


    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        env_nested_delimiter="__",
    )

    @field_validator("GOOGLE_APPLICATION_CREDENTIALS", mode="before")
    @classmethod
    def _expand_gcp_key(cls, v: str) -> str:
        if not v:
            return v
        raw = str(v).strip()
        if raw.startswith("{") and raw.endswith("}"):
            return raw
        p = Path(str(v)).expanduser()
        if p.is_absolute():
            return str(p)

        app_dir = get_app_dir()
        candidate = (app_dir / "files" / p).resolve()
        return str(candidate)


settings = Settings()
