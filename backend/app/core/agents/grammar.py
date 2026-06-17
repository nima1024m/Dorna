"""Grammar correction orchestration.

Relocated out of the ``ai.py`` facade, where it was the one function carrying
real work while everything around it was a one-line forward. Correcting grammar
is a three-step pipeline — split into sentences, fix each, then tag the diff
between original and suggestion — across two model calls. That orchestration is
a deep module in its own right, so it lives here with its own tests (the diff
tagging in particular had none while it was buried in the facade).

The model is injected (``agent``) so the whole pipeline can be exercised with a
fake GeminiAgent instead of the live API.
"""
from __future__ import annotations

import asyncio
import difflib
import json
import re
from typing import Optional

from app.core.agents.gemini import GeminiAgent
from app.core.agents.usage import attach_usages, pop_usages


def compute_diff(original: str, corrected: str) -> str:
    """Tag the change between two strings as ``<wrong>..</wrong><correct>..</correct>``.

    CPU-bound and pure; run in an executor by the orchestration so it doesn't
    block the event loop.
    """
    if original == corrected:
        return corrected

    def tokenize(text: str) -> list[str]:
        return re.findall(r"\w+|[^\w\s]|\s+", text, re.UNICODE)

    a_tokens = tokenize(original)
    b_tokens = tokenize(corrected)

    matcher = difflib.SequenceMatcher(None, a_tokens, b_tokens)
    threshold = 3
    merged = []

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if not merged:
            merged.append([tag, i1, i2, j1, j2])
            continue

        last = merged[-1]
        if tag == 'equal' and (i2 - i1) <= threshold and last[0] != 'equal':
            last[0] = 'replace'
            last[2] = i2
            last[4] = j2
        elif tag != 'equal' and last[0] != 'equal' and i1 - last[2] <= threshold:
            last[0] = 'replace'
            last[2] = i2
            last[4] = j2
        else:
            merged.append([tag, i1, i2, j1, j2])

    parts = []
    for tag, i1, i2, j1, j2 in merged:
        orig = "".join(a_tokens[i1:i2])
        corr = "".join(b_tokens[j1:j2])
        if tag == 'equal':
            parts.append(orig)
        else:
            parts.append(f"<wrong>{orig}</wrong><correct>{corr}</correct>")

    return "".join(parts)


async def correct_grammar(content: str, *, agent: Optional[GeminiAgent] = None) -> dict:
    """Split → fix → diff-tag. Returns the grammar-fix payload (usage attached)."""
    agent = agent or GeminiAgent()

    punctuation_res = await agent.sentence_seperator(user_input=content)
    # The punctuation schema declares `sentences` as a STRING, so calling Gemini
    # directly yields a JSON-encoded string. The claude-gateway ignores response
    # schemas, so it returns the array as-is — accept either shape.
    _sentences = punctuation_res['sentences']
    if isinstance(_sentences, str):
        _sentences = json.loads(_sentences)
    punctuation_res['sentences'] = _sentences
    sentences = [s['correct'] for s in punctuation_res['sentences']]
    fixed_content = await agent.grammar_fix(sentences)
    attach_usages(fixed_content, pop_usages(punctuation_res) + pop_usages(fixed_content))

    loop = asyncio.get_running_loop()

    for i in range(len(fixed_content['corrections'])):
        correction = fixed_content['corrections'][i]
        original = punctuation_res['sentences'][i]['wrong']
        correction['original'] = original
        if correction.get('original') != correction.get('suggestion'):
            correction['changed'] = True
        # Compute diff tags for changed corrections
        if correction.get('changed', False):
            suggestion = correction.get('suggestion', '')
            tagged_suggestion = await loop.run_in_executor(
                None, compute_diff, original, suggestion
            )
            correction['suggestion'] = tagged_suggestion

    return fixed_content
