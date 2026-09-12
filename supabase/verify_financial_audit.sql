-- ============================================================================
-- verify_financial_audit.sql — PHASE 10 (prompts/13_financial_audit.md)
-- Complete accounting regression: Treasury / Materials / Labor / Subcontracting
--
-- WARNING: operates against the live database. It creates and deletes its own
-- fixture rows ONLY (test owner, manager, projects, workers). It must run
-- against an empty or test database — never against production data.
--
-- Narrative values (realistic workshop numbers):
--   funding 100000 | cash expense 1500 (voided) | direct owner material 5000
--   material purchase 5000 | surplus 800/400/150 | worker daily_rate 200
--   subcontract order1 15000 | order2 30000
--
-- Every scenario asserts ALL THREE dimensions (Cash / Cost / Liability)
-- explicitly, even when a dimension is expected to be unchanged.
--
-- Usage: psql -v ON_ERROR_STOP=1 -f verify_financial_audit.sql
--        psql -v ON_ERROR_STOP=1 -v CLEANUP=false -f verify_financial_audit.sql
--        (leaves fixtures for manual inspection)
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

-- Cleanup defaults to true; pass -v CLEANUP=false to keep fixtures.
\if :{?CLEANUP}
\else
  \set CLEANUP true
\endif

CREATE TEMP TABLE _fix AS
SELECT
    gen_random_uuid() AS owner_id,
    gen_random_uuid() AS manager_id,
    gen_random_uuid() AS project_a,
    gen_random_uuid() AS project_b,
    gen_random_uuid() AS worker_id,
    gen_random_uuid() AS control_worker_id;

-- Pre-clean any test fixtures orphaned by an aborted prior run.
-- Covers NULL-project scrap adjustments and child surplus rows (self-FK).
DELETE FROM public.project_cost_adjustments
WHERE project_id IN (
    SELECT id FROM public.projects WHERE name IN ('Audit Project A', 'Audit Project B'))
   OR surplus_id IN (
    SELECT id FROM public.surplus_bank WHERE source_project_id IN (
        SELECT id FROM public.projects WHERE name IN ('Audit Project A', 'Audit Project B')));
DELETE FROM public.surplus_bank
WHERE parent_surplus_id IS NOT NULL AND source_project_id IN (
    SELECT id FROM public.projects WHERE name IN ('Audit Project A', 'Audit Project B'));
DELETE FROM public.surplus_bank WHERE source_project_id IN (
    SELECT id FROM public.projects WHERE name IN ('Audit Project A', 'Audit Project B'));
DELETE FROM public.subcontract_payments WHERE subcontract_order_id IN (
    SELECT id FROM public.subcontract_orders WHERE contractor_name LIKE 'Audit Contractor%');
DELETE FROM public.subcontract_orders WHERE contractor_name LIKE 'Audit Contractor%';
DELETE FROM public.worker_advances WHERE worker_id IN (
    SELECT id FROM public.workers
    WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker');
DELETE FROM public.worker_logs WHERE worker_id IN (
    SELECT id FROM public.workers
    WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker');
DELETE FROM public.workers
WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker';
DELETE FROM public.treasury_transactions WHERE created_by IN (
    SELECT id FROM auth.users WHERE email LIKE 'audit-test-%@example.test');
DELETE FROM public.projects WHERE name IN ('Audit Project A', 'Audit Project B');
DELETE FROM public.idempotency_keys WHERE key LIKE 'aaaaaaaa-aaaa-4aaa-8aaa-%';
-- Fixture identities may be referenced by the immutable audit trail
-- (migration 29): remove them only when nothing references them.
DELETE FROM public.profiles WHERE id IN (
    SELECT id FROM auth.users WHERE email LIKE 'audit-test-%@example.test')
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id IN (
    SELECT id FROM auth.users WHERE email LIKE 'audit-test-%@example.test'));
DELETE FROM auth.users WHERE email LIKE 'audit-test-%@example.test'
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id IN (
    SELECT id FROM auth.users WHERE email LIKE 'audit-test-%@example.test'));

-- ---------------------------------------------------------------------------
-- Seed owner + manager + projects + workers
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
SELECT
    owner_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'audit-test-owner-' || owner_id::text || '@example.test',
    'x', '{}', '{}', NOW(), NOW()
FROM _fix;

INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
SELECT
    manager_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'audit-test-manager-' || manager_id::text || '@example.test',
    'x', '{}', '{}', NOW(), NOW()
FROM _fix;

-- Phase 9 hardened handle_new_user: subsequent users get NO profile row.
-- Roles are granted explicitly (per migration 20260905000010).
INSERT INTO public.profiles (id, full_name, role)
SELECT owner_id, 'Audit Test Owner', 'owner' FROM _fix;
INSERT INTO public.profiles (id, full_name, role)
SELECT manager_id, 'Audit Test Manager', 'manager' FROM _fix;

INSERT INTO public.projects (id, name, status)
SELECT project_a, 'Audit Project A', 'active' FROM _fix;
INSERT INTO public.projects (id, name, status)
SELECT project_b, 'Audit Project B', 'active' FROM _fix;

INSERT INTO public.workers (id, name, daily_rate, is_active)
SELECT worker_id, 'Audit Worker', 200.00, true FROM _fix;
INSERT INTO public.workers (id, name, daily_rate, is_active)
SELECT control_worker_id, 'Audit Control Worker', 100.00, true FROM _fix;

-- Baseline deltas (robust against unrelated pre-existing rows)
CREATE TEMP TABLE _base AS
SELECT
    (SELECT current_balance FROM public.v_treasury_balance) AS treasury,
    (SELECT total_pending_liabilities FROM public.v_pending_liabilities) AS liability,
    (SELECT total_worker_liabilities FROM public.v_pending_liabilities) AS worker_liab,
    (SELECT total_subcontract_liabilities FROM public.v_pending_liabilities) AS subcon_liab,
    (SELECT total_surplus_value FROM public.v_surplus_available) AS surplus;

-- Impersonate the owner for the narrative (SECURITY INVOKER RPC guards)
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT owner_id::text FROM _fix)),
    false
);

-- ===========================================================================
-- T1: Owner funding IN 100000 — Cash +100000, Cost 0, Liability 0
-- ===========================================================================
CREATE TEMP TABLE _t1 AS
WITH ins AS (
    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    )
    SELECT 'in', 'owner_funding', 100000.00, 'audit funding', owner_id FROM _fix
    RETURNING id AS tx_id
)
SELECT * FROM ins;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_cb numeric; v_liab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 100000.00, 2) THEN
        RAISE EXCEPTION 'T1 FAIL: cash=% (expected base+100000)', v_cash;
    END IF;
    IF ROUND(COALESCE(v_ca,0),2) <> 0 OR ROUND(COALESCE(v_cb,0),2) <> 0 THEN
        RAISE EXCEPTION 'T1 FAIL: funding must not touch project cost (A=%, B=%)', v_ca, v_cb;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'T1 FAIL: funding must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'T1_FUNDING_OK cash+100000 cost=0 liab=0';
END $$;

-- ===========================================================================
-- T2: Cash expense OUT 1500 (general_expense) — Cash -1500, Cost 0, Liab 0
-- ===========================================================================
CREATE TEMP TABLE _t2 AS
WITH ins AS (
    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    )
    SELECT 'out', 'general_expense', 1500.00, 'audit general expense', owner_id FROM _fix
    RETURNING id AS tx_id
)
SELECT * FROM ins;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 98500.00, 2) THEN
        RAISE EXCEPTION 'T2 FAIL: cash=% (expected base+98500)', v_cash;
    END IF;
    IF ROUND(COALESCE(v_ca,0),2) <> 0 THEN
        RAISE EXCEPTION 'T2 FAIL: general expense must not touch project cost (%)', v_ca;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'T2 FAIL: general expense must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'T2_CASH_EXPENSE_OK cash-1500 cost=0 liab=0';
