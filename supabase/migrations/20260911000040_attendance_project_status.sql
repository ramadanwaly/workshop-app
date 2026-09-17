-- ============================================================================
-- Migration: 20260911000040_attendance_project_status.sql
-- Purpose: VULN-13 Remediation - Prevent attendance on completed/cancelled projects
-- ============================================================================

CREATE OR REPLACE FUNCTION public.rpc_record_attendance(
    p_worker_id UUID, p_project_id UUID, p_work_date DATE, p_fraction NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
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

    IF p_project_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
            RAISE EXCEPTION 'المشروع غير موجود';
        END IF;
        IF EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id AND status IN ('cancelled', 'completed')) THEN
            RAISE EXCEPTION 'لا يمكن تسجيل حضور على مشروع مكتمل أو ملغى';
        END IF;
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

    BEGIN
        INSERT INTO public.worker_logs (
            worker_id, project_id, log_date, fraction, daily_rate
        ) VALUES (
            p_worker_id, p_project_id, p_work_date, p_fraction, v_daily_rate
        ) RETURNING id INTO v_log_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'تم تسجيل حضور هذا العامل في هذا اليوم من قبل';
    END;

    RETURN jsonb_build_object(
        'worker_log_id', v_log_id,
        'worker_id', p_worker_id,
        'project_id', p_project_id,
        'fraction', p_fraction,
        'daily_rate', v_daily_rate,
        'calculated_amount', v_amount
    );
END;
$function$;
