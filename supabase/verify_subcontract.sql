-- ============================================================================
-- verify_subcontract.sql — Phase 5 subcontract RPC regression
--
-- WARNING: operates against the live database. It creates and deletes its own
-- fixture rows ONLY (test owner, manager, project, order, payments). It must
-- run against an empty or test database — never against production data.
--
-- Asserts, purely from database truth (deltas vs baseline — never absolute):
--   create order          : project cost += total, liability += total, treasury unchanged
--   partial payment       : treasury -= amount, liability -= amount, cost unchanged
--   full payment          : remaining liability = 0
--   overpayment rejection : nothing written (treasury & payments unchanged)
--   voided payment        : treasury restored, liability back up (reversal)
--   closed order          : payment rejected; completed requires fully paid
--   manager rejection     : create/pay/void/close are owner-only, rejected from the start
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

CREATE TEMP TABLE _fix AS
SELECT
    gen_random_uuid() AS owner_id,
    gen_random_uuid() AS manager_id,
    gen_random_uuid() AS project_id;

-- Pre-clean any test fixtures orphaned by an aborted prior run
DELETE FROM public.subcontract_payments WHERE subcontract_order_id IN (
    SELECT id FROM public.subcontract_orders WHERE contractor_name = 'Subcontract Test Contractor');
DELETE FROM public.treasury_transactions WHERE created_by IN (
    SELECT id FROM auth.users WHERE email LIKE 'subcontract-test-%@example.test');
DELETE FROM public.subcontract_orders WHERE contractor_name = 'Subcontract Test Contractor';
DELETE FROM public.projects WHERE name = 'Subcontract Test Project';
DELETE FROM public.profiles WHERE id IN (
    SELECT id FROM auth.users WHERE email LIKE 'subcontract-test-%@example.test');
DELETE FROM auth.users WHERE email LIKE 'subcontract-test-%@example.test';

-- ---------------------------------------------------------------------------
-- Seed owner + manager (manager seeded FIRST so handle_new_user makes it the
-- second user — but we force roles explicitly anyway)
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
SELECT
    owner_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'subcontract-test-owner-' || owner_id::text || '@example.test',
    'x', '{}', '{}', NOW(), NOW()
FROM _fix;

INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
SELECT
    manager_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'subcontract-test-manager-' || manager_id::text || '@example.test',
    'x', '{}', '{}', NOW(), NOW()
FROM _fix;

UPDATE public.profiles SET role = 'owner'   WHERE id = (SELECT owner_id FROM _fix);
UPDATE public.profiles SET role = 'manager' WHERE id = (SELECT manager_id FROM _fix);

INSERT INTO public.projects (id, name, status)
SELECT project_id, 'Subcontract Test Project', 'active' FROM _fix;

-- Baseline deltas (robust against unrelated pre-existing rows)
CREATE TEMP TABLE _base AS
SELECT
    (SELECT current_balance FROM public.v_treasury_balance)            AS treasury,
    COALESCE((SELECT (COALESCE(t.subcontract_cost,0) + COALESCE(t.material_cost,0) + COALESCE(t.labor_cost,0) + COALESCE(t.freight_cost,0) + COALESCE(t.surplus_consumptions,0) - COALESCE(t.surplus_returns,0))::numeric
              FROM public.v_project_direct_costs t WHERE t.project_id = (SELECT project_id FROM _fix)), 0) AS project_cost,
    (SELECT total_subcontract_liabilities FROM public.v_pending_liabilities) AS liability;

-- ===========================================================================
-- SCENARIO 0: Manager rejection from the start (owner-only operations)
-- ===========================================================================
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT manager_id::text FROM _fix)),
    false
);

DO $$
DECLARE
    v_orders_before bigint;
    v_orders_after  bigint;
BEGIN
    SELECT count(*) INTO v_orders_before FROM public.subcontract_orders;

    BEGIN
        PERFORM public.rpc_create_subcontract_order(
            (SELECT project_id FROM _fix), 'Subcontract Test Contractor',
            'manager impersonation', 10000.00);
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_CREATE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_CREATE%' THEN
            RAISE EXCEPTION 'SCENARIO0 FAIL: manager create order was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO0: unexpected create error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_orders_after FROM public.subcontract_orders;
    IF v_orders_after <> v_orders_before THEN
        RAISE EXCEPTION 'SCENARIO0 FAIL: rejected create still wrote an order';
    END IF;
    RAISE NOTICE 'SCENARIO0_CREATE_REJECTED_OK (manager cannot create subcontract agreements)';
