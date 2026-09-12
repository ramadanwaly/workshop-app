-- ============================================================================
-- seed.sql — Subcontract concurrency test fixture provisioning (run BEFORE consumers)
-- Inserts: test owner profile, test project, active subcontract order (total = 100)
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
    'subconcurrency-test@example.test',
    'x',
    '{}',
    '{}',
    NOW(),
    NOW()
)
-- Bare DO NOTHING: the stable fixture identity may already exist (id or
-- email), and that is fine — re-runs reuse it.
ON CONFLICT DO NOTHING;

-- handle_new_user only auto-creates a profile when the table is empty
-- (first-user-as-owner). Once a real owner exists, fixture users get no
-- profile, so a payment RPC that sets created_by = user.id would violate the
-- profiles FK. Create the profile explicitly (owner) before the money moves.
INSERT INTO public.profiles (id, full_name, role)
VALUES (:'c_user'::uuid, 'Subconcurrency Test Owner', 'owner')
ON CONFLICT (id) DO UPDATE SET role = 'owner';

INSERT INTO public.projects (id, name, status)
VALUES (:'c_project'::uuid, 'Subconcurrency Test Project', 'active');

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
    'Concurrency Contractor',
    'race-condition fixture',
    100.00,
    'active'
);

SELECT :'c_user'::uuid AS user_id, :'c_project'::uuid AS project_id, :'c_order'::uuid AS order_id;