-- ==========================================================================
-- Migration: 20260911000032_fix_audit_triggers.sql
-- Audit fixes H-03 & H-04
-- H-03: trg_log_subpay_void was logging NEW.void_reason; correct to NEW.notes
-- H-04: ensure close_reason column and rpc_close_subcontract_order p_reason
-- ==========================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- H-03: Fix trg_log_subpay_void — record NEW.notes instead of NEW.void_reason
-- The original trigger passed void_reason but the audit context should capture
-- the payment notes for traceability.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.trg_log_subpay_void()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_subcontract_payment', 'subcontract_payments', NEW.id, NEW.notes,
            jsonb_build_object('amount', NEW.amount, 'order_id', NEW.subcontract_order_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create trigger (idempotent)
DROP TRIGGER IF EXISTS trg_audit_subpay_void ON public.subcontract_payments;
CREATE TRIGGER trg_audit_subpay_void
    AFTER UPDATE ON public.subcontract_payments
    FOR EACH ROW
    EXECUTE FUNCTION app_private.trg_log_subpay_void();

-- ---------------------------------------------------------------------------
-- H-04: Ensure close_reason column on subcontract_orders (idempotent)
-- Already added in 20260910000024_mandatory_reasons.sql but re-stated here
-- for audit completeness.
-- ---------------------------------------------------------------------------
ALTER TABLE public.subcontract_orders
    ADD COLUMN IF NOT EXISTS close_reason TEXT;

-- rpc_close_subcontract_order already accepts p_reason and stores it into
-- close_reason (see 20260910000024). No changes needed to the RPC.

COMMIT;
