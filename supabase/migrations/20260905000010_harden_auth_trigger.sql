-- ============================================================================
-- 20260905000010_harden_auth_trigger.sql
-- PHASE 9: Security & Concurrency Audit — close privileged self-registration
--
-- Previous behaviour: handle_new_user granted the first user 'owner' and every
-- subsequent signed-up user 'manager' automatically. With a public domain and
-- a client-visible anon key, anyone could call auth.signUp() and instantly
-- receive manager access (read all financial data, record expenses/attendance/
-- surplus). Privilege escalation via open registration.
--
-- New behaviour (defense-in-depth, independent of server settings):
--   - first profile (empty profiles table)  => 'owner'
--   - any subsequent user                   => NO profile row (no access at all)
--
-- Roles are now granted exclusively by the owner, e.g.:
--   INSERT INTO public.profiles (id, full_name, role)
--   VALUES ('<auth-users-id>', 'اسم المدير', 'manager')
--   ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;
--
-- Server-side requirement (out of band, Supabase Auth settings): disable
-- "Allow new users to sign up". The owner's own account must be created FIRST
-- while the profiles table is still empty.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    users_count INT;
BEGIN
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