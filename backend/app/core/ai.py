import asyncio
import json
import re
import difflib

from diff_match_patch import diff_match_patch

from app.core.config import settings
from app.core.agents.gemini import GeminiAgent

LLM_AGENTS = {
    'gemini': GeminiAgent,
}


def _compute_diff_sync(original: str, corrected: str) -> str:
    """
    Compute diff between original and corrected text, returning a string
    with <wrong>...</wrong><correct>...</correct> tags for changes.
    
    This is a sync/CPU-bound function that should be run in an executor.
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

def _collect_usage(*payloads: dict) -> list[dict]:
    usages = []
    for payload in payloads:
        if not payload:
            continue
        usage = payload.get("_usage")
        if isinstance(usage, dict):
            usages.append(usage)
        usage_list = payload.get("_usage_list")
        if isinstance(usage_list, list):
            usages.extend([u for u in usage_list if isinstance(u, dict)])
    return usages


async def ai_health() -> bool:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    return await agent.ai_health()


async def grammar_correction(content: str) -> dict:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    punctuation_res = await agent.sentence_seperator(user_input=content)
    punctuation_res['sentences'] = json.loads(punctuation_res['sentences'])
    sentences = [s['correct'] for s in punctuation_res['sentences']]
    fixed_content = await agent.grammar_fix(sentences)
    usage_list = _collect_usage(punctuation_res, fixed_content)
    if usage_list:
        fixed_content["_usage_list"] = usage_list
    
    loop = asyncio.get_running_loop()
    
    for i in range(len(fixed_content['corrections'])):
        correction = fixed_content['corrections'][i]
        original = punctuation_res['sentences'][i]['wrong']
        correction['original'] = original
        # print(f"original: {original}\n")
        if correction.get('original') != correction.get('suggestion'):
            correction['changed'] = True
        # Compute diff tags for changed corrections
        if correction.get('changed', False):
            suggestion = correction.get('suggestion', '')
            tagged_suggestion = await loop.run_in_executor(
                None, _compute_diff_sync, original, suggestion
            )
            correction['suggestion'] = tagged_suggestion
            # print(f"tagged_suggestion: {tagged_suggestion}\n")
            # print(f"suggestion: {suggestion}\n\n\n")

    return fixed_content


async def translate_text(content: str, target_lang: str) -> dict:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    return await agent.translate_text(user_input=content, target_lang=target_lang)


async def tone_adjustment(content: str, target_tone: str, parent_tones: list[str],
                          user_approved_tones: list) -> dict:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    return await agent.tone_adjustment(
        user_input=content, target_tone=target_tone, parent_tones=parent_tones, user_approved_tones=user_approved_tones)


async def suggest_podcast_topics(interests: str, already_covered: str, count: int) -> dict:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    return await agent.suggest_podcast_topics(
        interests=interests, already_covered=already_covered, count=count)


async def generate_podcast_script(topic: str) -> dict:
    agent = LLM_AGENTS[settings.LLM_AGENT]()
    return await agent.generate_podcast_script(topic=topic)
