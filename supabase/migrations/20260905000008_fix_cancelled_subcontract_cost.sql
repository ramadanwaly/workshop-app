-- ============================================================================
-- 20260905000008_fix_cancelled_subcontract_cost.sql
-- PHASE 5 FIX: Correct project cost for a CANCELLED subcontract order.
--
-- Old behaviour (bug): v_project_direct_costs excluded a cancelled order
-- entirely (status != 'cancelled'), dropping the FULL agreed amount from
-- project cost — including the portion that was actually paid.
--
-- New behaviour (financially correct): a cancelled order contributes ONLY its
-- valid (non-voided) paid portion to project cost; the unpaid obligation is
-- reversed at cancellation (it was an estimated recognition that no longer
-- applies). v_pending_liabilities already excludes non-active orders, so the
-- unpaid portion correctly stops being a pending liability on cancellation.
-- ============================================================================

CREATE OR REPLACE VIEW public.v_project_direct_costs AS
WITH project_materials AS (
    -- المواد تشمل الكاش والدفع المباشر طالما ليست ملغاة
    SELECT
        project_id,
        COALESCE(SUM(amount), 0) AS material_cost
    FROM public.treasury_transactions
    WHERE category = 'material'
      AND NOT is_voided
      AND project_id IS NOT NULL
    GROUP BY project_id
),
project_freight AS (
    -- النولون المربوط بالمشروع حصراً
    SELECT
        project_id,
        COALESCE(SUM(amount), 0) AS freight_cost
    FROM public.treasury_transactions
    WHERE category = 'freight'
      AND NOT is_voided
      AND project_id IS NOT NULL
    GROUP BY project_id
),
project_labor AS (
    -- أجور العمال المربوطة بالمشروع
    SELECT
        project_id,
        COALESCE(SUM(calculated_amount), 0) AS labor_cost
    FROM public.worker_logs
    WHERE project_id IS NOT NULL
    GROUP BY project_id
),
project_subcontracts AS (
    -- تكلفة مقاولي الباطن تعتمد عند توقيع الاتفاق (Accrual basis)
    -- للمتفق عليه في الاتفاقيات النشطة أو المكتملة
    SELECT
        project_id,
        COALESCE(SUM(total_agreed_amount), 0) AS subcontract_cost
    FROM public.subcontract_orders
    WHERE status IN ('active', 'completed')
    GROUP BY project_id
),
cancelled_subcontract_cost AS (
    -- الاتفاقية الملغاة: يبقى فقط الجزء المدفوع فعلاً (غير الملغى) حقيقياً
    -- على المشروع، ويُرجع الجزء غير المدفوع (لم يعد التزاماً ولا تكلفة حقيقية)
    SELECT
        so.project_id,
        COALESCE(SUM(sp.amount), 0) AS paid_cost
    FROM public.subcontract_orders so
    LEFT JOIN public.subcontract_payments sp
        ON sp.subcontract_order_id = so.id
       AND NOT sp.is_voided
    WHERE so.status = 'cancelled'
    GROUP BY so.project_id
),
project_surplus AS (
    -- عوائد الفائض تطرح، واستهلاك الفائض يضاف
    SELECT
        project_id,
        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_return' THEN amount ELSE 0 END), 0) AS surplus_returns,
        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_consumption' THEN amount ELSE 0 END), 0) AS surplus_consumptions
    FROM public.project_cost_adjustments
    WHERE project_id IS NOT NULL
    GROUP BY project_id
),
current_settings AS (
    SELECT overhead_percentage
    FROM public.settings
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
    -- Direct Cost Equation:
    -- materials + freight + labor + subcontracts - surplus_returns + surplus_consumptions
    (
        COALESCE(pm.material_cost, 0) +
        COALESCE(pf.freight_cost, 0) +
        COALESCE(pl.labor_cost, 0) +
        COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -
        COALESCE(psurp.surplus_returns, 0) +
        COALESCE(psurp.surplus_consumptions, 0)
    ) AS direct_project_cost,
    s.overhead_percentage,
    ROUND(
        (
            COALESCE(pm.material_cost, 0) +
            COALESCE(pf.freight_cost, 0) +
            COALESCE(pl.labor_cost, 0) +
            COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -
            COALESCE(psurp.surplus_returns, 0) +
            COALESCE(psurp.surplus_consumptions, 0)
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
LEFT JOIN project_surplus psurp ON p.id = psurp.project_id;

-- CREATE OR REPLACE VIEW resets options to defaults; re-assert security_invoker
-- so base-table RLS still applies to the view (financial audit requirement).
ALTER VIEW public.v_project_direct_costs SET (security_invoker = true);