-- ============================================================================
-- 20260905000001_initial_schema.sql
-- PHASE 1: Complete PostgreSQL Schema for Workshop Management System
-- ============================================================================

-- 1. Helper Function: Update timestamps trigger
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. Table: settings
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overhead_percentage NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (overhead_percentage >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_settings
    BEFORE UPDATE ON public.settings
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 3. Table: profiles (Extends auth.users)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_profiles
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 4. Table: projects
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'on_hold', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_projects
    BEFORE UPDATE ON public.projects
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 5. Table: treasury_transactions (Pure Cash Movement Log)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.treasury_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('in', 'out')),
    category TEXT NOT NULL CHECK (
        category IN (
            'owner_funding',
            'material',
            'freight',
            'advance',
            'settlement',
            'subcontract_payment',
            'general_expense',
            'carried_forward_advance',
            'other'
        )
    ),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,
    is_direct_owner_payment BOOLEAN NOT NULL DEFAULT false,
    is_voided BOOLEAN NOT NULL DEFAULT false,
    voided_at TIMESTAMPTZ,
    void_reason TEXT,
    voided_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraint: Direct owner payments are non-cash for treasury, always type 'out' logically
    CONSTRAINT check_direct_owner_payment_type CHECK (
        NOT is_direct_owner_payment OR transaction_type = 'out'
    )
);

CREATE INDEX idx_treasury_transactions_category ON public.treasury_transactions(category);
CREATE INDEX idx_treasury_transactions_project_id ON public.treasury_transactions(project_id);
CREATE INDEX idx_treasury_transactions_is_voided ON public.treasury_transactions(is_voided);

CREATE TRIGGER set_timestamp_treasury_transactions
    BEFORE UPDATE ON public.treasury_transactions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 6. Table: surplus_bank (Inventory of Reusable Materials)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.surplus_bank (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_name TEXT NOT NULL,
    unit TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL CHECK (quantity >= 0),
    initial_quantity NUMERIC(12,2) NOT NULL CHECK (initial_quantity > 0),
    estimated_value NUMERIC(12,2) NOT NULL CHECK (estimated_value >= 0),
    source_project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'consumed', 'scrapped')),
    parent_surplus_id UUID REFERENCES public.surplus_bank(id) ON DELETE RESTRICT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_surplus_bank_status ON public.surplus_bank(status);
CREATE INDEX idx_surplus_bank_source_project ON public.surplus_bank(source_project_id);

CREATE TRIGGER set_timestamp_surplus_bank
    BEFORE UPDATE ON public.surplus_bank
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 7. Table: project_cost_adjustments (Surplus Returns, Consumptions & Scraps)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.project_cost_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,
    adjustment_type TEXT NOT NULL CHECK (
        adjustment_type IN ('surplus_return', 'surplus_consumption', 'surplus_scrap')
    ),
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    surplus_id UUID REFERENCES public.surplus_bank(id) ON DELETE RESTRICT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Invariant: Scrap write-offs must not be linked to any project (general workshop loss)
    CONSTRAINT check_scrap_no_project CHECK (
        (adjustment_type = 'surplus_scrap' AND project_id IS NULL) OR
        (adjustment_type != 'surplus_scrap' AND project_id IS NOT NULL)
    )
);

CREATE INDEX idx_project_cost_adjustments_project_id ON public.project_cost_adjustments(project_id);

CREATE TRIGGER set_timestamp_project_cost_adjustments
    BEFORE UPDATE ON public.project_cost_adjustments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 8. Table: workers
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    daily_rate NUMERIC(10,2) NOT NULL CHECK (daily_rate > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_workers
    BEFORE UPDATE ON public.workers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 9. Table: worker_logs (Daily Attendance & Wage Calculation)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worker_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE RESTRICT,
    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    fraction NUMERIC(3,2) NOT NULL CHECK (fraction IN (0.25, 0.50, 1.00)),
    daily_rate NUMERIC(10,2) NOT NULL CHECK (daily_rate > 0),
    calculated_amount NUMERIC(10,2) NOT NULL GENERATED ALWAYS AS (daily_rate * fraction) STORED,
    is_settled BOOLEAN NOT NULL DEFAULT false,
    settlement_id UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_logs_worker_id ON public.worker_logs(worker_id);
CREATE INDEX idx_worker_logs_is_settled ON public.worker_logs(is_settled);
CREATE INDEX idx_worker_logs_project_id ON public.worker_logs(project_id);

CREATE TRIGGER set_timestamp_worker_logs
    BEFORE UPDATE ON public.worker_logs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 10. Table: worker_advances
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worker_advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE RESTRICT,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,
    is_settled BOOLEAN NOT NULL DEFAULT false,
    settlement_id UUID,
    is_carried_forward BOOLEAN NOT NULL DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_advances_worker_id ON public.worker_advances(worker_id);
CREATE INDEX idx_worker_advances_is_settled ON public.worker_advances(is_settled);

CREATE TRIGGER set_timestamp_worker_advances
    BEFORE UPDATE ON public.worker_advances
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 11. Table: subcontract_orders (Accrual Point for Subcontracts)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subcontract_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
    contractor_name TEXT NOT NULL,
    description TEXT NOT NULL,
    total_agreed_amount NUMERIC(12,2) NOT NULL CHECK (total_agreed_amount > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subcontract_orders_project_id ON public.subcontract_orders(project_id);

CREATE TRIGGER set_timestamp_subcontract_orders
    BEFORE UPDATE ON public.subcontract_orders
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 12. Table: subcontract_payments (Cash Reductions of Liability)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subcontract_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subcontract_order_id UUID NOT NULL REFERENCES public.subcontract_orders(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,
    is_voided BOOLEAN NOT NULL DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subcontract_payments_order_id ON public.subcontract_payments(subcontract_order_id);

CREATE TRIGGER set_timestamp_subcontract_payments
    BEFORE UPDATE ON public.subcontract_payments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 13. Table: general_expenses (Non-project overheads paid from Treasury)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.general_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_general_expenses
    BEFORE UPDATE ON public.general_expenses
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 14. Table: idempotency_keys (Double-Submit & Concurrency Guard)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.idempotency_keys (
    key TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
    response_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX idx_idempotency_keys_expires_at ON public.idempotency_keys(expires_at);

-- ----------------------------------------------------------------------------
-- 15. Idempotent Profile Creation Trigger on auth.users
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    users_count INT;
    assigned_role TEXT;
BEGIN
    SELECT COUNT(*) INTO users_count FROM public.profiles;
    IF users_count = 0 THEN
        assigned_role := 'owner';
    ELSE
        assigned_role := 'manager';
    END IF;

    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
        assigned_role
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Insert default settings row if not exists
INSERT INTO public.settings (overhead_percentage)
VALUES (10.00)
ON CONFLICT DO NOTHING;