END $$;

-- ===========================================================================
-- T3: Direct owner expense OUT 5000 (material, project A, direct payment)
--     Cash UNCHANGED (excluded), Cost A +5000, Liability 0
-- ===========================================================================
INSERT INTO public.treasury_transactions (
    transaction_type, category, subcategory, amount, description, project_id,
    is_direct_owner_payment, created_by
)
SELECT 'out', 'material', 'wood_boards', 5000.00, 'audit direct owner material',
    project_a, true, owner_id FROM _fix;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 98500.00, 2) THEN
        RAISE EXCEPTION 'T3 FAIL: direct owner payment must leave cash (%)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 5000.00 THEN
        RAISE EXCEPTION 'T3 FAIL: cost A=% (expected 5000)', v_ca;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'T3 FAIL: direct owner payment must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'T3_DIRECT_OWNER_OK cash=0 costA+5000 liab=0';
END $$;

-- ===========================================================================
-- T4: VOID the T2 cash expense — Cash restored +1500, Cost 0, Liability 0
-- ===========================================================================
UPDATE public.treasury_transactions
SET is_voided = true, voided_at = NOW(),
    void_reason = 'audit void', voided_by = (SELECT owner_id FROM _fix)
WHERE id = (SELECT tx_id FROM _t2);

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric; v_voided boolean;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT is_voided INTO v_voided FROM public.treasury_transactions WHERE id = (SELECT tx_id FROM _t2);
    IF v_voided IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'T4 FAIL: void flag not set (found %)', v_voided;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 100000.00, 2) THEN
        RAISE EXCEPTION 'T4 FAIL: cash=% (expected base+100000 after void)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 5000.00 THEN
        RAISE EXCEPTION 'T4 FAIL: void must not touch cost A (%)', v_ca;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'T4 FAIL: void must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'T4_VOID_OK cash restored cost=0 liab=0 (no hard delete)';
END $$;

-- ===========================================================================
-- M1: Material purchase OUT 5000 (cash, project A)
--     Cash -5000, Cost A +5000 (now 10000), Liability 0
-- ===========================================================================
INSERT INTO public.treasury_transactions (
    transaction_type, category, subcategory, amount, description, project_id, created_by
)
SELECT 'out', 'material', 'wood_boards', 5000.00, 'audit material purchase',
    project_a, owner_id FROM _fix;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'M1 FAIL: cash=% (expected base+95000)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 10000.00 THEN
        RAISE EXCEPTION 'M1 FAIL: cost A=% (expected 10000)', v_ca;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'M1 FAIL: purchase must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'M1_PURCHASE_OK cash-5000 costA=10000 liab=0';
END $$;

-- ===========================================================================
-- M2: Surplus return item1 (qty 10, value 800, from A)
--     Cash 0, Cost A -800 (9200), Surplus +800, Liability 0
-- ===========================================================================
SELECT public.rpc_return_surplus(
    (SELECT project_a FROM _fix), 'Audit Beech Wood', 'piece', 10, 800.00, 'audit return 1'
) AS return1;

CREATE TEMP TABLE _sur1 AS
SELECT id AS surplus_id FROM public.surplus_bank
WHERE material_name = 'Audit Beech Wood' ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric; v_surp numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'M2 FAIL: return must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 9200.00 THEN
        RAISE EXCEPTION 'M2 FAIL: cost A=% (expected 9200)', v_ca;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base) + 800.00, 2) THEN
        RAISE EXCEPTION 'M2 FAIL: surplus=% (expected base+800)', v_surp;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'M2 FAIL: return must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'M2_RETURN_OK cash=0 costA=9200 surplus+800 liab=0';
END $$;

-- ===========================================================================
-- M3: Partial consumption 4/10 (320) into B
--     Cash 0, Cost B +320, Surplus -320 (480 left), Liability 0
-- ===========================================================================
SELECT public.rpc_consume_surplus(
    (SELECT surplus_id FROM _sur1), (SELECT project_b FROM _fix), 4, 'audit partial'
) AS partial_consume;

DO $$
DECLARE
    v_cash numeric; v_cb numeric; v_liab numeric; v_surp numeric; v_mode text;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    IF ROUND(v_cb,2) <> 320.00 THEN
        RAISE EXCEPTION 'M3 FAIL: cost B=% (expected 320)', v_cb;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base) + 480.00, 2) THEN
        RAISE EXCEPTION 'M3 FAIL: surplus=% (expected base+480)', v_surp;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'M3 FAIL: consume must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'M3 FAIL: consume must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'M3_PARTIAL_OK cash=0 costB=320 surplus-320 liab=0';
END $$;

-- ===========================================================================
-- M4: Full consumption of remaining 6 (480) into B
--     Cash 0, Cost B = 800, Surplus 0 (item1 consumed), Liability 0
-- ===========================================================================
SELECT public.rpc_consume_surplus(
    (SELECT surplus_id FROM _sur1), (SELECT project_b FROM _fix), 6, 'audit full'
) AS full_consume;

DO $$
DECLARE
    v_cash numeric; v_cb numeric; v_liab numeric; v_surp numeric; v_status text;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    SELECT status INTO v_status FROM public.surplus_bank WHERE id = (SELECT surplus_id FROM _sur1);
    IF v_status IS DISTINCT FROM 'consumed' THEN
        RAISE EXCEPTION 'M4 FAIL: item1 status=% (expected consumed)', v_status;
    END IF;
    IF ROUND(v_cb,2) <> 800.00 THEN
        RAISE EXCEPTION 'M4 FAIL: cost B=% (expected 800)', v_cb;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base),2) THEN
        RAISE EXCEPTION 'M4 FAIL: surplus=% (expected baseline)', v_surp;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'M4 FAIL: consume must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'M4 FAIL: consume must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'M4_FULL_OK cash=0 costB=800 surplus=base liab=0';
END $$;

-- ===========================================================================
-- M5: Surplus return item2 (qty 5, value 400, from A)
--     Cash 0, Cost A = 8800, Surplus +400, Liability 0
-- ===========================================================================
SELECT public.rpc_return_surplus(
    (SELECT project_a FROM _fix), 'Audit Pine Offcut', 'piece', 5, 400.00, 'audit return 2'
) AS return2;

CREATE TEMP TABLE _sur2 AS
SELECT id AS surplus_id FROM public.surplus_bank
WHERE material_name = 'Audit Pine Offcut' ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_ca numeric; v_surp numeric;
BEGIN
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    IF ROUND(v_ca,2) <> 8800.00 THEN
        RAISE EXCEPTION 'M5 FAIL: cost A=% (expected 8800)', v_ca;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base) + 400.00, 2) THEN
        RAISE EXCEPTION 'M5 FAIL: surplus=% (expected base+400)', v_surp;
    END IF;
    RAISE NOTICE 'M5_RETURN2_OK costA=8800 surplus+400';
END $$;

