-- ============================================================================
-- 20260905000011_workers_rls_owner_only.sql
-- Enforcement of the principle "the database is the real boundary":
-- workers must be created/edited/deleted ONLY by the owner at the row level,
-- not merely hidden in the UI or gated in a server action.
--
-- Previously the RLS write policy was staff-wide (is_staff): a manager with
-- direct database access (or a caller bypassing the app) could create/update
-- workers. This closes that gap so create/update workers is owner-only at the
-- database boundary. The read policy stays staff-wide (manager still needs to
-- view workers to record attendance).
-- ============================================================================

-- Drop the old staff-wide write policy
DROP POLICY IF EXISTS "workers_insert_update" ON public.workers;

-- Owner-only INSERT (avoid duplicate policy errors if re-run)
DROP POLICY IF EXISTS "workers_insert_owner_only" ON public.workers;
CREATE POLICY "workers_insert_owner_only" ON public.workers
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

-- Owner-only UPDATE (and DELETE is disallowed entirely; workers are soft-managed via is_active)
DROP POLICY IF EXISTS "workers_update_owner_only" ON public.workers;
CREATE POLICY "workers_update_owner_only" ON public.workers
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());

-- Keep read open to staff (manager must view workers to record attendance)
DROP POLICY IF EXISTS "workers_select" ON public.workers;
CREATE POLICY "workers_select" ON public.workers
    FOR SELECT TO authenticated USING (app_private.is_staff());
