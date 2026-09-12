#!/usr/bin/env bash
# P2-06 scratch validation on homeserver (does NOT touch the live postgres DB).
# 1. Creates empty DB p2_06_scratch with pgcrypto + stub auth schema.
# 2. Applies supabase/migrations 01..27 in order (ON_ERROR_STOP=1).
# 3. Functional tests of the new audit triggers + exclusion RPCs
#    (auth.uid() stub is steered via stub.current_uid table).
# 4. Drops the scratch DB.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGR="$HERE/supabase/migrations"
SCRATCH="p2_06_scratch"

remote_psql() { # $1 = db, stdin = SQL
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

echo "[scratch] applying migrations 01..27 in order..."
for f in "$MIGR"/[0-9]*.sql; do
  scp -q "$f" homeserver:/tmp/scratch_mig.sql
  ssh homeserver 'bash -s' <<'EOF'
set -euo pipefail
export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 \
  psql "postgresql://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/p2_06_scratch?sslmode=disable" \
  -v ON_ERROR_STOP=1 < /tmp/scratch_mig.sql > /dev/null
rm -f /tmp/scratch_mig.sql
EOF
  echo "  applied $(basename "$f")"
done

echo "[scratch] functional tests..."
remote_psql "${SCRATCH}" "" <<'SQL'
-- Owner + manager identities (the auth trigger auto-creates profiles:
-- first user -> owner, second -> manager; then fix the display names)
INSERT INTO auth.users (id) VALUES
  ('11111111-1111-4111-8111-111111111111'),
  ('22222222-2222-4222-8222-222222222222');
UPDATE public.profiles SET full_name = 'Owner' WHERE id = '11111111-1111-4111-8111-111111111111';
UPDATE public.profiles SET full_name = 'Manager' WHERE id = '22222222-2222-4222-8222-222222222222';
INSERT INTO stub_current_uid (id) VALUES ('11111111-1111-4111-8111-111111111111');

-- 1. Treasury void is logged (direct UPDATE path, like voidTransaction action)
DO $$
DECLARE v_tx UUID; v_proj UUID;
BEGIN
  INSERT INTO public.projects (name) VALUES ('Audit Test Project') RETURNING id INTO v_proj;
  INSERT INTO public.treasury_transactions (transaction_type, category, amount, description, created_by)
  VALUES ('in', 'owner_funding', 10000, 'seed', '11111111-1111-4111-8111-111111111111') RETURNING id INTO v_tx;
  UPDATE public.treasury_transactions
  SET is_voided = true, voided_at = NOW(), void_reason = 'سبب تجريبي', voided_by = '11111111-1111-4111-8111-111111111111'
  WHERE id = v_tx;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'void_treasury' AND entity_id = v_tx AND reason = 'سبب تجريبي') THEN
    RAISE EXCEPTION 'FAIL: void_treasury not logged';
  END IF;
  RAISE NOTICE 'ok: void_treasury logged';
END $$;

-- 2. Subcontract order close (cancelled) is logged
DO $$
DECLARE v_proj UUID; v_ord UUID;
BEGIN
  SELECT id INTO v_proj FROM public.projects WHERE name = 'Audit Test Project';
  INSERT INTO public.subcontract_orders (project_id, contractor_name, description, total_agreed_amount)
  VALUES (v_proj, 'مقاول', 'عمل', 5000) RETURNING id INTO v_ord;
  UPDATE public.subcontract_orders SET status = 'cancelled', close_reason = 'إلغاء تجريبي' WHERE id = v_ord;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'close_subcontract_order' AND entity_id = v_ord AND reason = 'إلغاء تجريبي') THEN
    RAISE EXCEPTION 'FAIL: close_subcontract_order not logged';
  END IF;
  RAISE NOTICE 'ok: close_subcontract_order logged';
END $$;

-- 3. Subcontract payment + void are logged (payment has no audit row; void does)
DO $$
DECLARE v_proj UUID; v_ord UUID; v_pay UUID; v_tx UUID;
BEGIN
  SELECT id INTO v_proj FROM public.projects WHERE name = 'Audit Test Project';
  INSERT INTO public.subcontract_orders (project_id, contractor_name, description, total_agreed_amount)
  VALUES (v_proj, 'مقاول2', 'عمل2', 4000) RETURNING id INTO v_ord;
  INSERT INTO public.treasury_transactions (transaction_type, category, amount, description, created_by)
  VALUES ('out', 'subcontract_payment', 1000, 'دفعة', '11111111-1111-4111-8111-111111111111') RETURNING id INTO v_tx;
  INSERT INTO public.subcontract_payments (subcontract_order_id, amount, treasury_transaction_id, notes)
  VALUES (v_ord, 1000, v_tx, 'دفعة أولى') RETURNING id INTO v_pay;
  UPDATE public.subcontract_payments SET is_voided = true, void_reason = 'دفعة خاطئة' WHERE id = v_pay;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'void_subcontract_payment' AND entity_id = v_pay AND reason = 'دفعة خاطئة') THEN
    RAISE EXCEPTION 'FAIL: void_subcontract_payment not logged';
  END IF;
  RAISE NOTICE 'ok: void_subcontract_payment logged';
