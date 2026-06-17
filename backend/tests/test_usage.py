# tests/test_usage.py
"""Tests for the typed token-usage seam that replaced the _usage magic key."""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from app.core.agents.usage import (
    TokenUsage,
    attach_usage,
    attach_usages,
    pop_usages,
)
from app.core.agents.gemini import GeminiAgent
from app.services.token_usage import TokenUsageService


class _Usage:
    def __init__(self, p, c, t):
        self.prompt_token_count = p
        self.candidates_token_count = c
        self.total_token_count = t


class _Resp:
    def __init__(self, text, usage=None):
        self.text = text
        self.usage_metadata = usage


def test_attach_and_pop_single():
    payload = {"status": "OK"}
    attach_usage(payload, TokenUsage("m", 1, 2, 3))
    assert payload.get("_usage") == TokenUsage("m", 1, 2, 3)
    assert pop_usages(payload) == [TokenUsage("m", 1, 2, 3)]
    assert "_usage" not in payload  # popped -> cannot leak into an API response


def test_attach_usage_none_is_noop():
    payload = {"status": "OK"}
    attach_usage(payload, None)
    assert payload == {"status": "OK"}
    assert pop_usages(payload) == []


def test_attach_and_pop_list():
    payload = {"corrections": []}
    attach_usages(payload, [TokenUsage("m", 1, 1, 2), TokenUsage("m", 3, 3, 6)])
    assert pop_usages(payload) == [TokenUsage("m", 1, 1, 2), TokenUsage("m", 3, 3, 6)]
    assert "_usage_list" not in payload


def test_pop_usages_tolerates_non_dict():
    assert pop_usages(None) == []
    assert pop_usages([1, 2]) == []


@pytest.mark.anyio
async def test_gemini_attaches_typed_usage(monkeypatch):
    monkeypatch.setattr("app.core.agents.gemini.settings.GEMINI_API_KEY", "fake")
    monkeypatch.setattr("app.core.agents.gemini.settings.ASSISTANT_LANGS", ["en"])
    monkeypatch.setattr("app.core.agents.gemini.settings.ASSISTANT_TONES", ["formal"])
    monkeypatch.setattr("app.core.agents.gemini.settings.GRAMMAR_MODEL", {"seperator": "gemini-x"})

    with patch("app.core.agents.gemini.genai.Client") as cls:
        client = MagicMock()
        cls.return_value = client
        client.aio.models.generate_content = AsyncMock(
            return_value=_Resp('{"status":"OK","sentences":"[]"}', usage=_Usage(10, 20, 30))
        )
        agent = GeminiAgent()
        result = await agent.sentence_seperator("hi")

    # The payload now carries a typed TokenUsage, recovered (and stripped) by pop_usages.
    assert pop_usages(result) == [TokenUsage("gemini-x", 10, 20, 30)]
    assert result["status"] == "OK"
    assert "_usage" not in result


@pytest.mark.anyio
async def test_record_all_records_each(monkeypatch):
    spy = AsyncMock()
    monkeypatch.setattr(TokenUsageService, "record", spy)
    await TokenUsageService.record_all(
        object(), [TokenUsage("m", 1, 1, 2), TokenUsage("m", 3, 3, 6)], user_id=1, source="gemini"
    )
    assert spy.await_count == 2
