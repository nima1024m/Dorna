"""Typed token-usage extraction for google-genai responses.

One place that reads the usage counters off a model response. The google-genai
SDK exposes them under either snake_case (``usage_metadata.prompt_token_count``)
or camelCase (``usageMetadata.promptTokenCount``) depending on transport, so the
getattr-or-getattr dance lives here once instead of being copy-pasted at every
call site. Both the gateway-routed path (:class:`GeminiAgent`) and the grounded
path (:class:`GroundedGeminiAgent`) return a :class:`TokenUsage`.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional


@dataclass(frozen=True)
class TokenUsage:
    """What a single model call cost. ``model`` is the model the caller asked for."""

    model: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


def extract_usage(response: Any, model: str) -> Optional[TokenUsage]:
    """Pull token counts off a google-genai response, or ``None`` if absent.

    Tolerant of both snake_case and camelCase field names. When only the
    component counts are present, ``total`` is derived from them.
    """
    usage = getattr(response, "usage_metadata", None) or getattr(response, "usageMetadata", None)
    if not usage:
        return None

    prompt_tokens = getattr(usage, "prompt_token_count", None) or getattr(usage, "promptTokenCount", None)
    completion_tokens = getattr(usage, "candidates_token_count", None) or getattr(usage, "candidatesTokenCount", None)
    total_tokens = getattr(usage, "total_token_count", None) or getattr(usage, "totalTokenCount", None)

    if total_tokens is None and (prompt_tokens is not None or completion_tokens is not None):
        total_tokens = (prompt_tokens or 0) + (completion_tokens or 0)

    if total_tokens is None:
        return None

    return TokenUsage(
        model=model,
        prompt_tokens=int(prompt_tokens or 0),
        completion_tokens=int(completion_tokens or 0),
        total_tokens=int(total_tokens or 0),
    )


# --------------------------------------------------------------------------- #
# Carrying usage on a JSON payload
#
# Structured GeminiAgent calls return a plain dict (the model's JSON) and stash
# the call's TokenUsage alongside it so the caller can record the charge. These
# two reserved keys used to be read and re-mapped by hand at ~8 call sites; now
# they are known ONLY here. Producers call attach_usage(s); consumers call
# pop_usages and hand the result to TokenUsageService.record_all.
# --------------------------------------------------------------------------- #
_USAGE_KEY = "_usage"
_USAGE_LIST_KEY = "_usage_list"


def attach_usage(payload: Any, usage: Optional[TokenUsage]) -> Any:
    """Stash a single TokenUsage on ``payload``. No-op when usage is None."""
    if isinstance(payload, dict) and usage is not None:
        payload[_USAGE_KEY] = usage
    return payload


def attach_usages(payload: Any, usages: list[TokenUsage]) -> Any:
    """Stash several TokenUsage on ``payload`` (multi-call flows, e.g. grammar)."""
    if isinstance(payload, dict) and usages:
        payload[_USAGE_LIST_KEY] = list(usages)
    return payload


def pop_usages(payload: Any) -> list[TokenUsage]:
    """Remove and return every TokenUsage a payload carries (single and/or list).

    The single seam that knows the reserved keys. Mutates ``payload`` so the
    usage never leaks downstream into an API response.
    """
    usages: list[TokenUsage] = []
    if not isinstance(payload, dict):
        return usages
    single = payload.pop(_USAGE_KEY, None)
    if isinstance(single, TokenUsage):
        usages.append(single)
    listed = payload.pop(_USAGE_LIST_KEY, None)
    if isinstance(listed, list):
        usages.extend(u for u in listed if isinstance(u, TokenUsage))
    return usages
