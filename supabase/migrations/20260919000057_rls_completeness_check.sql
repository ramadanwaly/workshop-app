-- =============================================================================
-- Migration: 20260919000057_rls_completeness_check.sql
-- Purpose  : RPC to verify all public tables have Row-Level Security (RLS) enabled.
--            Can be queried periodically or via automated smoke checks.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.rpc_check_rls_completeness()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_unprotected TEXT[];
BEGIN
    SELECT COALESCE(array_agg(c.relname::text), '{}')
    INTO v_unprotected
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relrowsecurity = false;

    IF array_length(v_unprotected, 1) IS NULL OR array_length(v_unprotected, 1) = 0 THEN
        RETURN jsonb_build_object(
            'healthy', true,
            'unprotected_count', 0,
            'unprotected_tables', '[]'::jsonb
        );
    ELSE
        RETURN jsonb_build_object(
            'healthy', false,
            'unprotected_count', array_length(v_unprotected, 1),
            'unprotected_tables', to_jsonb(v_unprotected)
        );
    END IF;
END;
$$;

-- Revoke default execute from PUBLIC and anon; grant only to authenticated role
REVOKE EXECUTE ON FUNCTION public.rpc_check_rls_completeness() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_check_rls_completeness() TO authenticated;
