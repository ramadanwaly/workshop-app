-- =============================================================================
-- verify_rls_manager_boundaries.sql
-- Purpose: التحقق من أن سياسات RLS الجديدة (migrations 48-51) تمنع المدير
--          من تعديل الجداول الحساسة مباشرة.
--
-- تشغيل: في Supabase SQL Editor بجلسة manager (أو عبر SET ROLE manager).
-- هذه الاستعلامات تعمل في بيئة Supabase حيث يمكن تغيير الدور ومحاكاة المستخدمين.
--
-- ملاحظة: يجب تطبيق migrations 48-51 أولاً قبل تشغيل هذه الفحوصات.
-- =============================================================================

-- ============================================================
-- الإعداد: استبدل القيم أدناه بمعرفات حقيقية من بيئتك
-- ============================================================
-- \set manager_user_id 'UUID-المدير-هنا'
-- \set worker_log_id   'UUID-سجل-حضور-غير-مسوّى-هنا'
-- \set surplus_id      'UUID-فائض-متاح-هنا'

-- ============================================================
-- الفحص 1: المدير لا يستطيع تعديل worker_logs مباشرة
-- ============================================================
-- المتوقع: ERROR - new row violates row-level security policy
-- الخطوات في Supabase Dashboard > SQL Editor:
--   1. تسجيل دخول بمستخدم manager
--   2. تشغيل: UPDATE public.worker_logs SET fraction = 1.00 WHERE id = '<log_id>';
--   3. النتيجة المتوقعة: رسالة خطأ RLS

DO $$
BEGIN
  RAISE NOTICE '=== فحص 1: worker_logs UPDATE ===';
  RAISE NOTICE 'تحقق يدوياً: المدير لا يجب أن يستطيع UPDATE على worker_logs';
  RAISE NOTICE 'الأمر: UPDATE public.worker_logs SET fraction = 1.00 WHERE id = ''<log_id>''';
  RAISE NOTICE 'النتيجة المتوقعة: ERROR - row-level security policy violation';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 2: المدير لا يستطيع تعديل surplus_bank مباشرة
-- ============================================================
-- المتوقع: ERROR - new row violates row-level security policy

DO $$
BEGIN
  RAISE NOTICE '=== فحص 2: surplus_bank UPDATE ===';
  RAISE NOTICE 'تحقق يدوياً: المدير لا يجب أن يستطيع UPDATE على surplus_bank';
  RAISE NOTICE 'الأمر: UPDATE public.surplus_bank SET quantity = 0 WHERE id = ''<surplus_id>''';
  RAISE NOTICE 'النتيجة المتوقعة: ERROR - row-level security policy violation';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 3: المدير لا يستطيع إدراج project_cost_adjustments مباشرة
-- ============================================================
-- المتوقع: ERROR - new row violates row-level security policy

DO $$
BEGIN
  RAISE NOTICE '=== فحص 3: project_cost_adjustments INSERT ===';
  RAISE NOTICE 'تحقق يدوياً: المدير لا يجب أن يستطيع INSERT في project_cost_adjustments';
  RAISE NOTICE 'الأمر: INSERT INTO public.project_cost_adjustments (...) VALUES (...)';
  RAISE NOTICE 'النتيجة المتوقعة: ERROR - row-level security policy violation';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 4: المدير لا يستطيع إلغاء حركة خزينة مباشرة
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '=== فحص 4: treasury_transactions UPDATE (void) ===';
  RAISE NOTICE 'تحقق يدوياً: المدير لا يجب أن يستطيع UPDATE is_voided = true';
  RAISE NOTICE 'الأمر: UPDATE public.treasury_transactions SET is_voided = true WHERE id = ''<tx_id>''';
  RAISE NOTICE 'النتيجة المتوقعة: ERROR - row-level security policy violation';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 5: rpc_correct_attendance تعمل للمالك وترفض المدير
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '=== فحص 5: rpc_correct_attendance ===';
  RAISE NOTICE 'للمالك: SELECT rpc_correct_attendance(''<log_id>'', 0.50, NULL, ''تصحيح الكسر'')';
  RAISE NOTICE 'النتيجة المتوقعة للمالك: نجاح مع JSON يحتوي على التصحيح';
  RAISE NOTICE 'للمدير: نفس الاستدعاء';
  RAISE NOTICE 'النتيجة المتوقعة للمدير: ERROR - غير مصرح: تصحيح سجلات الحضور مخصص لمالك الورشة فقط';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 6: rpc_consume_surplus و rpc_scrap_surplus تعمل للمدير عبر RPC
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '=== فحص 6: surplus RPCs تعمل للمدير ===';
  RAISE NOTICE 'SELECT rpc_scrap_surplus(''<surplus_id>'', ''سبب الإتلاف هنا'')';
  RAISE NOTICE 'النتيجة المتوقعة للمدير: نجاح (SECURITY DEFINER تتجاوز RLS بأمان)';
  RAISE NOTICE 'مع تسجيل تلقائي في audit_log عبر Trigger';
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- الفحص 7: تحقق من وجود السياسات الجديدة في قاعدة البيانات
-- ============================================================

SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename IN ('worker_logs', 'surplus_bank', 'project_cost_adjustments')
  AND policyname IN (
    'worker_logs_update_owner_only',
    'surplus_bank_update_owner_only'
  )
ORDER BY tablename, policyname;

-- النتيجة المتوقعة: صفان يظهران السياستين الجديدتين بـ roles = {authenticated}
-- وcmd = UPDATE، بدون أي صف لـ cost_adj_insert (تم حذفها).

-- ============================================================
-- الفحص 8: التأكد من عدم وجود سياسات IS_STAFF على UPDATE الحساسة
-- ============================================================

SELECT tablename, policyname, qual
FROM pg_policies
WHERE tablename IN ('worker_logs', 'surplus_bank')
  AND cmd = 'UPDATE'
  AND qual LIKE '%is_staff%';

-- النتيجة المتوقعة: 0 صفوف (يجب أن لا توجد سياسة UPDATE مفتوحة للـ staff)
