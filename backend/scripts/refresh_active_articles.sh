#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:8000}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
COUNT="${COUNT:-3}"
LOG_FILE="${LOG_FILE:-/var/log/dorna_article_refresh.log}"

if [[ -z "$ADMIN_TOKEN" ]]; then
  echo "ADMIN_TOKEN is required"
  exit 1
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
response="$(curl -sS -X POST "${API_URL}/admin/topics/articles/refresh-active?count=${COUNT}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json")"

echo "${timestamp} ${response}" >> "${LOG_FILE}"
echo "${response}"
