-- ============================================================================
-- Migration: 20260911000038_surplus_no_zero_value.sql
-- Purpose: VULN-06 Remediation - Enforce estimated_value > 0 for surplus returns
-- ============================================================================

CREATE OR REPLACE FUNCTION public.rpc_return_surplus(
    p_project_id UUID,
    p_material_name TEXT,
    p_unit TEXT,
    p_quantity NUMERIC,
    p_estimated_value NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_surplus_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر';
    END IF;
    IF p_estimated_value <= 0 THEN
        RAISE EXCEPTION 'القيمة التقديرية يجب أن تكون أكبر من صفر';
    END IF;

    INSERT INTO public.surplus_bank (
        material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, notes
    ) VALUES (
        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value, p_project_id, 'available', p_notes
    ) RETURNING id INTO v_surplus_id;

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
$$ LANGUAGE plpgsql;
