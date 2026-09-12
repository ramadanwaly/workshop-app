-- =============================================================================
-- Migration: 20260910000019_no_hard_delete_policies.sql
-- Purpose  : P1-05 — remove hard DELETE from financial RLS policies.
--            Every FOR ALL policy below implicitly allowed DELETE, so any staff
--            member (or owner) with direct database access could permanently
--            delete wages, advances, subcontracts or surplus rows, violating the
--            rule (no hard delete — void only via is_voided).
--            Each policy is split into SELECT (kept as-is) + INSERT + UPDATE
--            with the SAME role check it had before. No DELETE policy means
--            DELETE is denied by default. Legit flows are unaffected: the app
--            only INSERTs and UPDATEs these tables (void = UPDATE is_voided).
--            Out of scope here (later phases): settings FOR ALL (P2-09) and
--            operating exclusions DELETE (P2-03, needs a reason column first).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. surplus_bank (was: staff FOR ALL) → staff INSERT + staff UPDATE
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "surplus_bank_insert_update" ON public.surplus_bank;

DROP POLICY IF EXISTS "surplus_bank_insert" ON public.surplus_bank;
CREATE POLICY "surplus_bank_insert" ON public.surplus_bank
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_staff());

DROP POLICY IF EXISTS "surplus_bank_update" ON public.surplus_bank;
CREATE POLICY "surplus_bank_update" ON public.surplus_bank
    FOR UPDATE TO authenticated
    USING (app_private.is_staff())
    WITH CHECK (app_private.is_staff());

-- ----------------------------------------------------------------------------
-- 2. worker_logs (was: staff FOR ALL) → staff INSERT + staff UPDATE
--    Attendance RPC inserts rows; settlement RPC flips is_settled — both stay.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "worker_logs_insert_update" ON public.worker_logs;

DROP POLICY IF EXISTS "worker_logs_insert" ON public.worker_logs;
CREATE POLICY "worker_logs_insert" ON public.worker_logs
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_staff());

DROP POLICY IF EXISTS "worker_logs_update" ON public.worker_logs;
CREATE POLICY "worker_logs_update" ON public.worker_logs
    FOR UPDATE TO authenticated
    USING (app_private.is_staff())
    WITH CHECK (app_private.is_staff());

-- ----------------------------------------------------------------------------
-- 3. worker_advances (was: owner FOR ALL) → owner INSERT + owner UPDATE
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "worker_advances_insert_update" ON public.worker_advances;

DROP POLICY IF EXISTS "worker_advances_insert" ON public.worker_advances;
CREATE POLICY "worker_advances_insert" ON public.worker_advances
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

DROP POLICY IF EXISTS "worker_advances_update" ON public.worker_advances;
CREATE POLICY "worker_advances_update" ON public.worker_advances
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 4. subcontract_orders (was: owner FOR ALL) → owner INSERT + owner UPDATE
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "subcontract_orders_modify" ON public.subcontract_orders;

DROP POLICY IF EXISTS "subcontract_orders_insert" ON public.subcontract_orders;
CREATE POLICY "subcontract_orders_insert" ON public.subcontract_orders
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

DROP POLICY IF EXISTS "subcontract_orders_update" ON public.subcontract_orders;
CREATE POLICY "subcontract_orders_update" ON public.subcontract_orders
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 5. subcontract_payments (was: owner FOR ALL) → owner INSERT + owner UPDATE
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "subcontract_payments_modify" ON public.subcontract_payments;

DROP POLICY IF EXISTS "subcontract_payments_insert" ON public.subcontract_payments;
CREATE POLICY "subcontract_payments_insert" ON public.subcontract_payments
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

DROP POLICY IF EXISTS "subcontract_payments_update" ON public.subcontract_payments;
CREATE POLICY "subcontract_payments_update" ON public.subcontract_payments
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 6. general_expenses (was: owner FOR ALL + staff INSERT) → keep staff INSERT,
--    owner UPDATE only. No DELETE.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "general_expenses_modify" ON public.general_expenses;

DROP POLICY IF EXISTS "general_expenses_update" ON public.general_expenses;
CREATE POLICY "general_expenses_update" ON public.general_expenses
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());
