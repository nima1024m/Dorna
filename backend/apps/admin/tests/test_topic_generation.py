"""Tests for the admin grounded-generation methods.

Before the GroundedGeminiAgent extraction these two methods were effectively
untestable — they built a live genai client inline — so they had no coverage.
With the seam in place a fake agent drives them, and we can assert the behaviour
the architecture review called out (notably: generate_topic_podcast now records
token usage, which it silently skipped before).
"""
import pytest
from unittest.mock import AsyncMock, MagicMock

from apps.admin.services import topic_service as ts
from app.core.agents.grounded import GroundedResult, GroundedSource
from app.core.agents.usage import TokenUsage


def _result(*, scalar=None, all_list=None):
    """A MagicMock standing in for an awaited db.execute() result."""
    r = MagicMock()
    r.scalar_one_or_none.return_value = scalar
    r.scalars.return_value.all.return_value = all_list if all_list is not None else []
    return r


def _fake_agent(canned):
    class _FakeAgent:
        def __init__(self, *a, **k):
            pass

        def generate(self, prompt, *, schema, model):
            return canned

    return _FakeAgent


@pytest.mark.asyncio
async def test_generate_topic_podcast_records_usage_and_persists(mock_db, mock_topic, monkeypatch):
    canned = GroundedResult(
        data={"script": [{"speaker": "Alex", "text": "hi"}]},
        sources=[GroundedSource("Reuters", "https://r.com")],
        usage=TokenUsage("gemini-x", 5, 5, 10),
    )
    monkeypatch.setattr(ts, "GroundedGeminiAgent", _fake_agent(canned))
    record_spy = AsyncMock()
    monkeypatch.setattr(ts.TokenUsageService, "record", record_spy)

    # get_topic_by_id -> topic ; get_topic_podcast -> None (new record path)
    mock_db.execute.side_effect = [_result(scalar=mock_topic), _result(scalar=None)]

    record = await ts.TopicManagementService(mock_db).generate_topic_podcast("tech_news")

    record_spy.assert_awaited_once()  # the bug fix: usage was never recorded before
    assert record.status == "READY"
    assert record.script_json == [{"speaker": "Alex", "text": "hi"}]
    assert record.sources_json == [{"title": "Reuters", "url": "https://r.com"}]


@pytest.mark.asyncio
async def test_generate_topic_podcast_marks_failed_on_error(mock_db, mock_topic, monkeypatch):
    class _BoomAgent:
        def __init__(self, *a, **k):
            pass

        def generate(self, *a, **k):
            raise RuntimeError("grounding down")

    monkeypatch.setattr(ts, "GroundedGeminiAgent", _BoomAgent)
    # get_topic_by_id -> topic ; get_topic_podcast (in except) -> None
    mock_db.execute.side_effect = [_result(scalar=mock_topic), _result(scalar=None)]

    record = await ts.TopicManagementService(mock_db).generate_topic_podcast("tech_news")

    assert record.status == "FAILED"
    assert "grounding down" in (record.error_message or "")


@pytest.mark.asyncio
async def test_generate_topic_articles_records_usage_and_persists(mock_db, mock_topic, monkeypatch):
    canned = GroundedResult(
        data={"articles": [{"title": "T", "published_at": "2026-06-17T00:00:00", "content": "body"}]},
        sources=[GroundedSource("Reuters", "https://r.com")],
        usage=TokenUsage("gemini-x", 5, 5, 10),
    )
    monkeypatch.setattr(ts, "GroundedGeminiAgent", _fake_agent(canned))
    record_spy = AsyncMock()
    monkeypatch.setattr(ts.TokenUsageService, "record", record_spy)
    monkeypatch.setattr(
        ts.TopicManagementService, "_resolve_article_image", AsyncMock(return_value="https://img")
    )

    # get_topic_by_id -> topic (scalar) ; get_topic_articles -> [] (scalars().all())
    mock_db.execute.side_effect = [_result(scalar=mock_topic), _result(all_list=[])]

    created = await ts.TopicManagementService(mock_db).generate_topic_articles("tech_news", count=1)

    record_spy.assert_awaited_once()
    assert len(created) == 1
    assert created[0].title == "T"
    assert created[0].content == "body"
    assert created[0].image_url == "https://img"
    assert created[0].sources_json == [{"title": "Reuters", "url": "https://r.com"}]
