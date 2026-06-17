.DEFAULT_GOAL := help
.PHONY: help migrate upgrade downgrade history current heads check merge stamp-baseline

# Alembic is invoked through Poetry's virtualenv so these targets behave the same
# locally and in CI. Database connection comes from DB_URL (see .env / settings).

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

migrate: ## Autogenerate a revision from model changes:  make migrate m="add foo column"
	@test -n "$(m)" || (echo "usage: make migrate m=\"message\""; exit 1)
	poetry run alembic revision --autogenerate -m "$(m)"

upgrade: ## Apply all pending migrations (alembic upgrade head)
	poetry run alembic upgrade head

downgrade: ## Revert the most recent migration (alembic downgrade -1)
	poetry run alembic downgrade -1

history: ## Show the full migration history
	poetry run alembic history --indicate-current

current: ## Show the revision the database is currently on
	poetry run alembic current

heads: ## Show current head(s) — more than one means a branch to merge
	poetry run alembic heads

check: ## Fail if models have drifted from migrations (used in CI)
	poetry run alembic check

merge: ## Merge divergent heads after a branchy merge:  make merge m="merge x and y"
	@test -n "$(m)" || (echo "usage: make merge m=\"message\""; exit 1)
	poetry run alembic merge heads -m "$(m)"

stamp-baseline: ## One-time: mark an existing (create_all-built) DB as being at the baseline
	poetry run alembic stamp aaed617c4069
