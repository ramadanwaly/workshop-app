-- ============================================================================
-- Migration: 20260911000035_enforce_db_overdraft_and_idempotency.sql
-- Purpose: VULN-01 and VULN-02 Remediation
--   1. Create trg_enforce_treasury_overdraft trigger using advisory lock
--   2. Create rpc_record_treasury_transaction atomic idempotency engine
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. trg_enforce_treasury_overdraft
-- Prevents managers from bypassing the zero-balance limit via race condition
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_enforce_treasury_overdraft()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    -- Only check for OUT transactions that are NOT direct owner payments
    IF NEW.transaction_type = 'out' AND NEW.is_direct_owner_payment = false THEN
        -- Only enforce for non-owners (owner can bypass overdraft)
        IF NOT app_private.is_owner() THEN
            -- Acquire advisory lock to prevent Read-Committed bypasses
            PERFORM pg_advisory_xact_lock(hashtext('treasury_balance_lock'));
            
            -- Calculate real-time balance
            SELECT COALESCE(SUM(CASE WHEN transaction_type = 'in' THEN amount ELSE -amount END), 0)
            INTO v_balance
            FROM public.treasury_transactions
            WHERE NOT is_voided AND NOT is_direct_owner_payment;

            IF (v_balance - NEW.amount) < 0 THEN
                RAISE EXCEPTION 'رصيد الخزينة غير كافٍ لإتمام هذه المعاملة (الرصيد الحالي: %)', v_balance USING ERRCODE = 'P0001';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_treasury_overdraft_check ON public.treasury_transactions;
CREATE TRIGGER trg_treasury_overdraft_check
    BEFORE INSERT ON public.treasury_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_treasury_overdraft();

-- ----------------------------------------------------------------------------
-- 2. rpc_record_treasury_transaction
-- Atomic Idempotency Engine
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_record_treasury_transaction(
    p_idempotency_key TEXT,
    p_action TEXT,
    p_transaction_type TEXT,
    p_category TEXT,
    p_subcategory TEXT,
    p_amount NUMERIC,
    p_project_id UUID,
    p_is_direct_owner BOOLEAN,
    p_description TEXT
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_existing_status TEXT;
    v_existing_payload JSONB;
    v_tx_id UUID;
    v_current_user UUID;
    v_transaction RECORD;
BEGIN
    SELECT auth.uid() INTO v_current_user;
    IF v_current_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح' USING ERRCODE = 'P0001';
    END IF;

    -- 1. Idempotency Check
    -- INSERT ... ON CONFLICT DO NOTHING pattern before acquiring SELECT ... FOR UPDATE
    INSERT INTO public.idempotency_keys (key, user_id, action, status)
    VALUES (p_idempotency_key, v_current_user, p_action, 'pending')
    ON CONFLICT (key, user_id, action) DO NOTHING;

    -- Lock the row
    SELECT status, response_payload INTO v_existing_status, v_existing_payload
    FROM public.idempotency_keys
    WHERE key = p_idempotency_key AND user_id = v_current_user AND action = p_action
    FOR UPDATE;

    -- If completed, return cached response
    IF v_existing_status = 'completed' THEN
        RETURN v_existing_payload;
    END IF;

    -- 2. Validate input and role limits
    -- is_direct_owner_payment is for owners only
    IF p_is_direct_owner = true AND NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'تحديد سداد المالك المباشر يتطلب صلاحيات المالك فقط' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Perform Insert
    INSERT INTO public.treasury_transactions (
        transaction_type,
        category,
        subcategory,
        amount,
        description,
        project_id,
        is_direct_owner_payment,
        created_by
    ) VALUES (
        p_transaction_type,
        p_category,
        p_subcategory,
        p_amount,
        p_description,
        p_project_id,
        p_is_direct_owner,
        v_current_user
    ) RETURNING * INTO v_transaction;

    -- Convert the inserted row into JSONB payload
    v_existing_payload := to_jsonb(v_transaction);

    -- 4. Mark as completed in the same transaction
    UPDATE public.idempotency_keys
    SET status = 'completed',
        response_payload = v_existing_payload,
        created_at = NOW() -- update the timestamp for completeness
    WHERE key = p_idempotency_key AND user_id = v_current_user AND action = p_action;

    RETURN v_existing_payload;
END;
$$ LANGUAGE plpgsql;
