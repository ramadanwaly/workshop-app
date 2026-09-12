-- =============================================================================
-- Migration: 20260910000028_cleanup_gate_settings_attendance.sql
-- Purpose  : P2-09 — close the last three P2 gaps.
--   1. Cleanup gate: REVOKE EXECUTE on cleanup_expired_idempotency_keys()
--      from authenticated/anon/PUBLIC. Any signed-in manager could call it
--      over REST and wipe the double-submit protection (it is SECURITY
--      DEFINER). The nightly cron calls it via `docker exec ... -U postgres`
--      (direct SQL, not REST), so the schedule is unaffected.
--   2. Settings: replace the FOR ALL owner policy with INSERT + UPDATE
--      owner-only. Settings rows are load-bearing (overhead %); they may be
--      changed but never deleted — no app path deletes them.
--   3. Attendance duplication: one row per worker per day
--      (UNIQUE worker_id + log_date). The app records a single fraction per
--      call and no multi-row day exists in production; a concurrent
--      double-submit with different idempotency keys previously double-paid.
--      rpc_record_attendance now converts the unique violation into a clear
--      Arabic business rejection (P0001, relayed verbatim by the app).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Cleanup gate.
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_idempotency_keys()
    FROM authenticated, anon, PUBLIC;

-- ----------------------------------------------------------------------------
-- 2. Settings: changeable, never deletable.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "settings_modify_owner_only" ON public.settings;

DROP POLICY IF EXISTS "settings_insert_owner_only" ON public.settings;
CREATE POLICY "settings_insert_owner_only" ON public.settings
    FOR INSERT TO authenticated
    WITH CHECK (app_private.is_owner());

DROP POLICY IF EXISTS "settings_update_owner_only" ON public.settings;
CREATE POLICY "settings_update_owner_only" ON public.settings
    FOR UPDATE TO authenticated
    USING (app_private.is_owner())
    WITH CHECK (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 3. One attendance row per worker per day.
-- ----------------------------------------------------------------------------
ALTER TABLE public.worker_logs
    ADD CONSTRAINT worker_logs_one_row_per_day UNIQUE (worker_id, log_date);

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
