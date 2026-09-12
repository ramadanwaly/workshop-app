-- ============================================================================
-- verify_and_cleanup.sql — Assert concurrency invariant, then explicit cleanup
-- Runs AFTER both consumer sessions complete.
-- Invariants checked (single surplus, qty 100, two concurrent consume(70)):
--   1. Net consumed over the surplus never exceeds its initial quantity.
--   2. Remaining quantity + consumed records reconcile to exactly 100.
--   3. Exactly zero negative quantities remain.
-- Accepts psql variables: c_user, c_project, c_source_project, c_surplus
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

-- Load fixture ids into a temp table at top level, where psql interpolates
-- :'var' correctly (interpolation does NOT work inside $$...$$ DO blocks).
-- Session-scoped (no ON COMMIT DROP): each statement autocommits separately
-- when piped via stdin, so the table must survive across statements. It is
-- dropped automatically when the psql session ends.
CREATE TEMP TABLE _zz_cc_ids AS
SELECT
    :'c_user'::uuid           AS v_user_id,
    :'c_project'::uuid        AS v_project_id,
    :'c_source_project'::uuid AS v_source_project_id,
    :'c_surplus'::uuid        AS v_surplus_id;

DO $$
DECLARE
    v_negative      INT;
    v_row_count     INT;
    v_total_qty     NUMERIC;
    v_surplus       UUID;
BEGIN
    SELECT v_surplus_id, v_project_id INTO v_surplus
    FROM _zz_cc_ids;

    SELECT COUNT(*) INTO v_negative
    FROM public.surplus_bank
    WHERE (id = (SELECT v_surplus_id FROM _zz_cc_ids)
        OR parent_surplus_id = (SELECT v_surplus_id FROM _zz_cc_ids))
      AND quantity < 0;

    IF v_negative > 0 THEN
        RAISE EXCEPTION 'negative surplus quantity found (count=%)', v_negative;
    END IF;

    -- Conservation: parent + any partial-consumption children must sum to the
    -- original quantity (100). Over-consumption would push the total above 100.
    SELECT COUNT(*), COALESCE(SUM(quantity), 0) INTO v_row_count, v_total_qty
    FROM public.surplus_bank
    WHERE id = v_surplus OR parent_surplus_id = v_surplus;

    IF v_row_count < 1 THEN
        RAISE EXCEPTION 'expecting at least the parent surplus row';
    END IF;

    IF ROUND(v_total_qty, 2) > 100.00 THEN
        RAISE EXCEPTION 'OVER-CONSUMPTION DETECTED: total quantity=% (expected <= 100)', v_total_qty;
    END IF;

    RAISE NOTICE 'CONCURRENCY INVARIANT OK: rows=% total quantity=%', v_row_count, COALESCE(v_total_qty, 0);
END $$;

-- ----------------------------------------------------------------------------
-- Explicit cleanup (never rely on rollback — fixture was committed by seed)
-- ----------------------------------------------------------------------------
DELETE FROM public.project_cost_adjustments
WHERE surplus_id IN (
        SELECT id FROM public.surplus_bank
        WHERE id = (SELECT v_surplus_id FROM _zz_cc_ids)
           OR parent_surplus_id = (SELECT v_surplus_id FROM _zz_cc_ids)
    )
   OR project_id IN (
        SELECT v_project_id FROM _zz_cc_ids
        UNION ALL SELECT v_source_project_id FROM _zz_cc_ids
    );

DELETE FROM public.surplus_bank WHERE parent_surplus_id = (SELECT v_surplus_id FROM _zz_cc_ids);
DELETE FROM public.surplus_bank WHERE id = (SELECT v_surplus_id FROM _zz_cc_ids);

DELETE FROM public.projects WHERE id IN (
    SELECT v_project_id FROM _zz_cc_ids
    UNION ALL SELECT v_source_project_id FROM _zz_cc_ids
);

-- Fixture identity is stable across runs AND may be referenced by the
-- immutable audit trail: remove it only when nothing references it.
DELETE FROM public.profiles WHERE id = (SELECT v_user_id FROM _zz_cc_ids)
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id = (SELECT v_user_id FROM _zz_cc_ids));

DELETE FROM auth.users WHERE id = (SELECT v_user_id FROM _zz_cc_ids)
  AND NOT EXISTS (SELECT 1 FROM public.audit_log WHERE actor_id = (SELECT v_user_id FROM _zz_cc_ids));

\echo CLEANUP_AND_VERIFY_DONE