"""Thin facade over the configured LLM agent.

This module is the seam the services cross to reach the model. Two changes
deepened it:

- The genai client is no longer rebuilt on every call. ``get_agent()`` caches
  one agent per configured provider — the genai client it holds is meant to be
  reused.
- The grammar-correction orchestration (separator → fix → diff tagging) moved to
  ``app.core.agents.grammar``; it was the one deep function misfiled among
  one-line forwards. What remains here are uniform thin forwards plus that one
  delegation, all going through the cached agent.

``LLM_AGENTS`` is a one-adapter registry selected by ``settings.LLM_AGENT``;
keep it only while a second provider is plausible.
"""
from __future__ import annotations

from typing import Optional

from app.core.config import settings
from app.core.agents.gemini import GeminiAgent
from app.core.agents.grammar import correct_grammar

LLM_AGENTS = {
    'gemini': GeminiAgent,
}

_agent: Optional[GeminiAgent] = None


def get_agent() -> GeminiAgent:
    """Return the cached agent for the configured provider, building it once."""
    global _agent
    if _agent is None:
        _agent = LLM_AGENTS[settings.LLM_AGENT]()
    return _agent


def reset_agent_cache() -> None:
    """Drop the cached agent (tests, or after a config change)."""
    global _agent
    _agent = None


async def ai_health() -> bool:
    return await get_agent().ai_health()


async def grammar_correction(content: str) -> dict:
    return await correct_grammar(content, agent=get_agent())


async def translate_text(content: str, target_lang: str) -> dict:
    return await get_agent().translate_text(user_input=content, target_lang=target_lang)


async def tone_adjustment(content: str, target_tone: str, parent_tones: list[str],
                          user_approved_tones: list) -> dict:
    return await get_agent().tone_adjustment(
        user_input=content, target_tone=target_tone, parent_tones=parent_tones,
        user_approved_tones=user_approved_tones)


async def suggest_podcast_topics(interests: str, already_covered: str, count: int) -> dict:
    return await get_agent().suggest_podcast_topics(
        interests=interests, already_covered=already_covered, count=count)


async def generate_podcast_script(topic: str) -> dict:
    return await get_agent().generate_podcast_script(topic=topic)


async def generate_daily_brief(
    city: str, level: int, date_label: str = "", news_context: str = ""
) -> dict:
    return await get_agent().generate_daily_brief(
        city=city, level=level, date_label=date_label, news_context=news_context
    )


async def generate_event_prep(
    title: str, description: str = "", location: str = "", when: str = "", level: int = 6
) -> dict:
    return await get_agent().generate_event_prep(
        title=title, description=description, location=location, when=when, level=level
    )
