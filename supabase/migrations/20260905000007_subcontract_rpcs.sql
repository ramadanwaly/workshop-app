-- ============================================================================
-- 20260905000007_subcontract_rpcs.sql
-- PHASE 5: Subcontracting — with Concurrency Protection
--   rpc_create_subcontract_order  (owner-only) — accrual point for cost/liability
--   rpc_pay_subcontract           (owner-only) — atomic, SELECT ... FOR UPDATE
--   rpc_void_subcontract_payment  (owner-only) — reversal (never hard delete)
--   rpc_close_subcontract_order   (owner-only) — completed must be fully paid
--
-- The existing views already make order cost/liability authoritative:
--   v_project_direct_costs  : subcontract_cost = SUM(total_agreed) of non-cancelled
--   v_pending_liabilities   : remaining = total_agreed - SUM(not-voided payments)
-- These RPCs only write rows; the views always derive totals from DB truth.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. rpc_create_subcontract_order — owner only
--    Creates an ACTIVE order. Immediately (via views) raises project cost and
--    liability by total_agreed_amount. Treasury unchanged at this point.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_create_subcontract_order(
    p_project_id UUID,
    p_contractor_name TEXT,
    p_description TEXT,
    p_total_agreed_amount NUMERIC
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_order_id  UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';
    END IF;

    IF p_total_agreed_amount <= 0 THEN
        RAISE EXCEPTION 'المبلغ المتفق عليه يجب أن يكون أكبر من صفر';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;

    INSERT INTO public.subcontract_orders (
        project_id, contractor_name, description, total_agreed_amount, status
    ) VALUES (
        p_project_id, p_contractor_name, p_description, p_total_agreed_amount, 'active'
    ) RETURNING id INTO v_order_id;

    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'project_id', p_project_id,
        'contractor_name', p_contractor_name,
        'total_agreed_amount', p_total_agreed_amount,
        'status', 'active'
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. rpc_pay_subcontract — owner only, atomic, row-locked, authoritative
--    Locks the order row FOR UPDATE and validates BEFORE writing:
--      payment > 0
--      SUM(valid, non-voided payments) + payment <= total_agreed_amount
--    Blocks payment on a non-active (closed/cancelled) order.
--    Writes: subcontract_payment + treasury OUT (category 'subcontract_payment').
--    Project cost NOT increased again (accrual already recorded at agreement).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_pay_subcontract(
    p_order_id UUID,
    p_amount NUMERIC,
    p_payment_date DATE,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_order       RECORD;
    v_paid        NUMERIC(12,2);
    v_payment_id  UUID;
    v_tx_id       UUID;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: سداد مقاولي الباطن مخصص لمالك الورشة فقط';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ الدفعة يجب أن يكون أكبر من صفر';
    END IF;

    SELECT * INTO v_order
    FROM public.subcontract_orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';
    END IF;

    IF v_order.status != 'active' THEN
        RAISE EXCEPTION 'لا يمكن سداد اتفاقية مغلقة (حالتها: %)', v_order.status;
    END IF;

    v_paid := COALESCE((
        SELECT SUM(amount)
        FROM public.subcontract_payments
        WHERE subcontract_order_id = p_order_id
          AND NOT is_voided
    ), 0);

    IF v_paid + p_amount > v_order.total_agreed_amount THEN
        RAISE EXCEPTION
            'دفعة مرفوضة: مجموع المدفوعات (%) + هذه الدفعة (%) يتجاوز المبلغ المتفق عليه (%)',
            v_paid, p_amount, v_order.total_agreed_amount;
    END IF;

    SELECT auth.uid() INTO v_current_user;

    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    ) VALUES (
        'out', 'subcontract_payment', p_amount,
        COALESCE(p_notes, 'دفعة لمقاول الباطن: ' || v_order.contractor_name || ' - ' || v_order.description),
        v_current_user
    ) RETURNING id INTO v_tx_id;

    INSERT INTO public.subcontract_payments (
        subcontract_order_id, amount, payment_date, treasury_transaction_id, notes
    ) VALUES (
        p_order_id, p_amount, p_payment_date, v_tx_id, p_notes
    ) RETURNING id INTO v_payment_id;

    RETURN jsonb_build_object(
        'payment_id', v_payment_id,
        'order_id', p_order_id,
        'amount', p_amount,
        'treasury_transaction_id', v_tx_id,
        'total_paid_after', v_paid + p_amount
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. rpc_void_subcontract_payment — owner only, reversal (never hard delete)
--    Marks the payment is_voided = true AND voids its linked treasury OUT, so:
--      treasury balance is restored (view excludes voided)
--      the amount no longer counts against the paid sum (liability back up)
--      payment is still visible/historical for audit
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_void_subcontract_payment(
    p_payment_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_payment RECORD;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء دفعات مقاولي الباطن مخصص لمالك الورشة فقط';
    END IF;

    SELECT * INTO v_payment
    FROM public.subcontract_payments
    WHERE id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الدفعة غير موجودة';
    END IF;

    IF v_payment.is_voided THEN
        RAISE EXCEPTION 'هذه الدفعة ملغاة بالفعل مسبقاً';
    END IF;

    SELECT auth.uid() INTO v_current_user;

    UPDATE public.subcontract_payments
    SET is_voided = true,
        notes = COALESCE(p_reason, notes)
    WHERE id = p_payment_id;

    IF v_payment.treasury_transaction_id IS NOT NULL THEN
        UPDATE public.treasury_transactions
        SET is_voided = true,
            voided_at = NOW(),
            void_reason = COALESCE(p_reason, 'إلغاء دفعة مقاول باطن'),
            voided_by = v_current_user
        WHERE id = v_payment.treasury_transaction_id;
    END IF;

    RETURN jsonb_build_object(
        'payment_id', p_payment_id,
        'order_id', v_payment.subcontract_order_id,
        'voided', true,
        'treasury_transaction_id', v_payment.treasury_transaction_id
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 4. rpc_close_subcontract_order — owner only
--    status = 'completed' : requires fully paid (remaining = 0) per invariant
--                           "a closed order must not retain an unexplained
--                            unpaid balance" (payments are blocked once closed)
--    status = 'cancelled' : no full-payment requirement (unpaid is explained by
--                           the cancellation itself)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_close_subcontract_order(
    p_order_id UUID,
    p_status TEXT DEFAULT 'completed'
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_order RECORD;
    v_paid  NUMERIC(12,2);
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';
    END IF;

    IF p_status NOT IN ('completed', 'cancelled') THEN
        RAISE EXCEPTION 'حالة الإغلاق غير صالحة (يسمح فقط بـ completed أو cancelled)';
    END IF;

    SELECT * INTO v_order
    FROM public.subcontract_orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';
    END IF;

    IF v_order.status != 'active' THEN
        RAISE EXCEPTION 'الاتفاقية مغلقة بالفعل (حالتها: %)', v_order.status;
    END IF;

    IF p_status = 'completed' THEN
        v_paid := COALESCE((
            SELECT SUM(amount)
            FROM public.subcontract_payments
            WHERE subcontract_order_id = p_order_id
              AND NOT is_voided
        ), 0);

        IF v_paid <> v_order.total_agreed_amount THEN
            RAISE EXCEPTION
                'لا يمكن إغلاق الاتفاقية كـ completed: يوجد رصيد غير مدفوع (المتبقي %)',
                v_order.total_agreed_amount - v_paid;
        END IF;
    END IF;

    UPDATE public.subcontract_orders
    SET status = p_status
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'order_id', p_order_id,
        'status', p_status
    );
END;
$$ LANGUAGE plpgsql;
