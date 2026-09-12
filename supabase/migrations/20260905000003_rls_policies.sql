-- ============================================================================
-- 20260905000003_rls_policies.sql
-- PHASE 1.2: Row-Level Security (RLS) & Role-Based Authorization
-- ============================================================================

-- 1. Helper function to get the current user's role securely
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 2. Helper function to check if user is owner
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS BOOLEAN AS $$
    SELECT (public.current_user_role() = 'owner');
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 3. Helper function to check if user is manager or owner
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN AS $$
    SELECT (public.current_user_role() IN ('owner', 'manager'));
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Enable RLS on ALL Application Tables
-- ----------------------------------------------------------------------------
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surplus_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_cost_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcontract_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcontract_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.general_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idempotency_keys ENABLE ROW LEVEL SECURITY;

-- Ensure Views respect RLS
ALTER VIEW public.v_treasury_balance SET (security_invoker = true);
ALTER VIEW public.v_project_direct_costs SET (security_invoker = true);
ALTER VIEW public.v_pending_liabilities SET (security_invoker = true);

-- ----------------------------------------------------------------------------
-- POLICIES: settings
-- ----------------------------------------------------------------------------
CREATE POLICY "settings_select" ON public.settings
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "settings_modify_owner_only" ON public.settings
    FOR ALL TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

-- ----------------------------------------------------------------------------
-- POLICIES: profiles
-- ----------------------------------------------------------------------------
CREATE POLICY "profiles_select" ON public.profiles
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "profiles_update" ON public.profiles
    FOR UPDATE TO authenticated
    USING (public.is_owner() OR id = auth.uid())
    WITH CHECK (
        -- User can update their name, but cannot self-promote to owner
        public.is_owner() OR (
            id = auth.uid() AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
        )
    );

-- ----------------------------------------------------------------------------
-- POLICIES: projects
-- ----------------------------------------------------------------------------
CREATE POLICY "projects_select" ON public.projects
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "projects_insert" ON public.projects
    FOR INSERT TO authenticated WITH CHECK (public.is_staff());

CREATE POLICY "projects_update" ON public.projects
    FOR UPDATE TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

-- ----------------------------------------------------------------------------
-- POLICIES: treasury_transactions
-- ----------------------------------------------------------------------------
CREATE POLICY "treasury_select" ON public.treasury_transactions
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "treasury_insert" ON public.treasury_transactions
    FOR INSERT TO authenticated
    WITH CHECK (
        public.is_staff() AND (
            -- Owner funding, advances, and settlements require owner role
            (category NOT IN ('owner_funding', 'advance', 'settlement')) OR public.is_owner()
        )
    );

CREATE POLICY "treasury_update_void_owner_only" ON public.treasury_transactions
    FOR UPDATE TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

-- NO DELETE POLICY on treasury_transactions (Hard delete prohibited)

-- ----------------------------------------------------------------------------
-- POLICIES: surplus_bank & project_cost_adjustments
-- ----------------------------------------------------------------------------
CREATE POLICY "surplus_bank_select" ON public.surplus_bank
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "surplus_bank_insert_update" ON public.surplus_bank
    FOR ALL TO authenticated
    USING (public.is_staff())
    WITH CHECK (public.is_staff());

CREATE POLICY "cost_adj_select" ON public.project_cost_adjustments
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "cost_adj_insert" ON public.project_cost_adjustments
    FOR INSERT TO authenticated WITH CHECK (public.is_staff());

-- ----------------------------------------------------------------------------
-- POLICIES: workers & worker_logs
-- ----------------------------------------------------------------------------
CREATE POLICY "workers_select" ON public.workers
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "workers_insert_update" ON public.workers
    FOR ALL TO authenticated
    USING (public.is_staff())
    WITH CHECK (public.is_staff());

CREATE POLICY "worker_logs_select" ON public.worker_logs
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "worker_logs_insert_update" ON public.worker_logs
    FOR ALL TO authenticated
    USING (public.is_staff())
    WITH CHECK (public.is_staff());

-- ----------------------------------------------------------------------------
-- POLICIES: worker_advances (Owner Only for mutations)
-- ----------------------------------------------------------------------------
CREATE POLICY "worker_advances_select" ON public.worker_advances
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "worker_advances_insert_update" ON public.worker_advances
    FOR ALL TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

-- ----------------------------------------------------------------------------
-- POLICIES: subcontract_orders & subcontract_payments (Owner Only for mutations)
-- ----------------------------------------------------------------------------
CREATE POLICY "subcontract_orders_select" ON public.subcontract_orders
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "subcontract_orders_modify" ON public.subcontract_orders
    FOR ALL TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

CREATE POLICY "subcontract_payments_select" ON public.subcontract_payments
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "subcontract_payments_modify" ON public.subcontract_payments
    FOR ALL TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

-- ----------------------------------------------------------------------------
-- POLICIES: general_expenses
-- ----------------------------------------------------------------------------
CREATE POLICY "general_expenses_select" ON public.general_expenses
    FOR SELECT TO authenticated USING (public.is_staff());

CREATE POLICY "general_expenses_insert" ON public.general_expenses
    FOR INSERT TO authenticated WITH CHECK (public.is_staff());

CREATE POLICY "general_expenses_modify" ON public.general_expenses
    FOR ALL TO authenticated
    USING (public.is_owner())
    WITH CHECK (public.is_owner());

-- ----------------------------------------------------------------------------
-- POLICIES: idempotency_keys
-- ----------------------------------------------------------------------------
CREATE POLICY "idempotency_keys_user" ON public.idempotency_keys
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
