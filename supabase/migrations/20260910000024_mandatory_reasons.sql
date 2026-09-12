-- =============================================================================
-- Migration: 20260910000024_mandatory_reasons.sql
-- Purpose  : P2-03 — mandatory reasons + note preservation (SQ-34, SQ-35,
--            SQ-45). Every money-destroying or reallocating operation now
--            requires a reason (min 3 chars, enforced in Zod AND in the RPC
--            for direct-DB callers), and void/close reasons live in dedicated
--            columns so original notes/descriptions are never overwritten.
--            Also forbids consuming surplus into its own source project
--            (ledger noise). New RPC params default to NULL so old callers
--            fail with an Arabic message instead of a signature error.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 0. New reason columns (NULL for old rows — history stays readable)
-- ----------------------------------------------------------------------------
ALTER TABLE public.subcontract_payments
    ADD COLUMN IF NOT EXISTS void_reason TEXT;

ALTER TABLE public.subcontract_orders
    ADD COLUMN IF NOT EXISTS close_reason TEXT;

-- ----------------------------------------------------------------------------
-- 1. rpc_void_subcontract_payment — reason required, notes preserved
--    (was: notes = COALESCE(p_reason, notes) which destroyed the original)
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

    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإلغاء (3 أحرف على الأقل)';
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
        void_reason = p_reason
    WHERE id = p_payment_id;

    IF v_payment.treasury_transaction_id IS NOT NULL THEN
        UPDATE public.treasury_transactions
        SET is_voided = true,
            voided_at = NOW(),
            void_reason = p_reason,
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
-- 2. rpc_close_subcontract_order — close reason required + stored
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_close_subcontract_order(
    p_order_id UUID,
    p_status TEXT DEFAULT 'completed',
    p_reason TEXT DEFAULT NULL
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

    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإغلاق (3 أحرف على الأقل)';
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
    SET status = p_status,
        close_reason = p_reason
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'order_id', p_order_id,
        'status', p_status
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. rpc_remove_operating_exclusion — removal reason required (validated here;
--    permanently recorded by the P2-06 audit log; echoed in the result meanwhile)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_remove_operating_exclusion(
    p_year_month DATE, p_project_id UUID, p_reason TEXT DEFAULT NULL
)
RETURNS JSONB SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإزالة (3 أحرف على الأقل)';
    END IF;
    DELETE FROM public.operating_allocation_exclusions
    WHERE year_month = date_trunc('month', p_year_month)::date AND project_id = p_project_id;
    RETURN jsonb_build_object('removed', true, 'reason', p_reason);
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 4. rpc_scrap_surplus — scrap reason required (surplus notes untouched)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(
    p_surplus_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_surplus RECORD;
    v_scrap_value NUMERIC(12,2);
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF coalesce(char_length(trim(coalesce(p_notes, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإتلاف (3 أحرف على الأقل)';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'لا يمكن إتلاف عنصر غير متاح (حالته: %)', v_surplus.status;
    END IF;

    v_scrap_value := v_surplus.estimated_value;

    UPDATE public.surplus_bank
    SET status = 'scrapped',
        quantity = 0
    WHERE id = p_surplus_id;

    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        NULL, 'surplus_scrap', v_scrap_value, p_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id', p_surplus_id,
        'status', 'scrapped',
        'scrapped_value', v_scrap_value,
        'adjustment_id', v_adjustment_id
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 5. rpc_consume_surplus — forbid consuming into the source project itself
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_consume_surplus(
    p_surplus_id UUID,
    p_target_project_id UUID,
    p_consume_qty NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_surplus RECORD;
    v_consumed_value NUMERIC(12,2);
    v_child_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_consume_qty <= 0 THEN
        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'هذا العنصر غير متاح للاستهلاك (حالته: %)', v_surplus.status;
    END IF;

    IF v_surplus.source_project_id IS NOT NULL
        AND v_surplus.source_project_id = p_target_project_id THEN
        RAISE EXCEPTION 'لا يمكن استهلاك الفائض لنفس مشروع المصدر — اختر مشروعاً آخر';
    END IF;

    IF p_consume_qty > v_surplus.quantity THEN
        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity;
    END IF;

    IF p_consume_qty = v_surplus.quantity THEN
        v_consumed_value := v_surplus.estimated_value;

        UPDATE public.surplus_bank
        SET quantity = 0,
            estimated_value = 0,
            status = 'consumed'
        WHERE id = p_surplus_id;

        INSERT INTO public.project_cost_adjustments (
            project_id, adjustment_type, amount, surplus_id, notes
        ) VALUES (
            p_target_project_id, 'surplus_consumption', v_consumed_value, p_surplus_id, p_notes
        ) RETURNING id INTO v_adjustment_id;

        RETURN jsonb_build_object(
            'mode', 'full_consumption',
            'surplus_id', p_surplus_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value', v_consumed_value,
            'adjustment_id', v_adjustment_id
        );
    ELSE
        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);

        UPDATE public.surplus_bank
        SET quantity = quantity - p_consume_qty,
            estimated_value = estimated_value - v_consumed_value
        WHERE id = p_surplus_id;

        INSERT INTO public.surplus_bank (
            material_name, unit, quantity, initial_quantity, estimated_value,
            source_project_id, status, parent_surplus_id, notes
        ) VALUES (
            v_surplus.material_name, v_surplus.unit, p_consume_qty, p_consume_qty, v_consumed_value,
            v_surplus.source_project_id, 'consumed', v_surplus.id, p_notes
        ) RETURNING id INTO v_child_id;

        INSERT INTO public.project_cost_adjustments (
            project_id, adjustment_type, amount, surplus_id, notes
        ) VALUES (
            p_target_project_id, 'surplus_consumption', v_consumed_value, v_child_id, p_notes
        ) RETURNING id INTO v_adjustment_id;

        RETURN jsonb_build_object(
            'mode', 'partial_consumption',
            'parent_surplus_id', p_surplus_id,
            'child_surplus_id', v_child_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value', v_consumed_value,
            'remaining_quantity', v_surplus.quantity - p_consume_qty,
            'remaining_value', v_surplus.estimated_value - v_consumed_value,
            'adjustment_id', v_adjustment_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql;
