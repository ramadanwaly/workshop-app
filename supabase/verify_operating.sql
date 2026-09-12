-- Read-only smoke for AMENDMENT 1 (no data persisted: every write runs inside a rollback)
\set ON_ERROR_STOP on

-- Schema surfaces
SELECT 'subcategory column' AS check_name,
       (SELECT count(*) FROM information_schema.columns
        WHERE table_schema='public' AND table_name='treasury_transactions' AND column_name='subcategory') = 1 AS ok;
SELECT 'workshop_operating in category check' AS check_name,
       EXISTS (SELECT 1 FROM pg_constraint c
               JOIN pg_class t ON t.oid = c.conrelid
               WHERE t.relname='treasury_transactions'
                 AND c.conname='treasury_transactions_category_check'
                  AND pg_get_constraintdef(c.oid) LIKE '%workshop_operating%') AS ok;
SELECT 'cycle partial unique index' AS check_name,
       EXISTS (SELECT 1 FROM pg_indexes
               WHERE schemaname='public' AND tablename='operating_allocation_cycles'
                 AND indexname='uq_operating_cycles_month_active') AS ok;
SELECT 'engine exec revoked from authenticated' AS check_name,
       NOT EXISTS (
           SELECT 1 FROM information_schema.routine_privileges rp
           JOIN pg_proc p ON p.proname = split_part(rp.routine_name, '(', 1)
           WHERE p.pronamespace = 'app_private'::regnamespace
             AND p.proname = 'run_operating_allocation'
             AND rp.grantee IN ('authenticated','anon','service_role','PUBLIC')
       ) AS ok;
SELECT 'view has operating_cost term' AS check_name,
       EXISTS (SELECT 1 FROM pg_views
               WHERE schemaname='public' AND viewname='v_project_direct_costs')
       AND EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema='public' AND table_name='v_project_direct_costs'
                     AND column_name='operating_cost') AS ok;

-- Positive path: engine accepts a month and produces internally consistent output (rolled back)
BEGIN;
DO $$
DECLARE r JSONB;
BEGIN
    r := app_private.run_operating_allocation('2026-08-01'::date);
    IF (r->>'allocated_lines')::int <> 0 AND r->>'status' = 'applied' THEN
        IF (r->>'allocated_sum')::numeric <> (SELECT COALESCE(SUM(amount),0)::numeric
            FROM public.treasury_transactions
            WHERE category='workshop_operating' AND NOT is_voided
              AND NOT is_direct_owner_payment
              AND created_at >= '2026-08-01' AND created_at < '2026-09-01') THEN
            RAISE EXCEPTION 'allocated_sum mismatch';
        END IF;
    END IF;
    RAISE NOTICE 'engine ok status=% lines=% sum=%', r->>'status', r->>'allocated_lines', r->>'allocated_sum';
END $$;
ROLLBACK;

-- Negative path: unauthenticated session (postgres, no auth.uid()) is rejected by the owner wrapper
DO $$
BEGIN
    BEGIN
        PERFORM public.rpc_run_operating_allocation('2026-08-01'::date);
        RAISE EXCEPTION 'expected owner-gate rejection but wrapper ran';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%غير مصرح%' THEN
                RAISE NOTICE 'owner-gate ok';
            ELSE
                RAISE;
            END IF;
    END;
END $$;
