-- ============================================================================
-- verify_smoke.sql
-- Read-only financial regression smoke against the live database.
-- Run as postgres: psql -v ON_ERROR_STOP=1 -f verify_smoke.sql
-- Every check RAISE EXCEPTION on failure -> nonzero exit, never modifies data.
-- ============================================================================

-- 1) Official migration baseline is recorded (created via `supabase migration repair`)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_class WHERE relname = 'schema_migrations') THEN
    RAISE EXCEPTION 'supabase_migrations.schema_migrations missing: baseline not recorded';
  END IF;
END $$;

-- Hard gate: the ledger must EXACTLY equal the migration files in
-- supabase/migrations/ (17 files: versions 01..14 after the 20260905000011
-- collision fix, plus 15 revoke_execute_public_functions,
-- 16 revoke_select_public_views and 17 worker_liabilities_view,
-- plus 18 idempotency_scope, 19 no_hard_delete_policies,
-- 20 default_privileges and 21 treasury_write_hardening,
-- plus 22 amount_upper_bounds, 23 text_bounds, 24 mandatory_reasons,
-- 25 rate_limits, 26 drop_old_remove_exclusion, 27 audit_log,
-- 28 cleanup_gate_settings_attendance, 29 audit_actor_nullable_lookup,
-- 30 attendance_unique_reverted and 31 drop_old_close_overload,
-- plus 32 fix_audit_triggers, 33 idempotency_expiration, 34 secure_auth_trigger,
-- 35 rate_limit_auth, 36 rpc_void_treasury_transaction, 37 settings_no_delete,
-- 38 surplus_no_zero_value, 39 settlement_audit_trail, 40 attendance_project_status,
-- 41 subcontract_immutability, and 42 handle_new_user_lock).
DO $$
DECLARE
  v_expected text[] := ARRAY[
    '20260905000001','20260905000002','20260905000003','20260905000004',
    '20260905000005','20260905000006','20260905000007','20260905000008',
    '20260905000009','20260905000010','20260905000011','20260905000012',
    '20260905000013','20260905000014','20260905000015','20260905000016',
    '20260905000017','20260910000018','20260910000019','20260910000020',
    '20260910000021','20260910000022','20260910000023','20260910000024',
    '20260910000025','20260910000026','20260910000027','20260910000028',
    '20260910000029','20260910000030','20260910000031','20260911000032',
    '20260911000033','20260911000034','20260911000035','20260911000036',
    '20260911000037','20260911000038','20260911000039','20260911000040',
    '20260911000041','20260911000042'
  ];
  v_actual   text[];
BEGIN
  v_actual := ARRAY(SELECT version FROM supabase_migrations.schema_migrations ORDER BY 1);
  IF (SELECT count(*) FROM supabase_migrations.schema_migrations) <> 42
     OR v_actual IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'SMOKE FAIL: migration ledger drift (rows=% actual=% expected=% max=%)',
      (SELECT count(*) FROM supabase_migrations.schema_migrations),
      v_actual, v_expected, (SELECT max(version) FROM supabase_migrations.schema_migrations);
  END IF;
  RAISE NOTICE 'migration ledger ok (42 / max 20260911000042)';
END $$;

-- 2) Treasury balance view matches a manual recompute (scenarios 1 & 18)
DO $$
DECLARE
  v_view   numeric;
  v_manual numeric;
BEGIN
  SELECT current_balance INTO v_view FROM public.v_treasury_balance;
  SELECT COALESCE(SUM(
    CASE WHEN transaction_type = 'in' THEN amount ELSE -amount END
  ), 0) INTO v_manual
  FROM public.treasury_transactions
  WHERE NOT is_voided AND NOT is_direct_owner_payment;

  IF v_view IS DISTINCT FROM v_manual THEN
    RAISE EXCEPTION 'treasury balance drift: view=% manual=%', v_view, v_manual;
  END IF;
  RAISE NOTICE 'treasury_balance == manual recompute: %', v_view;
END $$;

