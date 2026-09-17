-- ============================================================================
-- Migration: 20260911000041_subcontract_immutability.sql
-- Purpose: VULN-15 Remediation - Prevent modifying total_agreed_amount on subcontract orders
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trg_prevent_subcontract_amount_change()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF OLD.total_agreed_amount IS DISTINCT FROM NEW.total_agreed_amount THEN
        RAISE EXCEPTION 'لا يمكن تعديل قيمة أمر المقاولة من الباطن بعد إنشائه' USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_subcontract_amount_immutability ON public.subcontract_orders;
CREATE TRIGGER trg_subcontract_amount_immutability
    BEFORE UPDATE ON public.subcontract_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_prevent_subcontract_amount_change();
