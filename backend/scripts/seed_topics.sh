#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -x "$ROOT_DIR/.venv/bin/python" ]]; then
  "$ROOT_DIR/scripts/bootstrap.sh"
fi

exec "$ROOT_DIR/.venv/bin/python" -m app.scripts.sync_news_topics_csv