-- ===========================================================================
-- M6: Scrap item2 (400) — general workshop loss, project cost UNCHANGED
--     Cash 0, Cost A = 8800, Surplus back to base, Liability 0
-- ===========================================================================
SELECT public.rpc_scrap_surplus(
    (SELECT surplus_id FROM _sur2), 'audit scrap'
) AS scrap_result;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_liab numeric; v_surp numeric;
    v_status text; v_loss numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    SELECT status INTO v_status FROM public.surplus_bank WHERE id = (SELECT surplus_id FROM _sur2);
    SELECT COALESCE(SUM(amount),0) INTO v_loss FROM public.project_cost_adjustments
    WHERE adjustment_type = 'surplus_scrap' AND project_id IS NULL
      AND surplus_id = (SELECT surplus_id FROM _sur2);
    IF v_status IS DISTINCT FROM 'scrapped' THEN
        RAISE EXCEPTION 'M6 FAIL: item2 status=% (expected scrapped)', v_status;
    END IF;
    IF ROUND(v_loss,2) <> 400.00 THEN
        RAISE EXCEPTION 'M6 FAIL: general loss=% (expected 400, project_id NULL)', v_loss;
    END IF;
    IF ROUND(v_ca,2) <> 8800.00 THEN
        RAISE EXCEPTION 'M6 FAIL: scrap must not touch project cost (%)', v_ca;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base),2) THEN
        RAISE EXCEPTION 'M6 FAIL: surplus=% (expected baseline)', v_surp;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'M6 FAIL: scrap must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'M6 FAIL: scrap must not touch liability (%)', v_liab;
    END IF;
    RAISE NOTICE 'M6_SCRAP_OK cash=0 costA=8800 loss=400(general) liab=0';
END $$;

-- ===========================================================================
-- M7: Surplus return item3 (qty 3, value 150, from A) — left AVAILABLE
--     Cash 0, Cost A = 8650, Surplus +150, Liability 0
-- ===========================================================================
SELECT public.rpc_return_surplus(
    (SELECT project_a FROM _fix), 'Audit Oak Piece', 'piece', 3, 150.00, 'audit return 3'
) AS return3;

CREATE TEMP TABLE _sur3 AS
SELECT id AS surplus_id FROM public.surplus_bank
WHERE material_name = 'Audit Oak Piece' ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_ca numeric; v_surp numeric;
BEGIN
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;
    IF ROUND(v_ca,2) <> 8650.00 THEN
        RAISE EXCEPTION 'M7 FAIL: cost A=% (expected 8650)', v_ca;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base) + 150.00, 2) THEN
        RAISE EXCEPTION 'M7 FAIL: surplus=% (expected base+150)', v_surp;
    END IF;
    RAISE NOTICE 'M7_RETURN3_OK costA=8650 surplus+150(available)';
END $$;

-- ===========================================================================
-- MN: Surplus negative guards — over-consume / consumed consume / bad scrap
--     Nothing written; all three dimensions unchanged.
-- ===========================================================================
DO $$
DECLARE
    v_tx_before bigint; v_adj_before bigint; v_bank_before bigint;
    v_tx_after bigint; v_adj_after bigint; v_bank_after bigint;
    v_cash numeric; v_ca numeric; v_liab numeric;
BEGIN
    SELECT count(*) INTO v_tx_before FROM public.treasury_transactions;
    SELECT count(*) INTO v_adj_before FROM public.project_cost_adjustments;
    SELECT count(*) INTO v_bank_before FROM public.surplus_bank;

    -- N1: consume from an already-consumed item
    BEGIN
        PERFORM public.rpc_consume_surplus(
            (SELECT surplus_id FROM _sur1), (SELECT project_b FROM _fix), 1, 'over consume');
        RAISE EXCEPTION 'OVERCONSUME_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%OVERCONSUME_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'MN FAIL: consume of consumed item was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%غير متاح للاستهلاك%' THEN
            RAISE EXCEPTION 'MN N1: unexpected error: %', SQLERRM;
        END IF;
    END;

    -- N2: consume MORE than available (item3 has 3)
    BEGIN
        PERFORM public.rpc_consume_surplus(
            (SELECT surplus_id FROM _sur3), (SELECT project_b FROM _fix), 5, 'too much');
        RAISE EXCEPTION 'OVERQTY_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%OVERQTY_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'MN FAIL: over-quantity consume was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%أكبر من الكمية المتاحة%' THEN
            RAISE EXCEPTION 'MN N2: unexpected error: %', SQLERRM;
        END IF;
    END;

    -- N3: scrap a non-available (consumed) item
    BEGIN
        PERFORM public.rpc_scrap_surplus(
            (SELECT surplus_id FROM _sur1), 'bad scrap');
        RAISE EXCEPTION 'BADSCRAP_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%BADSCRAP_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'MN FAIL: scrap of consumed item was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%لا يمكن إتلاف عنصر غير متاح%' THEN
            RAISE EXCEPTION 'MN N3: unexpected error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_tx_after FROM public.treasury_transactions;
    SELECT count(*) INTO v_adj_after FROM public.project_cost_adjustments;
    SELECT count(*) INTO v_bank_after FROM public.surplus_bank;
    IF v_tx_after <> v_tx_before OR v_adj_after <> v_adj_before OR v_bank_after <> v_bank_before THEN
        RAISE EXCEPTION 'MN FAIL: rejected surplus ops wrote rows';
    END IF;

    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2)
       OR ROUND(v_ca,2) <> 8650.00
       OR ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'MN FAIL: dimensions drifted after rejections (cash=%, A=%, liab=%)', v_cash, v_ca, v_liab;
    END IF;
    RAISE NOTICE 'MN_NEGATIVES_OK (over-consume / over-qty / bad scrap rejected, dimensions stable)';
END $$;

-- ===========================================================================
-- L1: Attendance on project A, 1.00 -> 200 (server-computed)
--     Cash 0, Cost A +200 (8850), Worker liability +200
-- ===========================================================================
SELECT public.rpc_record_attendance(
    (SELECT worker_id FROM _fix), (SELECT project_a FROM _fix), CURRENT_DATE, 1.00
) AS attendance_a;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_wliab numeric; v_liab numeric; v_amt numeric;
BEGIN
    SELECT calculated_amount INTO v_amt FROM public.worker_logs
    WHERE worker_id = (SELECT worker_id FROM _fix) ORDER BY created_at DESC LIMIT 1;
    IF ROUND(v_amt,2) IS DISTINCT FROM 200.00 THEN
        RAISE EXCEPTION 'L1 FAIL: server amount=% (expected 200)', v_amt;
    END IF;
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 95000.00, 2) THEN
        RAISE EXCEPTION 'L1 FAIL: attendance must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 8850.00 THEN
        RAISE EXCEPTION 'L1 FAIL: cost A=% (expected 8850)', v_ca;
    END IF;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base) + 200.00, 2) THEN
        RAISE EXCEPTION 'L1 FAIL: worker liability=% (expected base+200)', v_wliab;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base) + 200.00, 2) THEN
        RAISE EXCEPTION 'L1 FAIL: total liability=% (expected base+200)', v_liab;
    END IF;
    RAISE NOTICE 'L1_ATTENDANCE_OK cash=0 costA=8850 workerLiab+200';
END $$;

-- ===========================================================================
-- L2: General attendance (no project), 0.50 -> 100
--     Cash 0, project Cost 0, Worker liability +100 (total +300)
-- ===========================================================================
SELECT public.rpc_record_attendance(
    (SELECT worker_id FROM _fix), NULL, CURRENT_DATE, 0.50
) AS attendance_general;

DO $$
DECLARE
    v_ca numeric; v_cb numeric; v_wliab numeric;
BEGIN
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    IF ROUND(v_ca,2) <> 8850.00 OR ROUND(v_cb,2) <> 800.00 THEN
        RAISE EXCEPTION 'L2 FAIL: general labor must not touch project cost (A=%, B=%)', v_ca, v_cb;
    END IF;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base) + 300.00, 2) THEN
        RAISE EXCEPTION 'L2 FAIL: worker liability=% (expected base+300)', v_wliab;
    END IF;
    RAISE NOTICE 'L2_GENERAL_OK cost=0 workerLiab+300';
END $$;

