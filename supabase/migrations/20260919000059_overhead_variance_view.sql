-- ============================================================================
-- 20260919000059_overhead_variance_view.sql
-- Add view for calculating overhead variance (difference between applied overhead and actual treasury out)
-- ============================================================================

CREATE OR REPLACE VIEW public.v_overhead_variance_summary AS
WITH treasury_out AS (
    SELECT COALESCE(total_out, 0) AS total_treasury_out
    FROM public.v_treasury_balance
),
projects_cost AS (
    SELECT COALESCE(SUM(estimated_total_cost), 0) AS total_projects_cost
    FROM public.v_project_profitability
)
SELECT 
    t.total_treasury_out,
    p.total_projects_cost,
    (p.total_projects_cost - t.total_treasury_out) AS overhead_variance
FROM treasury_out t CROSS JOIN projects_cost p;

ALTER VIEW public.v_overhead_variance_summary SET (security_invoker = true);
REVOKE SELECT ON public.v_overhead_variance_summary FROM PUBLIC;
REVOKE SELECT ON public.v_overhead_variance_summary FROM anon;
GRANT SELECT ON public.v_overhead_variance_summary TO authenticated;

COMMENT ON VIEW public.v_overhead_variance_summary IS 'فروق التحميل الإداري: يحسب الفارق بين إجمالي تكلفة المشاريع (المحملة بالنسبة الإدارية) وإجمالي المنصرف الفعلي من الخزنة.';
