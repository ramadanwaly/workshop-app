#!/usr/bin/env bash
# P2-09 scratch validation on homeserver (does NOT touch the live postgres DB).
# 1. Creates empty DB p2_09_scratch with pgcrypto + stub auth schema.
# 2. Applies supabase/migrations 01..28 in order (ON_ERROR_STOP=1).
# 3. Structural checks (cleanup REVOKE, settings policies, attendance unique).
# 4. Functional check: double attendance is rejected with the Arabic message.
# 5. Drops the scratch DB.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGR="$HERE/supabase/migrations"
SCRATCH="p2_09_scratch"

remote_psql() { # $1 = db, $2 = extra args, stdin = SQL
  ssh homeserver "export POSTGRES_PASSWORD=\"\$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)\"; docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 psql \"postgresql://postgres:\$POSTGRES_PASSWORD@supabase-db:5432/${1}?sslmode=disable\" -v ON_ERROR_STOP=1 $2"
}

echo "[scratch] recreate database ${SCRATCH}..."
printf "DROP DATABASE IF EXISTS %s;" "${SCRATCH}" | remote_psql postgres ""
printf "CREATE DATABASE %s;" "${SCRATCH}" | remote_psql postgres ""

echo "[scratch] stubs: pgcrypto + auth.users + steerable auth.uid()..."
remote_psql "${SCRATCH}" "" <<'SQL'
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (id UUID PRIMARY KEY, raw_user_meta_data JSONB);
CREATE TABLE IF NOT EXISTS stub_current_uid (id UUID);
INSERT INTO auth.users (id) VALUES ('00000000-0000-4000-8000-000000000001');
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
  SELECT id FROM stub_current_uid LIMIT 1;
$$ LANGUAGE sql STABLE;
SQL

echo "[scratch] applying migrations 01..28 in order..."
for f in "$MIGR"/[0-9]*.sql; do
  scp -q "$f" homeserver:/tmp/scratch_mig.sql
  ssh homeserver 'bash -s' <<'EOF'
set -euo pipefail
export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 \
  psql "postgresql://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/p2_09_scratch?sslmode=disable" \
  -v ON_ERROR_STOP=1 < /tmp/scratch_mig.sql > /dev/null
rm -f /tmp/scratch_mig.sql
EOF
  echo "  applied $(basename "$f")"
done

echo "[scratch] structural + functional tests..."
remote_psql "${SCRATCH}" "" <<'SQL'
-- identities: first user -> owner (trigger), second -> manager
INSERT INTO auth.users (id) VALUES
  ('11111111-1111-4111-8111-111111111111'),
  ('22222222-2222-4222-8222-222222222222');
INSERT INTO stub_current_uid (id) VALUES ('11111111-1111-4111-8111-111111111111');

-- 1. Cleanup gate: nobody except the server role may execute it
DO $$
BEGIN
  IF has_function_privilege('anon', 'public.cleanup_expired_idempotency_keys()', 'EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: anon can execute cleanup';
  END IF;
  IF has_function_privilege('authenticated', 'public.cleanup_expired_idempotency_keys()', 'EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: authenticated can execute cleanup';
  END IF;
  IF NOT has_function_privilege('postgres', 'public.cleanup_expired_idempotency_keys()', 'EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: postgres lost cleanup (cron would break)';
  END IF;
  RAISE NOTICE 'ok: cleanup gate (cron role keeps access)';
END $$;

-- 2. Settings: changeable, never deletable
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND cmd = 'DELETE') THEN
    RAISE EXCEPTION 'FAIL: settings still has a DELETE policy';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND cmd = 'ALL') THEN
    RAISE EXCEPTION 'FAIL: settings still has a FOR ALL policy';
  END IF;
  IF (SELECT count(*) FROM pg_policies WHERE tablename = 'settings' AND cmd IN ('INSERT', 'UPDATE')) <> 2 THEN
    RAISE EXCEPTION 'FAIL: settings owner INSERT/UPDATE policies missing';
  END IF;
  RAISE NOTICE 'ok: settings changeable, never deletable';
END $$;

-- 3. Attendance unique constraint exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.worker_logs'::regclass AND conname = 'worker_logs_one_row_per_day'
  ) THEN
    RAISE EXCEPTION 'FAIL: attendance unique constraint missing';
  END IF;
  RAISE NOTICE 'ok: attendance unique constraint present';
END $$;

-- 4. Double attendance rejected with the Arabic message (as owner/staff)
DO $$
DECLARE v_worker UUID; v_msg TEXT;
BEGIN
  INSERT INTO public.workers (name, daily_rate, is_active)
  VALUES ('عامل تجريبي', 100, true) RETURNING id INTO v_worker;
  PERFORM public.rpc_record_attendance(v_worker, NULL, CURRENT_DATE, 1.00);
  BEGIN
    PERFORM public.rpc_record_attendance(v_worker, NULL, CURRENT_DATE, 1.00);
    RAISE EXCEPTION 'FAIL: second attendance accepted';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'تم تسجيل حضور هذا العامل في هذا اليوم من قبل' THEN
      RAISE EXCEPTION 'FAIL: wrong duplicate message: %', v_msg;
    END IF;
  END;
  RAISE NOTICE 'ok: duplicate attendance rejected in Arabic';
END $$;
SQL

echo "[scratch] dropping ${SCRATCH}..."
printf "DROP DATABASE IF EXISTS %s;" "${SCRATCH}" | remote_psql postgres ""
echo "SCRATCH_P2_09_OK"
