# tests/test_grounded_agent.py
"""Tests for the grounded-generation module — the seam four call sites now share.

The whole point of the extraction is testability: a fake genai client exercises
the parse / source-walk / usage-extract machinery once, instead of four copies
that could only be tested against the live Google Search API.
"""
import json
import pytest
from unittest.mock import AsyncMock

from app.core.agents.grounded import GroundedGeminiAgent, GroundedResult, GroundedSource
from app.core.agents.usage import TokenUsage, extract_usage
from app.services.token_usage import TokenUsageService


# --------------------------------------------------------------------------- #
# Fakes mimicking the google-genai response shape
# --------------------------------------------------------------------------- #
class _Web:
    def __init__(self, uri, title):
        self.uri = uri
        self.title = title


class _Chunk:
    def __init__(self, uri=None, title=None, has_web=True):
        self.web = _Web(uri, title) if has_web else None


class _GroundingMeta:
    def __init__(self, chunks):
        self.grounding_chunks = chunks


class _Candidate:
    def __init__(self, gm):
        self.grounding_metadata = gm


class _UsageSnake:
    def __init__(self, p, c, t):
        self.prompt_token_count = p
        self.candidates_token_count = c
        self.total_token_count = t


class _UsageCamel:
    def __init__(self, p, c, t):
        self.promptTokenCount = p
        self.candidatesTokenCount = c
        self.totalTokenCount = t


class _Response:
    def __init__(self, text="", candidates=None, usage=None):
        self.text = text
        self.candidates = candidates or []
        self.usage_metadata = usage


class _Models:
    def __init__(self, response):
        self._response = response
        self.calls = []

    def generate_content(self, *, model, contents, config):
        self.calls.append({"model": model, "contents": contents, "config": config})
        return self._response


class FakeClient:
    def __init__(self, response):
        self.models = _Models(response)


def _agent(response):
    return GroundedGeminiAgent(client=FakeClient(response))


# --------------------------------------------------------------------------- #
# generate(): data + sources + usage
# --------------------------------------------------------------------------- #
def test_generate_parses_object_data():
    resp = _Response(text='{"script": [{"speaker": "Alex", "text": "hi"}]}')
    result = _agent(resp).generate("p", schema={"type": "OBJECT"}, model="m")
    assert isinstance(result, GroundedResult)
    assert result.data == {"script": [{"speaker": "Alex", "text": "hi"}]}
    assert result.raw_text.startswith("{")


def test_generate_parses_array_data():
    resp = _Response(text='[{"speaker": "Alex", "text": "hi"}]')
    result = _agent(resp).generate("p", schema={"type": "ARRAY"}, model="m")
    assert result.data == [{"speaker": "Alex", "text": "hi"}]


def test_generate_empty_text_yields_none_data():
    result = _agent(_Response(text="")).generate("p", schema={}, model="m")
    assert result.data is None
    assert result.sources == []
    assert result.usage is None


def test_generate_malformed_json_raises():
    # Three of the four original sites called json.loads directly; preserve that
    # a malformed (non-empty) body surfaces as an error for the caller to handle.
    with pytest.raises(json.JSONDecodeError):
        _agent(_Response(text="not json")).generate("p", schema={}, model="m")


def test_generate_passes_model_schema_and_search_tool():
    resp = _Response(text="{}")
    agent = _agent(resp)
    schema = {"type": "OBJECT", "properties": {}}
    agent.generate("the-prompt", schema=schema, model="gemini-x")
    call = agent._client.models.calls[0]
    assert call["model"] == "gemini-x"
    assert call["config"].response_schema == schema
    assert call["config"].response_mime_type == "application/json"
    # the grounding tool must be attached — that's the module's reason to exist
    assert call["config"].tools, "google_search tool must be present"


