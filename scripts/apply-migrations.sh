#!/usr/bin/env bash
# Applies pending supabase/migrations in filename order — one command, no manual psql.
# Each applied file is recorded (filename + sha256) in supabase_migrations.schema_migrations.
# Re-runs skip applied files; abort if a recorded file was EDITED afterwards
# (migrations are append-only — a changed sha means someone broke the rule).
#
# Usage:
#   scripts/apply-migrations.sh [--db NAME] [--baseline] [--no-verify]
#
#   --db NAME    target database (default: postgres).
#                To test safely: create a scratch DB once via
#                  ssh homeserver '... psql -c "CREATE DATABASE migtest"'
#                and run with --db migtest --no-verify.
#   --baseline   record every local file as applied WITHOUT running it.
#                Use ONCE when adopting this script on a database that already
#                has all migrations (confirm state first with scripts/verify-db.sh).
#   --no-verify  skip the automatic scripts/verify-db.sh run at the end
#                (verify only works against the live postgres database).
#
# Safety notes: do not run two copies concurrently; each file runs with
# ON_ERROR_STOP=1 so a failure stops before recording (resume by re-running).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGR="${SUPABASE_MIGRATIONS_DIR:-$HERE/supabase/migrations}"
DB="postgres"
BASELINE=0
VERIFY=1

while [ $# -gt 0 ]; do
  case "$1" in
    --db) DB="${2:?--db needs a name}"; shift 2;;
    --baseline) BASELINE=1; shift;;
    --no-verify) VERIFY=0; shift;;
    *) echo "unknown arg: $1 (see header)" >&2; exit 2;;
  esac
done

# Remote psql helper: SQL arrives on stdin (never embedded in remote quoting),
# optional psql flags in $1. Mirrors scripts/verify-db.sh (same SSH target,
# same postgres image); stdin flows local -> ssh -> docker -> psql.
remote_psql_stdin() {
  ssh homeserver "export POSTGRES_PASSWORD=\"\$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)\"; docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 psql \"postgresql://postgres:\$POSTGRES_PASSWORD@supabase-db:5432/${DB}?sslmode=disable\" -v ON_ERROR_STOP=1 $1"
}

# Single-statement query helper: $1 = psql flags, $2 = SQL. Prints stdout.
remote_query() {
  printf '%s' "$2" | remote_psql_stdin "$1"
}

echo "[migrate] target database: ${DB} (baseline=${BASELINE})"

# Bookkeeping reuses the Supabase-CLI-compatible table when present
# (version TEXT PK, statements TEXT[], name TEXT); our columns are added only
# if missing. version = leading timestamp (matches CLI rows like 20260905000001);
# full filename goes to name; sha256 powers edited-file detection.
remote_query "" "
  CREATE SCHEMA IF NOT EXISTS supabase_migrations;
  CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
    version TEXT PRIMARY KEY,
    statements TEXT[],
    name TEXT
  );
  ALTER TABLE supabase_migrations.schema_migrations
    ADD COLUMN IF NOT EXISTS sha256 TEXT;
  ALTER TABLE supabase_migrations.schema_migrations
    ADD COLUMN IF NOT EXISTS applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
" > /dev/null
echo "[migrate] bookkeeping table ready"

APPLIED=0
SKIPPED=0
# Guard: filenames must start with a pure numeric version followed by _ .
# A letter suffix like 49b collides with 49 because version extraction takes
# leading digits only — fail fast instead of recording a wrong ledger row.
for f in "$MIGR"/[0-9]*.sql; do
  base="$(basename "$f")"
  if ! printf '%s' "$base" | grep -qE '^[0-9]+_'; then
    echo "[migrate] FAIL: bad migration filename (must be <digits>_<name>.sql, no letter suffix like 49b): ${base}" >&2
    exit 1
  fi
done
# Guard: no two files may map to the same numeric version.
dup_versions="$(for f in "$MIGR"/[0-9]*.sql; do basename "$f" | grep -oE '^[0-9]+'; done | sort | uniq -d || true)"
if [ -n "$dup_versions" ]; then
  echo "[migrate] FAIL: duplicate migration versions (rename to pure numeric versions): ${dup_versions}" >&2
  exit 1
fi
for f in "$MIGR"/[0-9]*.sql; do
  base="$(basename "$f")"
  v="$(printf '%s' "$base" | grep -oE '^[0-9]+')"
  sha="$(sha256sum "$f" | cut -d' ' -f1)"
  rec="$(remote_query "-tA" "SELECT COALESCE(sha256, '<no-sha>') FROM supabase_migrations.schema_migrations WHERE version = '${v}';")"
  if [ -n "$rec" ] && [ "$rec" != "<no-sha>" ]; then
    if [ "$rec" != "$sha" ]; then
      echo "[migrate] FAIL: ${base} was EDITED after being applied (migrations are append-only)" >&2
      exit 1
    fi
    echo "[migrate] skip ${base} (already applied)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [ "$rec" = "<no-sha>" ]; then
    # Adopted: applied before sha tracking existed (e.g. via supabase db push).
    # Live state was verified (policies, defaults, green smoke suite).
    remote_query "" "UPDATE supabase_migrations.schema_migrations SET sha256 = '${sha}', name = '${base}' WHERE version = '${v}';" > /dev/null
    echo "[migrate] adopt ${base} (was applied, sha recorded now)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [ "$BASELINE" -eq 1 ]; then
    remote_query "" "INSERT INTO supabase_migrations.schema_migrations (version, name, sha256) VALUES ('${v}', '${base}', '${sha}') ON CONFLICT (version) DO UPDATE SET sha256 = EXCLUDED.sha256, name = EXCLUDED.name;" > /dev/null
    echo "[migrate] baseline ${v} (recorded, not executed)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  echo "[migrate] applying ${base}..."
  scp -q "$f" homeserver:/tmp/mig_apply.sql
  ssh homeserver 'bash -s' <<EOF
  set -euo pipefail
  export POSTGRES_PASSWORD="\$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
  docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 \
    psql "postgresql://postgres:\${POSTGRES_PASSWORD}@supabase-db:5432/${DB}?sslmode=disable" -v ON_ERROR_STOP=1 < /tmp/mig_apply.sql
  rm -f /tmp/mig_apply.sql
EOF
  remote_query "" "INSERT INTO supabase_migrations.schema_migrations (version, name, sha256) VALUES ('${v}', '${base}', '${sha}');" > /dev/null
  echo "[migrate] applied ${base}"
  APPLIED=$((APPLIED + 1))
done

echo "[migrate] done: ${APPLIED} applied, ${SKIPPED} already had."

if [ "$VERIFY" -eq 1 ] && [ "$DB" = "postgres" ]; then
  echo "[migrate] running smoke suite..."
  "$HERE/scripts/verify-db.sh" > /tmp/mig_verify.log 2>&1
  tail -3 /tmp/mig_verify.log
fi
