-- ============================================================================
-- 20260905000006_labor_rpcs.sql
-- PHASE 4: Labor — Attendance, Advances, and Settlement with Credit Carry-Forward
-- All RPCs are SECURITY INVOKER (surplus pattern), guard on app_private helpers,
-- compute amounts authoritatively in the database, and lock rows where concurrency
-- could corrupt a balance (advance / settlement).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. rpc_record_attendance — Project or General attendance (manager/owner)
--    labor cost = daily_rate x fraction (computed server-side, never client)
--    known fraction set: 0.25 / 0.50 / 1.00
--    project linked  => project direct cost + worker liability
--    project NULL    => general workshop labor cost + worker liability
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_record_attendance(
    p_worker_id UUID,
    p_project_id UUID,          -- NULL => general attendance
    p_work_date DATE,
    p_fraction NUMERIC
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_worker      RECORD;
    v_daily_rate  NUMERIC(10,2);
    v_amount      NUMERIC(10,2);
    v_log_id      UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_fraction NOT IN (0.25, 0.50, 1.00) THEN
        RAISE EXCEPTION 'نسبة العمل غير صالحة (يسمح فقط بـ 0.25 أو 0.50 أو 1.00)';
    END IF;

    IF p_project_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;

    SELECT * INTO v_worker
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    IF NOT v_worker.is_active THEN
        RAISE EXCEPTION 'العامل غير نشط ولا يمكن تسجيل حضور له';
    END IF;

    v_daily_rate := v_worker.daily_rate;
    v_amount     := ROUND(v_daily_rate * p_fraction, 2);

    INSERT INTO public.worker_logs (
        worker_id, project_id, log_date, fraction, daily_rate
    ) VALUES (
        p_worker_id, p_project_id, p_work_date, p_fraction, v_daily_rate
    ) RETURNING id INTO v_log_id;

    RETURN jsonb_build_object(
        'worker_log_id', v_log_id,
        'worker_id', p_worker_id,
        'project_id', p_project_id,
        'fraction', p_fraction,
        'daily_rate', v_daily_rate,
        'calculated_amount', v_amount
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. rpc_record_advance — owner only, atomic (advance + treasury OUT)
--    advance => treasury OUT (category 'advance'), worker liability +
--    NEVER a project cost.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_record_advance(
    p_worker_id UUID,
    p_amount NUMERIC,
    p_advance_date DATE,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_worker      RECORD;
    v_advance_id  UUID;
    v_tx_id       UUID;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إصدار السلف مخصص لمالك الورشة فقط';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ السلفة يجب أن يكون أكبر من صفر';
    END IF;

    SELECT * INTO v_worker
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    SELECT auth.uid() INTO v_current_user;

    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    ) VALUES (
        'out', 'advance', p_amount,
        COALESCE(p_notes, 'سلفة للعامل: ' || v_worker.name),
        v_current_user
    ) RETURNING id INTO v_tx_id;

    INSERT INTO public.worker_advances (
        worker_id, amount, advance_date, treasury_transaction_id, notes
    ) VALUES (
        p_worker_id, p_amount, p_advance_date, v_tx_id, p_notes
    ) RETURNING id INTO v_advance_id;

    RETURN jsonb_build_object(
        'advance_id', v_advance_id,
        'worker_id', p_worker_id,
        'amount', p_amount,
        'treasury_transaction_id', v_tx_id
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. rpc_settle_worker — owner only, atomic, row-locked, authoritative
--    Net Payable = SUM(earned unsettled wages) - SUM(unsettled advances)
--    net > 0 : treasury settlement OUT = net, mark logs & advances settled
--    net <=0 : treasury unchanged (OUT = 0), mark settled, open a new
--              carried_forward_advance record for the excess (never discarded)
-- ----------------------------------------------------------------------------
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
        SET is_settled = true, settlement_id = v_tx_id
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = v_tx_id
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
        v_orig_adv := v_advances;   -- preserve original unsettled advances
        v_advances := ABS(v_net);   -- the excess (advances - earned)

        UPDATE public.worker_logs
        SET is_settled = true, settlement_id = NULL
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = NULL
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
            'mode', 'credit_carry_forward',
            'worker_id', p_worker_id,
            'earned_wages', v_earned,
            'unsettled_advances', v_orig_adv,   -- original advances
            'net_payable', 0,
            'treasury_transaction_id', NULL,
            'carried_forward_advance', v_advances,
            'carried_forward_id', v_carry_id,
            'open_advance_record_count', v_count
        );
    END IF;
END;
$$ LANGUAGE plpgsql;