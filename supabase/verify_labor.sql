-- ============================================================================
-- verify_labor.sql — Phase 4 labor RPC regression (attendance/advance/settlement)
--
-- WARNING: operates against the live database. It creates and deletes its own
-- fixture rows ONLY (test owner, worker, project). It must run against an empty
-- or test database — never against production data.
--
-- Asserts, purely from database truth:
--   attendance: calculated_amount = daily_rate x fraction (server-side)
--   advance    : treasury OUT (category advance), liability +
--   settlement >0 : treasury OUT (settlement), records settled
--   settlement <=0: treasury unchanged, carried_forward_advance opened
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

CREATE TEMP TABLE _fix AS
SELECT
    gen_random_uuid() AS user_id,
    gen_random_uuid() AS worker_id,
    gen_random_uuid() AS project_id;

-- Pre-clean any test fixtures orphaned by an aborted prior run
DELETE FROM public.project_cost_adjustments
WHERE surplus_id IN (SELECT id FROM public.surplus_bank WHERE source_project_id IN (SELECT id FROM public.projects WHERE name='Labor Test Project'));
DELETE FROM public.worker_advances WHERE worker_id IN (SELECT id FROM public.workers WHERE name='Labor Test Worker');
DELETE FROM public.worker_logs    WHERE worker_id IN (SELECT id FROM public.workers WHERE name='Labor Test Worker');
DELETE FROM public.workers  WHERE name='Labor Test Worker';
DELETE FROM public.projects WHERE name='Labor Test Project';
DELETE FROM public.treasury_transactions WHERE created_by IN (
    SELECT id FROM auth.users WHERE email LIKE 'labor-test-%@example.test');
DELETE FROM public.profiles WHERE id IN (
    SELECT id FROM auth.users WHERE email LIKE 'labor-test-%@example.test');
DELETE FROM auth.users WHERE email LIKE 'labor-test-%@example.test';

-- ---------------------------------------------------------------------------
-- Seed an owner so RPC guards (app_private.is_owner) pass
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) SELECT
    user_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'labor-test-' || user_id::text || '@example.test', 'x', '{}', '{}', NOW(), NOW()
FROM _fix;

UPDATE public.profiles SET role = 'owner' WHERE id = (SELECT user_id FROM _fix);

-- Impersonate the owner for the whole session
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT user_id::text FROM _fix)),
    false
);

-- ---------------------------------------------------------------------------
-- Worker + project
-- ---------------------------------------------------------------------------
INSERT INTO public.workers (id, name, daily_rate, is_active)
SELECT worker_id, 'Labor Test Worker', 200.00, true FROM _fix;

INSERT INTO public.projects (id, name, status)
SELECT project_id, 'Labor Test Project', 'active' FROM _fix;

-- ---------------------------------------------------------------------------
-- 1. Attendance: project 1.00 -> 200 ; general 0.50 -> 100
-- ---------------------------------------------------------------------------
SELECT public.rpc_record_attendance((SELECT worker_id FROM _fix), (SELECT project_id FROM _fix), CURRENT_DATE, 1.00) AS attendance_project;
SELECT public.rpc_record_attendance((SELECT worker_id FROM _fix), NULL, CURRENT_DATE, 0.50) AS attendance_general;

-- Invariant: server-computed amount
DO $$
DECLARE v_total numeric;
BEGIN
    SELECT SUM(calculated_amount) INTO v_total
    FROM public.worker_logs
    WHERE worker_id = (SELECT worker_id FROM _fix);
    IF v_total <> 300.00 THEN
        RAISE EXCEPTION 'attendance amount wrong: % (expected 300)', v_total;
    END IF;
    RAISE NOTICE 'ATTENDANCE_OK total=%', v_total;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Advance 250 -> treasury OUT, liability
-- ---------------------------------------------------------------------------
SELECT public.rpc_record_advance((SELECT worker_id FROM _fix), 250.00, CURRENT_DATE, 'advance test') AS advance_result;

-- ---------------------------------------------------------------------------
-- 3b. Settlement: earned 300 - advance 250 = 50 net (cash)
-- ---------------------------------------------------------------------------
SELECT public.rpc_settle_worker((SELECT worker_id FROM _fix), 'settle test') AS settlement_cash;

-- Assert the cash-settlement invariant
DO $$
DECLARE
    v_pending numeric;
    v_settled_logs bigint := (
        SELECT count(*) FROM public.worker_logs
        WHERE worker_id = (SELECT worker_id FROM _fix) AND is_settled);
    v_settled_adv bigint := (
        SELECT count(*) FROM public.worker_advances
        WHERE worker_id = (SELECT worker_id FROM _fix)
          AND is_settled AND NOT is_carried_forward);
BEGIN
    IF v_settled_logs <> 2 THEN
        RAISE EXCEPTION 'expected 2 settled logs, got %', v_settled_logs;
    END IF;
    IF v_settled_adv <> 1 THEN
        RAISE EXCEPTION 'expected 1 settled advance, got %', v_settled_adv;
    END IF;
    RAISE NOTICE 'CASH_SETTLEMENT_OK settled_logs=% settled_advances=%', v_settled_logs, v_settled_adv;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Second period: advance exceeds wages -> credit carry-forward
--    wage 100, advance 200 -> net = -100, OUT = 0, carried 100 forward
-- ---------------------------------------------------------------------------
SELECT public.rpc_record_attendance((SELECT worker_id FROM _fix), NULL, CURRENT_DATE, 0.50);
SELECT public.rpc_record_advance((SELECT worker_id FROM _fix), 200.00, CURRENT_DATE, 'advance2');
SELECT public.rpc_settle_worker((SELECT worker_id FROM _fix), 'credit carry forward') AS settlement_credit;

