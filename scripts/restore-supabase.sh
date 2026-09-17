#!/usr/bin/env bash
# restore-supabase.sh — restore the latest backup into a SCRATCH database and
# prove the recovery procedure end-to-end WITHOUT touching production data.
# Runs on the homeserver (Debian 12). Installed from repo scripts/.
# Requirements: a backup in /srv/backups/supabase and /srv/scripts/verify_smoke.sql
# Usage: /srv/scripts/restore-supabase.sh
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/srv/backups/supabase}"
SUPABASE_DIR="${SUPABASE_DIR:-/srv/compose/supabase}"
SMOKE_SQL="${SMOKE_SQL:-/srv/scripts/verify_smoke.sql}"
SG_USER="${POSTGRES_USER:-supabase_admin}"
LATEST="$(ls -1t "$BACKUP_DIR"/supabase_*.dump 2>/dev/null | head -1)"

[ -n "${LATEST:-}" ] || { echo "FATAL: no backup found in $BACKUP_DIR" >&2; exit 1; }
export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' "$SUPABASE_DIR/.env")"
SCRATCH="restore_test_$(date +%Y%m%d_%H%M%S)"

PG_ENV="-e PGHOST=supabase-db -e PGPORT=5432 -e PGUSER=${SG_USER} -e PGPASSWORD=${POSTGRES_PASSWORD}"
PSQL() { docker run --rm -i --network supabase_default $PG_ENV \
  supabase/postgres:17.6.1.136 psql "$@"; }

# Always clean up the scratch DB, even on failure.
trap 'PSQL -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS \"$SCRATCH\"" >/dev/null 2>&1 || true' EXIT

SQL_COUNTS='
SELECT
 (SELECT count(*) FROM public.profiles) AS profiles,
 (SELECT count(*) FROM public.projects) AS projects,
 (SELECT count(*) FROM public.workers) AS workers,
 (SELECT count(*) FROM public.treasury_transactions) AS treasury_transactions,
 (SELECT count(*) FROM public.surplus_bank) AS surplus_bank,
 (SELECT count(*) FROM public.project_cost_adjustments) AS cost_adjustments,
 (SELECT count(*) FROM public.worker_logs) AS worker_logs,
 (SELECT count(*) FROM public.worker_advances) AS worker_advances,
 (SELECT count(*) FROM public.subcontract_orders) AS subcon_orders,
 (SELECT count(*) FROM public.subcontract_payments) AS subcon_payments,
 (SELECT count(*) FROM public.general_expenses) AS general_expenses,
 (SELECT count(*) FROM public.idempotency_keys) AS idem_keys,
 (SELECT count(*) FROM public.settings) AS settings;'
SQL_VIEWS='
SELECT '\''treasury_balance'\'' AS k, to_jsonb(x)::text AS v
  FROM (SELECT * FROM public.v_treasury_balance ORDER BY 1) x
UNION ALL SELECT '\''surplus_available'\'', to_jsonb(x)::text
  FROM (SELECT * FROM public.v_surplus_available ORDER BY 1) x
UNION ALL SELECT '\''pending_liabilities'\'', to_jsonb(x)::text
  FROM (SELECT * FROM public.v_pending_liabilities ORDER BY 1) x
UNION ALL SELECT '\''project_direct_costs'\'', to_jsonb(x)::text
  FROM (SELECT * FROM public.v_project_direct_costs ORDER BY 1) x;'

# Baseline production snapshot BEFORE anything happens.
printf '%s\n' "$SQL_COUNTS" | PSQL -tA -d postgres > /tmp/live_counts_before.txt
printf '%s\n' "$SQL_VIEWS" | PSQL -tA -d postgres > /tmp/live_views_before.txt

echo "== restoring $LATEST into scratch db $SCRATCH =="
PSQL -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$SCRATCH\"" >/dev/null
# NOTE (P2-07): --no-owner is kept (objects land owned by the restoring admin),
# but privileges MUST be restored (no --no-privileges): our security model
# lives in REVOKEs (migrations 15/20/27), and a recovery without them would
# silently reopen every function to PUBLIC. Same-cluster roles always exist,
# so restoring ACLs is safe.
docker run --rm -i --network supabase_default $PG_ENV \
  supabase/postgres:17.6.1.136 pg_restore -h supabase-db -p 5432 -U "${SG_USER}" \
  -d "$SCRATCH" --no-owner < "$LATEST" >/dev/null
echo "PG_RESTORE_OK"

echo "== schema/RLS/migrations smoke against the restored scratch db =="
PSQL -d "$SCRATCH" -v ON_ERROR_STOP=1 < "$SMOKE_SQL" >/dev/null
echo "SMOKE_AGAINST_RESTORE_OK"

echo "== data matching: row counts + financial views, live vs restored =="
printf '%s\n' "$SQL_COUNTS" | PSQL -tA -d "$SCRATCH" > /tmp/scratch_counts.txt
printf '%s\n' "$SQL_VIEWS" | PSQL -tA -d "$SCRATCH" > /tmp/scratch_views.txt
if ! diff -u /tmp/live_counts_before.txt /tmp/scratch_counts.txt; then
  echo "FAIL: ROW-COUNT mismatch live vs restored" >&2; exit 1
fi
if ! diff -u /tmp/live_views_before.txt /tmp/scratch_views.txt; then
  echo "FAIL: FINANCIAL-VIEW mismatch live vs restored" >&2; exit 1
fi
echo "ROW_COUNTS_MATCH:"
cat /tmp/live_counts_before.txt
echo "VIEWS_MATCH:"
cat /tmp/live_views_before.txt

# Prove the whole exercise did not touch production data.
printf '%s\n' "$SQL_COUNTS" | PSQL -tA -d postgres > /tmp/live_counts_after.txt
if ! diff -u /tmp/live_counts_before.txt /tmp/live_counts_after.txt; then
  echo "FAIL: live DB changed during the restore test" >&2; exit 1
fi
echo "PROD_UNCHANGED_OK"

echo "RESTORE_OK scratch=$SCRATCH backup=$LATEST"