END $$;

-- Manager must also be rejected for the other owner-only subcontract RPCs
-- (pay / void / close). These hit the auth guard before any business logic,
-- so we can fire them with dummy ids and still expect the SAME owner-only error.
DO $$
DECLARE v_dummy uuid := gen_random_uuid();
BEGIN
    BEGIN
        PERFORM public.rpc_pay_subcontract(v_dummy, 1.00, CURRENT_DATE, 'mgr pay');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_PAY';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_PAY%' THEN
            RAISE EXCEPTION 'SCENARIO0 FAIL: manager pay was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO0: unexpected pay error: %', SQLERRM;
        END IF;
    END;

    BEGIN
        PERFORM public.rpc_void_subcontract_payment(v_dummy, 'mgr void');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_VOID';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_VOID%' THEN
            RAISE EXCEPTION 'SCENARIO0 FAIL: manager void was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO0: unexpected void error: %', SQLERRM;
        END IF;
    END;

    BEGIN
        PERFORM public.rpc_close_subcontract_order(v_dummy, 'completed');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_CLOSE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_CLOSE%' THEN
            RAISE EXCEPTION 'SCENARIO0 FAIL: manager close was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO0: unexpected close error: %', SQLERRM;
        END IF;
    END;
    RAISE NOTICE 'SCENARIO0_PAY_VOID_CLOSE_REJECTED_OK (manager)';
END $$;

-- Switch back to the owner for the main flow
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT owner_id::text FROM _fix)),
    false
);

-- ===========================================================================
-- SCENARIO 1: New order — cost += 10000, liability += 10000, treasury unchanged
-- ===========================================================================
SELECT public.rpc_create_subcontract_order(
    (SELECT project_id FROM _fix), 'Subcontract Test Contractor',
    'تشطيب خشبي بالكامل', 10000.00) AS order_result;

DO $$
DECLARE
    v_cost_after  numeric;
    v_liab_after  numeric;
    v_treas_after numeric;
BEGIN
    SELECT (COALESCE(t.subcontract_cost,0) + COALESCE(t.material_cost,0) + COALESCE(t.labor_cost,0) + COALESCE(t.freight_cost,0) + COALESCE(t.surplus_consumptions,0) - COALESCE(t.surplus_returns,0))::numeric
    INTO v_cost_after
    FROM public.v_project_direct_costs t WHERE t.project_id = (SELECT project_id FROM _fix);

    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;
    SELECT current_balance INTO v_treas_after FROM public.v_treasury_balance;

    IF ROUND(v_cost_after, 2) <> ROUND((SELECT project_cost FROM _base) + 10000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO1 FAIL: cost before=% after=% (expected +10000)', (SELECT project_cost FROM _base), v_cost_after;
    END IF;
    IF ROUND(v_liab_after, 2) <> ROUND((SELECT liability FROM _base) + 10000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO1 FAIL: liability before=% after=% (expected +10000)', (SELECT liability FROM _base), v_liab_after;
    END IF;
    IF ROUND(v_treas_after, 2) <> ROUND((SELECT treasury FROM _base), 2) THEN
        RAISE EXCEPTION 'SCENARIO1 FAIL: treasury changed on order creation (before=% after=%)', (SELECT treasury FROM _base), v_treas_after;
    END IF;
    RAISE NOTICE 'SCENARIO1_CREATE_OK (cost+10000, liability+10000, treasury unchanged)';
END $$;

-- ===========================================================================
-- SCENARIO 2: Partial payment 3000 — treasury -3000, liability -3000
-- ===========================================================================
CREATE TEMP TABLE _order AS
SELECT id AS order_id, total_agreed_amount FROM public.subcontract_orders
WHERE contractor_name = 'Subcontract Test Contractor';

SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _order), 3000.00, CURRENT_DATE, 'partial 3000') AS partial_payment;

CREATE TEMP TABLE _pay1 AS
SELECT id AS payment_id FROM public.subcontract_payments
WHERE subcontract_order_id = (SELECT order_id FROM _order) AND notes = 'partial 3000'
ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_liab_after numeric;
    v_treas_after numeric;
