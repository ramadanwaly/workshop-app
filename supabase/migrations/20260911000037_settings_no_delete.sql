-- ============================================================================
-- Migration: 20260911000037_settings_no_delete.sql
-- Purpose: VULN-03 Remediation - Ensure settings table has no DELETE policy
--   Settings rows are critical system parameters and must never be deleted.
-- ============================================================================

-- Drop any lingering FOR ALL policies on public.settings
DROP POLICY IF EXISTS "settings_modify_owner_only" ON public.settings;
DROP POLICY IF EXISTS "settings_delete_owner_only" ON public.settings;

-- Explicitly ensure standard non-deletable policies: SELECT (staff), INSERT (owner), UPDATE (owner)
DROP POLICY IF EXISTS "settings_select" ON public.settings;
CREATE POLICY "settings_select" ON public.settings
    FOR SELECT TO authenticated
    USING (app_private.is_staff());

DROP POLICY IF EXISTS "settings_insert_owner_only" ON public.settings;
CREATE POLICY "settings_insert_owner_only" ON public.settings
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

DROP POLICY IF EXISTS "settings_update_owner_only" ON public.settings;
CREATE POLICY "settings_update_owner_only" ON public.settings
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());
