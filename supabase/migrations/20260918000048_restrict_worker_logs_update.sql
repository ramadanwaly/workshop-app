-- =============================================================================
-- Migration: 20260918000048_restrict_worker_logs_update.sql
-- Purpose  : P0-01 — تضييق سياسة UPDATE على worker_logs.
--
--   المشكلة: سياسة worker_logs_update (migration 19) تمنح is_staff() صلاحية
--   UPDATE كاملة، مما يتيح للمدير تغيير daily_rate وfraction وproject_id
--   وis_settled وsettlement_id مباشرة دون المرور بـ RPC.
--
--   الحل:
--   1. حذف السياسة العامة (is_staff).
--   2. إنشاء سياسة UPDATE محدودة للمالك فقط، تغطي تدفق rpc_settle_worker
--      الذي يُحدِّث is_settled وsettlement_id باعتباره SECURITY INVOKER.
--   3. إنشاء rpc_correct_attendance للمالك فقط لتصحيح سجل حضور غير مسوّى.
--
--   ملاحظة: rpc_record_attendance تُدرج فقط (INSERT) فلا تتأثر.
--   rpc_settle_worker تُحدِّث is_settled وsettlement_id وهي SECURITY INVOKER،
--   لذا تحتاج RLS تسمح بـ UPDATE للمالك — وهو ما توفره السياسة الجديدة.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. حذف سياسة UPDATE العامة (is_staff) واستبدالها بسياسة للمالك فقط.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "worker_logs_update" ON public.worker_logs;

CREATE POLICY "worker_logs_update_owner_only"
ON public.worker_logs
FOR UPDATE TO authenticated
USING (app_private.is_owner())
WITH CHECK (app_private.is_owner());

-- ----------------------------------------------------------------------------
-- 2. rpc_correct_attendance — تصحيح سجل حضور (للمالك فقط)
--    القيود:
--    - المالك فقط.
--    - السجل يجب أن يكون غير مسوّى (is_settled = false).
--    - daily_rate يُعاد قراءته من جدول workers (لا يُقبل من الطالب).
--    - fraction محصور في 0.25 / 0.50 / 1.00.
--    - سبب التصحيح إلزامي (3 أحرف على الأقل).
--    - التسجيل في audit_log غير مدعوم حالياً (action CHECK في migration 27
--      لا يتضمن 'correct_attendance') — يمكن إضافته في migration منفصلة.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_correct_attendance(
    p_log_id         UUID,
    p_new_fraction   NUMERIC,
    p_new_project_id UUID DEFAULT NULL,
    p_correction_reason TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY INVOKER
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

    -- 6. قراءة الأجر اليومي الحالي من جدول workers (لا يُقبل من الطالب)
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

    -- 8. تنفيذ التصحيح — daily_rate يُحسب من workers، لا من الطلب
    UPDATE public.worker_logs
    SET fraction    = p_new_fraction,
        daily_rate  = v_new_rate,
        project_id  = p_new_project_id,
        notes       = COALESCE(notes || ' | تصحيح: ' || p_correction_reason,
                               'تصحيح: ' || p_correction_reason)
    WHERE id = p_log_id;

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
