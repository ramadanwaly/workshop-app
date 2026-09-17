-- ============================================================================
-- Migration: 20260915000043_performance_indexes.sql
-- Purpose: Performance audit follow-up - missing btree indexes on columns
--          used daily for filtering and ordering. Indexes only; no tables,
--          views, RLS policies, or application code are touched.
--          pg_trigram / ilike search is intentionally out of scope.
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_projects_status
    ON public.projects(status);

CREATE INDEX IF NOT EXISTS idx_projects_name
    ON public.projects(name);

CREATE INDEX IF NOT EXISTS idx_treasury_transactions_created_at
    ON public.treasury_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_worker_logs_log_date
    ON public.worker_logs(log_date);

CREATE INDEX IF NOT EXISTS idx_worker_advances_advance_date
    ON public.worker_advances(advance_date);

CREATE INDEX IF NOT EXISTS idx_subcontract_orders_status
    ON public.subcontract_orders(status);
