-- ============================================================================
-- 20260915000044_surplus_status_stats_view.sql
-- DB-computed statistics for the Surplus Bank page (GROUP BY status).
--
-- Context: app/(workspace)/surplus/page.tsx used to select (status,
-- estimated_value) for EVERY surplus_bank row (no limit) and aggregate
-- count/sum per status in a JavaScript loop. All money math must live in
-- PostgreSQL, so this view returns ONE row per status with the item count
-- and the total estimated value, computed by the database. The page now
-- reads at most 3 aggregated rows instead of the whole table.
--
-- security_invoker keeps the same RLS the page's direct table select had
-- (surplus_bank_select → app_private.is_staff()), so the aggregated numbers
-- are computed over exactly the same rows the old JS loop saw.
-- ============================================================================

CREATE OR REPLACE VIEW public.v_surplus_status_stats AS
SELECT
    status,
    COUNT(*) AS item_count,
    COALESCE(SUM(estimated_value), 0) AS total_estimated_value
FROM public.surplus_bank
GROUP BY status;

ALTER VIEW public.v_surplus_status_stats SET (security_invoker = true);

-- Hardening consistent with 20260905000016 / 20260910000020: no anon/PUBLIC
-- reads; objects created after the default-privileges lock-down need an
-- explicit grant for authenticated (see 20260910000027_audit_log.sql).
REVOKE SELECT ON public.v_surplus_status_stats FROM PUBLIC;
REVOKE SELECT ON public.v_surplus_status_stats FROM anon;
GRANT SELECT ON public.v_surplus_status_stats TO authenticated;

COMMENT ON VIEW public.v_surplus_status_stats IS 'إحصائيات بنك الفائض مجمعة حسب الحالة (عدد الأصناف وإجمالي القيمة التقديرية) — تُحسب في قاعدة البيانات فقط.';