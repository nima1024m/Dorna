# Dorna backend (FastAPI)

Async **FastAPI** service powering the Dorna app: auth, AI text actions
(grammar/translate/tone via Gemini), TTS, podcasts, a news layer, and an admin
panel. Data is in **PostgreSQL** (async SQLAlchemy + Alembic); background jobs
run on **Celery + Redis**. Repo‑wide context is in the root [`CLAUDE.md`](../CLAUDE.md).

## Toolchain

**Python 3.14**, managed with **Poetry** (`pyproject.toml`). Pydantic v2.
See `backend/README.md` for the human‑facing setup walkthrough.

## Layout

- `app/main.py` — the FastAPI app; mounts routers `/system`, `/v1`, `/admin`.
- `app/api/` — endpoints. `api/v1/` is the versioned app API (`auth`, `users`,
  `assistant`, `tts`, `podcast`, `news`, `onboarding`, `track`); `system.py` is
  the system router; `deps.py` holds shared dependencies.
- `app/core/` — `config.py` (settings from `.env`), `database.py` (async engine),
  `security.py`, `auth_deps.py`, `rate_limit.py`, `ai.py`, plus `agents/` (Gemini
  LLM agents) and `email/` (Brevo).
- `app/models/` — SQLAlchemy models. `app/schemas/` — Pydantic request/response
  schemas. `app/services/` — business logic.
- `app/worker/` — Celery app (`celery_app.py`) + task modules (`tts_tasks`,
  `user_tasks`, `podcast_tasks`, `news_tasks`, `article_tasks`), routed to
  per‑domain queues `tts` / `user` / `podcast` / `news`.
- `app/files/prompt/*.txt` — runtime **LLM system prompts** (data, not code; edit
  these to tune model behavior).
- `apps/admin/` — the admin panel (its own `api/`, `models/`, `schemas/`,
  `router.py`, templates/static, tests, and `README.md`).
- `alembic/` + `alembic.ini` — migrations; the `Makefile` wraps common targets.

## Configuration

Copy `.env.example` → `.env` (gitignored) and fill it in. `app/core/config.py`
loads settings **at import**, so the app won't import without a valid `.env`.
Required: `DB_URL` (`postgresql+asyncpg://…`). The worker also needs
`CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` (Redis). Other keys: Gemini, Brevo,
Google Cloud TTS, JWT — see `.env.example` for the full list.

## Commands

```bash
poetry install
poetry run uvicorn app.main:app --reload     # API → http://127.0.0.1:8000/docs

# Migrations (Alembic, via the Makefile):
make upgrade                 # apply all pending (alembic upgrade head)
make migrate m="message"     # autogenerate a revision from model changes
make downgrade               # revert the latest revision
make current / make history / make check / make heads   # inspect / drift / heads

# Worker:
poetry run celery -A app.worker.celery_app:celery_app worker -Q tts,user,podcast,news
poetry run celery -A app.worker.celery_app:celery_app flower   # monitoring UI

# Tests:
poetry run pytest tests apps/admin/tests
```

## Conventions (MUST follow)

- **Migrations are Alembic‑managed.** After changing a model, run
  `make migrate m="…"`, **review** the generated revision, then `make upgrade`.
  Don't rely on `create_all` for schema changes. Keep a single head
  (`make heads`; resolve divergence with `make merge`).
- **Layering:** thin routers in `api/`, request/response shapes in `schemas/`,
  business logic in `services/`, persistence in `models/`. Keep handlers thin.
- **Long‑running work** (TTS, podcast generation, news ingestion) belongs in
  Celery tasks under `app/worker/`, not in request handlers.
- **Run tests with explicit paths** — `pytest tests apps/admin/tests`, *not* bare
  `pytest`: a bare collection imports `scripts/gateway_smoke_test.py`, which calls
  `sys.exit` during import. A couple of admin user‑service tests are known to fail
  on a clean baseline (a pre‑existing mock mismatch), so a "green" run is not 100%.
- Reuse existing patterns and the established naming convention; keep changes
  scoped to the task.
