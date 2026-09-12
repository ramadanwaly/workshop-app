-- =============================================================================
-- Migration: 20260910000023_text_bounds.sql
-- Purpose  : P2-02 — length + format CHECKs matching lib/validations/text.ts:
--            names ≤ 200, descriptions/notes/reasons ≤ 1000, phone/unit ≤ 30,
--            idempotency keys must be UUIDs (the app generates them with
--            crypto.randomUUID; all 18 live keys verified UUID-shaped).
--            Zod rejects first in Arabic; these guard direct database access.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Idempotency keys must be UUIDs
-- ----------------------------------------------------------------------------
ALTER TABLE public.idempotency_keys
    DROP CONSTRAINT IF EXISTS idempotency_key_uuid_format;
ALTER TABLE public.idempotency_keys
    ADD CONSTRAINT idempotency_key_uuid_format CHECK (
        key ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );

-- ----------------------------------------------------------------------------
-- 2. Text length bounds (NULL passes CHECK automatically)
-- ----------------------------------------------------------------------------
ALTER TABLE public.projects
    DROP CONSTRAINT IF EXISTS projects_text_bounds;
ALTER TABLE public.projects
    ADD CONSTRAINT projects_text_bounds CHECK (
        char_length(name) <= 200 AND char_length(coalesce(description, '')) <= 1000
    );

ALTER TABLE public.workers
    DROP CONSTRAINT IF EXISTS workers_text_bounds;
ALTER TABLE public.workers
    ADD CONSTRAINT workers_text_bounds CHECK (
        char_length(name) <= 200 AND char_length(coalesce(phone, '')) <= 30
    );

ALTER TABLE public.subcontract_orders
    DROP CONSTRAINT IF EXISTS subcontract_orders_text_bounds;
ALTER TABLE public.subcontract_orders
    ADD CONSTRAINT subcontract_orders_text_bounds CHECK (
        char_length(contractor_name) <= 200 AND char_length(description) <= 1000
    );

ALTER TABLE public.subcontract_payments
    DROP CONSTRAINT IF EXISTS subcontract_payments_text_bounds;
ALTER TABLE public.subcontract_payments
    ADD CONSTRAINT subcontract_payments_text_bounds CHECK (
        char_length(coalesce(notes, '')) <= 1000
    );

ALTER TABLE public.worker_advances
    DROP CONSTRAINT IF EXISTS worker_advances_text_bounds;
ALTER TABLE public.worker_advances
    ADD CONSTRAINT worker_advances_text_bounds CHECK (
        char_length(coalesce(notes, '')) <= 1000
    );

ALTER TABLE public.worker_logs
    DROP CONSTRAINT IF EXISTS worker_logs_text_bounds;
ALTER TABLE public.worker_logs
    ADD CONSTRAINT worker_logs_text_bounds CHECK (
        char_length(coalesce(notes, '')) <= 1000
    );

ALTER TABLE public.treasury_transactions
    DROP CONSTRAINT IF EXISTS treasury_text_bounds;
ALTER TABLE public.treasury_transactions
    ADD CONSTRAINT treasury_text_bounds CHECK (
        char_length(coalesce(description, '')) <= 1000
        AND char_length(coalesce(void_reason, '')) <= 1000
    );

ALTER TABLE public.surplus_bank
    DROP CONSTRAINT IF EXISTS surplus_bank_text_bounds;
ALTER TABLE public.surplus_bank
    ADD CONSTRAINT surplus_bank_text_bounds CHECK (
        char_length(material_name) <= 200
        AND char_length(unit) <= 30
        AND char_length(coalesce(notes, '')) <= 1000
    );

ALTER TABLE public.project_cost_adjustments
    DROP CONSTRAINT IF EXISTS cost_adj_text_bounds;
ALTER TABLE public.project_cost_adjustments
    ADD CONSTRAINT cost_adj_text_bounds CHECK (
        char_length(coalesce(notes, '')) <= 1000
    );

ALTER TABLE public.operating_allocation_cycles
    DROP CONSTRAINT IF EXISTS operating_cycles_text_bounds;
ALTER TABLE public.operating_allocation_cycles
    ADD CONSTRAINT operating_cycles_text_bounds CHECK (
        char_length(coalesce(notes, '')) <= 1000
        AND char_length(coalesce(void_reason, '')) <= 1000
    );

ALTER TABLE public.operating_allocation_exclusions
    DROP CONSTRAINT IF EXISTS operating_exclusions_text_bounds;
ALTER TABLE public.operating_allocation_exclusions
    ADD CONSTRAINT operating_exclusions_text_bounds CHECK (
        char_length(coalesce(reason, '')) <= 1000
    );