-- ===========================================================================
-- L3: Advance 250 — Cash -250, Cost 0, net payable drops 300 -> 50
-- ===========================================================================
SELECT public.rpc_record_advance(
    (SELECT worker_id FROM _fix), 250.00, CURRENT_DATE, 'audit advance'
) AS advance_result;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_wliab numeric; v_cat text;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    SELECT category INTO v_cat FROM public.treasury_transactions
    WHERE created_by = (SELECT owner_id FROM _fix) AND amount = 250.00
    ORDER BY created_at DESC LIMIT 1;
    IF v_cat IS DISTINCT FROM 'advance' THEN
        RAISE EXCEPTION 'L3 FAIL: advance treasury category=% (expected advance)', v_cat;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 94750.00, 2) THEN
        RAISE EXCEPTION 'L3 FAIL: cash=% (expected base+94750)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 8850.00 THEN
        RAISE EXCEPTION 'L3 FAIL: advance must not touch project cost (%)', v_ca;
    END IF;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base) + 50.00, 2) THEN
        RAISE EXCEPTION 'L3 FAIL: net payable=% (expected base+50)', v_wliab;
    END IF;
    RAISE NOTICE 'L3_ADVANCE_OK cash-250 cost=0 netPayable=50';
END $$;

-- ===========================================================================
-- L4: Positive settlement (earned 300 - advances 250 = 50 cash OUT)
--     Cash -50, Cost 0, Worker liability back to base
-- ===========================================================================
SELECT public.rpc_settle_worker(
    (SELECT worker_id FROM _fix), 'audit settle'
) AS settlement_cash;

DO $$
DECLARE
    v_cash numeric; v_wliab numeric; v_ca numeric; v_mode text;
    v_logs bigint; v_adv bigint;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT count(*) INTO v_logs FROM public.worker_logs
    WHERE worker_id = (SELECT worker_id FROM _fix) AND is_settled;
    SELECT count(*) INTO v_adv FROM public.worker_advances
    WHERE worker_id = (SELECT worker_id FROM _fix) AND is_settled AND NOT is_carried_forward;
    IF v_logs <> 2 THEN
        RAISE EXCEPTION 'L4 FAIL: settled logs=% (expected 2)', v_logs;
    END IF;
    IF v_adv <> 1 THEN
        RAISE EXCEPTION 'L4 FAIL: settled advances=% (expected 1)', v_adv;
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 94700.00, 2) THEN
        RAISE EXCEPTION 'L4 FAIL: cash=% (expected base+94700)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 8850.00 THEN
        RAISE EXCEPTION 'L4 FAIL: settlement must not touch project cost (%)', v_ca;
    END IF;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base),2) THEN
        RAISE EXCEPTION 'L4 FAIL: worker liability=% (expected baseline)', v_wliab;
    END IF;
    RAISE NOTICE 'L4_SETTLE_OK cash-50 cost=0 workerLiab=base';
END $$;

-- ===========================================================================
-- L5: Credit carry-forward — wage 100, advance 200 -> net -100
--     Cash -200 (advance only), Cost 0, Liability 0, carried 100 forward
-- ===========================================================================
SELECT public.rpc_record_attendance(
    (SELECT worker_id FROM _fix), NULL, CURRENT_DATE, 0.50
) AS attendance_p2;
SELECT public.rpc_record_advance(
    (SELECT worker_id FROM _fix), 200.00, CURRENT_DATE, 'audit advance 2'
) AS advance2;
SELECT public.rpc_settle_worker(
    (SELECT worker_id FROM _fix), 'audit credit carry forward'
) AS settlement_credit;

DO $$
DECLARE
    v_cash numeric; v_wliab numeric; v_ca numeric;
    v_carried numeric; v_open boolean;
BEGIN
    SELECT amount, is_settled INTO v_carried, v_open
    FROM public.worker_advances
    WHERE worker_id = (SELECT worker_id FROM _fix) AND is_carried_forward
    ORDER BY created_at DESC LIMIT 1;
    IF v_carried IS NULL THEN
        RAISE EXCEPTION 'L5 FAIL: no carried-forward advance row found';
    END IF;
    IF ROUND(v_carried,2) <> 100.00 THEN
        RAISE EXCEPTION 'L5 FAIL: carried=% (expected 100)', v_carried;
    END IF;
    IF v_open IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'L5 FAIL: carried-forward must stay open (unsettled)';
    END IF;
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 94500.00, 2) THEN
        RAISE EXCEPTION 'L5 FAIL: cash=% (expected base+94500)', v_cash;
    END IF;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base),2) THEN
        RAISE EXCEPTION 'L5 FAIL: credit settlement must leave net payable at baseline (%)', v_wliab;
    END IF;
    IF ROUND(v_ca,2) <> 8850.00 THEN
        RAISE EXCEPTION 'L5 FAIL: settlement must not touch project cost (%)', v_ca;
    END IF;
    RAISE NOTICE 'L5_CARRY_OK cash-200(advance) cost=0 liab=0 carried=100';
END $$;

-- ===========================================================================
-- LM: Manager controls — dummy ids hit owner guard first (no fixtures needed)
--     + positive control: manager MAY record attendance (staff), then removed
-- ===========================================================================
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT manager_id::text FROM _fix)),
    false
);

DO $$
DECLARE v_dummy uuid := gen_random_uuid();
BEGIN
    BEGIN
        PERFORM public.rpc_record_advance(v_dummy, 60.00, CURRENT_DATE, 'mgr impersonation');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_ADVANCE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_ADVANCE%' THEN
            RAISE EXCEPTION 'LM FAIL: manager advance was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'LM: unexpected advance error: %', SQLERRM;
        END IF;
    END;
    BEGIN
        PERFORM public.rpc_settle_worker(v_dummy, 'mgr impersonation');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_SETTLE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_SETTLE%' THEN
            RAISE EXCEPTION 'LM FAIL: manager settlement was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'LM: unexpected settlement error: %', SQLERRM;
        END IF;
    END;
    RAISE NOTICE 'LM_MGR_MONEY_REJECTED_OK (advance + settlement owner-only)';
END $$;

-- Positive control on an isolated control worker (removed right after)
SELECT public.rpc_record_attendance(
    (SELECT control_worker_id FROM _fix), NULL, CURRENT_DATE, 1.00
) AS mgr_attendance;

DO $$
DECLARE v_wliab numeric;
BEGIN
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base) + 100.00, 2) THEN
        RAISE EXCEPTION 'LM FAIL: manager attendance not recorded (worker liab=%)', v_wliab;
    END IF;
    RAISE NOTICE 'LM_MGR_ATTENDANCE_OK (staff may record attendance)';
END $$;

DELETE FROM public.worker_logs WHERE worker_id = (SELECT control_worker_id FROM _fix);

DO $$
DECLARE v_wliab numeric;
BEGIN
    SELECT total_worker_liabilities INTO v_wliab FROM public.v_pending_liabilities;
    IF ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base),2) THEN
        RAISE EXCEPTION 'LM FAIL: control log removal did not restore liability (%)', v_wliab;
    END IF;
    RAISE NOTICE 'LM_CONTROL_CLEANED_OK';
END $$;

-- Back to the owner for the subcontract narrative
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT owner_id::text FROM _fix)),
    false
);

-- ===========================================================================
-- S0: Manager rejection for ALL subcontract RPCs (dummy ids, owner guard first)
-- ===========================================================================
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT manager_id::text FROM _fix)),
    false
);

