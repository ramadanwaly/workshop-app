-- ============================================================================
-- Migration: 20260911000036_rpc_void_treasury_transaction.sql
-- Purpose: VULN-01 and VULN-02 Remediation
--   Atomic Void Transaction RPC with FOR UPDATE lock and database-level idempotency
-- ============================================================================

CREATE OR REPLACE FUNCTION public.rpc_void_treasury_transaction(
    p_idempotency_key TEXT,
    p_action TEXT,
    p_transaction_id UUID,
    p_reason TEXT
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_existing_status TEXT;
    v_existing_payload JSONB;
    v_current_user UUID;
    v_target_tx RECORD;
    v_updated_tx RECORD;
BEGIN
    SELECT auth.uid() INTO v_current_user;
    IF v_current_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح' USING ERRCODE = 'P0001';
    END IF;

    -- Only owner can void transactions
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'إلغاء المعاملات يتطلب صلاحيات المالك فقط' USING ERRCODE = 'P0001';
    END IF;

    -- 1. Idempotency Check & Lock
    INSERT INTO public.idempotency_keys (key, user_id, action, status)
    VALUES (p_idempotency_key, v_current_user, p_action, 'pending')
    ON CONFLICT (key, user_id, action) DO NOTHING;

    SELECT status, response_payload INTO v_existing_status, v_existing_payload
    FROM public.idempotency_keys
    WHERE key = p_idempotency_key AND user_id = v_current_user AND action = p_action
    FOR UPDATE;

    IF v_existing_status = 'completed' THEN
        RETURN v_existing_payload;
    END IF;

    -- 2. Lock target transaction row (FOR UPDATE) to prevent race condition
    SELECT * INTO v_target_tx
    FROM public.treasury_transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الحركة المالية غير موجودة' USING ERRCODE = 'P0001';
    END IF;

    IF v_target_tx.is_voided THEN
        RAISE EXCEPTION 'هذه الحركة ملغاة بالفعل مسبقاً' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Perform void update
    UPDATE public.treasury_transactions
    SET is_voided = true,
        voided_at = NOW(),
        void_reason = p_reason,
        voided_by = v_current_user
    WHERE id = p_transaction_id
    RETURNING * INTO v_updated_tx;

    v_existing_payload := to_jsonb(v_updated_tx);

    -- 4. Mark idempotency as completed
    UPDATE public.idempotency_keys
    SET status = 'completed',
        response_payload = v_existing_payload,
        created_at = NOW()
    WHERE key = p_idempotency_key AND user_id = v_current_user AND action = p_action;

    RETURN v_existing_payload;
END;
$$ LANGUAGE plpgsql;
