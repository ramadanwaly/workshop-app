-- =============================================================================
-- Migration: 20260910000030_attendance_unique_reverted.sql
-- Purpose  : REVERT the UNIQUE(worker_id, log_date) from migration 28.
--            The locked Phase-10 financial suite (supabase/
--            verify_financial_audit.sql, L1/L2/L5) legitimately records
--            several same-day rows per worker — including the EXACT same
--            (worker, day, project, fraction) twice (L2 then L5). An
--            intentional repeat and a double-click retry are therefore
--            indistinguishable at the database level, so no UNIQUE
--            constraint can separate them without breaking real work.
--            Duplicate protection stays at the app layer (idempotency keys:
--            same key = same request, blocked) plus the immutable audit
--            trail (who/when for every row). A "confirm when a row already
--            exists today" dialog is a product decision for the owner (P3).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

ALTER TABLE public.worker_logs
    DROP CONSTRAINT IF EXISTS worker_logs_one_row_per_day;

-- Restore the original rpc_record_attendance body (the unique_violation
-- branch is dead without the constraint and would only confuse).
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
$function$;
