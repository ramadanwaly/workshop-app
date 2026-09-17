#!/usr/bin/env bash
# verify-pooler.sh — functional + concurrent-load proof for the Postgres pooler
# (Supavisor). Runs against the homeserver's self-hosted Supabase.
#  * functional: a real pooled query succeeds on 6543 (transaction) and 5432 (session)
#  * concurrent-load: N parallel pooled clients each run a financial battery;
#    every checksum must equal the serial baseline, proving no data loss/garbling.
# Usage: POOLER_TENANT_ID=your-tenant-id scripts/verify-pooler.sh [N]
set -euo pipefail

N="${1:-24}"
TENANT="${POOLER_TENANT_ID:-your-tenant-id}"

ssh homeserver 'bash -s' "$N" "$TENANT" <<'RSCRIPT'
  set -euo pipefail
  N="$1"; TENANT="$2"
  export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"

  read -r -d '' BATTERY <<'SQL' || true
SELECT
 (SELECT current_balance FROM public.v_treasury_balance)::text || '|' ||
 (SELECT total_pending_liabilities::text FROM public.v_pending_liabilities) || '|' ||
 (SELECT total_surplus_value::text FROM public.v_surplus_available) || '|' ||
 (SELECT count(*)::text FROM public.worker_logs) || '|' ||
 (SELECT count(*)::text FROM public.treasury_transactions) || '|' ||
 (SELECT count(*)::text FROM public.subcontract_payments) || '|' ||
 (SELECT count(*)::text FROM public.profiles);
SQL

  run_one() { docker run --rm --network supabase_default supabase/postgres:17.6.1.136 \
    psql "postgresql://postgres.${TENANT}:${POSTGRES_PASSWORD}@supabase-pooler:${1}/postgres?sslmode=disable" \
    -tA -c "$BATTERY" > "$2"; }

  echo "== functional: pooled query on 6543 and 5432 =="
  run_one 6543 /tmp/pool_6543.txt
  run_one 5432 /tmp/pool_5432.txt
  echo "port 6543: $(cat /tmp/pool_6543.txt)"
  echo "port 5432: $(cat /tmp/pool_5432.txt)"
  # NOTE: the checksum may start with '-' (negative treasury balance) —
  # the '--' stops grep from parsing it as a flag.
  grep -qx -- "$(cat /tmp/pool_6543.txt)" /tmp/pool_5432.txt || { echo "FAIL: functional ports disagree" >&2; exit 1; }
  echo "POOLER_FUNCTIONAL_OK"

  echo "== serial baseline =="
  run_one 6543 /tmp/pool_base.txt
  BASE="$(cat /tmp/pool_base.txt)"
  echo "baseline=( $BASE )"

  echo "== concurrent load: $N parallel pooled clients on 6543 + 5432 =="
  rm -f /tmp/pool_out_*; mkdir -p /tmp/pool_jobs; rm -f /tmp/pool_jobs/*
  i=1
  while [ "$i" -le "$N" ]; do
    P=$(( (i % 2 == 0) ? 5432 : 6543 ))
    run_one "$P" "/tmp/pool_jobs/${i}.txt" &
    i=$((i+1))
  done
  wait
  FAILS=0; RESULTS=0
  for f in /tmp/pool_jobs/*.txt; do
    RESULTS=$((RESULTS+1))
    if [ "$(cat "$f")" != "$BASE" ]; then FAILS=$((FAILS+1)); echo "MISMATCH in $f"; fi
  done
  echo "clients_run=$RESULTS mismatches=$FAILS"
  [ "$RESULTS" -eq "$N" ] || { echo "FAIL: only $RESULTS/$N parallel jobs completed" >&2; exit 1; }
  [ "$FAILS" -eq 0 ] || { echo "FAIL: $FAILS parallel results diverged from baseline" >&2; exit 1; }
  echo "POOLER_CONCURRENT_OK ($RESULTS/$N identical)"
RSCRIPT