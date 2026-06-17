# Database migrations (Alembic)

Alembic is the **single source of truth** for the Dorna database schema. The
schema is no longer created with `Base.metadata.create_all()` — every change to
the SQLAlchemy models must ship with a migration, and CI fails if the two drift
apart.

- Config: [`alembic.ini`](../alembic.ini) · Environment: [`env.py`](env.py) · Revisions: [`versions/`](versions)
- Connection comes from `DB_URL` (see `.env` / `app/core/config.py`).
- Helper targets live in the [`Makefile`](../Makefile) (`make help`).

---

## TL;DR

```bash
# 1. change your models in app/models/** or apps/admin/models/**
make migrate m="add collect_data flag to users"   # autogenerate a revision
#    -> review the generated file in alembic/versions/ before committing!
make upgrade                                        # apply it locally
```

CI then re-applies every migration on a clean Postgres and runs `alembic check`
to prove the models and migrations agree.

---

## Everyday workflow

1. **Edit the models.** Add/change columns, tables, indexes, constraints.
2. **Autogenerate a revision:** `make migrate m="short description"`.
3. **Review the generated file.** Autogenerate is a draft, not gospel —
   confirm the `upgrade()` / `downgrade()` ops are correct, data-safe, and
   ordered sensibly. Add data backfills or `op.execute(...)` where needed.
4. **Apply locally:** `make upgrade`, and sanity-check the result.
5. **Commit the model change and the migration together** in the same PR.

The empty-migration guard in `env.py` refuses to write a no-op revision, so if
`make migrate` says *"No schema changes detected"* there is nothing to commit.

## Command reference

| Make target            | Alembic command                              | Purpose                                   |
| ---------------------- | -------------------------------------------- | ----------------------------------------- |
| `make migrate m="..."` | `alembic revision --autogenerate -m "..."`   | Draft a revision from model changes       |
| `make upgrade`         | `alembic upgrade head`                       | Apply all pending migrations              |
| `make downgrade`       | `alembic downgrade -1`                        | Revert the most recent migration          |
| `make current`         | `alembic current`                            | Show the DB's current revision            |
| `make history`         | `alembic history --indicate-current`         | Show the migration history                |
| `make heads`           | `alembic heads`                              | Show head(s); >1 means a branch to merge  |
| `make check`           | `alembic check`                              | Fail if models drifted from migrations    |
| `make merge m="..."`   | `alembic merge heads -m "..."`               | Merge divergent heads                     |
| `make stamp-baseline`  | `alembic stamp aaed617c4069`                 | Adopt Alembic on an existing database     |

(If `make` is unavailable — e.g. on Windows — run the `poetry run alembic ...`
command from the table directly.)

---

## The baseline (`aaed617c4069`)

`aaed617c4069_initial_baseline.py` contains the **entire schema** as it existed
when the project adopted Alembic (it was previously built by `create_all`). It
is the root of the migration history (`down_revision = None`).

- **Fresh databases** (CI, a new environment, a local dev DB) run the baseline
  and get the whole schema, then any later migrations stack on top.
- **The existing production database** already ran this revision as a no-op
  before it was filled in, so it is stamped at `aaed617c4069` and will **not**
  re-run it — later migrations apply on top as normal.

### Adopting Alembic on a pre-existing database

If you have a database whose tables were created by the old `create_all` path
and it is **not yet** at `aaed617c4069` (i.e. `alembic current` is empty), do
**not** run `alembic upgrade` first — the baseline would try to `CREATE` tables
that already exist. Instead, mark it as already-at-baseline once:

```bash
make stamp-baseline      # alembic stamp aaed617c4069
make upgrade             # now applies only migrations newer than the baseline
```

---

## Branching & merging

When two PRs each add a migration, `main` ends up with two heads. Resolve it
explicitly:

```bash
make heads                       # shows two head revisions
make merge m="merge auth + tts"  # creates a merge revision joining them
make upgrade
```

## Rolling back

```bash
make downgrade           # revert the latest migration (alembic downgrade -1)
# or target a specific revision:
poetry run alembic downgrade <revision>
```

Every revision must implement a working `downgrade()`. The baseline's
`downgrade()` also drops the PG `ENUM` types it created, so a
`downgrade base` → `upgrade head` cycle is repeatable.

---

## CI drift gate

[`.github/workflows/backend-migrations.yml`](../../.github/workflows/backend-migrations.yml)
runs on every backend change:

1. spins up a clean `postgres:16`,
2. `alembic upgrade head` — proves the migrations build the schema from scratch,
3. `alembic check` — fails the build if the models and migrations disagree.

The deploy pipeline (`backend/.gitlab-ci.yml`) additionally runs `alembic upgrade head`
on each release so production schema tracks `head`.

---

## Conventions & gotchas

- **Review autogenerated server defaults / type changes.** `env.py` enables
  `compare_type` and `compare_server_default`, so these are detected — but
  verify the rendered ops are what you intend.
- **Naming convention.** `Base.metadata` carries a global naming convention
  (see `NAMING_CONVENTION` in `app/core/database.py`): `pk_*`, `fk_*`, `uq_*`,
  `ck_*`, `ix_*`. The live database was originally built by `create_all` with
  PostgreSQL's default names; migration `b2a7f3c19d40` brings those existing
  names in line with the convention using **catalog-only `RENAME`s** (no table
  rewrite) guarded by `lock_timeout` (see its docstring). Because the `uq`/`ck`
  templates only reference the first column, give every *new* multi-column
  `UniqueConstraint` / `CheckConstraint` an explicit `name=`.
- **`citext` extension.** `users.email` is `CITEXT`; the baseline runs
  `CREATE EXTENSION IF NOT EXISTS citext` before creating tables. New
  environments need a Postgres build that ships the `citext` contrib module
  (the official `postgres` image does).
- **Enum types.** PostgreSQL `ENUM`s are created implicitly by enum columns but
  are **not** dropped by `drop_table`. When a migration removes the last user of
  an enum, drop the type explicitly in `downgrade()`.
