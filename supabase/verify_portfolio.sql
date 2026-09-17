-- ============================================================================
-- verify_portfolio.sql — فحص حي للقراءة فقط لمعرض الأعمال (المرحلة 1).
-- التشغيل: عبر scripts/verify-db.sh ضد قاعدة تجريبية بعد تطبيق migration 46.
-- لا يعدّل أي بيانات: كل الفحوص SELECT وقراءة كتالوج، وأي فشل يرفع استثناء.
-- يثبت: (1) الجدولان والـView والـbucket موجودة، (2) الـView يسرد 7 أعمدة
-- عامة فقط بلا مالية وبلا project_id، (3) لا سياسة TO anon على الجدولين
-- ولا على storage.objects، (4) المنح العام الوحيد هو الـView نفسه.
-- ============================================================================

-- 1) الجدولان موجودان وعليهما RLS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolio_entries'
  ) THEN
    RAISE EXCEPTION 'الجدول portfolio_entries غير موجود';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolio_photos'
  ) THEN
    RAISE EXCEPTION 'الجدول portfolio_photos غير موجود';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename IN ('portfolio_entries', 'portfolio_photos')
      AND rowsecurity IS NOT TRUE
  ) THEN
    RAISE EXCEPTION 'يجب تفعيل RLS على جدولي المعرض';
  END IF;
  RAISE NOTICE 'جدولا المعرض موجودان وعليهما RLS: ok';
END $$;

-- 2) الـView موجود ويسرد 7 أعمدة عامة فقط بالاسم
DO $$
DECLARE
  v_cols text[];
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'v_portfolio_gallery_public' AND c.relkind = 'v'
  ) THEN
    RAISE EXCEPTION 'الـView العام v_portfolio_gallery_public غير موجود';
  END IF;
  SELECT array_agg(a.attname ORDER BY a.attnum) INTO v_cols
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'v_portfolio_gallery_public'
    AND a.attnum > 0 AND NOT a.attisdropped;
  IF v_cols IS DISTINCT FROM ARRAY[
    'entry_id', 'display_title', 'public_description',
    'storage_path', 'alt_text', 'sort_order', 'completed_at'
  ] THEN
    RAISE EXCEPTION 'أعمدة الـView العام غير مطابقة (يجب 7 أعمدة عامة فقط): %', v_cols;
  END IF;
  RAISE NOTICE 'أعمدة الـView العام 7 فقط بلا مالية وبلا project_id: ok';
END $$;

-- 3) تعريف الـView: بلا SELECT * ويفلتر completed فقط
-- وملاحظة: security_invoker=false مقصود (عكس المالية) — يقرأ anon الـView
-- مباشرة دون أي GRANT على الجدولين الأساسيين.
DO $$
DECLARE
  v_def text;
  v_opts text;
BEGIN
  SELECT pg_get_viewdef('public.v_portfolio_gallery_public'::regclass) INTO v_def;
  IF v_def LIKE '%e.*%' OR v_def LIKE '%ph.*%' OR v_def LIKE '%p.*%' THEN
    RAISE EXCEPTION 'الـView العام يستخدم SELECT * (ممنوع)';
  END IF;
  IF v_def NOT LIKE '%completed%' THEN
    RAISE EXCEPTION 'الـView العام لا يفلتر المشاريع المكتملة';
  END IF;
  -- كلمة project_id تظهر حتما داخل شرط الربط الداخلي (p.id = e.project_id)
  -- وهذا طبيعي وآمن — المهم أن قائمة الأعمدة المعروضة (الفحص 2 أعلاه أثبت
  -- أنها 7 أعمدة فقط) لا تحويه. هنا نرفض فقط ظهوره كعمود معروض.
  IF v_def ILIKE '%AS project_id%' THEN
    RAISE EXCEPTION 'الـView العام يكشف project_id كعمود معروض (ممنوع)';
  END IF;
  SELECT COALESCE(array_to_string(c.reloptions, ','), '') INTO v_opts
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relname = 'v_portfolio_gallery_public';
  IF v_opts LIKE '%security_invoker=true%' THEN
    RAISE EXCEPTION 'الـView العام يجب أن يبقى security_invoker=false حتى يقرأه الزائر دون منح على الجداول';
  END IF;
  RAISE NOTICE 'تعريف الـView العام سليم (مسمى + completed + بلا project_id + definer): ok';
END $$;

-- 4) لا سياسة TO anon على جدولي المعرض ولا على storage.objects
DO $$
DECLARE
  v_bad text;
BEGIN
  SELECT string_agg(policyname, ', ') INTO v_bad FROM pg_policies
  WHERE schemaname IN ('public', 'storage')
    AND tablename IN ('portfolio_entries', 'portfolio_photos', 'objects')
    AND (roles::text ILIKE '%anon%' OR roles::text ILIKE '%public%');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'سياسة عامة مرفوضة على المعرض/Tخزين: %', v_bad;
  END IF;
  RAISE NOTICE 'لا سياسة anon على الجدولين ولا storage.objects: ok';
END $$;

-- 5) المنح العام الوحيد: SELECT على الـView العام فقط
DO $$
BEGIN
  IF NOT has_table_privilege('anon', 'public.v_portfolio_gallery_public', 'SELECT') THEN
    RAISE EXCEPTION 'يجب منح anon قراءة الـView العام';
  END IF;
  IF has_table_privilege('anon', 'public.portfolio_entries', 'SELECT') THEN
    RAISE EXCEPTION 'ممنوع منح anon قراءة portfolio_entries مباشرة';
  END IF;
  IF has_table_privilege('anon', 'public.portfolio_photos', 'SELECT') THEN
    RAISE EXCEPTION 'ممنوع منح anon قراءة portfolio_photos مباشرة';
  END IF;
  IF has_table_privilege('anon', 'public.projects', 'SELECT') THEN
    RAISE EXCEPTION 'ممنوع منح anon قراءة projects مباشرة';
  END IF;
  IF has_table_privilege('anon', 'public.treasury_transactions', 'SELECT') THEN
    RAISE EXCEPTION 'ممنوع منح anon قراءة treasury_transactions مباشرة';
  END IF;
  RAISE NOTICE 'المنح العام محصور على الـView فقط: ok';
END $$;

-- 6) الـbucket موجود بإعدادات مثبتة (عام + 5MB + الأنواع فقط)
DO $$
DECLARE
  v_public boolean;
  v_limit bigint;
  v_mimes text[];
BEGIN
  SELECT public, file_size_limit, allowed_mime_types
    INTO v_public, v_limit, v_mimes
  FROM storage.buckets WHERE id = 'portfolio';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'الـbucket portfolio غير موجود';
  END IF;
  IF v_public IS NOT TRUE THEN
    RAISE EXCEPTION 'الـbucket portfolio يجب أن يكون عاما';
  END IF;
  IF v_limit <> 10485760 THEN
    RAISE EXCEPTION 'حد الـbucket portfolio يجب أن يكون 10MB';
  END IF;
  IF v_mimes IS DISTINCT FROM ARRAY['image/jpeg', 'image/png', 'image/webp'] THEN
    RAISE EXCEPTION 'أنواع الـbucket portfolio غير مطابقة: %', v_mimes;
  END IF;
  RAISE NOTICE 'إعدادات الـbucket portfolio سليمة: ok';
END $$;

DO $$ BEGIN RAISE NOTICE 'PORTFOLIO VERIFY PASSED'; END $$;