DO $$
DECLARE v_dummy uuid := gen_random_uuid(); v_before bigint; v_after bigint;
BEGIN
    SELECT count(*) INTO v_before FROM public.subcontract_orders;
    BEGIN
        PERFORM public.rpc_create_subcontract_order(
            (SELECT project_a FROM _fix), 'Audit Contractor 1', 'mgr', 15000.00);
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_CREATE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_CREATE%' THEN
            RAISE EXCEPTION 'S0 FAIL: manager create was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'S0: unexpected create error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_after FROM public.subcontract_orders;
    IF v_after <> v_before THEN
        RAISE EXCEPTION 'S0 FAIL: rejected create wrote an order';
    END IF;

    BEGIN
        PERFORM public.rpc_pay_subcontract(v_dummy, 1.00, CURRENT_DATE, 'mgr');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_PAY';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_PAY%' THEN
            RAISE EXCEPTION 'S0 FAIL: manager pay was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'S0: unexpected pay error: %', SQLERRM;
        END IF;
    END;
    BEGIN
        PERFORM public.rpc_void_subcontract_payment(v_dummy, 'mgr');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_VOID';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_VOID%' THEN
            RAISE EXCEPTION 'S0 FAIL: manager void was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'S0: unexpected void error: %', SQLERRM;
        END IF;
    END;
    BEGIN
        PERFORM public.rpc_close_subcontract_order(v_dummy, 'completed', 'سبب تجريبي للفحص');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_CLOSE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_CLOSE%' THEN
            RAISE EXCEPTION 'S0 FAIL: manager close was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'S0: unexpected close error: %', SQLERRM;
        END IF;
    END;
    RAISE NOTICE 'S0_MGR_ALL_REJECTED_OK (create/pay/void/close owner-only)';
END $$;

SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT owner_id::text FROM _fix)),
    false
);

-- ===========================================================================
-- S1: Agreement order1 (A, 15000) — Cost A +15000 (23850), Liab +15000, Cash 0
-- ===========================================================================
SELECT public.rpc_create_subcontract_order(
    (SELECT project_a FROM _fix), 'Audit Contractor 1', 'audit woodwork', 15000.00
) AS order1;

CREATE TEMP TABLE _ord1 AS
SELECT id AS order_id FROM public.subcontract_orders
WHERE contractor_name = 'Audit Contractor 1';

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_sliab numeric; v_liab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 94500.00, 2) THEN
        RAISE EXCEPTION 'S1 FAIL: agreement must not touch cash (%)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 23850.00 THEN
        RAISE EXCEPTION 'S1 FAIL: cost A=% (expected 23850)', v_ca;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base) + 15000.00, 2) THEN
        RAISE EXCEPTION 'S1 FAIL: subcontract liability=% (expected base+15000)', v_sliab;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base) + 15000.00, 2) THEN
        RAISE EXCEPTION 'S1 FAIL: total liability=% (expected base+15000)', v_liab;
    END IF;
    RAISE NOTICE 'S1_AGREE_OK cash=0 costA=23850 subconLiab+15000';
END $$;

-- ===========================================================================
-- S2: Partial payment 6000 — Cash -6000, Cost 0, Liability -6000
-- ===========================================================================
SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _ord1), 6000.00, CURRENT_DATE, 'audit partial 6000'
) AS pay_partial;

CREATE TEMP TABLE _pay1 AS
SELECT id AS payment_id FROM public.subcontract_payments
WHERE subcontract_order_id = (SELECT order_id FROM _ord1) AND notes = 'audit partial 6000'
ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_sliab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 88500.00, 2) THEN
        RAISE EXCEPTION 'S2 FAIL: cash=% (expected base+88500)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 23850.00 THEN
        RAISE EXCEPTION 'S2 FAIL: payment must not touch cost (%)', v_ca;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base) + 9000.00, 2) THEN
        RAISE EXCEPTION 'S2 FAIL: remaining liability=% (expected base+9000)', v_sliab;
    END IF;
    RAISE NOTICE 'S2_PARTIAL_OK cash-6000 cost=0 remaining=9000';
END $$;

-- ===========================================================================
-- S3: REVERSAL — void the 6000 payment — Cash +6000, Liability +6000, Cost 0
-- ===========================================================================
SELECT public.rpc_void_subcontract_payment(
    (SELECT payment_id FROM _pay1), 'audit reversal'
) AS void_result;

DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_sliab numeric; v_voided boolean;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    SELECT is_voided INTO v_voided FROM public.subcontract_payments WHERE id = (SELECT payment_id FROM _pay1);
    IF v_voided IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'S3 FAIL: payment void flag not set (found %)', v_voided;
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.treasury_transactions tt
        JOIN public.subcontract_payments sp ON tt.id = sp.treasury_transaction_id
        WHERE sp.id = (SELECT payment_id FROM _pay1) AND NOT tt.is_voided
    ) THEN
        RAISE EXCEPTION 'S3 FAIL: linked treasury tx not voided';
    END IF;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 94500.00, 2) THEN
        RAISE EXCEPTION 'S3 FAIL: cash=% (expected base+94500 restored)', v_cash;
    END IF;
    IF ROUND(v_ca,2) <> 23850.00 THEN
        RAISE EXCEPTION 'S3 FAIL: reversal must not touch cost (%)', v_ca;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base) + 15000.00, 2) THEN
        RAISE EXCEPTION 'S3 FAIL: liability=% (expected base+15000 restored)', v_sliab;
    END IF;
    RAISE NOTICE 'S3_REVERSAL_OK cash restored liab restored cost=0 (audit trail kept)';
END $$;

-- ===========================================================================
-- S4: Full payment 15000 — Cash -15000, Cost 0, Liability back to base
-- ===========================================================================
SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _ord1), 15000.00, CURRENT_DATE, 'audit full 15000'
) AS pay_full;

DO $$
DECLARE
    v_cash numeric; v_sliab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 79500.00, 2) THEN
        RAISE EXCEPTION 'S4 FAIL: cash=% (expected base+79500)', v_cash;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base),2) THEN
        RAISE EXCEPTION 'S4 FAIL: subcontract liability=% (expected baseline)', v_sliab;
    END IF;
    RAISE NOTICE 'S4_FULL_OK cash-15000 order1 liability=0';
END $$;

-- ===========================================================================
-- S5: Overpayment rejection (1.00 on fully-paid order1) — nothing written
-- ===========================================================================
DO $$
DECLARE
    v_pay_before bigint; v_tx_before bigint; v_pay_after bigint; v_tx_after bigint;
    v_cash numeric; v_sliab numeric; v_ca numeric;
BEGIN
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;
    SELECT count(*) INTO v_tx_before FROM public.treasury_transactions;
    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _ord1), 1.00, CURRENT_DATE, 'overpay attempt');
        RAISE EXCEPTION 'OVERPAY_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%OVERPAY_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'S5 FAIL: overpayment was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%يتجاوز المبلغ المتفق عليه%' THEN
            RAISE EXCEPTION 'S5: unexpected error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    SELECT count(*) INTO v_tx_after FROM public.treasury_transactions;
    IF v_pay_after <> v_pay_before OR v_tx_after <> v_tx_before THEN
        RAISE EXCEPTION 'S5 FAIL: rejected overpayment wrote rows (pay %->%, tx %->%)',
            v_pay_before, v_pay_after, v_tx_before, v_tx_after;
    END IF;
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 79500.00, 2)
       OR ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base),2)
       OR ROUND(v_ca,2) <> 23850.00 THEN
        RAISE EXCEPTION 'S5 FAIL: dimensions drifted after rejection (cash=%, liab=%, A=%)', v_cash, v_sliab, v_ca;
    END IF;
    RAISE NOTICE 'S5_OVERPAY_REJECTED_OK (no rows, dimensions stable)';
END $$;

-- ===========================================================================
-- S6: Close order1 as completed — payment on closed order rejected
-- ===========================================================================
SELECT public.rpc_close_subcontract_order(
    (SELECT order_id FROM _ord1), 'completed', 'اكتمل العمل واستلم كاملاً'
) AS close1;