BEGIN
    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;
    SELECT current_balance INTO v_treas_after FROM public.v_treasury_balance;

    IF ROUND(v_treas_after, 2) <> ROUND((SELECT treasury FROM _base) - 3000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO2 FAIL: treasury=% (expected base-3000=% )', v_treas_after, (SELECT treasury FROM _base) - 3000.00;
    END IF;
    IF ROUND(v_liab_after, 2) <> ROUND((SELECT liability FROM _base) + 7000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO2 FAIL: liability=% (expected base+7000=% )', v_liab_after, (SELECT liability FROM _base) + 7000.00;
    END IF;
    RAISE NOTICE 'SCENARIO2_PARTIAL_OK (treasury -3000, remaining liability 7000)';
END $$;

-- ===========================================================================
-- SCENARIO 3: Full payment 7000 — remaining liability = 0
-- ===========================================================================
SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _order), 7000.00, CURRENT_DATE, 'remaining 7000') AS full_payment;

CREATE TEMP TABLE _pay2 AS
SELECT id AS payment_id FROM public.subcontract_payments
WHERE subcontract_order_id = (SELECT order_id FROM _order) AND notes = 'remaining 7000'
ORDER BY created_at DESC LIMIT 1;

DO $$
DECLARE
    v_liab_after numeric;
    v_treas_after numeric;
BEGIN
    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;
    SELECT current_balance INTO v_treas_after FROM public.v_treasury_balance;

    IF ROUND(v_liab_after, 2) <> ROUND((SELECT liability FROM _base), 2) THEN
        RAISE EXCEPTION 'SCENARIO3 FAIL: liability=% (expected base %)', v_liab_after, (SELECT liability FROM _base);
    END IF;
    IF ROUND(v_treas_after, 2) <> ROUND((SELECT treasury FROM _base) - 10000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO3 FAIL: treasury=% (expected base-10000=% )', v_treas_after, (SELECT treasury FROM _base) - 10000.00;
    END IF;
    RAISE NOTICE 'SCENARIO3_FULL_OK (liability back to baseline, treasury -10000)';
END $$;

-- ===========================================================================
-- SCENARIO 4: Overpayment rejection — nothing written
-- ===========================================================================
DO $$
DECLARE
    v_pay_before bigint;
    v_tx_before  bigint;
    v_pay_after  bigint;
    v_tx_after   bigint;
    v_liab_after numeric;
    v_treas_after numeric;
BEGIN
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;
    SELECT count(*) INTO v_tx_before FROM public.treasury_transactions;

    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _order), 1.00, CURRENT_DATE, 'overpay attempt');
        RAISE EXCEPTION 'OVERPAY_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%OVERPAY_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'SCENARIO4 FAIL: overpayment was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%يتجاوز المبلغ المتفق عليه%' THEN
            RAISE EXCEPTION 'SCENARIO4: unexpected error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    SELECT count(*) INTO v_tx_after  FROM public.treasury_transactions;
    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;
    SELECT current_balance INTO v_treas_after FROM public.v_treasury_balance;

    IF v_pay_after <> v_pay_before OR v_tx_after <> v_tx_before THEN
        RAISE EXCEPTION 'SCENARIO4 FAIL: rejected overpayment still wrote rows (pay %->%, tx %->%)',
            v_pay_before, v_pay_after, v_tx_before, v_tx_after;
    END IF;
    IF ROUND(v_liab_after, 2) <> ROUND((SELECT liability FROM _base), 2) THEN
        RAISE EXCEPTION 'SCENARIO4 FAIL: liability drifted after rejection (%)', v_liab_after;
    END IF;
    IF ROUND(v_treas_after, 2) <> ROUND((SELECT treasury FROM _base) - 10000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO4 FAIL: treasury drifted after rejection (%)', v_treas_after;
    END IF;
    RAISE NOTICE 'SCENARIO4_OVERPAY_REJECTED_OK (no rows written)';
END $$;

-- ===========================================================================
-- SCENARIO 5: Voided payment — reversal: treasury restored, liability back up
--   Void the first payment (3000). Treasury -10000 -> -7000 (back), and the
--   freed 3000 is again payable (valid payments exclude voided ones).
-- ===========================================================================
SELECT public.rpc_void_subcontract_payment(
    (SELECT payment_id FROM _pay1), 'voided for test') AS void_result;

DO $$
DECLARE
    v_liab_after numeric;
    v_treas_after numeric;
    v_pay_voided boolean;
BEGIN
    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;
    SELECT current_balance INTO v_treas_after FROM public.v_treasury_balance;

    IF ROUND(v_treas_after, 2) <> ROUND((SELECT treasury FROM _base) - 7000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO5 FAIL: treasury=% (expected base-7000=% ) after void', v_treas_after, (SELECT treasury FROM _base) - 7000.00;
    END IF;
    IF ROUND(v_liab_after, 2) <> ROUND((SELECT liability FROM _base) + 3000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO5 FAIL: liability=% (expected base+3000=% ) after void', v_liab_after, (SELECT liability FROM _base) + 3000.00;
    END IF;

    SELECT is_voided INTO v_pay_voided FROM public.subcontract_payments WHERE id = (SELECT payment_id FROM _pay1);
    IF NOT v_pay_voided THEN
        RAISE EXCEPTION 'SCENARIO5 FAIL: voided payment is_voided not set';
    END IF;

    -- The voided treasury tx must also be marked voided
    IF EXISTS (
        SELECT 1 FROM public.treasury_transactions tt
        JOIN public.subcontract_payments sp ON tt.id = sp.treasury_transaction_id
        WHERE sp.id = (SELECT payment_id FROM _pay1) AND NOT tt.is_voided
    ) THEN
        RAISE EXCEPTION 'SCENARIO5 FAIL: linked treasury tx not voided';
    END IF;

    RAISE NOTICE 'SCENARIO5_VOID_OK (treasury restored, remaining liability 3000)';
END $$;

-- After voiding, a payment of up to 3000 is allowed again; a further 1 over
-- is still rejected (valid paid = 7000, limit 10000).
DO $$
DECLARE v_pay_before bigint; v_pay_after bigint;
BEGIN
    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;

    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _order), 3000.01, CURRENT_DATE, 'over after void');
        RAISE EXCEPTION 'OVERPAY2_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%OVERPAY2_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'SCENARIO5 FAIL: 3000.01 acceptance not bounded (voided freed only 3000)';
        END IF;
        IF SQLERRM NOT LIKE '%يتجاوز المبلغ المتفق عليه%' THEN
            RAISE EXCEPTION 'SCENARIO5: unexpected bound error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    IF v_pay_after <> v_pay_before THEN
        RAISE EXCEPTION 'SCENARIO5 FAIL: bounded payment still wrote a row';
    END IF;
    RAISE NOTICE 'SCENARIO5_BOUND_OK (voided payment frees exactly its amount)';
END $$;

-- ===========================================================================
-- SCENARIO 6: Closed order — payment rejected; completed requires fully paid
--   Re-pay the 3000 (now valid), state = fully paid, then close as completed.
--   A payment on the closed order must be rejected (nothing written).
-- ===========================================================================
SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _order), 3000.00, CURRENT_DATE, 'repaid after void') AS repaid;

