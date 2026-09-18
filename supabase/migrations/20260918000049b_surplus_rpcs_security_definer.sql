-- =============================================================================
-- Migration: 20260918000049b_surplus_rpcs_security_definer.sql
-- Purpose  : تحويل rpc_scrap_surplus و rpc_consume_surplus إلى SECURITY DEFINER
--            حتى يستطيع المدير تنفيذها عبر المسار الآمن المقصود،
--            بعد أن أصبح UPDATE على surplus_bank مقيداً للمالك فقط (migration 49).
--
--   الضمانات المحتفظ بها:
--   - الفحص is_staff() داخل RPC: يمنع أي مستدعٍ دون صلاحية staff.
--   - FOR UPDATE lock: يمنع race conditions.
--   - حسابات القيمة النسبية تتم داخل RPC.
--   - التسجيل في audit_log يتم عبر Triggers على surplus_bank وproject_cost_adjustments.
--   - SECURITY DEFINER تعني أن الدالة تعمل بمستخدم postgres (مالك الجدول)،
--     لذا تتجاوز RLS — وهذا مقصود لأن المنطق الأمني محمي داخل الدالة.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. rpc_scrap_surplus — SECURITY DEFINER (نسخة من migration 24 مع التعديل)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(
    p_surplus_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_surplus       RECORD;
    v_scrap_value   NUMERIC(12,2);
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك'
            USING ERRCODE = 'P0001';
    END IF;

    IF coalesce(char_length(trim(coalesce(p_notes, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإتلاف (3 أحرف على الأقل)'
            USING ERRCODE = 'P0001';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود'
            USING ERRCODE = 'P0001';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'لا يمكن إتلاف عنصر غير متاح (حالته: %)', v_surplus.status
            USING ERRCODE = 'P0001';
    END IF;

    v_scrap_value := v_surplus.estimated_value;

    UPDATE public.surplus_bank
    SET status   = 'scrapped',
        quantity = 0
    WHERE id = p_surplus_id;

    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        NULL, 'surplus_scrap', v_scrap_value, p_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id',      p_surplus_id,
        'status',          'scrapped',
        'scrapped_value',  v_scrap_value,
        'adjustment_id',   v_adjustment_id
    );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. rpc_consume_surplus — SECURITY DEFINER (نسخة من migration 24 مع التعديل)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_consume_surplus(
    p_surplus_id        UUID,
    p_target_project_id UUID,
    p_consume_qty       NUMERIC,
    p_notes             TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_surplus        RECORD;
    v_consumed_value NUMERIC(12,2);
    v_child_id       UUID;
    v_adjustment_id  UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_consume_qty <= 0 THEN
        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر'
            USING ERRCODE = 'P0001';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود'
            USING ERRCODE = 'P0001';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'هذا العنصر غير متاح للاستهلاك (حالته: %)', v_surplus.status
            USING ERRCODE = 'P0001';
    END IF;

    IF v_surplus.source_project_id IS NOT NULL
       AND v_surplus.source_project_id = p_target_project_id THEN
        RAISE EXCEPTION 'لا يمكن استهلاك الفائض لنفس مشروع المصدر — اختر مشروعاً آخر'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_consume_qty > v_surplus.quantity THEN
        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity
            USING ERRCODE = 'P0001';
    END IF;

    IF p_consume_qty = v_surplus.quantity THEN
        -- استهلاك كامل
        v_consumed_value := v_surplus.estimated_value;

        UPDATE public.surplus_bank
        SET quantity        = 0,
            estimated_value = 0,
            status          = 'consumed'
        WHERE id = p_surplus_id;

        INSERT INTO public.project_cost_adjustments (
            project_id, adjustment_type, amount, surplus_id, notes
        ) VALUES (
            p_target_project_id, 'surplus_consumption', v_consumed_value, p_surplus_id, p_notes
        ) RETURNING id INTO v_adjustment_id;

        RETURN jsonb_build_object(
            'mode',            'full_consumption',
            'surplus_id',      p_surplus_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value',  v_consumed_value,
            'adjustment_id',   v_adjustment_id
        );
    ELSE
        -- استهلاك جزئي
        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);

        UPDATE public.surplus_bank
        SET quantity        = quantity - p_consume_qty,
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
            'mode',              'partial_consumption',
            'parent_surplus_id', p_surplus_id,
            'child_surplus_id',  v_child_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value',    v_consumed_value,
            'remaining_quantity', v_surplus.quantity - p_consume_qty,
            'remaining_value',   v_surplus.estimated_value - v_consumed_value,
            'adjustment_id',     v_adjustment_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql;
