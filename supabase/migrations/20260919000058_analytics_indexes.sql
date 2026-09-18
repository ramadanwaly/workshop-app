-- ============================================================================
-- Migration: 20260919000058_analytics_indexes.sql
-- Purpose: Performance indexing for audit logs, treasury queries, and attendance.
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
    ON public.audit_log(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_entity
    ON public.audit_log(entity_table, entity_id);

CREATE INDEX IF NOT EXISTS idx_treasury_type_created
    ON public.treasury_transactions(transaction_type, created_at DESC)
    WHERE NOT is_voided;

CREATE INDEX IF NOT EXISTS idx_worker_logs_composite
    ON public.worker_logs(worker_id, log_date DESC);
