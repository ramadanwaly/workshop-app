-- ============================================================================
-- 20260905000012_operating_allocation.sql
-- AMENDMENT 1: Treasury categories/subcategories + Monthly Workshop Operating Allocation
-- Owner-approved on 2026-09-06. Engine unreachable via API (app_private, EXECUTE postgres-only).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. treasury_transactions: category CHECK + workshop_operating, subcategory
-- ----------------------------------------------------------------------------
ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS treasury_transactions_category_check;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT treasury_transactions_category_check CHECK (
        category IN (
            'owner_funding', 'material', 'freight', 'advance', 'settlement',
            'subcontract_payment', 'general_expense', 'carried_forward_advance',
            'other', 'workshop_operating'
        )
    );

ALTER TABLE public.treasury_transactions
    ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- subcategory may only pair with its owning category
ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS treasury_subcategory_pairing;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT treasury_subcategory_pairing CHECK (
        subcategory IS NULL
        OR (category = 'material'   AND subcategory IN ('wood_boards','upholstery_fabric_textile','foam_filling','hardware_hinges','glue_adhesives','paints_varnishes','glass_mirrors','small_fasteners','consumables_tools','machine_maintenance'))
        OR (category = 'freight'    AND subcategory IN ('site_transport','merchant_transport','workshop_machine_transport','tools_site_transport','completed_work_transport'))
        OR (category = 'workshop_operating' AND subcategory IN ('electricity','rent','waste_collection'))
    );

-- subcategory is mandatory exactly for the three classified categories
ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS treasury_subcategory_required;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT treasury_subcategory_required CHECK (
        category NOT IN ('material', 'freight', 'workshop_operating')
        OR subcategory IS NOT NULL
    );

-- workshop_operating is never linked to a project
ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS check_workshop_operating_no_project;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT check_workshop_operating_no_project CHECK (
        category <> 'workshop_operating' OR project_id IS NULL
    );

CREATE INDEX IF NOT EXISTS idx_treasury_transactions_subcategory
    ON public.treasury_transactions(subcategory);
CREATE INDEX IF NOT EXISTS idx_treasury_workshop_operating
    ON public.treasury_transactions(created_at)
    WHERE category = 'workshop_operating' AND NOT is_voided AND NOT is_direct_owner_payment;

-- ----------------------------------------------------------------------------
-- 2. project_cost_adjustments: operating_allocation type + void semantics
-- ----------------------------------------------------------------------------
ALTER TABLE public.project_cost_adjustments
    DROP CONSTRAINT IF EXISTS project_cost_adjustments_adjustment_type_check;
ALTER TABLE public.project_cost_adjustments
    ADD CONSTRAINT project_cost_adjustments_adjustment_type_check CHECK (
        adjustment_type IN ('surplus_return', 'surplus_consumption', 'surplus_scrap', 'operating_allocation')
    );

ALTER TABLE public.project_cost_adjustments
    ADD COLUMN IF NOT EXISTS is_voided BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS voided_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS void_reason TEXT,
    ADD COLUMN IF NOT EXISTS voided_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS operating_cycle_id UUID;

CREATE INDEX IF NOT EXISTS idx_project_cost_adjustments_voided
    ON public.project_cost_adjustments(is_voided);
CREATE INDEX IF NOT EXISTS idx_project_cost_adjustments_cycle
    ON public.project_cost_adjustments(operating_cycle_id);

-- Manager must never fabricate allocation lines directly (RLS boundary)
DROP POLICY IF EXISTS "cost_adj_insert" ON public.project_cost_adjustments;
CREATE POLICY "cost_adj_insert" ON public.project_cost_adjustments
    FOR INSERT TO authenticated
    WITH CHECK (
        app_private.is_staff()
        AND (adjustment_type <> 'operating_allocation' OR app_private.is_owner())
    );

-- ----------------------------------------------------------------------------
-- 3. operating_allocation_cycles
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.operating_allocation_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_month DATE NOT NULL CHECK (year_month = date_trunc('month', year_month)::date),
    status TEXT NOT NULL CHECK (status IN ('applied', 'noop')),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    eligible_project_ids UUID[],
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    is_voided BOOLEAN NOT NULL DEFAULT false,
    voided_at TIMESTAMPTZ,
    voided_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    void_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Idempotency: exactly one non-voided cycle per month