# --------------------------------------------------------------------------- #
# source extraction
# --------------------------------------------------------------------------- #
def test_sources_deduped_with_title_fallback():
    chunks = [
        _Chunk("https://a.com", "A"),
        _Chunk("https://a.com", "A-dupe"),      # duplicate url -> dropped
        _Chunk("https://b.com", ""),            # missing title -> falls back to url
        _Chunk(has_web=False),                  # no web -> skipped
        _Chunk("", "empty"),                    # empty url -> skipped
    ]
    resp = _Response(text="{}", candidates=[_Candidate(_GroundingMeta(chunks))])
    result = _agent(resp).generate("p", schema={}, model="m")
    assert result.sources == [
        GroundedSource(title="A", url="https://a.com"),
        GroundedSource(title="https://b.com", url="https://b.com"),
    ]
    assert result.sources_as_dicts() == [
        {"title": "A", "url": "https://a.com"},
        {"title": "https://b.com", "url": "https://b.com"},
    ]


def test_no_candidates_yields_no_sources():
    result = _agent(_Response(text="{}", candidates=[])).generate("p", schema={}, model="m")
    assert result.sources == []


# --------------------------------------------------------------------------- #
# usage extraction (snake + camel)
# --------------------------------------------------------------------------- #
def test_usage_extracted_snake_case():
    resp = _Response(text="{}", usage=_UsageSnake(10, 20, 30))
    result = _agent(resp).generate("p", schema={}, model="gemini-x")
    assert result.usage == TokenUsage(model="gemini-x", prompt_tokens=10, completion_tokens=20, total_tokens=30)


def test_usage_extracted_camel_case():
    assert extract_usage(_Response(usage=_UsageCamel(1, 2, 3)), "m") == TokenUsage("m", 1, 2, 3)


def test_usage_total_derived_when_missing():
    u = _UsageSnake(4, 6, None)
    assert extract_usage(_Response(usage=u), "m") == TokenUsage("m", 4, 6, 10)


def test_usage_none_when_absent():
    assert extract_usage(_Response(usage=None), "m") is None


# --------------------------------------------------------------------------- #
# TokenUsageService.record — the typed bridge
# --------------------------------------------------------------------------- #
@pytest.mark.anyio
async def test_record_none_usage_is_noop(monkeypatch):
    spy = AsyncMock()
    monkeypatch.setattr(TokenUsageService, "record_usage", spy)
    await TokenUsageService.record(object(), None, user_id=1, source="system")
    spy.assert_not_called()


@pytest.mark.anyio
async def test_record_usage_forwards_fields(monkeypatch):
    spy = AsyncMock()
    monkeypatch.setattr(TokenUsageService, "record_usage", spy)
    usage = TokenUsage(model="gemini-x", prompt_tokens=10, completion_tokens=20, total_tokens=30)
    db = object()
    await TokenUsageService.record(db, usage, user_id=7, source="system")
    spy.assert_awaited_once_with(
        db,
        user_id=7,
        source="system",
        model_name="gemini-x",
        prompt_tokens=10,
        completion_tokens=20,
        total_tokens=30,
    )


# --------------------------------------------------------------------------- #
# integration: the rewired /v1/news/podcast endpoint
# --------------------------------------------------------------------------- #
@pytest.mark.anyio
async def test_news_podcast_endpoint_uses_grounded_agent(client, monkeypatch):
    canned = GroundedResult(
        data=[{"speaker": "Alex", "text": "Breaking news!"}, {"speaker": "Sarah", "text": "Indeed."}],
        sources=[GroundedSource(title="Reuters", url="https://reuters.com/x")],
        usage=TokenUsage(model="gemini-x", prompt_tokens=5, completion_tokens=5, total_tokens=10),
    )

    class _FakeAgent:
        def __init__(self, *a, **k):
            pass

        def generate(self, prompt, *, schema, model):
            return canned

    monkeypatch.setattr("app.api.v1.news.GroundedGeminiAgent", _FakeAgent)

    resp = await client.post("/v1/news/podcast", json={"topic": "AI"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["topic"] == "AI"
    assert [t["speaker"] for t in body["script"]] == ["Alex", "Sarah"]
    assert body["sources"] == [{"title": "Reuters", "url": "https://reuters.com/x"}]
    assert body["imageUrl"].startswith("http")
