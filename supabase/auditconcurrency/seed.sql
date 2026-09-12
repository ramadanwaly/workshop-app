-- ============================================================================
-- seed.sql — Audit concurrency fixture (run BEFORE consumers)
-- Inserts: test owner profile, test project, subcontract order (agreed 30000)
-- Runs with autocommit (psql), so the two consumer sessions see the row.
-- Accepts psql variables: c_user, c_project, c_order
-- Stable fixture identity (migration 29): c_user is resolved by its fixed
-- email and reused across runs, so re-runs never collide with leftovers.
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
    'audit-concurrency-test@example.test',
    'x',
    '{}',
    '{}',
    NOW(),
    NOW()
)
-- Bare DO NOTHING: the stable fixture identity may already exist (id or
-- email), and that is fine — re-runs reuse it.
ON CONFLICT DO NOTHING;

-- Phase 9 hardened handle_new_user: subsequent users get NO profile row,
-- so grant the role explicitly (per migration 20260905000010).
INSERT INTO public.profiles (id, full_name, role)
VALUES (:'c_user'::uuid, 'Audit Concurrency Owner', 'owner')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

INSERT INTO public.projects (id, name, status)
VALUES (:'c_project'::uuid, 'Audit Concurrency Project', 'active');

INSERT INTO public.subcontract_orders (
    id,
    project_id,
    contractor_name,
    description,
    total_agreed_amount,
    status
) VALUES (
    :'c_order'::uuid,
    :'c_project'::uuid,
    'Audit Concurrency Contractor',
    'audit race job',
    30000.00,
    'active'
);

SELECT :'c_user'::uuid AS user_id, :'c_project'::uuid AS project_id, :'c_order'::uuid AS order_id;