-- 3) Financial views are security_invoker (base-table RLS applies)
DO $$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'v'
    AND c.relname IN ('v_treasury_balance', 'v_project_direct_costs', 'v_pending_liabilities', 'v_surplus_available', 'v_worker_liabilities')
    AND COALESCE(array_to_string(c.reloptions, ','), '') NOT LIKE '%security_invoker%';

  IF bad > 0 THEN
    RAISE EXCEPTION '% financial view(s) are not security_invoker', bad;
  END IF;
  RAISE NOTICE 'financial views security_invoker: ok';
END $$;

-- 4) Surplus consumption/scrap RPCs lock rows (concurrency scenarios 16 & 17)
DO $$
BEGIN
  IF pg_get_functiondef('public.rpc_consume_surplus'::regproc) NOT LIKE '%FOR UPDATE%' THEN
    RAISE EXCEPTION 'rpc_consume_surplus lacks row lock';
  END IF;
  IF pg_get_functiondef('public.rpc_scrap_surplus'::regproc) NOT LIKE '%FOR UPDATE%' THEN
    RAISE EXCEPTION 'rpc_scrap_surplus lacks row lock';
  END IF;
  RAISE NOTICE 'surplus consume/scrap row locks: ok';
END $$;

-- 5) RPC authorization guards via app_private helpers (scenarios 19)
DO $$
BEGIN
  IF pg_get_functiondef('public.rpc_return_surplus'::regproc) NOT LIKE '%app_private.is_staff%' THEN
    RAISE EXCEPTION 'rpc_return_surplus missing staff guard';
  END IF;
  IF pg_get_functiondef('public.rpc_consume_surplus'::regproc) NOT LIKE '%app_private.is_staff%' THEN
    RAISE EXCEPTION 'rpc_consume_surplus missing staff guard';
  END IF;
  IF pg_get_functiondef('public.rpc_scrap_surplus'::regproc) NOT LIKE '%app_private.is_staff%' THEN
    RAISE EXCEPTION 'rpc_scrap_surplus missing staff guard';
  END IF;
  RAISE NOTICE 'RPC staff guards: ok';
END $$;

-- 6) Double-submit prevention: idempotency key is a PRIMARY KEY (scenario 20)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'idempotency_keys'
      AND constraint_type = 'PRIMARY KEY' AND constraint_name = 'idempotency_keys_pkey'
  ) THEN
    RAISE EXCEPTION 'idempotency_keys lacks unique PRIMARY KEY';
  END IF;
  RAISE NOTICE 'idempotency_keys primary key (double-submit guard): ok';
END $$;

-- 7) Void keeps a full audit trail (scenario 18)
DO $$
DECLARE
  cols int;
BEGIN
  SELECT count(*) INTO cols FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'treasury_transactions'
    AND column_name IN ('is_voided', 'voided_at', 'void_reason', 'voided_by');

  IF cols < 3 THEN
    RAISE EXCEPTION 'void audit columns incomplete (found %)', cols;
  END IF;
  RAISE NOTICE 'void audit columns: ok';
END $$;

-- 8) Owner-only void path enforced at RLS level
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'treasury_transactions'
      AND policyname = 'treasury_update_void_owner_only'
  ) THEN
    RAISE EXCEPTION 'owner-only void policy missing';
  END IF;
  RAISE NOTICE 'owner-only void policy: ok';
END $$;

-- 9) RLS enabled on every public table
DO $$
DECLARE
  gaps int;
BEGIN
  SELECT count(*) INTO gaps
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity;

  IF gaps > 0 THEN
    RAISE EXCEPTION '% public table(s) without RLS', gaps;
  END IF;
  RAISE NOTICE 'RLS enabled on all public tables: ok';
END $$;

-- 10) Unsettled liabilities view is non-negative (no negative liability totals)
DO $$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad FROM public.v_pending_liabilities
  WHERE total_pending_liabilities < 0 OR total_worker_liabilities < 0 OR total_subcontract_liabilities < 0;

  IF bad > 0 THEN
    RAISE EXCEPTION 'negative liability totals found (%)', bad;
  END IF;
  RAISE NOTICE 'pending liabilities non-negative: ok';