SELECT public.rpc_close_subcontract_order(
    (SELECT order_id FROM _order), 'completed') AS close_result;

DO $$
DECLARE
    v_status text;
    v_pay_before bigint;
    v_pay_after  bigint;
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders WHERE id = (SELECT order_id FROM _order);
    IF v_status <> 'completed' THEN
        RAISE EXCEPTION 'SCENARIO6 FAIL: order status = % (expected completed)', v_status;
    END IF;

    SELECT count(*) INTO v_pay_before FROM public.subcontract_payments;

    BEGIN
        PERFORM public.rpc_pay_subcontract(
            (SELECT order_id FROM _order), 1.00, CURRENT_DATE, 'pay on closed');
        RAISE EXCEPTION 'CLOSED_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%CLOSED_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'SCENARIO6 FAIL: payment on closed order was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مغلقة%' THEN
            RAISE EXCEPTION 'SCENARIO6: unexpected closed error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_pay_after FROM public.subcontract_payments;
    IF v_pay_after <> v_pay_before THEN
        RAISE EXCEPTION 'SCENARIO6 FAIL: payment on closed order wrote a row';
    END IF;

    -- completed requires fully paid: closing a partially-paid order must fail
    IF EXISTS (
        SELECT 1 FROM public.subcontract_orders
        WHERE contractor_name = 'Subcontract Test Contractor'
          AND total_agreed_amount = 10000.00
          AND status = 'active'
    ) THEN
        RAISE NOTICE 'SCENARIO6_CLOSE_PARTIAL_PAID_REJECTED_OK (extra active order check)';
    END IF;

    RAISE NOTICE 'SCENARIO6_CLOSED_OK (payment rejected, remaining liability frozen)';
END $$;

-- Also verify: closing a NOT-fully-paid order as completed is rejected
SELECT public.rpc_create_subcontract_order(
    (SELECT project_id FROM _fix), 'Subcontract Partial Close',
    'close-guard fixture', 5000.00) AS order2_result;

CREATE TEMP TABLE _order2_id AS
SELECT id AS order_id FROM public.subcontract_orders WHERE contractor_name = 'Subcontract Partial Close';