END $$;

-- 4. Surplus return + scrap flow through the cost-adjustment trigger
DO $$
DECLARE v_proj UUID; v_sur UUID; v_adj UUID;
BEGIN
  SELECT id INTO v_proj FROM public.projects WHERE name = 'Audit Test Project';
  INSERT INTO public.surplus_bank (material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status)
  VALUES ('خشب', 'لوح', 10, 10, 1000, v_proj, 'available') RETURNING id INTO v_sur;
  INSERT INTO public.project_cost_adjustments (project_id, adjustment_type, amount, surplus_id, notes)
  VALUES (v_proj, 'surplus_return', 1000, v_sur, 'إرجاع تجريبي') RETURNING id INTO v_adj;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'return_surplus' AND entity_id = v_adj) THEN
    RAISE EXCEPTION 'FAIL: return_surplus not logged';
  END IF;
  UPDATE public.surplus_bank SET status = 'scrapped', quantity = 0 WHERE id = v_sur;
  INSERT INTO public.project_cost_adjustments (project_id, adjustment_type, amount, surplus_id, notes)
  VALUES (NULL, 'surplus_scrap', 1000, v_sur, 'إتلاف تجريبي');
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'scrap_surplus' AND reason = 'إتلاف تجريبي') THEN
    RAISE EXCEPTION 'FAIL: scrap_surplus not logged';
  END IF;
  RAISE NOTICE 'ok: return_surplus + scrap_surplus logged';
END $$;

-- 5. Allocation cycle run + void are logged (one row per run, not per line)
DO $$
DECLARE v_cyc UUID;
BEGIN
  INSERT INTO public.operating_allocation_cycles (year_month, status, total_amount, notes, created_by)
  VALUES ('2026-01-01', 'noop', 0, 'شهر تجريبي', '11111111-1111-4111-8111-111111111111') RETURNING id INTO v_cyc;
  IF (SELECT count(*) FROM public.audit_log WHERE action = 'run_operating_allocation' AND entity_id = v_cyc) <> 1 THEN
    RAISE EXCEPTION 'FAIL: run_operating_allocation not logged exactly once';
  END IF;
  UPDATE public.operating_allocation_cycles SET is_voided = true, voided_at = NOW(), void_reason = 'دورة خاطئة', voided_by = '11111111-1111-4111-8111-111111111111' WHERE id = v_cyc;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'void_allocation_cycle' AND entity_id = v_cyc AND reason = 'دورة خاطئة') THEN
    RAISE EXCEPTION 'FAIL: void_allocation_cycle not logged';
  END IF;
  RAISE NOTICE 'ok: run + void allocation cycle logged';
END $$;

-- 6. Exclusion add/remove RPCs log the reason (removal survives the DELETE)
DO $$
DECLARE v_proj UUID; r JSONB;
BEGIN
  SELECT id INTO v_proj FROM public.projects WHERE name = 'Audit Test Project';
  r := public.rpc_add_operating_exclusion('2026-02-01', v_proj, 'استبعاد تجريبي');
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'add_operating_exclusion' AND entity_id = v_proj AND reason = 'استبعاد تجريبي') THEN
    RAISE EXCEPTION 'FAIL: add_operating_exclusion not logged';
  END IF;
  r := public.rpc_remove_operating_exclusion('2026-02-01', v_proj, 'سبب الإزالة التجريبي');
  IF EXISTS (SELECT 1 FROM public.operating_allocation_exclusions WHERE project_id = v_proj) THEN
    RAISE EXCEPTION 'FAIL: exclusion row was not deleted';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_log WHERE action = 'remove_operating_exclusion' AND entity_id = v_proj AND reason = 'سبب الإزالة التجريبي') THEN
    RAISE EXCEPTION 'FAIL: remove_operating_exclusion reason not preserved';
  END IF;
  RAISE NOTICE 'ok: exclusion add/remove logged with reason';
END $$;

-- 7. Immutability: UPDATE and DELETE on audit_log must fail
DO $$
BEGIN
  BEGIN
    UPDATE public.audit_log SET reason = 'عبث' WHERE action = 'void_treasury';
    RAISE EXCEPTION 'FAIL: audit UPDATE was allowed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%سجل التدقيق دائم%' THEN RAISE; END IF;
  END;
  BEGIN
    DELETE FROM public.audit_log WHERE action = 'void_treasury';
    RAISE EXCEPTION 'FAIL: audit DELETE was allowed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%سجل التدقيق دائم%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'ok: audit_log immutable';
END $$;

-- 8. Operating-allocation LINES do not flood the log (cycle row is the entry)
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM public.audit_log WHERE action = 'run_operating_allocation';
  IF n <> 1 THEN RAISE EXCEPTION 'FAIL: expected 1 run_operating_allocation row, got %', n; END IF;
  RAISE NOTICE 'ok: no log flood (total audit rows=%)', (SELECT count(*) FROM public.audit_log);
END $$;
SQL

echo "[scratch] dropping database ${SCRATCH}..."
printf "DROP DATABASE IF EXISTS %s;" "${SCRATCH}" | remote_psql postgres ""
echo "[scratch] ALL SCRATCH CHECKS PASSED"