DO $$
DECLARE
    v_status text; v_pay_before bigint; v_pay_after bigint;
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders WHERE id = (SELECT order_id FROM _ord1);
    IF v_status IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'S6 FAIL: status=% (expected completed)', v_status;
    END IF;
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;
    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _ord1), 1.00, CURRENT_DATE, 'pay on closed');
        RAISE EXCEPTION 'CLOSED_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%CLOSED_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'S6 FAIL: payment on closed order was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مغلقة%' THEN
            RAISE EXCEPTION 'S6: unexpected closed error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    IF v_pay_after <> v_pay_before THEN
        RAISE EXCEPTION 'S6 FAIL: payment on closed order wrote a row';
    END IF;
    RAISE NOTICE 'S6_CLOSED_OK (completed; further payment rejected)';
END $$;

-- ===========================================================================
-- S6b: Closing a partially-paid order as completed is rejected (no state change)
-- ===========================================================================
SELECT public.rpc_create_subcontract_order(
    (SELECT project_b FROM _fix), 'Audit Contractor Partial', 'audit close guard', 5000.00
) AS order_partial;

CREATE TEMP TABLE _ordp AS
SELECT id AS order_id FROM public.subcontract_orders
WHERE contractor_name = 'Audit Contractor Partial';

SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _ordp), 2000.00, CURRENT_DATE, 'audit partial 2000'
) AS pay_partial2;

DO $$
DECLARE v_pay_before bigint; v_pay_after bigint;
BEGIN
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;
    BEGIN
        PERFORM public.rpc_close_subcontract_order(
            (SELECT order_id FROM _ordp), 'completed', 'سبب تجريبي للفحص');
        RAISE EXCEPTION 'PARTIAL_CLOSE_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%PARTIAL_CLOSE_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'S6b FAIL: partially-paid order closed as completed';
        END IF;
        IF SQLERRM NOT LIKE '%رصيد غير مدفوع%' THEN
            RAISE EXCEPTION 'S6b: unexpected error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    IF v_pay_after <> v_pay_before THEN
        RAISE EXCEPTION 'S6b FAIL: rejected close wrote rows';
    END IF;
    RAISE NOTICE 'S6b_CLOSE_PARTIAL_REJECTED_OK (completed requires full payment)';
END $$;

-- Cancel it so the narrative ends with a clean, explained state
SELECT public.rpc_close_subcontract_order(
    (SELECT order_id FROM _ordp), 'cancelled', 'إلغاء تجريبي للفحص'
) AS cancel_partial;

DO $$
DECLARE v_status text;
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders WHERE id = (SELECT order_id FROM _ordp);
    IF v_status IS DISTINCT FROM 'cancelled' THEN
        RAISE EXCEPTION 'S6b FAIL: cancel status=% (expected cancelled)', v_status;
    END IF;
    RAISE NOTICE 'S6b_CANCELLED_OK (unpaid obligation explained by cancellation)';
END $$;

-- ===========================================================================
-- S7: Agreement order2 (B, 30000) — Cost B +30000 (30800), Liab +30000, Cash 0
-- ===========================================================================
SELECT public.rpc_create_subcontract_order(
    (SELECT project_b FROM _fix), 'Audit Contractor 2', 'audit big job', 30000.00
) AS order2;

CREATE TEMP TABLE _ord2 AS
SELECT id AS order_id FROM public.subcontract_orders
WHERE contractor_name = 'Audit Contractor 2';

DO $$
DECLARE
    v_cash numeric; v_cb numeric; v_sliab numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 77500.00, 2) THEN
        RAISE EXCEPTION 'S7 FAIL: partial-close order2 cash drift (cash=%)', v_cash;
    END IF;
    IF ROUND(v_cb,2) <> 32800.00 THEN
        RAISE EXCEPTION 'S7 FAIL: cost B=% (expected 32800: 800 surplus + 2000 cancelled-paid + 30000 order2)', v_cb;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base) + 30000.00, 2) THEN
        RAISE EXCEPTION 'S7 FAIL: subcontract liability=% (expected base+30000)', v_sliab;
    END IF;
    RAISE NOTICE 'S7_AGREE2_OK cash=77500-delta costB=32800 subconLiab+30000';
END $$;

-- ===========================================================================
-- S8: SEQUENTIAL concurrency proof — pay 16000 OK, second 16000 REJECTED
--     (sum guard), then pay remaining 14000 and close completed.
--     Cash -30000 total, Cost 0, Liability back to base.
-- ===========================================================================
SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _ord2), 16000.00, CURRENT_DATE, 'audit seq 16000'
) AS pay_seq1;

DO $$
DECLARE
    v_pay_before bigint; v_pay_after bigint;
    v_cash numeric; v_sliab numeric;
BEGIN
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;
    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _ord2), 16000.00, CURRENT_DATE, 'audit seq over');
        RAISE EXCEPTION 'SEQ_OVER_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%SEQ_OVER_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'S8 FAIL: 16000+16000 over agreed 30000 was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%يتجاوز المبلغ المتفق عليه%' THEN
            RAISE EXCEPTION 'S8: unexpected error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    IF v_pay_after <> v_pay_before THEN
        RAISE EXCEPTION 'S8 FAIL: rejected second payment wrote a row';
    END IF;
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 61500.00, 2) THEN
        RAISE EXCEPTION 'S8 FAIL: cash=% (expected base+61500)', v_cash;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base) + 14000.00, 2) THEN
        RAISE EXCEPTION 'S8 FAIL: remaining=% (expected base+14000)', v_sliab;
    END IF;
    RAISE NOTICE 'S8_SEQ_GUARD_OK (exactly-one-win sequential; remaining 14000)';
END $$;

SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _ord2), 14000.00, CURRENT_DATE, 'audit remaining 14000'
) AS pay_remaining;

SELECT public.rpc_close_subcontract_order(
    (SELECT order_id FROM _ord2), 'completed', 'اكتمل العمل واستلم كاملاً'
) AS close2;

DO $$
DECLARE
    v_cash numeric; v_sliab numeric; v_liab numeric; v_cb numeric; v_status text;
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders WHERE id = (SELECT order_id FROM _ord2);
    IF v_status IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'S8 FAIL: order2 status=% (expected completed)', v_status;
    END IF;
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT total_subcontract_liabilities INTO v_sliab FROM public.v_pending_liabilities;
    SELECT total_pending_liabilities INTO v_liab FROM public.v_pending_liabilities;
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 47500.00, 2) THEN
        RAISE EXCEPTION 'S8 FAIL: cash=% (expected base+47500)', v_cash;
    END IF;
    IF ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base),2) THEN
        RAISE EXCEPTION 'S8 FAIL: subcontract liability=% (expected baseline)', v_sliab;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2) THEN
        RAISE EXCEPTION 'S8 FAIL: total liability=% (expected baseline)', v_liab;
    END IF;
    IF ROUND(v_cb,2) <> 32800.00 THEN
        RAISE EXCEPTION 'S8 FAIL: payments must not change cost B (%)', v_cb;
    END IF;
    RAISE NOTICE 'S8_COMPLETE_OK cash=base+47500 liab=base costB=32800';
END $$;

-- ===========================================================================
-- FINAL NARRATIVE STATE — exact expected totals after the whole story
--   Cash delta +47500 | Cost A 23850 | Cost B 32800 | Liab base | Surplus +150
-- ===========================================================================
DO $$
DECLARE
    v_cash numeric; v_ca numeric; v_cb numeric;
    v_liab numeric; v_wliab numeric; v_sliab numeric; v_surp numeric;