CREATE UNIQUE INDEX IF NOT EXISTS uq_operating_cycles_month_active
    ON public.operating_allocation_cycles(year_month)
    WHERE NOT is_voided;

CREATE TRIGGER set_timestamp_operating_allocation_cycles
    BEFORE UPDATE ON public.operating_allocation_cycles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 4. operating_allocation_exclusions (owner config for a specific month)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.operating_allocation_exclusions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_month DATE NOT NULL CHECK (year_month = date_trunc('month', year_month)::date),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,
    reason TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_operating_exclusion_month_project UNIQUE (year_month, project_id)
);

-- ----------------------------------------------------------------------------
-- 5. RLS on the new tables (writes flow through the secured RPCs only)
-- ----------------------------------------------------------------------------
ALTER TABLE public.operating_allocation_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operating_allocation_exclusions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cycles_select_staff" ON public.operating_allocation_cycles;
CREATE POLICY "cycles_select_staff" ON public.operating_allocation_cycles
    FOR SELECT TO authenticated USING (app_private.is_staff());

DROP POLICY IF EXISTS "exclusions_select_staff" ON public.operating_allocation_exclusions;
CREATE POLICY "exclusions_select_staff" ON public.operating_allocation_exclusions
    FOR SELECT TO authenticated USING (app_private.is_staff());
DROP POLICY IF EXISTS "exclusions_insert_owner" ON public.operating_allocation_exclusions;
CREATE POLICY "exclusions_insert_owner" ON public.operating_allocation_exclusions
    FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());
