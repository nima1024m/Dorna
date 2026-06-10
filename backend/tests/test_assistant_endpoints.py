import pytest


@pytest.mark.anyio
async def test_grammar_ok(client, monkeypatch):
    async def fake_grammar(content: str):
        return {
            "status": "OK",
            "corrections": [
                {
                    "changed": True,
                    "suggestion": "He wants to go to Paris.",
                    "explanation": "SV agreement & capitalization",
                    "original": "He want to go paris",
                }
            ],
        }

    monkeypatch.setattr("app.core.ai.grammar_correction", fake_grammar)

    payload = {"content": "he want to go to paris"}
    res = await client.post("/v1/assistant/grammar", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "OK"
    assert data["task"] == "grammar"
    assert "query_id" in data
    assert isinstance(data["corrections"], list)


@pytest.mark.anyio
async def test_translate_ok(client, monkeypatch):
    async def fake_translate(content: str, target_lang: str):
        return {"status": "OK", "translated": "من می‌روم."}

    monkeypatch.setattr("app.core.ai.translate_text", fake_translate)

    payload = {"content": "I go.", "target_lang": "fa"}
    res = await client.post("/v1/assistant/translate", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "OK"
    assert data["task"] == "translate"
    assert "query_id" in data
    assert data["translated"] == "من می‌روم."


@pytest.mark.anyio
async def test_translate_422_invalid_lang(client):
    payload = {"content": "I go.", "target_lang": "de"}
    res = await client.post("/v1/assistant/translate", json=payload)
    assert res.status_code == 422
    data = res.json()
    assert data["status"] == "ERROR"
    assert isinstance(data["detail"], list)


@pytest.mark.anyio
async def test_tone_ok(client, monkeypatch):
    async def fake_tone(content: str, target_tone: str, parent_tones=None, user_approved_tones=None):
        return {"status": "OK", "adjusted": "Could you please review it?"}

    monkeypatch.setattr("app.core.ai.tone_adjustment", fake_tone)

    payload = {"content": "can you review it?", "target_tone": "formal"}
    res = await client.post("/v1/assistant/tone", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "OK"
    assert data["task"] == "tone"
    assert "query_id" in data
    assert data["adjusted"].startswith("Could you please")


@pytest.mark.anyio
async def test_tone_422_invalid_tone(client):
    payload = {"content": "can you review it?", "target_tone": "sarcastic"}
    res = await client.post("/v1/assistant/tone", json=payload)
    assert res.status_code == 422
    data = res.json()
    assert data["status"] == "ERROR"


@pytest.mark.anyio
async def test_translate_llm_internal_error(client, monkeypatch):
    async def fake_translate_raise(content: str, target_lang: str):
        raise RuntimeError("boom")

    monkeypatch.setattr("app.core.ai.translate_text", fake_translate_raise)

    payload = {"content": "Hello", "target_lang": "fa"}
    res = await client.post("/v1/assistant/translate", json=payload)
    assert res.status_code == 422
    data = res.json()
    assert data["status"] == "ERROR"
    assert data["task"] == "translate"
    assert "query_id" in data
