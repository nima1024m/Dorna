"""Grounded (Google-Search) Gemini generation.

The sibling of :class:`~app.core.agents.gemini.GeminiAgent`. Where ``GeminiAgent``
handles gateway-routed, schema-constrained generation, this module handles the
flows that need **Google Search grounding** — a Google-only feature the gateway
cannot proxy, so these always reach real Gemini via
``make_genai_client(force_direct=True)``.

Before this module existed the same recipe was copy-pasted at four call sites
(news refresh, the live-news podcast endpoint, and admin topic podcast/article
generation): build the direct client, attach the ``google_search`` tool, parse
the JSON body, walk the grounding metadata for source links, and read the usage
counters. All of that now lives behind one interface:

    agent = GroundedGeminiAgent()
    result = agent.generate(prompt, schema=SCHEMA, model=settings.PODCAST_GENERATE_MODEL)
    result.data     # parsed JSON (dict or list per the schema), or None if empty
    result.sources  # deduped [GroundedSource] from search grounding
    result.usage    # TokenUsage | None

Callers keep their own persistence and error handling; the module is pure
generation + parsing and takes no database session.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from typing import Any, List, Optional, Union

from google.genai import types

from app.core.agents.genai_client import make_genai_client
from app.core.agents.usage import TokenUsage, extract_usage

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class GroundedSource:
    """A news/source link surfaced by Google Search grounding."""

    title: str
    url: str

    def to_dict(self) -> dict:
        return {"title": self.title, "url": self.url}


@dataclass
class GroundedResult:
    """Everything a caller needs from one grounded generation."""

    data: Any
    sources: List[GroundedSource] = field(default_factory=list)
    usage: Optional[TokenUsage] = None
    raw_text: str = ""

    def sources_as_dicts(self) -> List[dict]:
        return [s.to_dict() for s in self.sources]


# JSON schemas are intentionally NOT owned here — they are domain-specific and
# stay at the call sites. Only the grounding machinery is shared.
SchemaType = Union[dict, types.Schema]


class GroundedGeminiAgent:
    """Deep module for Google-Search-grounded Gemini generation."""

    def __init__(self, *, client=None):
        # Grounding cannot be proxied by the gateway, so always force the direct
        # client. Injectable for tests.
        self._client = client if client is not None else make_genai_client(force_direct=True)

    def generate(self, prompt: str, *, schema: SchemaType, model: str) -> GroundedResult:
        """Run one grounded generation and return parsed data + sources + usage.

        The underlying SDK call is synchronous, matching the original call sites.
        Raises whatever the SDK raises and re-raises JSON parse errors on a
        malformed (non-empty) body — callers wrap this in their own error
        handling exactly as before.
        """
        content = types.Content(parts=[types.Part(text=prompt)])
        response = self._client.models.generate_content(
            model=model,
            contents=content,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type="application/json",
                response_schema=schema,
            ),
        )

        raw_text = getattr(response, "text", "") or ""
        data = json.loads(raw_text) if raw_text.strip() else None
        sources = self._extract_sources(response)
        usage = extract_usage(response, model)

        return GroundedResult(data=data, sources=sources, usage=usage, raw_text=raw_text)

    @staticmethod
    def _extract_sources(response: Any) -> List[GroundedSource]:
        """Walk grounding metadata for unique source links (snake/camel tolerant)."""
        sources: List[GroundedSource] = []
        seen: set[str] = set()

        candidates = getattr(response, "candidates", None) or []
        if not candidates:
            return sources

        candidate0 = candidates[0]
        gm = getattr(candidate0, "grounding_metadata", None) or getattr(candidate0, "groundingMetadata", None)
        if not gm:
            return sources

        chunks = getattr(gm, "grounding_chunks", None) or getattr(gm, "groundingChunks", None) or []
        for chunk in chunks:
            web = getattr(chunk, "web", None)
            if not web:
                continue
            uri = (getattr(web, "uri", None) or "").strip()
            title = (getattr(web, "title", None) or "").strip()
            if not uri or uri in seen:
                continue
            seen.add(uri)
            sources.append(GroundedSource(title=title or uri, url=uri))

        return sources