DO $$
DECLARE
    v_carried   numeric;
    v_carry_settled boolean;
    v_treasury  numeric;
BEGIN
    SELECT amount, is_settled INTO v_carried, v_carry_settled
    FROM public.worker_advances
    WHERE worker_id = (SELECT worker_id FROM _fix) AND is_carried_forward
    ORDER BY created_at DESC LIMIT 1;

    IF v_carried <> 100.00 THEN
        RAISE EXCEPTION 'carried-forward amount wrong: % (expected 100)', v_carried;
    END IF;
    IF v_carry_settled THEN
        RAISE EXCEPTION 'carried-forward must remain an open (unsettled) advance';
    END IF;

    SELECT current_balance INTO v_treasury FROM public.v_treasury_balance;

    -- First pair: advance 250 out + settlement 50 out = 300 out
    -- Second pair: advance 200 out + credit (0 out) = 200 out  -> total 500 out
    IF v_treasury <> -500.00 THEN
        RAISE EXCEPTION 'treasury mismatch: % (expected -500)', v_treasury;
    END IF;

    RAISE NOTICE 'CREDIT_CARRY_FORWARD_OK carried=% treasury=%', v_carried, v_treasury;
END $$;

-- ---------------------------------------------------------------------------
-- 5. Scenario 19: a manager (staff, non-owner) may record attendance but is
--    REJECTED for advance and settlement (owner-only money moves)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _mgr AS SELECT gen_random_uuid() AS user_id;

INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) SELECT
    user_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'labor-test-manager-' || user_id::text || '@example.test',
    'x', '{}', '{}', NOW(), NOW()
FROM _mgr;

UPDATE public.profiles SET role = 'manager' WHERE id = (SELECT user_id FROM _mgr);

-- Impersonate the manager
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT user_id::text FROM _mgr)),
    false
);

-- Positive control: the manager CAN record attendance
DO $$
DECLARE v_logs_before bigint;
        v_logs_after  bigint;
BEGIN
    SELECT count(*) INTO v_logs_before FROM public.worker_logs;

    PERFORM public.rpc_record_attendance((SELECT worker_id FROM _fix), NULL, CURRENT_DATE, 1.00);

    SELECT count(*) INTO v_logs_after FROM public.worker_logs;
    IF v_logs_after <> v_logs_before + 1 THEN
        RAISE EXCEPTION 'SCENARIO19: manager attendance not recorded (before=%, after=%)',
            v_logs_before, v_logs_after;
    END IF;
    RAISE NOTICE 'SCENARIO19_MANAGER_ATTENDANCE_OK (staff may record attendance)';
END $$;

-- Negative: manager advance must be rejected, nothing written to treasury/advances
DO $$
DECLARE v_tx_before bigint;
        v_tx_after  bigint;
        v_adv_before bigint;
        v_adv_after  bigint;
BEGIN
    SELECT count(*) INTO v_tx_before FROM public.treasury_transactions;
    SELECT count(*) INTO v_adv_before FROM public.worker_advances;

    BEGIN
        PERFORM public.rpc_record_advance(
            (SELECT worker_id FROM _fix), 60.00, CURRENT_DATE, 'manager impersonation');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_ADVANCE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_ADVANCE%' THEN
            RAISE EXCEPTION 'SCENARIO19 FAIL: manager advance was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO19: unexpected advance error: %', SQLERRM;
        END IF;
    END;

    SELECT count(*) INTO v_tx_after FROM public.treasury_transactions;
    SELECT count(*) INTO v_adv_after FROM public.worker_advances;
    IF v_tx_after <> v_tx_before OR v_adv_after <> v_adv_before THEN
        RAISE EXCEPTION 'SCENARIO19 FAIL: rejected advance still wrote rows (tx %->%, adv %->%)',
            v_tx_before, v_tx_after, v_adv_before, v_adv_after;
    END IF;
    RAISE NOTICE 'SCENARIO19_ADVANCE_REJECTED_OK (owner-only)';
END $$;

-- Negative: manager settlement must be rejected
DO $$
BEGIN
    BEGIN
        PERFORM public.rpc_settle_worker((SELECT worker_id FROM _fix), 'manager impersonation');
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_SETTLE';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_SETTLE%' THEN
            RAISE EXCEPTION 'SCENARIO19 FAIL: manager settlement was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%مالك الورشة فقط%' THEN
            RAISE EXCEPTION 'SCENARIO19: unexpected settlement error: %', SQLERRM;
        END IF;
    END;
    RAISE NOTICE 'SCENARIO19_SETTLE_REJECTED_OK (owner-only)';
END $$;

-- Switch impersonation back to the owner so remaining flow/cleanup is owner-scoped
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT user_id::text FROM _fix)),
    false
);

-- ---------------------------------------------------------------------------
-- Explicit cleanup (this test seeded its own rows only)
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_uid uuid := (SELECT user_id FROM _fix);
        v_mid uuid := (SELECT user_id FROM _mgr);
        v_wid uuid := (SELECT worker_id FROM _fix);
        v_pid uuid := (SELECT project_id FROM _fix);
BEGIN
    DELETE FROM public.project_cost_adjustments WHERE project_id = v_pid;
    DELETE FROM public.worker_advances WHERE worker_id = v_wid;
    DELETE FROM public.worker_logs    WHERE worker_id = v_wid;
    DELETE FROM public.workers        WHERE id = v_wid;
    DELETE FROM public.projects       WHERE id = v_pid;
    DELETE FROM public.treasury_transactions WHERE created_by IN (v_uid, v_mid);
    DELETE FROM public.profiles       WHERE id IN (v_uid, v_mid);
    DELETE FROM auth.users            WHERE id IN (v_uid, v_mid);
END $$;

\echo LABOR_DB_TEST_DONE