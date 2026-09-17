-- ============================================================================
-- verify_and_cleanup.sql — Assert audit concurrency invariant, finish lifecycle
-- Runs AFTER both consumer sessions complete.
-- Invariants checked (single order, total = 30000, two concurrent pay(16000)):
--   1. SUM(valid payments) must never exceed total_agreed_amount (30000).
--   2. SUM(valid payments) equals exactly one winning payment (16000), since
--      only one of two 16000s can fit within the 30000 limit.
--   3. Every payment row is linked to an OUT treasury transaction of the same
--      amount (category subcontract_payment) — no orphan/double-count writes.
--   4. Remaining 14000 pays cleanly, order closes as completed, liability 0.
-- Accepts psql variables: c_user, c_project, c_order
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

-- Load fixture ids into a temp table at top level, where psql interpolates
-- :'var' correctly (interpolation does NOT work inside $$...$$ DO blocks).
CREATE TEMP TABLE _zz_audit_ids AS
SELECT
    :'c_user'::uuid    AS v_user_id,
    :'c_project'::uuid AS v_project_id,
    :'c_order'::uuid   AS v_order_id;

DO $$
DECLARE
    v_total          NUMERIC;
    v_pay_count      INT;
    v_ord_total      NUMERIC;
    v_tx_mismatch    INT;
BEGIN
    SELECT total_agreed_amount INTO v_ord_total
    FROM public.subcontract_orders
    WHERE id = (SELECT v_order_id FROM _zz_audit_ids);

    IF v_ord_total <> 30000.00 THEN
        RAISE EXCEPTION 'fixture order total wrong: % (expected 30000)', v_ord_total;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(amount), 0)
    INTO v_pay_count, v_total
    FROM public.subcontract_payments
    WHERE subcontract_order_id = (SELECT v_order_id FROM _zz_audit_ids)
      AND NOT is_voided;

    IF v_total > v_ord_total THEN
        RAISE EXCEPTION 'OVERPAYMENT DETECTED: total paid=% / agreed=%', v_total, v_ord_total;
    END IF;

    -- Exactly one winning 16000 (two 16000s cannot both fit within 30000).
    IF v_pay_count <> 1 OR ROUND(v_total, 2) <> 16000.00 THEN
        RAISE EXCEPTION 'expected exactly one winning 16000 payment, got count=% total=%', v_pay_count, v_total;
    END IF;

    -- Every non-voided payment has a linked, non-voided OUT treasury tx of the same amount.
    SELECT COUNT(*) INTO v_tx_mismatch
    FROM public.subcontract_payments sp
    LEFT JOIN public.treasury_transactions tt ON tt.id = sp.treasury_transaction_id
    WHERE sp.subcontract_order_id = (SELECT v_order_id FROM _zz_audit_ids)
      AND NOT sp.is_voided
      AND (tt.id IS NULL OR tt.is_voided OR tt.amount <> sp.amount OR tt.transaction_type <> 'out' OR tt.category <> 'subcontract_payment');

    IF v_tx_mismatch > 0 THEN
        RAISE EXCEPTION 'payment/treasury mismatch rows=%', v_tx_mismatch;
    END IF;

    RAISE NOTICE 'AUDIT CONCURRENCY INVARIANT OK: payments=% total=%', v_pay_count, v_total;
END $$;

-- Impersonate the seeded owner for the remaining owner-only RPCs.
SELECT set_config(
    'request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', (SELECT v_user_id::text FROM _zz_audit_ids)),
    false
);

-- Remaining 14000 pays cleanly, then close as completed.
SELECT public.rpc_pay_subcontract(
    (SELECT v_order_id FROM _zz_audit_ids), 14000.00, CURRENT_DATE, 'audit race remainder'
) AS remainder_pay;

SELECT public.rpc_close_subcontract_order(
    (SELECT v_order_id FROM _zz_audit_ids), 'completed', 'اكتمل العمل التجريبي'
) AS race_close;

DO $$
DECLARE v_status text; v_liab numeric;
BEGIN
    SELECT status INTO v_status FROM public.subcontract_orders
    WHERE id = (SELECT v_order_id FROM _zz_audit_ids);
    IF v_status IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'race order status=% (expected completed)', v_status;
    END IF;
    SELECT total_subcontract_liabilities INTO v_liab FROM public.v_pending_liabilities;
    IF v_liab < 0 THEN
        RAISE EXCEPTION 'negative subcontract liability after race (%)', v_liab;
    END IF;
    RAISE NOTICE 'AUDIT RACE LIFECYCLE OK (remainder paid, closed completed)';
END $$;

-- ----------------------------------------------------------------------------
-- Explicit cleanup (never rely on rollback — fixture was committed by seed)
-- ----------------------------------------------------------------------------
DELETE FROM public.subcontract_payments WHERE subcontract_order_id = (SELECT v_order_id FROM _zz_audit_ids);
DELETE FROM public.subcontract_orders    WHERE id = (SELECT v_order_id FROM _zz_audit_ids);
DELETE FROM public.treasury_transactions WHERE created_by = (SELECT v_user_id FROM _zz_audit_ids);

DELETE FROM public.projects WHERE id = (SELECT v_project_id FROM _zz_audit_ids);

-- Fixture identity may be referenced by the immutable audit trail
-- (migration 29): remove it only when nothing references it.
DELETE FROM public.profiles WHERE id = (SELECT v_user_id FROM _zz_audit_ids)
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id = (SELECT v_user_id FROM _zz_audit_ids));

DELETE FROM auth.users WHERE id = (SELECT v_user_id FROM _zz_audit_ids)
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id = (SELECT v_user_id FROM _zz_audit_ids));

\echo AUDIT_CONCURRENCY_CLEANUP_DONE
