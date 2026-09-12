-- ============================================================================
-- 20260905000009_dashboard_views.sql
-- PHASE 6: Dashboard Views
-- ============================================================================

-- View: Available Surplus Value
-- مجموع الفائض المتاح (status = 'available')
CREATE OR REPLACE VIEW public.v_surplus_available AS
SELECT
    COALESCE(SUM(estimated_value), 0) AS total_surplus_value,
    COALESCE(SUM(quantity), 0) AS total_surplus_quantity,
    COUNT(*) FILTER (WHERE status = 'available') AS item_count
FROM public.surplus_bank
WHERE status = 'available';

-- Enable RLS security_invoker
ALTER VIEW public.v_surplus_available SET (security_invoker = true);
