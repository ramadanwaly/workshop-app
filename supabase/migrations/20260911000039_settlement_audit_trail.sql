-- ============================================================================
-- Migration: 20260911000039_settlement_audit_trail.sql
-- Purpose: VULN-07 Remediation - Add settled_at timestamp to worker_logs and worker_advances
-- ============================================================================

ALTER TABLE public.worker_logs ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;
ALTER TABLE public.worker_advances ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.rpc_settle_worker(
    p_worker_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_earned      NUMERIC(10,2);
    v_advances    NUMERIC(10,2);
    v_net         NUMERIC(10,2);
    v_tx_id       UUID;
    v_worker_name TEXT;
    v_current_user UUID;
    v_carry_id    UUID;
    v_count       INT;
    v_orig_adv    NUMERIC(10,2);
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: تسوية العمال مخصصة لمالك الورشة فقط';
    END IF;

    SELECT name INTO v_worker_name
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    v_earned := COALESCE((
        SELECT SUM(calculated_amount)
        FROM public.worker_logs
        WHERE worker_id = p_worker_id AND NOT is_settled
    ), 0);

    v_advances := COALESCE((
        SELECT SUM(amount)
        FROM public.worker_advances
        WHERE worker_id = p_worker_id AND NOT is_settled
    ), 0);

    v_net := ROUND(v_earned - v_advances, 2);

    SELECT auth.uid() INTO v_current_user;

    IF v_net > 0 THEN
        -- treasury OUT for the net payable, then settle everything
        INSERT INTO public.treasury_transactions (
            transaction_type, category, amount, description, created_by
        ) VALUES (
            'out', 'settlement', v_net,
            COALESCE(p_notes, 'تسوية أجر العامل: ' || v_worker_name),
            v_current_user
        ) RETURNING id INTO v_tx_id;

        UPDATE public.worker_logs
        SET is_settled = true, settlement_id = v_tx_id, settled_at = NOW()
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = v_tx_id, settled_at = NOW()
        WHERE worker_id = p_worker_id AND NOT is_settled;

        RETURN jsonb_build_object(
            'mode', 'cash_settlement',
            'worker_id', p_worker_id,
            'earned_wages', v_earned,
            'unsettled_advances', v_advances,
            'net_payable', v_net,
            'treasury_transaction_id', v_tx_id,
            'carried_forward_advance', 0
        );
    ELSE
        -- advances exceeded wages: no cash out; carry the excess forward as
        -- a new opening record so the worker credit stays active & auditable.
        v_orig_adv := v_advances;
        v_advances := ABS(v_net);

        UPDATE public.worker_logs
        SET is_settled = true, settlement_id = NULL, settled_at = NOW()
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = NULL, settled_at = NOW()
        WHERE worker_id = p_worker_id AND NOT is_settled;

        IF v_advances > 0 THEN
            INSERT INTO public.worker_advances (
                worker_id, amount, advance_date,
                is_settled, is_carried_forward, notes
            ) VALUES (
                p_worker_id, v_advances, CURRENT_DATE,
                false, true,
                COALESCE(p_notes, 'سلفة محمولة من فترة سابقة (تجاوز الأجر)')
            ) RETURNING id INTO v_carry_id;
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM public.worker_advances
        WHERE worker_id = p_worker_id AND NOT is_settled;

        RETURN jsonb_build_object(
            'mode', 'advance_carry_forward',
            'worker_id', p_worker_id,
            'earned_wages', v_earned,
            'unsettled_advances', v_orig_adv,
            'net_payable', 0,
            'treasury_transaction_id', NULL,
            'carried_forward_advance', v_advances,
            'new_advance_id', v_carry_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql;
