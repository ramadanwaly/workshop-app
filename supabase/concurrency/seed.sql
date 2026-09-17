-- ============================================================================
-- seed.sql — Concurrency test fixture provisioning (run BEFORE consumers)
-- Inserts: test owner profile, target + source projects, surplus row (qty = 100)
-- NOTE (P2-03): surplus may NOT be consumed into its own source project, so
-- the surplus is sourced from c_source_project and consumed into c_project.
-- Runs with autocommit (psql), so the two consumer sessions see the row.
-- Accepts psql variables: c_user, c_project, c_source_project, c_surplus
-- ============================================================================
\set ON_ERROR_STOP on

INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    :'c_user'::uuid,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    -- Stable fixture identity (migration 29): its own email so re-runs
    -- never collide with one-off leftovers.
    'concurrency-stable@example.test',
    'x',
    '{}',
    '{}',
    NOW(),
    NOW()
)
-- Bare DO NOTHING: the stable fixture identity may already exist (id or
-- email), and that is fine — re-runs reuse it.
ON CONFLICT DO NOTHING;

-- Fixture identity: explicit profile row (the on_auth_user_created trigger
-- only covers the very first user, so fixtures must not rely on it).
-- Both inserts tolerate re-runs with the stable fixture identity.
INSERT INTO public.profiles (id, full_name, role)
VALUES (:'c_user'::uuid, 'Concurrency Test', 'owner')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.projects (id, name, status)
VALUES (:'c_project'::uuid, 'Concurrency Test Project', 'active');

INSERT INTO public.projects (id, name, status)
VALUES (:'c_source_project'::uuid, 'Concurrency Source Project', 'active');

INSERT INTO public.surplus_bank (
    id,
    material_name,
    unit,
    quantity,
    initial_quantity,
    estimated_value,
    source_project_id,
    status
) VALUES (
    :'c_surplus'::uuid,
    'Concurrency Test Material',
    'pcs',
    100,
    100,
    1000.00,
    :'c_source_project'::uuid,
    'available'
);

SELECT :'c_user'::uuid AS user_id, :'c_project'::uuid AS project_id, :'c_surplus'::uuid AS surplus_id;