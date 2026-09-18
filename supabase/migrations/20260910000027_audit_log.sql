-- =============================================================================
-- Migration: 20260910000027_audit_log.sql
-- Purpose  : P2-06 — permanent immutable audit log (SQ-34/35/45 follow-up).
--            Every money-destroying or reallocating operation already requires
--            a reason (P2-03, migration 24); this table preserves those reasons
--            forever, including rpc_remove_operating_exclusion whose DELETE
--            otherwise erases the row (the reason was only "echoed in the
--            result meanwhile" until now).
--            Writes flow ONLY through app_private.append_audit_log()
--            (SECURITY DEFINER, postgres-owned, bypasses RLS); direct INSERT
--            by clients is denied (no INSERT policy). Reads are owner-only.
--            UPDATE/DELETE are impossible: no policies + a blocking trigger.
--            Automatic triggers log voids/closes/cost-reallocations; the two
--            exclusion RPCs log explicitly so the removal reason survives.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table: audit_log (append-only, one row per corrective/reallocating event)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actor_id UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    action TEXT NOT NULL CHECK (
        action IN (
            'void_treasury',
            'void_subcontract_payment',
            'close_subcontract_order',
            'return_surplus',
            'consume_surplus',
            'scrap_surplus',
            'run_operating_allocation',
            'void_allocation_cycle',
            'void_allocation_line',
            'add_operating_exclusion',
            'remove_operating_exclusion'
        )
    ),
    entity_table TEXT NOT NULL CHECK (
        entity_table IN (
            'treasury_transactions',
            'subcontract_payments',
            'subcontract_orders',
            'surplus_bank',
            'project_cost_adjustments',
            'operating_allocation_cycles',
            'operating_allocation_exclusions'
        )
    ),
    entity_id UUID,
    reason TEXT,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT audit_log_reason_bounds CHECK (
        char_length(coalesce(reason, '')) <= 1000
    )
);

