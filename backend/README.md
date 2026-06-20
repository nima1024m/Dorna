# Dorna Backend

FastAPI service powering the Dorna AI Keyboard: auth, AI text actions
(grammar/translate/tone via Gemini), TTS, podcasts, a news layer, and an admin
panel. Data lives in PostgreSQL (async SQLAlchemy + Alembic); background jobs run
on Celery + Redis.

## Stack

- **Python 3.14**, managed with **Poetry** (`pyproject.toml`)
- **FastAPI** + Uvicorn (ASGI)
- **SQLAlchemy 2.x** (async) on **PostgreSQL** via `asyncpg`
- **Alembic** for migrations
- **Celery** (Redis broker) + **Flower** for async tasks (TTS, podcasts, news)

## Prerequisites

- Python 3.14 and [Poetry](https://python-poetry.org/)
- A PostgreSQL database
- A Redis instance (only needed for the Celery worker)

## Setup

```bash
cp .env.example .env      # then fill in DB_URL, JWT_SECRET, GEMINI_API_KEY, etc.
poetry install
```

All configuration is read from `.env` (see `.env.example` for the full list of
keys). At minimum the API needs `DB_URL`; the worker also needs the
`CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` Redis URLs.

## Run the API

```bash
poetry run uvicorn app.main:app --reload
```

Interactive docs are then served at `http://127.0.0.1:8000/docs` (OpenAPI) and
`/redoc`.

## Database migrations (Alembic)

Common tasks are wrapped in the `Makefile` (each runs Alembic inside Poetry's
virtualenv, against `DB_URL`):

```bash
make upgrade              # apply all pending migrations (alembic upgrade head)
make migrate m="message"  # autogenerate a revision from model changes
make downgrade            # revert the most recent migration
make current              # show the revision the DB is on
make history              # show full migration history
make check                # fail if models have drifted from migrations (CI)
```

`make help` lists every target. The equivalent raw command is
`poetry run alembic upgrade head`.

## Background worker (Celery)

Tasks are routed to per-domain queues (`tts`, `user`, `podcast`, `news`):

```bash
poetry run celery -A app.worker.celery_app:celery_app worker -Q tts,user,podcast,news
poetry run celery -A app.worker.celery_app:celery_app flower   # monitoring UI
```

## Tests

```bash
poetry run pytest tests apps/admin/tests
```

Run those paths explicitly rather than bare `pytest` — a bare collection imports
`scripts/gateway_smoke_test.py`, which exits the process on import.
