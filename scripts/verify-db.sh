#!/usr/bin/env bash
# Runs the read-only financial smoke suite against the live database.
# Usage: scripts/verify-db.sh [--db name]
set -euo pipefail

DB_NAME="postgres"
while [[ $# -gt 0 ]]; do
  case $1 in
    --db)
      DB_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scp -q "$HERE/supabase/verify_smoke.sql" homeserver:/tmp/verify_smoke.sql

ssh homeserver 'bash -s' "$DB_NAME" <<'EOF'
  set -euo pipefail
  TARGET_DB="$1"
  export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
  docker run --rm -i --network supabase_default \
    supabase/postgres:17.6.1.136 \
    psql "postgresql://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/${TARGET_DB}?sslmode=disable" \
      -v ON_ERROR_STOP=1 < /tmp/verify_smoke.sql
EOF