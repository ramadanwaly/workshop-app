-- ============================================================================
-- seed_demo.sql — بيانات تجريبية (موسومة "تجريبي") لتجربة التنقل الشامل
--   لوحة التحكم ← المشاريع ← تفاصيل مشروع ← العمال ← المقاولون
-- تشغيل: psql -v ON_ERROR_STOP=1 -f seed_demo.sql  (بدور المستخدم postgres)
-- ملاحظة: يمكن حذف كل هذه الصفوف لاحقاً دون تأثير على الدفاتر الحقيقية.
-- ============================================================================

BEGIN;

INSERT INTO public.projects (name, description, status)
VALUES (
  'مشروع تجريبي — مكتبة ومكتب (احذفني لاحقاً)',
  'بيانات تجريبية لتجربة النظام، يمكن حذف المشروع والعمال والاتفاقية المرتبطة به بعد الانتهاء من التجربة.',
  'active'
);

INSERT INTO public.workers (name, daily_rate, phone, is_active)
VALUES
  ('عامل تجريبي ١ — نجار', 300, '01000000000', true),
  ('عامل تجريبي ٢ — مساعد', 200, '01100000000', true);

INSERT INTO public.subcontract_orders (project_id, contractor_name, description, total_agreed_amount, status)
SELECT
  p.id,
  'مقاول تجريبي — دهان (احذفني لاحقاً)',
  'طلاء وتشطيب — بيانات تجريبية للاتفاقية.',
  8000,
  'active'
FROM public.projects p
WHERE p.name LIKE 'مشروع تجريبي — %'
ORDER BY p.created_at DESC
LIMIT 1;

COMMIT;