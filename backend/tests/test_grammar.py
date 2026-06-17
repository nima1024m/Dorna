# tests/test_grammar.py
"""Tests for the relocated grammar-correction module.

This orchestration (and especially the diff tagging) had no coverage while it
was buried in the ai.py facade. With the model injected it is now directly
testable end to end.
"""
import copy
import pytest

from app.core.agents.grammar import compute_diff, correct_grammar
from app.core.agents.usage import TokenUsage, pop_usages


# --------------------------------------------------------------------------- #
# compute_diff (pure)
# --------------------------------------------------------------------------- #
def test_compute_diff_identical_returns_input():
    assert compute_diff("hello world", "hello world") == "hello world"


def test_compute_diff_tags_changes():
    out = compute_diff("he go", "he goes")
    assert "<wrong>" in out and "<correct>" in out
    assert "<correct>" in out and "goes" in out


# --------------------------------------------------------------------------- #
# correct_grammar orchestration with an injected fake agent
# --------------------------------------------------------------------------- #
class FakeAgent:
    def __init__(self, sep, fix):
        self._sep, self._fix = sep, fix
        self.seen_sentences = None

    async def sentence_seperator(self, user_input):
        return copy.deepcopy(self._sep)

    async def grammar_fix(self, sentences):
        self.seen_sentences = sentences
        return copy.deepcopy(self._fix)


@pytest.mark.anyio
async def test_correct_grammar_tags_changed_and_attaches_usage():
    sep = {
        "status": "OK",
        "sentences": [{"wrong": "he go", "correct": "he go"}],
        "_usage": TokenUsage("m", 1, 1, 2),
    }
    fix = {
        "status": "OK",
        "corrections": [{"changed": False, "suggestion": "he goes", "explanation": "sva"}],
        "_usage": TokenUsage("m", 3, 3, 6),
    }
    agent = FakeAgent(sep, fix)

    result = await correct_grammar("he go", agent=agent)

    corr = result["corrections"][0]
    assert corr["original"] == "he go"
    assert corr["changed"] is True                      # original != suggestion -> flipped
    assert "<wrong>" in corr["suggestion"]              # diff tagged
    # usage from BOTH model calls is carried through and recoverable
    assert pop_usages(result) == [TokenUsage("m", 1, 1, 2), TokenUsage("m", 3, 3, 6)]
    # the second model call received the corrected sentences
    assert agent.seen_sentences == ["he go"]


@pytest.mark.anyio
async def test_correct_grammar_unchanged_is_not_tagged():
    sep = {"status": "OK", "sentences": [{"wrong": "hello", "correct": "hello"}]}
    fix = {"status": "OK", "corrections": [{"changed": False, "suggestion": "hello", "explanation": ""}]}

    result = await correct_grammar("hello", agent=FakeAgent(sep, fix))

    corr = result["corrections"][0]
    assert corr["changed"] is False
    assert corr["suggestion"] == "hello"   # no diff tags when nothing changed


@pytest.mark.anyio
async def test_correct_grammar_accepts_json_string_sentences():
    # Gateway compatibility: `sentences` can arrive as a JSON-encoded string.
    sep = {"status": "OK", "sentences": '[{"wrong": "he go", "correct": "he go"}]'}
    fix = {"status": "OK", "corrections": [{"changed": False, "suggestion": "he goes", "explanation": "sva"}]}

    result = await correct_grammar("he go", agent=FakeAgent(sep, fix))

    assert result["corrections"][0]["original"] == "he go"
    assert result["corrections"][0]["changed"] is True
