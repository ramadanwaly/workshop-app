#!/usr/bin/env bash
# ============================================================================
# verify-concurrency.sh — REAL two-request race test against the live DB.
# Two independent psql sessions concurrently consume the SAME surplus row.
# Only ONE can win; the loser must be rejected by the row lock + guard.
# Verifies over-consumption is impossible, then explicitly cleans up fixtures.
# Usage: scripts/verify-concurrency.sh
# ============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scp -q "$HERE/supabase/concurrency/seed.sql" \
        "$HERE/supabase/concurrency/consumer.sql" \
        "$HERE/supabase/concurrency/verify_and_cleanup.sql" \
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

  echo '== Generating fixture ids =='
  # Stable fixture identity: the immutable audit trail may reference the
  # fixture actor forever, so the user is fixed (reused across runs) while
  # data rows stay random per run. See migration 29.
  C_USER="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
  IFS='|' read -r C_PROJECT C_SOURCE_PROJECT C_SURPLUS < <(psql_run -tAc "SELECT gen_random_uuid(), gen_random_uuid(), gen_random_uuid()" < /dev/null)
  echo "  user=$C_USER (stable)"
  echo "  project=$C_PROJECT"
  echo "  source_project=$C_SOURCE_PROJECT"
  echo "  surplus=$C_SURPLUS"

  if [ -z "$C_PROJECT" ] || [ -z "$C_SOURCE_PROJECT" ] || [ -z "$C_SURPLUS" ]; then
    echo 'FAIL: id generation produced empty values' >&2
    exit 1
  fi

  echo '== Pre-cleansing any leftover fixtures from an aborted prior run =='
  psql_run -v ON_ERROR_STOP=1 -f /dev/stdin <<'PRE_SQL' || true
    DELETE FROM public.project_cost_adjustments
    WHERE surplus_id IN (SELECT id FROM public.surplus_bank WHERE material_name='Concurrency Test Material')
       OR project_id   IN (SELECT id FROM public.projects      WHERE name IN ('Concurrency Test Project', 'Concurrency Source Project'));
    DELETE FROM public.surplus_bank WHERE material_name='Concurrency Test Material';
    DELETE FROM public.projects      WHERE name IN ('Concurrency Test Project', 'Concurrency Source Project');
    -- NOTE: the stable fixture identity (auth.users/profiles) is intentionally
    -- kept: the immutable audit trail may reference it (migration 29).
PRE_SQL

  echo '== Seeding fixture (committed) =='
  psql_run -v ON_ERROR_STOP=1 \
    -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_source_project="$C_SOURCE_PROJECT" -v c_surplus="$C_SURPLUS" \
    < /tmp/seed.sql

  echo '== Firing two concurrent consume(70) requests on the same surplus =='
  CLAIMS_A=$(printf '{"sub":"%s","role":"authenticated"}' "$C_USER")
  CLAIMS_B=$(printf '{"sub":"%s","role":"authenticated"}' "$C_USER")
  psql_run -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_surplus="$C_SURPLUS" -v claims="$CLAIMS_A" -v c_tag="A" \
    < /tmp/consumer.sql > /tmp/consumer_a.out 2>&1 &
  PID_A=$!

  psql_run -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_surplus="$C_SURPLUS" -v claims="$CLAIMS_B" -v c_tag="B" \
    < /tmp/consumer.sql > /tmp/consumer_b.out 2>&1 &
  PID_B=$!

  set +e
  wait "$PID_A"; RC_A=$?
  wait "$PID_B"; RC_B=$?
  set -e

  echo '== Session A output =='
  cat /tmp/consumer_a.out
  echo '== Session B output =='
  cat /tmp/consumer_b.out

  WIN_A=$(grep -c 'mode=' /tmp/consumer_a.out || true)
  WIN_B=$(grep -c 'mode=' /tmp/consumer_b.out || true)
  ERR_A=$(grep -c 'ERROR:' /tmp/consumer_a.out || true)
  ERR_B=$(grep -c 'ERROR:' /tmp/consumer_b.out || true)

  echo "  A: success=$WIN_A errors=$ERR_A"
  echo "  B: success=$WIN_B errors=$ERR_B"

  if [ "$WIN_A" -ne 1 ] && [ "$WIN_B" -ne 1 ]; then
    echo 'FAIL: neither session consumed (concurrency test could not run)'
    exit 1
  fi
  if [ $((WIN_A + WIN_B)) -ne 1 ]; then
    echo 'FAIL: MORE THAN ONE SESSION SUCCEEDED — over-consumption risk!'
    exit 1
  fi
  if [ "$WIN_A" -ne 1 ] && [ "$ERR_A" -ne 1 ] || \
     [ "$WIN_B" -ne 1 ] && [ "$ERR_B" -ne 1 ]; then
    echo 'FAIL: expected the losing session to report an RPC error'
    exit 1
  fi
  echo "PASS: exactly one of two concurrent consumes succeeded"

  echo '== Verifying invariant + explicit cleanup =='
  psql_run -v ON_ERROR_STOP=1 \
    -v c_user="$C_USER" -v c_project="$C_PROJECT" -v c_source_project="$C_SOURCE_PROJECT" -v c_surplus="$C_SURPLUS" \
    < /tmp/verify_and_cleanup.sql
RSCRIPT

echo 'CONCURRENCY SUITE PASSED'