-- =============================================================================
-- Migration: 20260918000053_return_surplus_security_definer.sql
-- (renamed from 20260918000051b — pure numeric version; migrate script keys
--  on leading digits only so 51/51b collided. CREATE OR REPLACE → safe.)
-- Purpose  : تحويل rpc_return_surplus إلى SECURITY DEFINER.
--
--   بعد migration 51 (حذف cost_adj_insert policy) وmigration 49 (تقييد
--   surplus_bank_update للمالك)، أصبحت rpc_return_surplus (SECURITY INVOKER)
--   غير قادرة على الكتابة في surplus_bank وproject_cost_adjustments للمدير.
--
--   الحل: SECURITY DEFINER مع إبقاء الفحص is_staff() داخلياً.
--   الضمانات المحتفظ بها:
--   - is_staff() check: يمنع أي مستدعٍ غير مصرح.
--   - الحسابات تتم داخل الدالة الموثوقة.
--   - الـ Trigger trg_audit_cost_adj_insert يسجل في audit_log تلقائياً.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.rpc_return_surplus(
    p_project_id      UUID,
    p_material_name   TEXT,
    p_unit            TEXT,
    p_quantity        NUMERIC,
    p_estimated_value NUMERIC,
    p_notes           TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_surplus_id    UUID;
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_estimated_value < 0 THEN
        RAISE EXCEPTION 'القيمة التقديرية لا يمكن أن تكون سالبة'
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.surplus_bank (
        material_name, unit, quantity, initial_quantity, estimated_value,
        source_project_id, status, notes
    ) VALUES (
        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value,
        p_project_id, 'available', p_notes
    ) RETURNING id INTO v_surplus_id;

    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        p_project_id, 'surplus_return', p_estimated_value, v_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id',      v_surplus_id,
        'adjustment_id',   v_adjustment_id,
        'quantity',        p_quantity,
        'estimated_value', p_estimated_value
    );
END;
$$ LANGUAGE plpgsql;