BEGIN
    SELECT current_balance INTO v_cash FROM public.v_treasury_balance;
    SELECT direct_project_cost INTO v_ca FROM public.v_project_direct_costs WHERE project_id = (SELECT project_a FROM _fix);
    SELECT direct_project_cost INTO v_cb FROM public.v_project_direct_costs WHERE project_id = (SELECT project_b FROM _fix);
    SELECT total_pending_liabilities, total_worker_liabilities, total_subcontract_liabilities
    INTO v_liab, v_wliab, v_sliab FROM public.v_pending_liabilities;
    SELECT total_surplus_value INTO v_surp FROM public.v_surplus_available;

    IF ROUND(v_cash,2) <> ROUND((SELECT treasury FROM _base) + 47500.00, 2) THEN
        RAISE EXCEPTION 'FINAL FAIL: cash delta=% (expected +47500)', v_cash - (SELECT treasury FROM _base);
    END IF;
    IF ROUND(v_ca,2) <> 23850.00 THEN
        RAISE EXCEPTION 'FINAL FAIL: cost A=% (expected 23850)', v_ca;
    END IF;
    IF ROUND(v_cb,2) <> 32800.00 THEN
        RAISE EXCEPTION 'FINAL FAIL: cost B=% (expected 32800)', v_cb;
    END IF;
    IF ROUND(v_liab,2) <> ROUND((SELECT liability FROM _base),2)
       OR ROUND(v_wliab,2) <> ROUND((SELECT worker_liab FROM _base),2)
       OR ROUND(v_sliab,2) <> ROUND((SELECT subcon_liab FROM _base),2) THEN
        RAISE EXCEPTION 'FINAL FAIL: liability drift (total=%, worker=%, subcon=%)', v_liab, v_wliab, v_sliab;
    END IF;
    IF ROUND(v_surp,2) <> ROUND((SELECT surplus FROM _base) + 150.00, 2) THEN
        RAISE EXCEPTION 'FINAL FAIL: surplus delta=% (expected +150)', v_surp - (SELECT surplus FROM _base);
    END IF;
    RAISE NOTICE 'FINAL_STATE_OK cash+47500 costA=23850 costB=32800 liab=base surplus+150';
END $$;

-- ===========================================================================
-- RECONCILIATION — manual recompute from RAW tables vs authoritative views.
-- Any drift => RAISE EXCEPTION. State-agnostic (works with pre-existing data).
-- ===========================================================================

-- R1: Cash — view vs raw treasury rows (not voided, not direct owner payment)
DO $$
DECLARE v_view numeric; v_manual numeric;
BEGIN
    SELECT current_balance INTO v_view FROM public.v_treasury_balance;
    SELECT COALESCE(SUM(CASE WHEN transaction_type = 'in' THEN amount ELSE -amount END), 0)
    INTO v_manual FROM public.treasury_transactions
    WHERE NOT is_voided AND NOT is_direct_owner_payment;
    IF v_view IS DISTINCT FROM v_manual THEN
        RAISE EXCEPTION 'RECON CASH DRIFT: view=% manual=%', v_view, v_manual;
    END IF;
    RAISE NOTICE 'RECON_CASH_OK view==manual=%', v_view;
END $$;

-- R2: Cost — view vs raw recompute for BOTH audit projects
DO $$
DECLARE
    v_pid uuid; v_view numeric; v_manual numeric;
BEGIN
    FOR v_pid IN SELECT project_a FROM _fix UNION ALL SELECT project_b FROM _fix LOOP
        SELECT direct_project_cost INTO v_view
        FROM public.v_project_direct_costs WHERE project_id = v_pid;
        SELECT (
            COALESCE((SELECT SUM(amount) FROM public.treasury_transactions
                      WHERE project_id = v_pid AND category = 'material' AND NOT is_voided), 0)
          + COALESCE((SELECT SUM(amount) FROM public.treasury_transactions
                      WHERE project_id = v_pid AND category = 'freight' AND NOT is_voided), 0)
          + COALESCE((SELECT SUM(calculated_amount) FROM public.worker_logs
                      WHERE project_id = v_pid), 0)
          + COALESCE((SELECT SUM(total_agreed_amount) FROM public.subcontract_orders
                      WHERE project_id = v_pid AND status IN ('active','completed')), 0)
          + COALESCE((SELECT SUM(sp.amount) FROM public.subcontract_orders so
                      JOIN public.subcontract_payments sp ON sp.subcontract_order_id = so.id
                      WHERE so.project_id = v_pid AND so.status = 'cancelled' AND NOT sp.is_voided), 0)
          - COALESCE((SELECT SUM(amount) FROM public.project_cost_adjustments
                      WHERE project_id = v_pid AND adjustment_type = 'surplus_return'), 0)
          + COALESCE((SELECT SUM(amount) FROM public.project_cost_adjustments
                      WHERE project_id = v_pid AND adjustment_type = 'surplus_consumption'), 0)
        ) INTO v_manual;
        IF ROUND(v_view,2) IS DISTINCT FROM ROUND(v_manual,2) THEN
            RAISE EXCEPTION 'RECON COST DRIFT for %: view=% manual=%', v_pid, v_view, v_manual;
        END IF;
    END LOOP;
    RAISE NOTICE 'RECON_COST_OK both projects view==manual';
END $$;

-- R3: Liability — view vs raw recompute (worker net per-worker + active subcon)
DO $$
DECLARE
    v_view numeric; v_manual numeric;
    v_wages numeric; v_adv numeric;
BEGIN
    SELECT total_pending_liabilities INTO v_view FROM public.v_pending_liabilities;
    SELECT COALESCE(SUM(GREATEST(0,
        COALESCE((SELECT SUM(calculated_amount) FROM public.worker_logs l
                  WHERE l.worker_id = w.id AND NOT l.is_settled), 0)
      - COALESCE((SELECT SUM(amount) FROM public.worker_advances a
                  WHERE a.worker_id = w.id AND NOT a.is_settled), 0)
    )), 0) INTO v_wages FROM public.workers w;
    SELECT COALESCE(SUM(so.total_agreed_amount - COALESCE((
        SELECT SUM(sp.amount) FROM public.subcontract_payments sp
        WHERE sp.subcontract_order_id = so.id AND NOT sp.is_voided), 0)), 0)
    INTO v_adv FROM public.subcontract_orders so WHERE so.status = 'active';
    v_manual := v_wages + v_adv;
    IF ROUND(v_view,2) IS DISTINCT FROM ROUND(v_manual,2) THEN
        RAISE EXCEPTION 'RECON LIAB DRIFT: view=% manual=% (worker=% subcon=%)', v_view, v_manual, v_wages, v_adv;
    END IF;
    RAISE NOTICE 'RECON_LIAB_OK view==manual=% (worker=% subcon=%)', v_view, v_wages, v_adv;
END $$;

-- R4: Surplus — view vs raw available rows
DO $$
DECLARE v_view numeric; v_manual numeric; v_qty numeric; v_items int;
BEGIN
    SELECT total_surplus_value INTO v_view FROM public.v_surplus_available;
    SELECT COALESCE(SUM(estimated_value), 0), COALESCE(SUM(quantity), 0), COUNT(*)
    INTO v_manual, v_qty, v_items FROM public.surplus_bank WHERE status = 'available';
    IF v_view IS DISTINCT FROM v_manual THEN
        RAISE EXCEPTION 'RECON SURPLUS DRIFT: view=% manual=%', v_view, v_manual;
    END IF;
    RAISE NOTICE 'RECON_SURPLUS_OK value=% qty=% items=%', v_view, v_qty, v_items;
END $$;