CREATE INDEX IF NOT EXISTS idx_audit_log_occurred
    ON public.audit_log(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action
    ON public.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity
    ON public.audit_log(entity_table, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor
    ON public.audit_log(actor_id);

DROP TRIGGER IF EXISTS set_timestamp_audit_log ON public.audit_log;
CREATE TRIGGER set_timestamp_audit_log
    BEFORE UPDATE ON public.audit_log
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 2. RLS: owner-only reads; NO insert/update/delete policies (deny by default).
--    All writes go through app_private.append_audit_log() below, which runs
--    as postgres (table owner bypasses RLS). Direct client INSERTs fail.
-- ----------------------------------------------------------------------------
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_select_owner" ON public.audit_log;
CREATE POLICY "audit_select_owner" ON public.audit_log
    FOR SELECT TO authenticated
    USING (app_private.is_owner());

GRANT SELECT ON public.audit_log TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.audit_log FROM authenticated, anon, PUBLIC;

-- ----------------------------------------------------------------------------
-- 3. Immutability guard: even the owner cannot rewrite history.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_audit_log_mutation()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RAISE EXCEPTION 'سجل التدقيق دائم ولا يمكن تعديله أو حذفه';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_log_immutable ON public.audit_log;
CREATE TRIGGER trg_audit_log_immutable
    BEFORE UPDATE OR DELETE ON public.audit_log
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_audit_log_mutation();

-- ----------------------------------------------------------------------------
-- 4. Single writer: app_private.append_audit_log (SECURITY DEFINER).
--    Granted to authenticated so staff-triggered RPCs (e.g. manager surplus
--    consume/scrap) can leave a trail; managers still cannot READ the log
--    (SELECT policy is owner-only) nor write it directly (no INSERT policy).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.append_audit_log(
    p_action TEXT,
    p_entity_table TEXT,
    p_entity_id UUID,
    p_reason TEXT DEFAULT NULL,
    p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.audit_log (actor_id, action, entity_table, entity_id, reason, details)
    VALUES (auth.uid(), p_action, p_entity_table, p_entity_id, p_reason, coalesce(p_details, '{}'::jsonb))
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION app_private.append_audit_log(TEXT, TEXT, UUID, TEXT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION app_private.append_audit_log(TEXT, TEXT, UUID, TEXT, JSONB) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. Automatic triggers: voids / closes / cost-reallocations.
--    (Exclusions are logged inside their RPCs instead — section 6 — because
--    the removal reason lives only in the RPC parameter, not in the row.)
-- ----------------------------------------------------------------------------

-- 5a. Treasury void (covers the Server-Action direct UPDATE path too).
CREATE OR REPLACE FUNCTION app_private.trg_log_treasury_void()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_treasury', 'treasury_transactions', NEW.id, NEW.void_reason,
            jsonb_build_object(
                'amount', NEW.amount,
                'category', NEW.category,
                'transaction_type', NEW.transaction_type
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_treasury_void ON public.treasury_transactions;
CREATE TRIGGER trg_audit_treasury_void
    AFTER UPDATE ON public.treasury_transactions
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_treasury_void();

-- 5b. Subcontract payment void.
CREATE OR REPLACE FUNCTION app_private.trg_log_subpay_void()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_subcontract_payment', 'subcontract_payments', NEW.id, NEW.void_reason,
            jsonb_build_object('amount', NEW.amount, 'order_id', NEW.subcontract_order_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_subpay_void ON public.subcontract_payments;
CREATE TRIGGER trg_audit_subpay_void
    AFTER UPDATE ON public.subcontract_payments
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_subpay_void();

-- 5c. Subcontract order close (completed / cancelled).
CREATE OR REPLACE FUNCTION app_private.trg_log_suborder_close()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.status = 'active' AND NEW.status IN ('completed', 'cancelled') THEN
        PERFORM app_private.append_audit_log(
            'close_subcontract_order', 'subcontract_orders', NEW.id, NEW.close_reason,
            jsonb_build_object('status', NEW.status, 'total_agreed_amount', NEW.total_agreed_amount)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_suborder_close ON public.subcontract_orders;
CREATE TRIGGER trg_audit_suborder_close
    AFTER UPDATE ON public.subcontract_orders
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_suborder_close();

-- 5d. Cost-adjustment INSERT: surplus return / consumption / scrap.
--     Operating-allocation LINES are intentionally NOT logged here — the
--     cycle row (5f) is the single audit entry per monthly run, otherwise
--     one run would flood the log with one row per eligible project.
CREATE OR REPLACE FUNCTION app_private.trg_log_cost_adj_insert()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_action TEXT;
BEGIN
    v_action := CASE NEW.adjustment_type
        WHEN 'surplus_return' THEN 'return_surplus'
        WHEN 'surplus_consumption' THEN 'consume_surplus'
        WHEN 'surplus_scrap' THEN 'scrap_surplus'
        ELSE NULL
    END;
    IF v_action IS NOT NULL THEN
        PERFORM app_private.append_audit_log(
            v_action, 'project_cost_adjustments', NEW.id, NEW.notes,
            jsonb_build_object(
                'adjustment_type', NEW.adjustment_type,
                'amount', NEW.amount,
                'project_id', NEW.project_id,
                'surplus_id', NEW.surplus_id,
                'operating_cycle_id', NEW.operating_cycle_id
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_cost_adj_insert ON public.project_cost_adjustments;
CREATE TRIGGER trg_audit_cost_adj_insert
    AFTER INSERT ON public.project_cost_adjustments
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_cost_adj_insert();

-- 5e. Allocation LINE void (single-line correction by the owner).
CREATE OR REPLACE FUNCTION app_private.trg_log_cost_adj_void()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE
        AND NEW.adjustment_type = 'operating_allocation' THEN
        PERFORM app_private.append_audit_log(
            'void_allocation_line', 'project_cost_adjustments', NEW.id, NEW.void_reason,
            jsonb_build_object('amount', NEW.amount, 'project_id', NEW.project_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_cost_adj_void ON public.project_cost_adjustments;
CREATE TRIGGER trg_audit_cost_adj_void
    AFTER UPDATE ON public.project_cost_adjustments
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_cost_adj_void();

-- 5f. Allocation CYCLE run (insert) — one audit row per monthly run.
CREATE OR REPLACE FUNCTION app_private.trg_log_alloc_cycle_insert()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM app_private.append_audit_log(
        'run_operating_allocation', 'operating_allocation_cycles', NEW.id, NEW.notes,
        jsonb_build_object(
            'year_month', NEW.year_month,
            'status', NEW.status,
            'total_amount', NEW.total_amount
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_alloc_cycle_insert ON public.operating_allocation_cycles;
CREATE TRIGGER trg_audit_alloc_cycle_insert
    AFTER INSERT ON public.operating_allocation_cycles
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_alloc_cycle_insert();

-- 5g. Allocation CYCLE void (whole-month correction by the owner).
CREATE OR REPLACE FUNCTION app_private.trg_log_alloc_cycle_void()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_allocation_cycle', 'operating_allocation_cycles', NEW.id, NEW.void_reason,
            jsonb_build_object('year_month', NEW.year_month, 'total_amount', NEW.total_amount)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_alloc_cycle_void ON public.operating_allocation_cycles;
CREATE TRIGGER trg_audit_alloc_cycle_void
    AFTER UPDATE ON public.operating_allocation_cycles
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_alloc_cycle_void();

-- ----------------------------------------------------------------------------
-- 6. Exclusion RPCs: log explicitly so the reason survives the DELETE.
--    (A DELETE trigger could not see the RPC's p_reason parameter.)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_add_operating_exclusion(
    p_year_month DATE, p_project_id UUID, p_reason TEXT DEFAULT NULL
)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;
    INSERT INTO public.operating_allocation_exclusions (year_month, project_id, reason, created_by)
    VALUES (date_trunc('month', p_year_month)::date, p_project_id, p_reason, auth.uid())
    ON CONFLICT (year_month, project_id) DO NOTHING;
    PERFORM app_private.append_audit_log(
        'add_operating_exclusion', 'operating_allocation_exclusions', p_project_id, p_reason,
        jsonb_build_object('year_month', date_trunc('month', p_year_month)::date, 'project_id', p_project_id)
    );
    RETURN jsonb_build_object('year_month', date_trunc('month', p_year_month)::date,
        'project_id', p_project_id, 'added', true);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_remove_operating_exclusion(
    p_year_month DATE, p_project_id UUID, p_reason TEXT DEFAULT NULL
)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإزالة (3 أحرف على الأقل)';
    END IF;
    PERFORM app_private.append_audit_log(
        'remove_operating_exclusion', 'operating_allocation_exclusions', p_project_id, p_reason,
        jsonb_build_object('year_month', date_trunc('month', p_year_month)::date, 'project_id', p_project_id)
    );
    DELETE FROM public.operating_allocation_exclusions
    WHERE year_month = date_trunc('month', p_year_month)::date AND project_id = p_project_id;
    RETURN jsonb_build_object('removed', true, 'reason', p_reason);
END;
$$ LANGUAGE plpgsql;
