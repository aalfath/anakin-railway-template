#!/bin/sh
# Waits for Postgres, applies the upstream schema (idempotent: CREATE ... IF NOT EXISTS),
# then starts the AnakinScraper API server.
set -eu

if [ -z "${API_KEY:-}" ]; then
  echo "start.sh: API_KEY is empty; refusing to start an open scraping API" >&2
  exit 1
fi

if [ -n "${DATABASE_URL:-}" ]; then
  i=0
  until psql "$DATABASE_URL" -qtAc 'select 1' >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 90 ]; then
      echo "start.sh: Postgres not reachable after 3 minutes" >&2
      exit 1
    fi
    echo "start.sh: waiting for Postgres ($i)"
    sleep 2
  done
  psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -f /app/init-db.sql
  echo "start.sh: schema ready"
fi

exec /usr/local/bin/server