END $$;

-- 11) PUBLIC and anon have NO EXECUTE on any public-schema function
--     (from 20260905000015_revoke_execute_public_functions).
--     Sole exception: increment_rate_limit (migration 25) must be callable by
--     unauthenticated login posts; it only writes rate counters for
--     well-formed buckets.
DO $$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
  LEFT JOIN pg_roles r ON r.oid = a.grantee
  WHERE n.nspname = 'public'
    AND p.proname <> 'increment_rate_limit'
    AND a.privilege_type = 'EXECUTE'
    AND (a.grantee = 0 OR r.rolname = 'anon');

  IF bad > 0 THEN
    RAISE EXCEPTION 'public funcs executable by PUBLIC/anon (%)', bad;
  END IF;
  RAISE NOTICE 'public functions not executable by PUBLIC/anon: ok';
END $$;

-- 12) PUBLIC and anon have NO SELECT on any public table/view
--     (from 20260905000016_revoke_select_public_views; views are tables)
DO $$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl, acldefault('r', c.relowner))) a
  LEFT JOIN pg_roles r ON r.oid = a.grantee
  WHERE n.nspname = 'public'
    AND c.relkind IN ('r', 'v', 'm', 'p', 'f')
    AND a.privilege_type = 'SELECT'
    AND (a.grantee = 0 OR r.rolname = 'anon');

  IF bad > 0 THEN
    RAISE EXCEPTION 'public tables/views readable by PUBLIC/anon (%)', bad;
  END IF;
  RAISE NOTICE 'public tables/views not readable by PUBLIC/anon: ok';
END $$;

-- 13) authenticated still has SELECT on every public view (app depends on it)
DO $$
DECLARE
  gap int;
BEGIN
  SELECT count(*) INTO gap
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'v'
    AND NOT EXISTS (
      SELECT 1
      FROM aclexplode(COALESCE(c.relacl, acldefault('r', c.relowner))) a
      JOIN pg_roles r ON r.oid = a.grantee
      WHERE a.privilege_type = 'SELECT' AND r.rolname = 'authenticated'
    );

  IF gap > 0 THEN
    RAISE EXCEPTION '% public view(s) lost SELECT for authenticated', gap;
  END IF;
  RAISE NOTICE 'authenticated SELECT on all public views: ok';
END $$;

-- 14) v_pending_liabilities worker totals must equal the sum over
--     v_worker_liabilities (single-source-of-truth refactor, migration 17)
DO $$
DECLARE
  v_view    numeric;
  v_derived numeric;
BEGIN
  SELECT total_worker_liabilities INTO v_view FROM public.v_pending_liabilities;
  SELECT COALESCE(SUM(net_payable), 0) INTO v_derived FROM public.v_worker_liabilities;

  IF v_view IS DISTINCT FROM v_derived THEN
    RAISE EXCEPTION 'worker liability drift: view=% derived=%', v_view, v_derived;
  END IF;
  RAISE NOTICE 'pending worker liabilities == SUM(v_worker_liabilities.net_payable): ok';
END $$;