-- R5: Views are security_invoker (RLS applies through views)
DO $$
DECLARE bad int;
BEGIN
    SELECT count(*) INTO bad FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'v'
      AND c.relname IN ('v_treasury_balance','v_project_direct_costs','v_pending_liabilities','v_surplus_available')
      AND COALESCE(array_to_string(c.reloptions, ','), '') NOT LIKE '%security_invoker%';
    IF bad > 0 THEN
        RAISE EXCEPTION 'RECON: % financial view(s) are not security_invoker', bad;
    END IF;
    RAISE NOTICE 'RECON_VIEWS_OK security_invoker on all 4 views';
END $$;

-- ===========================================================================
-- IDEMPOTENCY — double-submit of the same key writes nothing extra (PK guard)
-- ===========================================================================
DO $$
DECLARE v_before bigint; v_after bigint;
BEGIN
    SELECT count(*) INTO v_before FROM public.idempotency_keys WHERE key LIKE 'aaaaaaaa-aaaa-4aaa-8aaa-%';
    -- Key format is UUID-only since P2-02 (idempotency_key_uuid_format):
    -- use a stable fixture UUID so pre-cleanup on re-runs keeps working.
    INSERT INTO public.idempotency_keys (key, user_id, action, status)
    SELECT 'aaaaaaaa-aaaa-4aaa-8aaa-ccccccccccc1', owner_id, 'audit_probe', 'pending' FROM _fix;
    BEGIN
        INSERT INTO public.idempotency_keys (key, user_id, action, status)
        SELECT 'aaaaaaaa-aaaa-4aaa-8aaa-ccccccccccc1', owner_id, 'audit_probe', 'pending' FROM _fix;
        RAISE EXCEPTION 'DUPKEY_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%DUPKEY_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'IDEMPOTENCY FAIL: duplicate key was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%duplicate key%' AND SQLERRM NOT LIKE '%already exists%' THEN
            RAISE EXCEPTION 'IDEMPOTENCY: unexpected error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_after FROM public.idempotency_keys WHERE key LIKE 'aaaaaaaa-aaaa-4aaa-8aaa-%';
    IF v_after <> v_before + 1 THEN
        RAISE EXCEPTION 'IDEMPOTENCY FAIL: key rows %->% (expected exactly +1)', v_before, v_after;
    END IF;
    RAISE NOTICE 'IDEMPOTENCY_OK duplicate key rejected, no double financial row possible';
END $$;

-- ===========================================================================
-- RLS NEGATIVES as authenticated manager — void + owner_funding denied (42501)
-- Then restore owner claims.
-- ===========================================================================
-- Pass ids via session GUCs: the authenticated role cannot read temp tables.
SELECT set_config('audit.mgr', (SELECT manager_id::text FROM _fix), false);
SELECT set_config('audit.fund', (SELECT tx_id::text FROM _t1), false);

SET ROLE authenticated;
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', current_setting('audit.mgr')),
    false
);

DO $$
DECLARE
    v_tx_before bigint; v_tx_after bigint;
    v_mgr uuid := current_setting('audit.mgr')::uuid;
    v_fund uuid := current_setting('audit.fund')::uuid;
    v_still_voided boolean;
BEGIN
    SELECT count(*) INTO v_tx_before FROM public.treasury_transactions;
    -- RLS UPDATE denial is silent (UPDATE 0): the proof is that a NON-voided
    -- row (the funding tx) remains untouched by the manager attempt.
    UPDATE public.treasury_transactions
    SET is_voided = true, void_reason = 'mgr attempt'
    WHERE id = v_fund;
    SELECT is_voided INTO v_still_voided FROM public.treasury_transactions WHERE id = v_fund;
    IF v_still_voided IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'RLS FAIL: manager treasury void modified the row';
    END IF;
    BEGIN
        INSERT INTO public.treasury_transactions (
            transaction_type, category, amount, description, created_by
        ) VALUES (
            'in', 'owner_funding', 1.00, 'mgr funding', v_mgr);
        RAISE EXCEPTION 'MGR_FUNDING_SHOULD_BE_DENIED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MGR_FUNDING_SHOULD_BE_DENIED%' THEN
            RAISE EXCEPTION 'RLS FAIL: manager owner_funding was NOT denied';
        END IF;
        IF SQLERRM NOT LIKE '%row-level security%' AND SQLERRM NOT LIKE '%policy%' THEN
            RAISE EXCEPTION 'RLS: unexpected funding error: %', SQLERRM;
        END IF;
    END;
    SELECT count(*) INTO v_tx_after FROM public.treasury_transactions;
    IF v_tx_after <> v_tx_before THEN
        RAISE EXCEPTION 'RLS FAIL: denied manager ops changed treasury rows';
    END IF;
    RAISE NOTICE 'RLS_MGR_DENIED_OK (void + owner_funding blocked, rows unchanged)';
END $$;

RESET ROLE;
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT owner_id::text FROM _fix)),
    false
);

-- ===========================================================================
-- Explicit cleanup (this test seeded its own rows only)
-- Skipped when run with -v CLEANUP=false (fixtures left for inspection).
-- ===========================================================================
\if :CLEANUP
DO $$
DECLARE v_oid uuid := (SELECT owner_id FROM _fix);
        v_mid uuid := (SELECT manager_id FROM _fix);
        v_pa  uuid := (SELECT project_a FROM _fix);
        v_pb  uuid := (SELECT project_b FROM _fix);
        v_wid uuid := (SELECT worker_id FROM _fix);
        v_cid uuid := (SELECT control_worker_id FROM _fix);
BEGIN
    DELETE FROM public.project_cost_adjustments WHERE project_id IN (v_pa, v_pb)
        OR surplus_id IN (SELECT id FROM public.surplus_bank WHERE source_project_id IN (v_pa, v_pb));
    -- Children before parents: parent_surplus_id is ON DELETE RESTRICT.
    DELETE FROM public.surplus_bank
    WHERE source_project_id IN (v_pa, v_pb) AND parent_surplus_id IS NOT NULL;
    DELETE FROM public.surplus_bank WHERE source_project_id IN (v_pa, v_pb);
    DELETE FROM public.subcontract_payments WHERE subcontract_order_id IN (
        SELECT id FROM public.subcontract_orders WHERE project_id IN (v_pa, v_pb));
    DELETE FROM public.subcontract_orders WHERE project_id IN (v_pa, v_pb);
    DELETE FROM public.worker_advances WHERE worker_id IN (v_wid, v_cid);
    DELETE FROM public.worker_logs    WHERE worker_id IN (v_wid, v_cid);
    DELETE FROM public.treasury_transactions WHERE created_by IN (v_oid, v_mid);
    DELETE FROM public.idempotency_keys WHERE key LIKE 'aaaaaaaa-aaaa-4aaa-8aaa-%';
    DELETE FROM public.workers  WHERE id IN (v_wid, v_cid);
    -- Sweep any audit-named workers left behind by an aborted earlier run
    -- (the pre-clean above also reclaims them, but belt-and-braces).
    DELETE FROM public.worker_advances WHERE worker_id IN (
        SELECT id FROM public.workers
        WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker');
    DELETE FROM public.worker_logs WHERE worker_id IN (
        SELECT id FROM public.workers
        WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker');
    DELETE FROM public.workers
    WHERE name LIKE 'Audit Worker%' OR name = 'Audit Control Worker';
    DELETE FROM public.projects WHERE id IN (v_pa, v_pb);
    -- Fixture identities may be referenced by the immutable audit trail
    -- (migration 29): remove them only when nothing references them.
    DELETE FROM public.profiles WHERE id IN (v_oid, v_mid)
      AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id IN (v_oid, v_mid));
    DELETE FROM auth.users      WHERE id IN (v_oid, v_mid)
      AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id IN (v_oid, v_mid));
    RAISE NOTICE 'AUDIT_CLEANUP_OK';
END $$;
\endif

\echo FINANCIAL_AUDIT_DONE
