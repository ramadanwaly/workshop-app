-- ============================================================================
-- 20260915000045_analytics_views.sql
-- PHASE 1: Analytics and Aggregation Views
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. View: v_monthly_treasury_stats
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_monthly_treasury_stats AS
SELECT
    DATE_TRUNC('month', created_at) AS month,
    COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'in'), 0) AS total_in,
    COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'out'), 0) AS total_out
FROM public.treasury_transactions
WHERE NOT is_voided
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY DATE_TRUNC('month', created_at) DESC;

ALTER VIEW public.v_monthly_treasury_stats SET (security_invoker = true);
REVOKE SELECT ON public.v_monthly_treasury_stats FROM PUBLIC;
REVOKE SELECT ON public.v_monthly_treasury_stats FROM anon;
GRANT SELECT ON public.v_monthly_treasury_stats TO authenticated;

COMMENT ON VIEW public.v_monthly_treasury_stats IS 'إحصائيات الخزنة مجمعة شهرياً (إيرادات ومصروفات) للحركات المعتمدة فقط.';

-- ----------------------------------------------------------------------------
-- 2. View: v_project_profitability
-- ----------------------------------------------------------------------------
-- We create a new view rather than modifying v_project_direct_costs to avoid
-- breaking any existing code that depends on its exact column structure.
-- This view joins v_project_direct_costs with aggregated revenues from treasury.
CREATE OR REPLACE VIEW public.v_project_profitability AS
WITH project_revenues AS (
    SELECT
        project_id,
        COALESCE(SUM(amount), 0) AS total_revenue
    FROM public.treasury_transactions
    WHERE transaction_type = 'in'
      AND NOT is_voided
      AND project_id IS NOT NULL
    GROUP BY project_id
)
SELECT
    pdc.*,
    COALESCE(pr.total_revenue, 0) AS total_revenue,
    (COALESCE(pr.total_revenue, 0) - pdc.estimated_total_cost) AS net_profit
FROM public.v_project_direct_costs pdc
LEFT JOIN project_revenues pr ON pdc.project_id = pr.project_id;

ALTER VIEW public.v_project_profitability SET (security_invoker = true);
REVOKE SELECT ON public.v_project_profitability FROM PUBLIC;
REVOKE SELECT ON public.v_project_profitability FROM anon;
GRANT SELECT ON public.v_project_profitability TO authenticated;

COMMENT ON VIEW public.v_project_profitability IS 'ربحية المشاريع: يدمج التكاليف المباشرة مع إجمالي الإيرادات لحساب صافي الربح أو الخسارة.';

-- ----------------------------------------------------------------------------
-- 3. View: v_worker_performance_stats
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_worker_performance_stats AS
WITH monthly_logs AS (
    SELECT
        worker_id,
        DATE_TRUNC('month', log_date) AS month,
        COALESCE(SUM(fraction), 0) AS total_days,
        COALESCE(SUM(calculated_amount), 0) AS total_wages
    FROM public.worker_logs
    GROUP BY worker_id, DATE_TRUNC('month', log_date)
),
monthly_advances AS (
    SELECT
        worker_id,
        DATE_TRUNC('month', advance_date) AS month,
        COALESCE(SUM(amount), 0) AS total_advances
    FROM public.worker_advances
    GROUP BY worker_id, DATE_TRUNC('month', advance_date)
),
all_months AS (
    SELECT worker_id, month FROM monthly_logs
    UNION
    SELECT worker_id, month FROM monthly_advances
)
SELECT
    am.worker_id,
    w.name AS worker_name,
    am.month,
    COALESCE(ml.total_days, 0) AS total_days,
    COALESCE(ml.total_wages, 0) AS total_wages,
    COALESCE(ma.total_advances, 0) AS total_advances
FROM all_months am
JOIN public.workers w ON am.worker_id = w.id
LEFT JOIN monthly_logs ml ON am.worker_id = ml.worker_id AND am.month = ml.month
LEFT JOIN monthly_advances ma ON am.worker_id = ma.worker_id AND am.month = ma.month
ORDER BY am.month DESC, w.name ASC;

ALTER VIEW public.v_worker_performance_stats SET (security_invoker = true);
REVOKE SELECT ON public.v_worker_performance_stats FROM PUBLIC;
REVOKE SELECT ON public.v_worker_performance_stats FROM anon;
GRANT SELECT ON public.v_worker_performance_stats TO authenticated;

COMMENT ON VIEW public.v_worker_performance_stats IS 'أداء العمال مجمع شهرياً: أيام العمل، الأجور، والسلف لكل عامل.';
