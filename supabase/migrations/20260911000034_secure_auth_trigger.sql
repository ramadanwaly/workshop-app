-- ============================================================================
-- 20260911000034_secure_auth_trigger.sql
-- M-03: First-User Owner Assignment Race Condition Fix
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    users_count INT;
BEGIN
    -- Acquire transaction-level advisory lock to serialize parallel signups
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

COMMIT;
