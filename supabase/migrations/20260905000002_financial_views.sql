-- ============================================================================
-- 20260905000002_financial_views.sql
-- PHASE 1.1: Authoritative Financial Views
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. View: v_treasury_balance
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_treasury_balance AS
SELECT
    COALESCE(SUM(amount) FILTER (
        WHERE transaction_type = 'in'
          AND NOT is_voided
          AND NOT is_direct_owner_payment
    ), 0) AS total_in,

    COALESCE(SUM(amount) FILTER (
        WHERE transaction_type = 'out'
          AND NOT is_voided
          AND NOT is_direct_owner_payment
    ), 0) AS total_out,

    COALESCE(SUM(
        CASE
            WHEN transaction_type = 'in' THEN amount
            WHEN transaction_type = 'out' THEN -amount
            ELSE 0
        END
    ) FILTER (
        WHERE NOT is_voided
          AND NOT is_direct_owner_payment
    ), 0) AS current_balance
FROM public.treasury_transactions;

-- ----------------------------------------------------------------------------
-- 2. View: v_project_direct_costs
-- ----------------------------------------------------------------------------
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
    SELECT
        project_id,
        COALESCE(SUM(total_agreed_amount), 0) AS subcontract_cost
    FROM public.subcontract_orders
    WHERE status != 'cancelled'
    GROUP BY project_id
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
    COALESCE(psub.subcontract_cost, 0) AS subcontract_cost,
    COALESCE(psurp.surplus_returns, 0) AS surplus_returns,
    COALESCE(psurp.surplus_consumptions, 0) AS surplus_consumptions,
    -- Direct Cost Equation:
    -- materials + freight + labor + subcontracts - surplus_returns + surplus_consumptions
    (
        COALESCE(pm.material_cost, 0) +
        COALESCE(pf.freight_cost, 0) +
        COALESCE(pl.labor_cost, 0) +
        COALESCE(psub.subcontract_cost, 0) -
        COALESCE(psurp.surplus_returns, 0) +
        COALESCE(psurp.surplus_consumptions, 0)
    ) AS direct_project_cost,
    s.overhead_percentage,
    ROUND(
        (
            COALESCE(pm.material_cost, 0) +
            COALESCE(pf.freight_cost, 0) +
            COALESCE(pl.labor_cost, 0) +
            COALESCE(psub.subcontract_cost, 0) -
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
LEFT JOIN project_surplus psurp ON p.id = psurp.project_id;

-- ----------------------------------------------------------------------------
-- 3. View: v_pending_liabilities (Worker Net Liabilities + Subcontract Balances)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_pending_liabilities AS
WITH worker_unsettled_wages AS (
    SELECT
        worker_id,
        COALESCE(SUM(calculated_amount), 0) AS total_wages
    FROM public.worker_logs
    WHERE NOT is_settled
    GROUP BY worker_id
),
worker_unsettled_advances AS (
    SELECT
        worker_id,
        COALESCE(SUM(amount), 0) AS total_advances
    FROM public.worker_advances
    WHERE NOT is_settled
    GROUP BY worker_id
),
worker_net_liabilities AS (
    -- التسوية لكل عامل على حدة: Net Payable = MAX(0, Wages - Advances)
    SELECT
        w.id AS worker_id,
        COALESCE(uw.total_wages, 0) AS unsettled_wages,
        COALESCE(ua.total_advances, 0) AS unsettled_advances,
        GREATEST(0, COALESCE(uw.total_wages, 0) - COALESCE(ua.total_advances, 0)) AS net_payable,
        GREATEST(0, COALESCE(ua.total_advances, 0) - COALESCE(uw.total_wages, 0)) AS carried_forward_credit
    FROM public.workers w
    LEFT JOIN worker_unsettled_wages uw ON w.id = uw.worker_id
    LEFT JOIN worker_unsettled_advances ua ON w.id = ua.worker_id
),
subcontract_balances AS (
    -- رصيد مقاول الباطن المتبقي = المتفق عليه - المسدد غير الملغى
    SELECT
        so.id AS subcontract_order_id,
        so.total_agreed_amount,
        COALESCE(SUM(sp.amount) FILTER (WHERE NOT sp.is_voided), 0) AS total_paid,
        (so.total_agreed_amount - COALESCE(SUM(sp.amount) FILTER (WHERE NOT sp.is_voided), 0)) AS remaining_balance
    FROM public.subcontract_orders so
    LEFT JOIN public.subcontract_payments sp ON so.id = sp.subcontract_order_id
    WHERE so.status = 'active'
    GROUP BY so.id, so.total_agreed_amount
)
SELECT
    COALESCE(SUM(net_payable), 0) AS total_worker_liabilities,
    COALESCE((SELECT SUM(remaining_balance) FROM subcontract_balances), 0) AS total_subcontract_liabilities,
    (
        COALESCE(SUM(net_payable), 0) +
        COALESCE((SELECT SUM(remaining_balance) FROM subcontract_balances), 0)
    ) AS total_pending_liabilities
FROM worker_net_liabilities;
