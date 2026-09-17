-- ============================================================================
-- verify_workers_rls.sql — RLS proof that workers writes are OWNER-ONLY at the
-- database boundary (migration 20260905000011_workers_rls_owner_only.sql).
--
-- The database is the real security boundary. This test proves it genuinely
-- against the live database by impersonating the Postgres `authenticated` role
-- with real auth.uid() JWT claims:
--   - a MANAGER (auth.uid() -> profiles.role='manager') CANNOT INSERT/UPDATE workers
--   - the OWNER  (auth.uid() -> profiles.role='owner')  CAN INSERT/UPDATE   (positive control)
--   - the MANAGER can still SELECT workers                (read stays staff-open)
--
-- IMPORTANT: to exercise row-level policies the session runs AS the `authenticated`
-- role (SET ROLE authenticated). A session as postgres bypasses RLS because table
-- owners are exempt — a naive run as postgres would wrongly report a pass.
-- Seeding/cleanup run as postgres.
--
-- Creates and deletes ONLY its own fixture rows (two auth.users/profiles, two
-- throwaway workers). Follows verify_labor.sql conventions.
-- ============================================================================
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset pager off

CREATE TEMP TABLE _fix AS
SELECT
    gen_random_uuid() AS owner_id,
    gen_random_uuid() AS manager_id,
    gen_random_uuid() AS worker_id;

-- Pre-clean any orphaned fixtures from an aborted prior run (as postgres)
DELETE FROM public.worker_logs
WHERE worker_id IN (SELECT id FROM public.workers WHERE name IN ('Worker RLS Test','Owner RLS Insert'));
DELETE FROM public.worker_advances
WHERE worker_id IN (SELECT id FROM public.workers WHERE name IN ('Worker RLS Test','Owner RLS Insert'));
DELETE FROM public.workers WHERE name IN ('Worker RLS Test','Owner RLS Insert');
DELETE FROM public.profiles WHERE id IN (
    SELECT id FROM auth.users WHERE email LIKE 'workers-rls-%@example.test');
DELETE FROM auth.users WHERE email LIKE 'workers-rls-%@example.test';

-- ---------------------------------------------------------------------------
-- Seed an owner and a manager (as postgres) so auth.uid() resolves to a role
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) SELECT
    id, '00000000-0000-0000-0000-000000000000', 'authenticated',
    'authenticated', 'workers-rls-' || id::text || '@example.test', 'x', '{}', '{}', NOW(), NOW()
FROM _fix
CROSS JOIN LATERAL (VALUES (1, owner_id), (2, manager_id)) t(ord, id);

UPDATE public.profiles SET role = 'owner'   WHERE id = (SELECT owner_id   FROM _fix);
UPDATE public.profiles SET role = 'manager' WHERE id = (SELECT manager_id FROM _fix);

-- The on_auth_user_created trigger only seeds a profile for the FIRST user, so
-- for our throwaway auth.users we must insert the profile rows explicitly.
-- (Profiles drive app_private.is_owner()/is_staff() via auth.uid().)
INSERT INTO public.profiles (id, full_name, role) VALUES
    ((SELECT owner_id   FROM _fix), 'Worker RLS Owner',   'owner'),
    ((SELECT manager_id FROM _fix), 'Worker RLS Manager', 'manager')
ON CONFLICT (id) DO NOTHING;

-- owner seeds a throwaway worker (owner policy allows INSERT) that the manager
-- will later try to UPDATE. IDs are loaded into local vars BEFORE switching role,
-- because the authenticated role cannot read the postgres-owned temp table _fix.
DO $$
DECLARE v_owner uuid := (SELECT owner_id   FROM _fix);
        v_wid   uuid := (SELECT worker_id  FROM _fix);
BEGIN
    PERFORM set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', v_owner), false);
    SET LOCAL ROLE authenticated;
    INSERT INTO public.workers (id, name, daily_rate, is_active)
    VALUES (v_wid, 'Worker RLS Test', 150.00, true);
    RESET ROLE;
END $$;

-- ---------------------------------------------------------------------------
-- NEGATIVE: MANAGER direct INSERT must be rejected by RLS; nothing written.
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_manager uuid := (SELECT manager_id FROM _fix);
BEGIN
    PERFORM set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', v_manager), false);
    SET LOCAL ROLE authenticated;

    BEGIN
        INSERT INTO public.workers (name, daily_rate, is_active)
        VALUES ('Manager RLS Insert', 150.00, true);
        RAISE EXCEPTION 'MANAGER_SHOULD_BE_REJECTED_INSERT';
    EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%MANAGER_SHOULD_BE_REJECTED_INSERT%' THEN
            RAISE EXCEPTION 'RLS FAIL: manager INSERT into workers was NOT rejected';
        END IF;
        IF SQLERRM NOT LIKE '%row-level security%' THEN
            RAISE EXCEPTION 'RLS: unexpected manager insert error: %', SQLERRM;
        END IF;
    END;

    RESET ROLE;
