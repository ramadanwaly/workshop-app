#!/usr/bin/env bash
# ============================================================================
# verify-audit-concurrency.sh — Phase 10 real parallel race + full audit run.
# 1. Runs supabase/verify_financial_audit.sql (sequential narrative incl. the
#    sequential exactly-one-win proof on order2).
# 2. Fires a REAL two-request race: two independent psql sessions concurrently
#    pay 16000 on the SAME fresh order (agreed 30000) — only ONE can win; the
#    loser must be rejected by the order row lock (FOR UPDATE) + sum guard.
# Usage: scripts/verify-audit-concurrency.sh
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scp -q "$HERE/supabase/verify_financial_audit.sql" \
        "$HERE/supabase/auditconcurrency/seed.sql" \
        "$HERE/supabase/auditconcurrency/consumer.sql" \
        "$HERE/supabase/auditconcurrency/verify_and_cleanup.sql" \
        homeserver:/tmp/

# ---------------------------------------------------------------------------
# Remote orchestration. Each SQL file is piped into its container via stdin
# (`< /tmp/...sql`), because the container does not see host /tmp itself.
# ---------------------------------------------------------------------------
ssh homeserver 'bash -s' <<'RSCRIPT'
  set -euo pipefail
  export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
  DSN="postgresql://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/postgres?sslmode=disable"

  psql_run() { docker run --rm -i --network supabase_default \
    supabase/postgres:17.6.1.136 psql "$DSN" "$@"; }

  echo '== Phase 10 sequential audit (narrative + reconciliation) =='
  psql_run -v ON_ERROR_STOP=1 < /tmp/verify_financial_audit.sql

  echo '== Resolving stable race fixture identity + generating data ids =='
  # Stable fixture identity: the immutable audit trail may reference the
  # fixture actor forever, so the user is resolved by its fixed email and
  # reused across runs (fixed fallback id for a fresh DB) while data rows
  # stay random per run. See migration 29 and the surplus-concurrency suite.
  C_USER="$(psql_run -tAc "SELECT COALESCE((SELECT id::text FROM auth.users WHERE email='audit-concurrency-test@example.test'), 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')" < /dev/null)"
  IFS='|' read -r C_PROJECT C_ORDER < <(psql_run -tAc "SELECT gen_random_uuid(), gen_random_uuid()" < /dev/null)
  echo "  user=$C_USER (stable)"
  echo "  project=$C_PROJECT"
  echo "  order=$C_ORDER"

  if [ -z "$C_USER" ] || [ -z "$C_PROJECT" ] || [ -z "$C_ORDER" ]; then
    echo 'FAIL: id generation produced empty values' >&2
    exit 1
  fi

  echo '== Pre-cleansing any leftover data fixtures from an aborted prior run =='
  psql_run -v ON_ERROR_STOP=1 -f /dev/stdin <<'PRE_SQL' || true
    DELETE FROM public.subcontract_payments WHERE subcontract_order_id IN (
      SELECT id FROM public.subcontract_orders WHERE contractor_name='Audit Concurrency Contractor');
    DELETE FROM public.subcontract_orders WHERE contractor_name='Audit Concurrency Contractor';
    DELETE FROM public.projects WHERE name='Audit Concurrency Project';
    -- NOTE: the stable fixture identity (auth.users/profiles) is intentionally
    -- kept: the immutable audit trail may reference it (migration 29).
PRE_SQL

  echo '== Seeding race fixture (committed) =='
  psql_run -v ON_ERROR_STOP=1 \
    -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_order="$C_ORDER" \
    < /tmp/seed.sql

  echo '== Firing two concurrent pay(16000) requests on the same order =='
  CLAIMS_A=$(printf '{"sub":"%s","role":"authenticated"}' "$C_USER")
  CLAIMS_B=$(printf '{"sub":"%s","role":"authenticated"}' "$C_USER")
  psql_run -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_order="$C_ORDER" -v claims="$CLAIMS_A" -v c_tag="A" \
    < /tmp/consumer.sql > /tmp/auditrace_a.out 2>&1 &
  PID_A=$!

  psql_run -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_order="$C_ORDER" -v claims="$CLAIMS_B" -v c_tag="B" \
    < /tmp/consumer.sql > /tmp/auditrace_b.out 2>&1 &
  PID_B=$!

  set +e
  wait "$PID_A"; RC_A=$?
  wait "$PID_B"; RC_B=$?
  set -e

  echo '== Session A output =='
  cat /tmp/auditrace_a.out
  echo '== Session B output =='
  cat /tmp/auditrace_b.out

  WIN_A=$(grep -c 'mode=' /tmp/auditrace_a.out || true)
  WIN_B=$(grep -c 'mode=' /tmp/auditrace_b.out || true)
  ERR_A=$(grep -c 'ERROR:' /tmp/auditrace_a.out || true)
  ERR_B=$(grep -c 'ERROR:' /tmp/auditrace_b.out || true)

  echo "  A: success=$WIN_A errors=$ERR_A"
  echo "  B: success=$WIN_B errors=$ERR_B"

  if [ "$WIN_A" -ne 1 ] && [ "$WIN_B" -ne 1 ]; then
    echo 'FAIL: neither session paid (concurrency test could not run)'
    exit 1
  fi
  if [ $((WIN_A + WIN_B)) -ne 1 ]; then
    echo 'FAIL: MORE THAN ONE SESSION SUCCEEDED — overpayment risk!'
    exit 1
  fi
  if [ "$WIN_A" -ne 1 ] && [ "$ERR_A" -ne 1 ] || \
     [ "$WIN_B" -ne 1 ] && [ "$ERR_B" -ne 1 ]; then
    echo 'FAIL: expected the losing session to report an RPC error'
    exit 1
  fi
  echo "PASS: exactly one of two concurrent payments succeeded"

  echo '== Verifying race invariant + lifecycle + explicit cleanup =='
  psql_run -v ON_ERROR_STOP=1 \
    -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_order="$C_ORDER" \
    < /tmp/verify_and_cleanup.sql
RSCRIPT

echo 'AUDIT CONCURRENCY SUITE PASSED'
