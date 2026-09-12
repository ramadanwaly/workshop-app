-- =============================================================================
-- Migration: 20260910000022_amount_upper_bounds.sql
-- Purpose  : P2-01 — explicit upper-bound CHECKs on money columns.
--            Zod (lib/validations/money.ts) rejects absurd values in Arabic
--            first; these CHECKs are defense-in-depth for direct database
--            access. Bounds mirror the NUMERIC widths (12,2 → 9999999999.99;
--            10,2 → 99999999.99) so no legitimate value is affected.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS treasury_amount_upper_bound;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT treasury_amount_upper_bound CHECK (amount <= 9999999999.99);

ALTER TABLE public.subcontract_orders
    DROP CONSTRAINT IF EXISTS subcontract_orders_amount_upper_bound;
ALTER TABLE public.subcontract_orders
    ADD CONSTRAINT subcontract_orders_amount_upper_bound CHECK (total_agreed_amount <= 9999999999.99);

ALTER TABLE public.subcontract_payments
    DROP CONSTRAINT IF EXISTS subcontract_payments_amount_upper_bound;
ALTER TABLE public.subcontract_payments
    ADD CONSTRAINT subcontract_payments_amount_upper_bound CHECK (amount <= 9999999999.99);

ALTER TABLE public.project_cost_adjustments
    DROP CONSTRAINT IF EXISTS cost_adj_amount_upper_bound;
ALTER TABLE public.project_cost_adjustments
    ADD CONSTRAINT cost_adj_amount_upper_bound CHECK (amount <= 9999999999.99);

ALTER TABLE public.surplus_bank
    DROP CONSTRAINT IF EXISTS surplus_bank_amounts_upper_bound;
ALTER TABLE public.surplus_bank
    ADD CONSTRAINT surplus_bank_amounts_upper_bound CHECK (
        quantity <= 9999999999.99
        AND initial_quantity <= 9999999999.99
        AND estimated_value <= 9999999999.99
    );

ALTER TABLE public.workers
    DROP CONSTRAINT IF EXISTS workers_rate_upper_bound;
ALTER TABLE public.workers
    ADD CONSTRAINT workers_rate_upper_bound CHECK (daily_rate <= 99999999.99);

ALTER TABLE public.worker_logs
    DROP CONSTRAINT IF EXISTS worker_logs_rate_upper_bound;
ALTER TABLE public.worker_logs
    ADD CONSTRAINT worker_logs_rate_upper_bound CHECK (daily_rate <= 99999999.99);

ALTER TABLE public.worker_advances
    DROP CONSTRAINT IF EXISTS worker_advances_amount_upper_bound;
ALTER TABLE public.worker_advances
    ADD CONSTRAINT worker_advances_amount_upper_bound CHECK (amount <= 99999999.99);

ALTER TABLE public.general_expenses
    DROP CONSTRAINT IF EXISTS general_expenses_amount_upper_bound;
ALTER TABLE public.general_expenses
    ADD CONSTRAINT general_expenses_amount_upper_bound CHECK (amount <= 99999999.99);
