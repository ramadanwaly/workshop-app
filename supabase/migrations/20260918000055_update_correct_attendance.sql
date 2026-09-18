-- =============================================================================
-- Migration: 20260918000055_update_correct_attendance.sql
-- Purpose  : 
-- 1. Add 'correct_attendance' to audit_log action constraint.
-- 2. Add 'worker_logs' to audit_log entity_table constraint.
-- 3. Update rpc_correct_attendance to be SECURITY DEFINER, insert audit_log, and restrict EXECUTE.
-- =============================================================================

-- 1. Update audit_log action constraint
ALTER TABLE public.audit_log DROP CONSTRAINT IF EXISTS audit_log_action_check;
ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_action_check CHECK (
    action IN (
        'void_treasury',
        'void_subcontract_payment',
        'close_subcontract_order',
        'return_surplus',
        'consume_surplus',
        'scrap_surplus',
        'run_operating_allocation',
        'void_allocation_cycle',
        'void_allocation_line',
        'add_operating_exclusion',
        'remove_operating_exclusion',
        'correct_attendance'
    )
);

-- 2. Update audit_log entity_table constraint
ALTER TABLE public.audit_log DROP CONSTRAINT IF EXISTS audit_log_entity_table_check;
ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_entity_table_check CHECK (
    entity_table IN (
        'treasury_transactions',
        'subcontract_payments',
        'subcontract_orders',
        'surplus_bank',
        'project_cost_adjustments',
        'operating_allocation_cycles',
        'operating_allocation_exclusions',
        'worker_logs'
    )
);

-- 3. Update rpc_correct_attendance
CREATE OR REPLACE FUNCTION public.rpc_correct_attendance(
    p_log_id         UUID,
    p_new_fraction   NUMERIC,
    p_new_project_id UUID DEFAULT NULL,
    p_correction_reason TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log        RECORD;
    v_worker     RECORD;
    v_new_rate   NUMERIC(10,2);
BEGIN
    -- 1. صلاحية المالك فقط
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: تصحيح سجلات الحضور مخصص لمالك الورشة فقط'
            USING ERRCODE = 'P0001';
    END IF;

    -- 2. سبب التصحيح إلزامي
    IF coalesce(char_length(trim(coalesce(p_correction_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب التصحيح (3 أحرف على الأقل)'
            USING ERRCODE = 'P0001';
    END IF;

    -- 3. نسبة العمل يجب أن تكون من القيم المسموح بها
    IF p_new_fraction NOT IN (0.25, 0.50, 1.00) THEN
        RAISE EXCEPTION 'نسبة العمل غير صالحة (يسمح فقط بـ 0.25 أو 0.50 أو 1.00)'
            USING ERRCODE = 'P0001';
    END IF;

    -- 4. قفل السجل وقراءته
    SELECT * INTO v_log
    FROM public.worker_logs
    WHERE id = p_log_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'سجل الحضور غير موجود'
            USING ERRCODE = 'P0001';
    END IF;

    -- 5. منع تعديل سجل مسوّى
    IF v_log.is_settled THEN
        RAISE EXCEPTION 'لا يمكن تعديل سجل حضور مرتبط بتسوية مكتملة'
            USING ERRCODE = 'P0001';
    END IF;

    -- 6. قراءة الأجر اليومي الحالي من جدول workers
    SELECT * INTO v_worker
    FROM public.workers
    WHERE id = v_log.worker_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'بيانات العامل غير موجودة'
            USING ERRCODE = 'P0001';
    END IF;

    v_new_rate := v_worker.daily_rate;

    -- 7. التحقق من المشروع الجديد إذا تم تحديده
    IF p_new_project_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_new_project_id) THEN
        RAISE EXCEPTION 'المشروع المحدد غير موجود'
            USING ERRCODE = 'P0001';
    END IF;

    -- 8. تنفيذ التصحيح
    UPDATE public.worker_logs
    SET fraction    = p_new_fraction,
        daily_rate  = v_new_rate,
        project_id  = p_new_project_id,
        notes       = COALESCE(notes || ' | تصحيح: ' || p_correction_reason,
                               'تصحيح: ' || p_correction_reason)
    WHERE id = p_log_id;

    -- 9. الإدراج في audit_log
    PERFORM app_private.append_audit_log(
        'correct_attendance',
        'worker_logs',
        p_log_id,
        p_correction_reason,
        jsonb_build_object(
            'worker_id', v_log.worker_id,
            'old_fraction', v_log.fraction,
            'new_fraction', p_new_fraction,
            'old_project_id', v_log.project_id,
            'new_project_id', p_new_project_id,
            'daily_rate_applied', v_new_rate
        )
    );

    RETURN jsonb_build_object(
        'log_id',             p_log_id,
        'worker_id',          v_log.worker_id,
        'old_fraction',       v_log.fraction,
        'new_fraction',       p_new_fraction,
        'old_project_id',     v_log.project_id,
        'new_project_id',     p_new_project_id,
        'daily_rate_applied', v_new_rate,
        'correction_reason',  p_correction_reason
    );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.rpc_correct_attendance(UUID, NUMERIC, UUID, TEXT) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.rpc_correct_attendance(UUID, NUMERIC, UUID, TEXT) TO authenticated;
