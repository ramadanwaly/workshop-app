-- ============================================================================
-- verify_dashboard.sql
-- PHASE 6: Dashboard view checks against the live database.
-- Run as postgres: psql -v ON_ERROR_STOP=1 -f verify_dashboard.sql
-- Read-only; every check RAISE EXCEPTION on failure -> nonzero exit.
-- ============================================================================

-- 1) v_surplus_available exists and is security_invoker
DO $$
DECLARE
  opts text;
BEGIN
  SELECT COALESCE(array_to_string(c.reloptions, ','), '') INTO opts
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'v' AND c.relname = 'v_surplus_available';

  IF opts IS NULL THEN
    RAISE EXCEPTION 'v_surplus_available view not found';
  END IF;
  IF opts NOT LIKE '%security_invoker%' THEN
    RAISE EXCEPTION 'v_surplus_available is not security_invoker';
  END IF;
  RAISE NOTICE 'v_surplus_available security_invoker: ok';
END $$;

-- 2) v_surplus_available totals equal a manual recompute (scenario 11 surplus scrap / returns)
DO $$
DECLARE
  v_view   numeric;
  v_manual numeric;
  v_qty    numeric;
  v_count  int;
BEGIN
  SELECT total_surplus_value, total_surplus_quantity, item_count
    INTO v_view, v_qty, v_count
  FROM public.v_surplus_available;

  SELECT COALESCE(SUM(estimated_value), 0), COALESCE(SUM(quantity), 0), COUNT(*)
    INTO v_manual, v_qty, v_count
  FROM public.surplus_bank
  WHERE status = 'available';

  IF v_view IS DISTINCT FROM v_manual THEN
    RAISE EXCEPTION 'surplus available drift: view=% manual=%', v_view, v_manual;
  END IF;
  RAISE NOTICE 'v_surplus_available == manual recompute: value=%, qty=%, items=%', v_view, v_qty, v_count;
END $$;

DO $$ BEGIN RAISE NOTICE 'DASHBOARD VERIFY PASSED'; END $$;
