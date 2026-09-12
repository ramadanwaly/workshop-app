-- ============================================================================
-- 20260905000017_worker_liabilities_view.sql
-- Per-worker unsettled liabilities view (DB-backed financial totals).
--
-- Context: v_pending_liabilities is a single AGGREGATE row (total_worker/
--   total_subcontract/total_pending) with no worker_id, so per-worker figures
--   cannot be read from it. The worker detail page used to recompute
--   wages/advances/net in TypeScript (violating SYSTEM_PROMPT rule 3). This
--   migration exposes the worker_net_liabilities CTE as per-worker rows so
--   getWorkerDetail reads authoritative PostgreSQL-computed totals.
--
-- v_pending_liabilities is re-created ON TOP of v_worker_liabilities so there
-- is a single source of truth for worker liability math.
-- ============================================================================

CREATE OR REPLACE VIEW public.v_worker_liabilities AS
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
)
SELECT
    w.id AS worker_id,
    COALESCE(uw.total_wages, 0) AS unsettled_wages,
    COALESCE(ua.total_advances, 0) AS unsettled_advances,
    GREATEST(0, COALESCE(uw.total_wages, 0) - COALESCE(ua.total_advances, 0)) AS net_payable,
    GREATEST(0, COALESCE(ua.total_advances, 0) - COALESCE(uw.total_wages, 0)) AS carried_forward_credit
FROM public.workers w
LEFT JOIN worker_unsettled_wages uw ON w.id = uw.worker_id
LEFT JOIN worker_unsettled_advances ua ON w.id = ua.worker_id;

ALTER VIEW public.v_worker_liabilities SET (security_invoker = true);

-- Hardening consistent with 20260905000016: no anon/PUBLIC reads
-- (authenticated keeps its default SELECT grant via Supabase default privileges).
REVOKE SELECT ON public.v_worker_liabilities FROM PUBLIC;
REVOKE SELECT ON public.v_worker_liabilities FROM anon;

COMMENT ON VIEW public.v_worker_liabilities IS 'التزامات العامل غير المسددة لكل عامل على حدة (أجور/سلف/صافي/رصيد محمول) — تُحسب في قاعدة البيانات فقط.';

-- ----------------------------------------------------------------------------
-- Re-assert v_pending_liabilities on top of v_worker_liabilities (single source).
-- Final output columns are identical to the previous definition (03/08 re-assert
-- security_invoker because CREATE OR REPLACE VIEW resets reloptions).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_pending_liabilities AS
WITH worker_net_liabilities AS (
    SELECT
        worker_id,
        unsettled_wages,
        unsettled_advances,
        net_payable,
        carried_forward_credit
    FROM public.v_worker_liabilities
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

ALTER VIEW public.v_pending_liabilities SET (security_invoker = true);
REVOKE SELECT ON public.v_pending_liabilities FROM PUBLIC;
REVOKE SELECT ON public.v_pending_liabilities FROM anon;