SELECT public.rpc_pay_subcontract(
    (SELECT order_id FROM _order2_id), 2000.00, CURRENT_DATE, 'partial 2000') AS partial_pay2;

DO $$
BEGIN
    BEGIN
        PERFORM public.rpc_close_subcontract_order(
            (SELECT order_id FROM _order2_id), 'completed');
        RAISE EXCEPTION 'PARTIAL_CLOSE_SHOULD_BE_REJECTED';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%PARTIAL_CLOSE_SHOULD_BE_REJECTED%' THEN
            RAISE EXCEPTION 'SCENARIO6.1 FAIL: partially-paid order closed as completed';
        END IF;
        IF SQLERRM NOT LIKE '%رصيد غير مدفوع%' THEN
            RAISE EXCEPTION 'SCENARIO6.1: unexpected partial-close error: %', SQLERRM;
        END IF;
    END;
    RAISE NOTICE 'SCENARIO6_1_CLOSE_PARTIAL_REJECTED_OK (completed requires full payment)';
END $$;

-- ===========================================================================
-- SCENARIO 7: Cancelled partially-paid order — unpaid cost/liability reversed
--   order2: agreed 5000, paid 2000, then cancelled.
--   Expected after cancellation:
--     project cost keeps only the paid portion (2000) of order2, plus the full
--     completed order1 (10000) => +12000 total vs baseline.
--     unpaid portion (3000) is reversed out of project cost.
--     subcontract liability back to baseline (no future obligations).
-- ===========================================================================
SELECT public.rpc_close_subcontract_order(
    (SELECT order_id FROM _order2_id), 'cancelled') AS cancel_result;

DO $$
DECLARE
    v_status   text;
    v_cost_after  numeric;
    v_liab_after  numeric;
    v_base_cost   numeric := (SELECT project_cost FROM _base);
    v_base_liab   numeric := (SELECT liability FROM _base);
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders WHERE id = (SELECT order_id FROM _order2_id);
    IF v_status <> 'cancelled' THEN
        RAISE EXCEPTION 'SCENARIO7 FAIL: order status = % (expected cancelled)', v_status;
    END IF;

    SELECT (COALESCE(t.subcontract_cost,0) + COALESCE(t.material_cost,0) + COALESCE(t.labor_cost,0) + COALESCE(t.freight_cost,0) + COALESCE(t.surplus_consumptions,0) - COALESCE(t.surplus_returns,0))::numeric
    INTO v_cost_after
    FROM public.v_project_direct_costs t WHERE t.project_id = (SELECT project_id FROM _fix);

    SELECT total_subcontract_liabilities INTO v_liab_after FROM public.v_pending_liabilities;

    -- cost = baseline + 10000 (order1 completed) + 2000 (order2 paid portion only)
    IF ROUND(v_cost_after, 2) <> ROUND(v_base_cost + 12000.00, 2) THEN
        RAISE EXCEPTION 'SCENARIO7 FAIL: cost after cancel=% (expected % => paid portion kept, unpaid 3000 reversed)',
            v_cost_after, v_base_cost + 12000.00;
    END IF;

    -- liability: neither completed nor cancelled orders are pending
    IF ROUND(v_liab_after, 2) <> ROUND(v_base_liab, 2) THEN
        RAISE EXCEPTION 'SCENARIO7 FAIL: liability after cancel=% (expected baseline %)',
            v_liab_after, v_base_liab;
    END IF;

    RAISE NOTICE 'SCENARIO7_CANCELLED_OK (paid 2000 kept in cost, unpaid 3000 reversed; liability cleared)';
END $$;

-- ===========================================================================
-- Explicit cleanup (this test seeded its own rows only)
-- ===========================================================================
DO $$
DECLARE v_oid uuid := (SELECT owner_id FROM _fix);
        v_mid uuid := (SELECT manager_id FROM _fix);
        v_pid uuid := (SELECT project_id FROM _fix);
BEGIN
    DELETE FROM public.subcontract_payments WHERE subcontract_order_id IN (
        SELECT id FROM public.subcontract_orders WHERE project_id = v_pid);
    DELETE FROM public.subcontract_orders WHERE project_id = v_pid;
    DELETE FROM public.treasury_transactions WHERE created_by IN (v_oid, v_mid);
    DELETE FROM public.projects WHERE id = v_pid;
    DELETE FROM public.profiles WHERE id IN (v_oid, v_mid);
    DELETE FROM auth.users WHERE id IN (v_oid, v_mid);
END $$;

\echo SUBCONTRACT_DB_TEST_DONE