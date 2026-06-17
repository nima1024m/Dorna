"""Factory for the google-genai client.

Single place that constructs ``google.genai.Client`` so the whole backend can be
pointed at a `claude-gateway <https://github.com/SamAG8/claude-gateway>`_ instance
(which speaks the Gemini wire protocol) by setting a single env var, instead of
calling Google's servers directly.

When ``settings.GEMINI_BASE_URL`` is set, requests go to
``{GEMINI_BASE_URL}/v1beta/models/{model}:generateContent`` with the API key sent
as the ``x-goog-api-key`` header — exactly what the gateway expects. The SDK
appends the ``/v1beta`` version path itself, so ``GEMINI_BASE_URL`` must NOT
include it. When the var is unset, behaviour is identical to before (real Gemini).
"""
from __future__ import annotations

from google import genai
from google.genai import types

from app.core.config import settings


def make_genai_client() -> genai.Client:
    """Build a google-genai client, honouring GEMINI_BASE_URL (gateway routing)."""
    http_options = (
        types.HttpOptions(base_url=settings.GEMINI_BASE_URL)
        if settings.GEMINI_BASE_URL
        else None
    )
    return genai.Client(api_key=settings.GEMINI_API_KEY, http_options=http_options)
