-- ============================================================================
-- 20260905000004_surplus_rpcs.sql
-- PHASE 3: Atomic Surplus Operations with Concurrency Locking
-- ============================================================================

-- 1. دالة إرجاع الفائض لبنك المواد وتخفيض تكلفة المشروع
CREATE OR REPLACE FUNCTION public.rpc_return_surplus(
    p_project_id UUID,
    p_material_name TEXT,
    p_unit TEXT,
    p_quantity NUMERIC,
    p_estimated_value NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_surplus_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر';
    END IF;
    IF p_estimated_value < 0 THEN
        RAISE EXCEPTION 'القيمة التقديرية لا يمكن أن تكون سالبة';
    END IF;

    -- أ. إضافة المواد في بنك الفائض
    INSERT INTO public.surplus_bank (
        material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, notes
    ) VALUES (
        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value, p_project_id, 'available', p_notes
    ) RETURNING id INTO v_surplus_id;

    -- ب. تخفيض تكلفة المشروع المصدر بنفس القيمة
    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        p_project_id, 'surplus_return', p_estimated_value, v_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id', v_surplus_id,
        'adjustment_id', v_adjustment_id,
        'quantity', p_quantity,
        'estimated_value', p_estimated_value
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. دالة استهلاك الفائض مع قفل الصفوف (Row-Level Locking)
CREATE OR REPLACE FUNCTION public.rpc_consume_surplus(
    p_surplus_id UUID,
    p_target_project_id UUID,
    p_consume_qty NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_surplus RECORD;
    v_consumed_value NUMERIC(12,2);
    v_child_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF p_consume_qty <= 0 THEN
        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر';
    END IF;

    -- قفل الصف حصرياً لمنع التزامن والسباق (Race Conditions)
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

    IF p_consume_qty > v_surplus.quantity THEN
        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity;
    END IF;

    -- احتساب القيمة المستهلكة
    IF p_consume_qty = v_surplus.quantity THEN
        -- استهلاك كامل (تجنب كسور التقريب)
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
        -- استهلاك جزئي: خصم الكمية من الأصل وإنشاء سجل ابن
        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);

        UPDATE public.surplus_bank
        SET quantity = quantity - p_consume_qty,
            estimated_value = estimated_value - v_consumed_value
        WHERE id = p_surplus_id;

        -- إنشاء سجل ابن بحالة consumed
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. دالة كهنة / إتلاف الفائض (Surplus Scrap)
CREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(
    p_surplus_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_surplus RECORD;
    v_scrap_value NUMERIC(12,2);
    v_adjustment_id UUID;
BEGIN
    -- قفل الصف
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

    -- تحويل الحالة إلى scrapped وتصفير الكمية
    UPDATE public.surplus_bank
    SET status = 'scrapped',
        quantity = 0
    WHERE id = p_surplus_id;

    -- تسجيل تسوية هالك عام (project_id = NULL)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
