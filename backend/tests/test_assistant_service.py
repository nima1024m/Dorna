# tests/test_assistant_service.py
import pytest
from app.schemas.assistant import SuggestGrammarIn, SuggestTranslateIn, SuggestToneIn
from app.services.assistant import AssistantService


@pytest.mark.anyio
async def test_service_grammar_ok(monkeypatch, fake_db):
    async def fake_grammar(content: str):
        return {"status": "OK", "corrections": []}

    monkeypatch.setattr("app.core.ai.grammar_correction", fake_grammar)

    data = SuggestGrammarIn(content="text")
    data.user_id = 1
    out = await AssistantService.grammar_correction(fake_db, data)
    assert out["status"] == "OK"
    assert out["task"] == "grammar"
    assert "query_id" in out


@pytest.mark.anyio
async def test_service_translate_error(monkeypatch, fake_db):
    async def fake_translate(content: str, target_lang: str):
        raise RuntimeError("downstream error")

    monkeypatch.setattr("app.core.ai.translate_text", fake_translate)

    data = SuggestTranslateIn(content="Hi", target_lang="fa")
    data.user_id = 1
    out = await AssistantService.translate_text(fake_db, data)
    assert out["status"] == "ERROR"
    assert out["task"] == "translate"
    assert "query_id" in out


@pytest.mark.anyio
async def test_service_tone_ok(monkeypatch, fake_db):
    async def fake_tone(content: str, target_tone: str, parent_tones=None, user_approved_tones=None):
        return {"status": "OK", "adjusted": "Hello."}

    monkeypatch.setattr("app.core.ai.tone_adjustment", fake_tone)

    data = SuggestToneIn(content="hi", target_tone="formal")
    data.user_id = 1
    out = await AssistantService.tone_adjustment(fake_db, data)
    assert out["status"] == "OK"
    assert out["task"] == "tone"
    assert "query_id" in out