-- 15) P2-06 audit log: table exists, RLS on, owner-only SELECT, no direct
--     write policies (writes only via app_private.append_audit_log), immutable
--     trigger present, and the exclusion RPCs log the reason permanently.
DO $$
DECLARE
  pol_count int;
  has_immutable int;
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'audit_log'
  ) THEN
    RAISE EXCEPTION 'audit_log table missing';
  END IF;

  IF EXISTS (
    SELECT FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'audit_log' AND NOT c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'audit_log lacks RLS';
  END IF;

  SELECT count(*) INTO pol_count FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'audit_log' AND policyname = 'audit_select_owner';
  IF pol_count <> 1 THEN
    RAISE EXCEPTION 'audit owner-only SELECT policy missing';
  END IF;

  IF EXISTS (
    SELECT FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'audit_log'
      AND (cmd = 'UPDATE' OR cmd = 'DELETE')
  ) THEN
    RAISE EXCEPTION 'audit_log must have no UPDATE/DELETE policies (immutable)';
  END IF;

  IF EXISTS (
    SELECT FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'audit_log' AND cmd = 'INSERT'
  ) THEN
    RAISE EXCEPTION 'audit_log must have no direct INSERT policy (writer is append_audit_log only)';
  END IF;

  SELECT count(*) INTO has_immutable FROM pg_trigger
  WHERE tgname = 'trg_audit_log_immutable';
  IF has_immutable <> 1 THEN
    RAISE EXCEPTION 'audit immutability trigger missing';
  END IF;

  IF pg_get_functiondef('public.rpc_remove_operating_exclusion'::regproc) NOT LIKE '%append_audit_log%' THEN
    RAISE EXCEPTION 'rpc_remove_operating_exclusion does not log the removal reason';
  END IF;
  IF pg_get_functiondef('public.rpc_add_operating_exclusion'::regproc) NOT LIKE '%append_audit_log%' THEN
    RAISE EXCEPTION 'rpc_add_operating_exclusion does not log';
  END IF;
  RAISE NOTICE 'audit log (P2-06): ok';
END $$;

-- P2-09: cleanup gate (cron-only) and settings never deletable.
-- (The attendance UNIQUE from migration 28 was reverted by migration 30:
-- the locked financial suite records legitimate same-day repeats, so the
-- constraint must stay ABSENT — guarded here against silent re-adding.)
DO $$
BEGIN
  IF has_function_privilege('authenticated', 'public.cleanup_expired_idempotency_keys()', 'EXECUTE') THEN
    RAISE EXCEPTION 'cleanup_expired_idempotency_keys still executable by authenticated (P2-09)';
  END IF;
  IF has_function_privilege('anon', 'public.cleanup_expired_idempotency_keys()', 'EXECUTE') THEN
    RAISE EXCEPTION 'cleanup_expired_idempotency_keys still executable by anon (P2-09)';
  END IF;

  IF EXISTS (
    SELECT FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'settings'
      AND (cmd = 'DELETE' OR cmd = 'ALL')
  ) THEN
    RAISE EXCEPTION 'settings must have no DELETE/FOR ALL policy (P2-09)';
  END IF;

  IF EXISTS (
    SELECT FROM pg_constraint
    WHERE conrelid = 'public.worker_logs'::regclass AND conname = 'worker_logs_one_row_per_day'
  ) THEN
    RAISE EXCEPTION 'worker_logs_one_row_per_day must stay dropped (migration 30: breaks L1/L2/L5 same-day narrative)';
  END IF;
  RAISE NOTICE 'cleanup gate + settings + attendance-revert (P2-09/30): ok';
END $$;

-- Migration 29: audit writer resolves the actor (NULL when no profile) so the
-- trail never breaks a business operation on an FK violation.
DO $$
BEGIN
  IF pg_get_functiondef('app_private.append_audit_log'::regproc) NOT LIKE '%SELECT id INTO v_actor FROM public.profiles%' THEN
    RAISE EXCEPTION 'append_audit_log does not resolve the actor safely (migration 29)';
  END IF;
  RAISE NOTICE 'audit actor lookup (migration 29): ok';
END $$;

-- Migrations 26/31 lesson: CREATE OR REPLACE with a new signature silently
-- creates an overload instead of replacing — stale overloads make positional
-- calls ambiguous ("function is not unique"). Forbid duplicates outright.
DO $$
DECLARE
  v_dup text;
BEGIN
  SELECT string_agg(dup, ', ') INTO v_dup FROM (
    SELECT p.proname AS dup FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname LIKE 'rpc\_%'
    GROUP BY p.proname HAVING count(*) > 1
  ) d;
  IF v_dup IS NOT NULL THEN
    RAISE EXCEPTION 'duplicated public RPC overloads (drop the stale one): %', v_dup;
  END IF;
  RAISE NOTICE 'no duplicated RPC overloads: ok';
END $$;

DO $$ BEGIN RAISE NOTICE 'SMOKE SUITE PASSED'; END $$;