-- =============================================================================
-- Migration: 20260918000054_fix_b_suffix_ledger.sql
-- Purpose  : تنظيف دفتر الهجرات بعد إصلاح تسمية الملفات ذات اللاحقة b.
--
--   المشكلة: كان لدينا ملفان بلاحقة حرفية:
--     20260918000049b_surplus_rpcs_security_definer.sql
--     20260918000051b_return_surplus_security_definer.sql
--   سكريبت apply-migrations.sh يستخرج الرقم عبر grep -o '^[0-9]*' أي الأرقام
--   الأولى فقط، فيعتبر 49 و49b نفس الإصدار 20260918000049 (وكذلك 51/51b).
--   وترتيب glob في bash يضع 49b قبل 49، فنُفذ ملف الـ RPCs أولاً وسُجل في
--   الدفتر بالاسم الخطأ تحت version=20260918000049، ثم توقف السكريبت عند
--   ملف 49 الحقيقي معتبراً إياه تعديلاً (FAIL append-only).
--
--   الإصلاح (تم على مستوى الملفات، خارج قاعدة البيانات):
--     49b -> أُعيدت تسميته إلى 20260918000052_surplus_rpcs_security_definer.sql
--     51b -> أُعيدت تسميته إلى 20260918000053_return_surplus_security_definer.sql
--   وكلاهما CREATE OR REPLACE (آمن لإعادة التطبيق).
--   وملف verify_smoke.sql حُدث ليتوقع 48,49,50,51,52,53,54.
--
--   هذه الهجرة نفسها:
--   1. تزيل سطر الدفتر الخطأ (version 49 المسجل باسم ملف 49b) إن وُجد،
--      حتى يُعاد تطبيق 49 ثم 52 بالترتيب الصحيح عبر السكريبت.
--   2. تضيف حارس تسمية: أي version غير رقمي بالكامل في الدفتر يفشل فوراً،
--      لمنع تكرار لاحقة b مستقبلاً.
--
--   ملاحظة أمان: تأثير ملف 49b الأصلي (دالتا SECURITY DEFINER) سيُعاد
--   تطبيقه نظيفاً عبر ملف 52 بعد هذه الهجرة، فلا يضيع أي إصلاح أمني.
--   Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- 1. إزالة سطر الدفتر الخطأ (49 المسجل باسم 49b) إن وُجد.
--    السطر الصحيح لـ 49 سيُسجل من جديد عند تطبيق ملف 49 الحقيقي.
DELETE FROM supabase_migrations.schema_migrations
WHERE version = '20260918000049'
  AND name = '20260918000049b_surplus_rpcs_security_definer.sql';

-- 2. حارس التسمية: امنع أي version يحتوي حروفاً (مثل لاحقة b).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM supabase_migrations.schema_migrations
        WHERE version !~ '^[0-9]+$'
    ) THEN
        RAISE EXCEPTION 'تسمية هجرة غير صالحة: version يجب أن يكون أرقاماً فقط (ممنوع لاحقة b)';
    END IF;
    RAISE NOTICE 'ledger naming guard ok (all versions are pure digits)';
END $$;
