"""Smoke-test Dorna's real LLM code paths against a claude-gateway (or Gemini).

Drives the actual app.core.ai functions the API/worker use — nothing mocked —
so it verifies grammar fix, tone rewrite, and translate end to end.

Usage (PowerShell), from anywhere:

    $env:GEMINI_BASE_URL='http://<gateway-host>:8000'   # omit to hit Google Gemini
    $env:GEMINI_API_KEY='<gateway-or-gemini-key>'
    python backend/scripts/gateway_smoke_test.py

Exit code 0 = all pass, 1 = a feature failed, 2 = missing config.
"""
import os
import sys
import json
import asyncio
import traceback
from pathlib import Path

# Make the script runnable from any cwd: app.core.* import paths and the Jinja
# prompt loader ("app/files/prompt") are resolved relative to the backend dir.
BACKEND_DIR = Path(__file__).resolve().parents[1]
os.chdir(BACKEND_DIR)
sys.path.insert(0, str(BACKEND_DIR))

# Force UTF-8 so non-Latin output (e.g. Persian translations) prints on Windows.
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

# Runtime config the GeminiAgent needs; model names mirror production. Gateway
# creds come from the real environment. Set before importing app.* .
os.environ.setdefault("LLM_AGENT", "gemini")
os.environ.setdefault(
    "GRAMMAR_MODEL",
    json.dumps({"seperator": "gemini-2.5-flash-lite", "grammar_fix": "gemini-2.5-flash-lite"}),
)
os.environ.setdefault("TRANSLATE_MODEL", "gemini-3-flash-preview")
os.environ.setdefault("TONE_MODEL", "gemini-2.5-flash-lite")
os.environ.setdefault("ASSISTANT_LANGS", json.dumps(["fa", "en"]))
os.environ.setdefault("ASSISTANT_TONES", json.dumps(["formal", "friendly", "concise", "polish"]))

if not os.environ.get("GEMINI_API_KEY"):
    print("ERROR: set GEMINI_API_KEY (and GEMINI_BASE_URL for gateway mode).")
    sys.exit(2)

from app.core.config import settings                         # noqa: E402
from app.core.agents.genai_client import make_genai_client   # noqa: E402
import app.core.ai as AI                                      # noqa: E402


def dump(obj) -> str:
    try:
        return json.dumps(obj, ensure_ascii=False, indent=2)
    except Exception:
        return repr(obj)


async def probe() -> bool:
    print("=" * 70)
    print("ROUTING PROBE - direct call through Dorna's make_genai_client()")
    print("  GEMINI_BASE_URL :", settings.GEMINI_BASE_URL or "(unset -> direct Gemini)")
    print("  GEMINI_API_KEY  : <set, len %d>" % len(settings.GEMINI_API_KEY or ""))
    try:
        resp = await make_genai_client().aio.models.generate_content(
            model=os.environ["TONE_MODEL"], contents="Reply with exactly one word: pong"
        )
        um = getattr(resp, "usage_metadata", None)
        print("  requested model :", os.environ["TONE_MODEL"])
        print("  answered model  :", getattr(resp, "model_version", None))
        print("  text            :", repr((getattr(resp, "text", "") or "").strip()[:80]))
        if um:
            print("  usage p/c       :", getattr(um, "prompt_token_count", None),
                  "/", getattr(um, "candidates_token_count", None))
        return True
    except Exception:
        print("  PROBE FAILED:")
        traceback.print_exc()
        return False


async def run(name, coro) -> bool:
    print("\n" + "=" * 70)
    print(name)
    print("-" * 70)
    try:
        res = await coro
        print("OK. result:")
        print(dump(res)[:2500])
        return True
    except Exception:
        print("FAILED:")
        traceback.print_exc()
        return False


async def main():
    ok = {"routing": await probe()}
    ok["grammar_fix"] = await run(
        "FEATURE 1/3 - grammar_correction()",
        AI.grammar_correction("she go to school yesterday and she dont did her homework"),
    )
    ok["tone_rewrite"] = await run(
        "FEATURE 2/3 - tone_adjustment(target_tone='formal')",
        AI.tone_adjustment("hey can u send me the report asap thx", "formal", [], []),
    )
    ok["translate"] = await run(
        "FEATURE 3/3 - translate_text(target_lang='fa')",
        AI.translate_text("Good morning, how are you today?", "fa"),
    )

    print("\n" + "=" * 70)
    print("SUMMARY")
    for k, v in ok.items():
        print(f"  {k:13}:", "PASS" if v else "FAIL")
    all_ok = all(ok.values())
    print("\nOVERALL:", "PASS" if all_ok else "FAIL")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    asyncio.run(main())
