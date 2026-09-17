-- ============================================================================
-- Migration: 20260911000042_handle_new_user_lock.sql
-- Purpose: VULN-12 Remediation - Ensure advisory lock in handle_new_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    users_count INT;
BEGIN
    -- Acquire advisory lock to serialize concurrent first-user registration attempts
    PERFORM pg_advisory_xact_lock(74291);

    SELECT COUNT(*) INTO users_count FROM public.profiles;

    IF users_count = 0 THEN
        INSERT INTO public.profiles (id, full_name, role)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
            'owner'
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