END $$;

-- Confirm the rejected manager insert wrote nothing, and report success.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.workers WHERE name='Manager RLS Insert') THEN
        RAISE EXCEPTION 'RLS FAIL: rejected manager insert still wrote a row';
    END IF;
    RAISE NOTICE 'RLS_MANAGER_INSERT_REJECTED_OK';
END $$;

-- ---------------------------------------------------------------------------
-- NEGATIVE: MANAGER direct UPDATE must be rejected (owner-only update policy).
-- UPDATE-level RLS silently filters rows (0 rows affected) rather than raising,
-- so the correct assertion is: the manager's UPDATE must change NOTHING.
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_manager uuid := (SELECT manager_id FROM _fix);
        v_wid      uuid := (SELECT worker_id  FROM _fix);
        v_affected bigint;
        v_rate     numeric;
BEGIN
    SELECT daily_rate INTO v_rate FROM public.workers WHERE id = v_wid; -- 150.00

    PERFORM set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', v_manager), false);
    SET LOCAL ROLE authenticated;

    UPDATE public.workers SET daily_rate = 999.00 WHERE id = v_wid;
    GET DIAGNOSTICS v_affected = ROW_COUNT;

    RESET ROLE;

    IF v_affected > 0 THEN
        RAISE EXCEPTION 'RLS FAIL: manager UPDATE affected % row(s); owner-only update policy not enforced', v_affected;
    END IF;
    IF EXISTS (SELECT 1 FROM public.workers WHERE id = v_wid AND daily_rate = 999.00) THEN
        RAISE EXCEPTION 'RLS FAIL: manager UPDATE actually changed the row';
    END IF;
    RAISE NOTICE 'RLS_MANAGER_UPDATE_REJECTED_OK (0 rows affected)';
END $$;

-- ---------------------------------------------------------------------------
-- POSITIVE: MANAGER can still SELECT the worker (read stays staff-open)
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_manager uuid := (SELECT manager_id FROM _fix);
        v_wid      uuid := (SELECT worker_id  FROM _fix);
        v_cnt      bigint;
BEGIN
    PERFORM set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', v_manager), false);
    SET LOCAL ROLE authenticated;
    SELECT count(*) INTO v_cnt FROM public.workers WHERE id = v_wid;
    RESET ROLE;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'RLS FAIL: manager could not SELECT worker (read must stay staff-open)';
    END IF;
    RAISE NOTICE 'RLS_MANAGER_SELECT_OK (read stays staff-open)';
END $$;

-- ---------------------------------------------------------------------------
-- POSITIVE CONTROL: OWNER can INSERT and UPDATE workers
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_owner uuid := (SELECT owner_id  FROM _fix);
        v_wid   uuid := (SELECT worker_id FROM _fix);
BEGIN
    PERFORM set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', v_owner), false);
    SET LOCAL ROLE authenticated;

    INSERT INTO public.workers (name, daily_rate, is_active)
    VALUES ('Owner RLS Insert', 160.00, true);

    UPDATE public.workers SET daily_rate = 170.00 WHERE id = v_wid;

    RESET ROLE;
END $$;

DO $$
DECLARE v_wid uuid := (SELECT worker_id FROM _fix);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.workers WHERE name='Owner RLS Insert') THEN
        RAISE EXCEPTION 'RLS FAIL: owner INSERT did not take effect';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.workers
                   WHERE id = v_wid AND daily_rate = 170.00) THEN
        RAISE EXCEPTION 'RLS FAIL: owner UPDATE did not take effect';
    END IF;
    RAISE NOTICE 'RLS_OWNER_INSERT_UPDATE_OK (owner allowed)';
END $$;

-- ---------------------------------------------------------------------------
-- Explicit cleanup (we seeded our own rows only)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    DELETE FROM public.worker_logs WHERE worker_id = (SELECT worker_id FROM _fix);
    DELETE FROM public.worker_advances WHERE worker_id = (SELECT worker_id FROM _fix);
    DELETE FROM public.workers WHERE name IN ('Worker RLS Test','Owner RLS Insert','Manager RLS Insert');
    DELETE FROM public.profiles
    WHERE id IN ((SELECT owner_id FROM _fix), (SELECT manager_id FROM _fix));
    DELETE FROM auth.users
    WHERE id IN ((SELECT owner_id FROM _fix), (SELECT manager_id FROM _fix));
END $$;

\echo WORKERS_RLS_DB_TEST_DONE
