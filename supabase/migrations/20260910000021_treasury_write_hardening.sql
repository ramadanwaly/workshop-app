-- =============================================================================
-- Migration: 20260910000021_treasury_write_hardening.sql
-- Purpose  : P1-07 — close treasury write holes (SQ-42, SQ-43).
--
-- (a) INSERT policy: the manager could insert category 'subcontract_payment'
--     directly, bypassing the overpayment / closed-order / owner checks inside
--     rpc_pay_subcontract, and likewise 'carried_forward_advance'. Both join
--     the owner-only list ('owner_funding', 'advance', 'settlement').
--     Verified: no legitimate manager flow inserts these categories — every
--     RPC writing them is internally owner-gated (labor 06, subcontracts 07).
--
-- (b) UPDATE trigger: the owner UPDATE policy allows touching ANY column, so
--     amount/category/project could be rewritten instead of a proper void.
--     The trigger freezes money-routing columns and forbids reopening voided
--     rows. Legitimate flows only flip void metadata (app voidTransaction +
--     rpc_void_subcontract_payment set is_voided/voided_at/void_reason/
--     voided_by and nothing else) — both keep working.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- (a) Owner-only insert for subcontract_payment + carried_forward_advance
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "treasury_insert" ON public.treasury_transactions;

CREATE POLICY "treasury_insert" ON public.treasury_transactions
    FOR INSERT TO authenticated
    WITH CHECK (
        app_private.is_staff() AND (
            (
                category NOT IN (
                    'owner_funding', 'advance', 'settlement',
                    'subcontract_payment', 'carried_forward_advance'
                )
            ) OR app_private.is_owner()
        )
    );

-- ----------------------------------------------------------------------------
-- (b) Freeze money columns; void is one-way (P0001 Arabic errors)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_treasury_update_tampering()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- 1. A voided row can never be reopened.
    IF OLD.is_voided AND NOT NEW.is_voided THEN
        RAISE EXCEPTION 'هذه الحركة ملغاة ولا يمكن إعادة فتحها';
    END IF;

    -- 2. Money-routing columns are immutable on every update.
    --    Voiding flips only is_voided/voided_at/void_reason/voided_by.
    IF NEW.amount IS DISTINCT FROM OLD.amount
        OR NEW.transaction_type IS DISTINCT FROM OLD.transaction_type
        OR NEW.category IS DISTINCT FROM OLD.category
        OR NEW.project_id IS DISTINCT FROM OLD.project_id
        OR NEW.is_direct_owner_payment IS DISTINCT FROM OLD.is_direct_owner_payment
        OR NEW.created_by IS DISTINCT FROM OLD.created_by
        OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'تعديل بيانات الحركة المالية ممنوع — المتاح هو الإلغاء بسبب فقط';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_treasury_no_tamper ON public.treasury_transactions;

CREATE TRIGGER trg_treasury_no_tamper
    BEFORE UPDATE ON public.treasury_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_treasury_update_tampering();