DROP POLICY IF EXISTS "exclusions_delete_owner" ON public.operating_allocation_exclusions;
CREATE POLICY "exclusions_delete_owner" ON public.operating_allocation_exclusions
    FOR DELETE TO authenticated USING (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 6. The engine — app_private, EXECUTE postgres-only (owner-approved grants)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.run_operating_allocation(
    p_year_month DATE
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_month_start   DATE;
    v_month_end     DATE;
    v_total         NUMERIC(12,2);
    v_cycle_id      UUID;
    v_eligible      UUID[] := NULL;
    v_excluded      UUID[] := NULL;
    v_count         INT;
    v_total_cents   BIGINT;
    v_share_cents   BIGINT;
    v_remainder     INT;
    v_amt           NUMERIC(12,2);
    v_alloc_sum     NUMERIC(12,2) := 0;
    v_note          TEXT;
    i               INT;
BEGIN
    v_month_start := date_trunc('month', p_year_month)::date;
    v_month_end   := (v_month_start + INTERVAL '1 month')::date;

    -- 1. Idempotency: one non-voided cycle per month (partial unique index guarantees <= 1)
    SELECT c.id INTO v_cycle_id
    FROM public.operating_allocation_cycles c
    WHERE c.year_month = v_month_start AND NOT c.is_voided;

    IF v_cycle_id IS NOT NULL THEN
        RETURN jsonb_build_object('status', 'already_exists', 'cycle_id', v_cycle_id);
    END IF;

    -- 2. Lock + sum the month's valid operating expenses
    -- (FOR UPDATE cannot combine with SUM in PG 14+; lock rows first via temp table)
    CREATE TEMP TABLE _locked_operating AS
        SELECT tt.amount
        FROM public.treasury_transactions tt
        WHERE tt.category = 'workshop_operating'
          AND NOT tt.is_voided
          AND NOT tt.is_direct_owner_payment
          AND tt.created_at >= v_month_start
          AND tt.created_at <  v_month_end
        FOR UPDATE;
    SELECT COALESCE(SUM(amount), 0) INTO v_total FROM _locked_operating;
    DROP TABLE _locked_operating;

    IF v_total = 0 THEN
        INSERT INTO public.operating_allocation_cycles (year_month, status, total_amount, notes, created_by)
        VALUES (v_month_start, 'noop', 0, 'لا توجد مصاريف تشغيل لهذا الشهر', auth.uid())
        RETURNING id INTO v_cycle_id;
        RETURN jsonb_build_object('status', 'noop', 'month', v_month_start,
            'cycle_id', v_cycle_id, 'total_amount', 0, 'allocated_lines', 0);
    END IF;

    -- 3. Primary pool: projects with recorded activity DATED IN the month (cancelled excluded)
    SELECT ARRAY_AGG(p.id ORDER BY p.id)
    INTO v_eligible
    FROM public.projects p
    WHERE p.status <> 'cancelled'
      AND (
          EXISTS (SELECT 1 FROM public.worker_logs wl
                  WHERE wl.project_id = p.id AND wl.log_date >= v_month_start AND wl.log_date < v_month_end)
          OR EXISTS (SELECT 1 FROM public.treasury_transactions tt
                     WHERE tt.project_id = p.id AND NOT tt.is_voided
                       AND tt.created_at >= v_month_start AND tt.created_at < v_month_end)
          OR EXISTS (SELECT 1 FROM public.subcontract_orders so
                     WHERE so.project_id = p.id AND so.status <> 'cancelled'
                       AND so.created_at >= v_month_start AND so.created_at < v_month_end)
          OR EXISTS (SELECT 1 FROM public.project_cost_adjustments pca
                     WHERE pca.project_id = p.id AND NOT pca.is_voided
                       AND pca.created_at >= v_month_start AND pca.created_at < v_month_end)
          OR (p.created_at >= v_month_start AND p.created_at < v_month_end)
      );

    -- 4. Fallback pool when the activity pool is empty: completed/on_hold (never cancelled)
    IF v_eligible IS NULL OR cardinality(v_eligible) = 0 THEN
        SELECT ARRAY_AGG(p.id ORDER BY p.id)
        INTO v_eligible
        FROM public.projects p
        WHERE p.status IN ('completed', 'on_hold');
        v_note := 'حوض بديل: لا يوجد نشاط مسجل في الشهر';
    END IF;

    -- 5. Apply per-cycle exclusions; the excluded share is redistributed equally among the rest
    SELECT ARRAY_AGG(e.project_id)
    INTO v_excluded
    FROM public.operating_allocation_exclusions e
    WHERE e.year_month = v_month_start;

    IF v_excluded IS NOT NULL AND cardinality(v_excluded) > 0 THEN
        SELECT ARRAY(SELECT x FROM unnest(v_eligible) x
                     EXCEPT SELECT y FROM unnest(v_excluded) y
                     ORDER BY 1)
        INTO v_eligible;
    END IF;

    IF v_eligible IS NULL OR cardinality(v_eligible) = 0 THEN
        INSERT INTO public.operating_allocation_cycles (year_month, status, total_amount, notes, created_by)
        VALUES (v_month_start, 'noop', v_total, 'لا توجد مشاريع مؤهلة بعد الاستبعادات', auth.uid())
        RETURNING id INTO v_cycle_id;
        RETURN jsonb_build_object('status', 'noop', 'month', v_month_start,
            'cycle_id', v_cycle_id, 'total_amount', v_total, 'allocated_lines', 0);
    END IF;

    -- 6. Equal shares, exact cents: floor to 2 decimals, leftover as 0.01 to the first projects
    v_count       := cardinality(v_eligible);
    v_total_cents := (v_total * 100)::BIGINT;
    v_share_cents := FLOOR(v_total_cents::NUMERIC / v_count)::BIGINT;
    v_remainder   := (v_total_cents - v_share_cents * v_count)::INT;

    INSERT INTO public.operating_allocation_cycles
        (year_month, status, total_amount, eligible_project_ids, notes, created_by)
    VALUES (v_month_start, 'applied', v_total, v_eligible, v_note, auth.uid())
    RETURNING id INTO v_cycle_id;

    FOR i IN 1..v_count LOOP
        v_amt := (v_share_cents + CASE WHEN i <= v_remainder THEN 1 ELSE 0 END) / 100.0;
        INSERT INTO public.project_cost_adjustments
            (project_id, adjustment_type, amount, notes, operating_cycle_id)
        VALUES
            (v_eligible[i], 'operating_allocation', v_amt,
             'نصيب شهري من مصاريف تشغيل الورشة (' || to_char(v_month_start, 'YYYY-MM') || ')',
             v_cycle_id);
        v_alloc_sum := v_alloc_sum + v_amt;
    END LOOP;

    RETURN jsonb_build_object('status', 'applied', 'month', v_month_start, 'cycle_id', v_cycle_id,
        'total_amount', v_total, 'allocated_lines', v_count, 'allocated_sum', v_alloc_sum);
EXCEPTION
    WHEN unique_violation THEN
        -- concurrent run lost the race; the winner's commitment now exists
        RETURN jsonb_build_object('status', 'already_exists', 'note', 'concurrent run detected');
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION app_private.run_operating_allocation(DATE) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION app_private.run_operating_allocation(DATE) FROM anon;
REVOKE EXECUTE ON FUNCTION app_private.run_operating_allocation(DATE) FROM authenticated;
REVOKE EXECUTE ON FUNCTION app_private.run_operating_allocation(DATE) FROM service_role;
GRANT EXECUTE ON FUNCTION app_private.run_operating_allocation(DATE) TO postgres;

-- ----------------------------------------------------------------------------
-- 7. Owner-only public wrappers (SECURITY DEFINER + is_owner gate)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_run_operating_allocation(p_year_month DATE)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: تشغيل توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;
    RETURN app_private.run_operating_allocation(p_year_month);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_void_allocation_cycle(p_cycle_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
DECLARE v_cycle RECORD;
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء دورة توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;

    SELECT * INTO v_cycle
    FROM public.operating_allocation_cycles
    WHERE id = p_cycle_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'دورة التوزيع غير موجودة'; END IF;
    IF v_cycle.is_voided THEN RAISE EXCEPTION 'هذه الدورة ملغاة بالفعل مسبقاً'; END IF;

    UPDATE public.project_cost_adjustments
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء كامل لدورة التوزيع الشهري'),
        voided_by = auth.uid()
    WHERE operating_cycle_id = p_cycle_id AND NOT is_voided;

    UPDATE public.operating_allocation_cycles
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء دورة التوزيع الشهري'),
        voided_by = auth.uid()
    WHERE id = p_cycle_id;

    RETURN jsonb_build_object('cycle_id', p_cycle_id, 'voided', true);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_void_allocation_line(p_adjustment_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
DECLARE v_adj public.project_cost_adjustments%ROWTYPE;
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء أسطر توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;

    SELECT * INTO v_adj
    FROM public.project_cost_adjustments
    WHERE id = p_adjustment_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'سطر التوزيع غير موجود'; END IF;
    IF v_adj.adjustment_type <> 'operating_allocation' THEN
        RAISE EXCEPTION 'هذا السطر ليس سطر توزيع مصاريف تشغيل';
    END IF;
    IF v_adj.is_voided THEN RAISE EXCEPTION 'هذا السطر ملغى بالفعل مسبقاً'; END IF;

    UPDATE public.project_cost_adjustments
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء سطر توزيع'),
        voided_by = auth.uid()
    WHERE id = p_adjustment_id;

    RETURN jsonb_build_object('adjustment_id', p_adjustment_id, 'voided', true);
END;
$$ LANGUAGE plpgsql;

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
    RETURN jsonb_build_object('year_month', date_trunc('month', p_year_month)::date,
        'project_id', p_project_id, 'added', true);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_remove_operating_exclusion(
    p_year_month DATE, p_project_id UUID
)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    DELETE FROM public.operating_allocation_exclusions
    WHERE year_month = date_trunc('month', p_year_month)::date AND project_id = p_project_id;
    RETURN jsonb_build_object('removed', true);
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 8. v_project_direct_costs: add operating_cost term; void-aware surplus
-- ----------------------------------------------------------------------------
-- The column set changes (operating_cost added), so OR REPLACE alone is rejected
-- by PostgreSQL — drop first to stay replayable on clean databases.
DROP VIEW IF EXISTS public.v_project_direct_costs;
CREATE OR REPLACE VIEW public.v_project_direct_costs AS
WITH project_materials AS (
    SELECT project_id, COALESCE(SUM(amount), 0) AS material_cost
    FROM public.treasury_transactions
    WHERE category = 'material' AND NOT is_voided AND project_id IS NOT NULL
    GROUP BY project_id
),
project_freight AS (
    SELECT project_id, COALESCE(SUM(amount), 0) AS freight_cost
    FROM public.treasury_transactions
    WHERE category = 'freight' AND NOT is_voided AND project_id IS NOT NULL
    GROUP BY project_id
),
project_labor AS (
    SELECT project_id, COALESCE(SUM(calculated_amount), 0) AS labor_cost
    FROM public.worker_logs
    WHERE project_id IS NOT NULL
    GROUP BY project_id
),
project_subcontracts AS (
    SELECT project_id, COALESCE(SUM(total_agreed_amount), 0) AS subcontract_cost
    FROM public.subcontract_orders
    WHERE status IN ('active', 'completed')
    GROUP BY project_id
),
cancelled_subcontract_cost AS (
    SELECT so.project_id, COALESCE(SUM(sp.amount), 0) AS paid_cost
    FROM public.subcontract_orders so
    LEFT JOIN public.subcontract_payments sp
        ON sp.subcontract_order_id = so.id AND NOT sp.is_voided
    WHERE so.status = 'cancelled'
    GROUP BY so.project_id
),
project_surplus AS (
    SELECT project_id,
        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_return' THEN amount ELSE 0 END), 0) AS surplus_returns,
        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_consumption' THEN amount ELSE 0 END), 0) AS surplus_consumptions
    FROM public.project_cost_adjustments
    WHERE project_id IS NOT NULL AND NOT is_voided
    GROUP BY project_id
),
project_operating AS (
    SELECT project_id, COALESCE(SUM(amount), 0) AS operating_cost
    FROM public.project_cost_adjustments
    WHERE adjustment_type = 'operating_allocation' AND NOT is_voided AND project_id IS NOT NULL
    GROUP BY project_id
),
current_settings AS (
    SELECT overhead_percentage FROM public.settings
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT
    p.id AS project_id,
    p.name AS project_name,
    p.status AS project_status,
    COALESCE(pm.material_cost, 0) AS material_cost,
    COALESCE(pf.freight_cost, 0) AS freight_cost,
    COALESCE(pl.labor_cost, 0) AS labor_cost,
    COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) AS subcontract_cost,
    COALESCE(psurp.surplus_returns, 0) AS surplus_returns,
    COALESCE(psurp.surplus_consumptions, 0) AS surplus_consumptions,
    COALESCE(pop.operating_cost, 0) AS operating_cost,
    -- Direct Cost Equation (incl. operating allocation term)
    (
        COALESCE(pm.material_cost, 0) +
        COALESCE(pf.freight_cost, 0) +
        COALESCE(pl.labor_cost, 0) +
        COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -
        COALESCE(psurp.surplus_returns, 0) +
        COALESCE(psurp.surplus_consumptions, 0) +
        COALESCE(pop.operating_cost, 0)
    ) AS direct_project_cost,
    s.overhead_percentage,
    ROUND(
        (
            COALESCE(pm.material_cost, 0) +
            COALESCE(pf.freight_cost, 0) +
            COALESCE(pl.labor_cost, 0) +
            COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -
            COALESCE(psurp.surplus_returns, 0) +
            COALESCE(psurp.surplus_consumptions, 0) +
            COALESCE(pop.operating_cost, 0)
        ) * (1 + s.overhead_percentage / 100.0),
        2
    ) AS estimated_total_cost
FROM public.projects p
CROSS JOIN current_settings s
LEFT JOIN project_materials pm ON p.id = pm.project_id
LEFT JOIN project_freight pf ON p.id = pf.project_id
LEFT JOIN project_labor pl ON p.id = pl.project_id
LEFT JOIN project_subcontracts psub ON p.id = psub.project_id
LEFT JOIN cancelled_subcontract_cost csc ON p.id = csc.project_id
LEFT JOIN project_surplus psurp ON p.id = psurp.project_id
LEFT JOIN project_operating pop ON p.id = pop.project_id;

ALTER VIEW public.v_project_direct_costs SET (security_invoker = true);
