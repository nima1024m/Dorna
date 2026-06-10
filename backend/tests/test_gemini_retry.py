# tests/test_gemini_retry.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from google.genai import types

from app.core.agents.gemini import GeminiAgent


class FakeResponse:
    """Fake LLM response for testing."""
    def __init__(self, text: str):
        self.text = text


@pytest.fixture
def gemini_agent(monkeypatch):
    """Create a GeminiAgent with mocked client."""
    # Prevent actual API client initialization
    monkeypatch.setattr("app.core.agents.gemini.settings.GEMINI_API_KEY", "fake-key")
    monkeypatch.setattr("app.core.agents.gemini.settings.ASSISTANT_LANGS", ["en", "fa"])
    monkeypatch.setattr("app.core.agents.gemini.settings.ASSISTANT_TONES", ["formal", "friendly"])
    
    with patch("app.core.agents.gemini.genai.Client") as mock_client_cls:
        mock_client = MagicMock()
        mock_client_cls.return_value = mock_client
        agent = GeminiAgent()
        yield agent, mock_client


@pytest.mark.anyio
async def test_agenerate_success_first_attempt(gemini_agent, monkeypatch):
    """Test successful LLM call on first attempt - no retry needed."""
    agent, mock_client = gemini_agent
    
    # Mock successful response
    mock_client.aio.models.generate_content = AsyncMock(
        return_value=FakeResponse('{"status": "OK", "sentences": "Hello. World."}')
    )
    monkeypatch.setattr(
        "app.core.agents.gemini.settings.GRAMMAR_MODEL",
        {"seperator": "gemini-2.0-flash"}
    )
    
    result = await agent.sentence_seperator("Hello World")
    
    assert result["status"] == "OK"
    assert mock_client.aio.models.generate_content.call_count == 1


@pytest.mark.anyio
async def test_agenerate_retry_then_success(gemini_agent, monkeypatch):
    """Test retry mechanism: fail twice, succeed on third attempt."""
    agent, mock_client = gemini_agent
    
    call_count = 0
    
    async def flaky_generate(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise Exception("Model overloaded")
        return FakeResponse('{"status": "OK", "sentences": "Test."}')
    
    mock_client.aio.models.generate_content = flaky_generate
    monkeypatch.setattr(
        "app.core.agents.gemini.settings.GRAMMAR_MODEL",
        {"seperator": "gemini-2.0-flash"}
    )
    
    # Patch wait to speed up test (don't actually wait 2-10 seconds)
    with patch("app.core.agents.gemini.wait_exponential", return_value=lambda _: 0):
        result = await agent.sentence_seperator("Test")
    
    assert result["status"] == "OK"
    assert call_count == 3  # 2 failures + 1 success


@pytest.mark.anyio
async def test_agenerate_exhausts_retries(gemini_agent, monkeypatch):
    """Test that exception is raised after all retries are exhausted."""
    agent, mock_client = gemini_agent
    
    call_count = 0
    
    async def always_fail(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        raise Exception("Persistent failure")
    
    mock_client.aio.models.generate_content = always_fail
    monkeypatch.setattr(
        "app.core.agents.gemini.settings.GRAMMAR_MODEL",
        {"seperator": "gemini-2.0-flash"}
    )
    
    with patch("app.core.agents.gemini.wait_exponential", return_value=lambda _: 0):
        with pytest.raises(Exception, match="Persistent failure"):
            await agent.sentence_seperator("Test")
    
    assert call_count == 3  # All 3 attempts exhausted


@pytest.mark.anyio
async def test_agenerate_images_retry_then_success(gemini_agent, monkeypatch, tmp_path):
    """Test retry mechanism for image-based LLM calls."""
    agent, mock_client = gemini_agent
    
    # Create a temporary test image
    test_image = tmp_path / "test.png"
    test_image.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 100)  # Minimal PNG header
    
    call_count = 0
    
    async def flaky_generate(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count < 2:
            raise Exception("Service unavailable")
        return FakeResponse('{"status": "OK", "extractions": [{"text": "extracted"}]}')
    
    mock_client.aio.models.generate_content = flaky_generate
    monkeypatch.setattr("app.core.agents.gemini.settings.TTS_OCR_MODEL", "gemini-2.0-flash")
    
    with patch("app.core.agents.gemini.wait_exponential", return_value=lambda _: 0):
        result = await agent.ocr_images([str(test_image)])
    
    assert result["status"] == "OK"
    assert call_count == 2  # 1 failure + 1 success


@pytest.mark.anyio
async def test_retry_logs_warning_before_sleep(gemini_agent, monkeypatch, caplog):
    """Test that retry attempts are logged at WARNING level."""
    import logging
    agent, mock_client = gemini_agent
    
    call_count = 0
    
    async def fail_once(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise Exception("Temporary error")
        return FakeResponse('{"status": "OK", "sentences": "Done."}')
    
    mock_client.aio.models.generate_content = fail_once
    monkeypatch.setattr(
        "app.core.agents.gemini.settings.GRAMMAR_MODEL",
        {"seperator": "gemini-2.0-flash"}
    )
    
    with patch("app.core.agents.gemini.wait_exponential", return_value=lambda _: 0):
        with caplog.at_level(logging.WARNING):
            result = await agent.sentence_seperator("Test")
    
    assert result["status"] == "OK"
    # Check that tenacity logged the retry
    assert any("Retrying" in record.message for record in caplog.records)


@pytest.mark.anyio
async def test_different_exception_types_trigger_retry(gemini_agent, monkeypatch):
    """Test that various exception types all trigger retry."""
    agent, mock_client = gemini_agent
    
    exceptions = [
        ConnectionError("Network error"),
        TimeoutError("Request timed out"),
        Exception("Generic error"),
    ]
    call_count = 0
    
    async def rotating_errors(*args, **kwargs):
        nonlocal call_count
        if call_count < len(exceptions):
            exc = exceptions[call_count]
            call_count += 1
            raise exc
        call_count += 1
        return FakeResponse('{"status": "OK", "sentences": "Success."}')
    
    mock_client.aio.models.generate_content = rotating_errors
    monkeypatch.setattr(
        "app.core.agents.gemini.settings.GRAMMAR_MODEL",
        {"seperator": "gemini-2.0-flash"}
    )
    
    # This should fail because we have 3 different exceptions and only 3 attempts
    with patch("app.core.agents.gemini.wait_exponential", return_value=lambda _: 0):
        with pytest.raises(Exception):  # Will raise the 3rd exception
            await agent.sentence_seperator("Test")
    
    assert call_count == 3

