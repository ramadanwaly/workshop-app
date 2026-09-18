-- =============================================================================
-- Migration: 20260918000056_health_schema_check.sql
-- Purpose  : Create a function to verify essential schema objects exist.
--            Used by the /api/health/schema endpoint to ensure migrations
--            have been properly applied to the database.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.rpc_health_schema_check()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
    v_audit_exists boolean;
    v_view_exists boolean;
BEGIN
    -- Check if the audit_log table exists
    SELECT EXISTS (
        SELECT FROM pg_tables
        WHERE schemaname = 'app_private'
        AND tablename  = 'audit_log'
    ) INTO v_audit_exists;

    -- Check if a vital view exists
    SELECT EXISTS (
        SELECT FROM pg_views
        WHERE schemaname = 'public'
        AND viewname   = 'v_treasury_balance'
    ) INTO v_view_exists;

    RETURN v_audit_exists AND v_view_exists;
END;
$$;

-- Grant execution to anon and authenticated for the health check
GRANT EXECUTE ON FUNCTION public.rpc_health_schema_check() TO anon, authenticated;
