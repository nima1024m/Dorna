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

Hybrid routing
--------------
Some flows depend on Google-only features the gateway cannot proxy — notably
**Google Search grounding** used by the news/topic features. Those call sites pass
``force_direct=True`` so they always reach real Gemini, even when the rest of the
backend is pointed at the gateway. Because ``GEMINI_API_KEY`` holds the *gateway's*
key in gateway mode (not a Google key), the direct path prefers
``settings.GEMINI_DIRECT_API_KEY`` and falls back to ``GEMINI_API_KEY`` (which is
the real Google key when no gateway is configured).
"""
from __future__ import annotations

import logging

from google import genai
from google.genai import types

from app.core.config import settings

logger = logging.getLogger(__name__)

# Warn at most once per process about the missing direct key, so logs aren't spammed.
_warned_missing_direct_key = False


def make_genai_client(*, force_direct: bool = False) -> genai.Client:
    """Build a google-genai client.

    Args:
        force_direct: When True, ignore ``GEMINI_BASE_URL`` and always talk to real
            Google Gemini. Use for flows that need Google-only features the gateway
            cannot proxy (e.g. Google Search grounding in news/topics).

    Default (``force_direct=False``) honours ``GEMINI_BASE_URL`` (gateway routing).
    """
    if force_direct:
        api_key = settings.GEMINI_DIRECT_API_KEY or settings.GEMINI_API_KEY
        if settings.GEMINI_BASE_URL and not settings.GEMINI_DIRECT_API_KEY:
            global _warned_missing_direct_key
            if not _warned_missing_direct_key:
                logger.warning(
                    "Grounding flow requested a direct Gemini client while "
                    "GEMINI_BASE_URL is set, but GEMINI_DIRECT_API_KEY is unset; "
                    "falling back to GEMINI_API_KEY, which is the gateway key in "
                    "gateway mode and will likely fail against Google. Set "
                    "GEMINI_DIRECT_API_KEY to a real Google key for news/topics."
                )
                _warned_missing_direct_key = True
        return genai.Client(api_key=api_key, http_options=None)

    http_options = (
        types.HttpOptions(base_url=settings.GEMINI_BASE_URL)
        if settings.GEMINI_BASE_URL
        else None
    )
    return genai.Client(api_key=settings.GEMINI_API_KEY, http_options=http_options)
