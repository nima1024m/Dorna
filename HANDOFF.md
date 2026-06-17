# HANDOFF — Dorna ↔ claude-gateway integration

> Temporary pickup doc for continuing this work on another machine. **Delete before merging the PR** (`git rm HANDOFF.md`).

## Status: DONE + verified. Open work is optional polish.

Route Dorna's backend Gemini traffic through a deployed **claude-gateway** (a drop-in
server that speaks the Gemini wire protocol but is answered by Claude) using a single
env var, with no change to call-site logic. Verified end-to-end against a live gateway.

- **Repo / branch:** `nima1024m/Dorna`, branch `claude/recursing-jepsen-f4b1be`
- **PR:** https://github.com/nima1024m/Dorna/pull/1 (OPEN)
- **Commits:**
  - `24a6f6f` routing switch + `make_genai_client()` factory + `.env.example`
  - `cd3e9e1` grammar array/string compatibility fix (found during live test)
  - (this handoff commit adds `backend/scripts/gateway_smoke_test.py` + `HANDOFF.md`)

## How it works

Dorna uses the `google-genai` SDK. New optional setting **`GEMINI_BASE_URL`**:
- **unset** → behaves exactly as before (calls Google Gemini directly).
- **set** (e.g. `http://<host>:8000`) → SDK calls `{base_url}/v1beta/models/{model}:generateContent`
  with the key in the `x-goog-api-key` header — exactly what the gateway expects.
  Do **not** include `/v1beta` (the SDK appends it). In gateway mode `GEMINI_API_KEY` holds the gateway's API key.

All five `genai.Client(...)` constructions now go through `app/core/agents/genai_client.make_genai_client()`,
which injects `HttpOptions(base_url=...)` when the var is set.

## Files changed (already committed)

- `backend/app/core/config.py` — `GEMINI_BASE_URL` setting
- `backend/app/core/agents/genai_client.py` *(new)* — the factory
- `backend/app/core/agents/gemini.py` — use factory; `ai_health()` probes via `generateContent` in gateway mode (gateway has no `:countTokens`)
- `backend/app/services/news.py`, `backend/app/api/v1/news.py`, `backend/apps/admin/services/topic_service.py` — use factory
- `backend/app/core/ai.py` — grammar flow accepts `sentences` as array OR string (see caveats)
- `backend/.env.example` *(new)* — documented template
- `backend/scripts/gateway_smoke_test.py` *(new)* — reusable E2E smoke test

## Verify on the new machine

1. Get the branch:
   ```
   git fetch origin
   git checkout claude/recursing-jepsen-f4b1be
   ```
2. Tooling: Python 3.10–3.14, plus `gh` (optional). On this machine they were scoop installs.
3. Create a venv with Dorna's runtime deps (full `poetry install` also works if you prefer):
   ```
   cd backend
   python -m venv .venv
   .\.venv\Scripts\python.exe -m pip install "google-genai>=1.33,<2.0" jinja2 tenacity pydantic pydantic-settings python-dotenv diff-match-patch
   ```
4. Run the smoke test (PowerShell — note the literal `$` in the key needs single quotes):
   ```
   $env:GEMINI_BASE_URL='http://<gateway-host>:8000'
   $env:GEMINI_API_KEY='<gateway-key>'      # the key from the session/your records
   .\.venv\Scripts\python.exe scripts\gateway_smoke_test.py
   ```
   Expect `OVERALL: PASS` — routing probe + grammar fix + tone rewrite + translate (en→fa).

Last run resolved the requested Gemini models to `claude-sonnet-4-6` and all four checks passed.

## Caveats / things a reviewer should know

- **Google Search grounding** (news/topic features: `services/news.py`, `api/v1/news.py`, `apps/admin/services/topic_service.py`)
  is NOT supported by the gateway — those flows lose live web results in gateway mode. The three keyboard
  features (grammar/tone/translate) don't use grounding and work fully.
- The gateway **ignores `response_schema`**. The grammar flow's punctuation step declares `sentences` as a
  STRING but the prompt asks for an array; Gemini coerces to a string, the gateway returns an array. `app/core/ai.py`
  now tolerates both (commit `cd3e9e1`).
- Dorna's model names (`gemini-2.5-flash-lite`, `gemini-3-flash-preview`) aren't in the gateway's `models.json`
  alias map → fall back to its default (`sonnet`). They never error. Add aliases in the gateway repo for cheaper tiers.
- `from google import genai` is intentionally kept (`# noqa: F401`) in `gemini.py` so `tests/test_gemini_retry.py`'s
  patch target still resolves.

## NOT in git (local to the original machine)

- `backend/.venv/` (gitignored) — recreate as above.
- The real production `.env` (gitignored, real secrets) — lives only on the origin machine. The smoke test
  does NOT need it; it only needs `GEMINI_BASE_URL` + `GEMINI_API_KEY`.

## Optional next steps

- Add `gemini-2.5-flash-lite → haiku` / `gemini-3-flash-preview → sonnet` aliases in the gateway's `models.json`.
- Decide hybrid routing if you want news/topics to keep using real Gemini (grounding) while the rest uses the gateway.
- **Rotate** the gateway key and the production `.env` secrets that were shared in chat.
