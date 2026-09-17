-- ============================================================================
-- 20260916000046_portfolio_gallery.sql
-- المرحلة 1 — معرض الأعمال العام (قاعدة البيانات فقط، بدون واجهة/Actions).
-- القرارات المثبتة (مرحلة 0): bucket باسم portfolio، حد 10 صور للمشروع،
-- 5MB للصورة، الأنواع jpeg/png/webp فقط، المسار العام /gallery.
-- المحتويات: portfolio_entries + portfolio_photos + الـView العام الوحيد
-- v_portfolio_gallery_public. الكتابة للموظفين فقط عبر is_staff().
-- لا Action ولا صفحة ولا مكوّن في هذه المرحلة.
-- Note: Migrations are append-only. Never edit an applied file.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. جدول portfolio_entries — صف واحد لكل مشروع معروض (بيانات عامة فقط)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.portfolio_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    display_title TEXT NOT NULL CHECK (
        char_length(display_title) >= 2 AND char_length(display_title) <= 200
    ),
    public_description TEXT CHECK (
        public_description IS NULL OR char_length(public_description) <= 1000
    ),
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT portfolio_entries_unique_project UNIQUE (project_id)
);

DROP TRIGGER IF EXISTS set_timestamp_portfolio_entries ON public.portfolio_entries;
CREATE TRIGGER set_timestamp_portfolio_entries
    BEFORE UPDATE ON public.portfolio_entries
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_portfolio_entries_project
    ON public.portfolio_entries(project_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_entries_completed
    ON public.portfolio_entries(completed_at DESC);

COMMENT ON TABLE public.portfolio_entries IS 'صف عرض عام واحد لكل مشروع مكتمل — الاسم والوصف المبسط فقط، بلا مالية.';
COMMENT ON COLUMN public.portfolio_entries.project_id IS 'ربط داخلي للتحقق والحذف التبعي فقط — لا يقرأ علنا أبدا.';
-- ----------------------------------------------------------------------------
-- 2. جدول portfolio_photos — صور كل entry (حتى 10 صور، مسار تخزين فقط)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.portfolio_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID NOT NULL REFERENCES public.portfolio_entries(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL CHECK (
        char_length(storage_path) >= 1 AND char_length(storage_path) <= 500
    ),
    sort_order INT NOT NULL DEFAULT 0 CHECK (sort_order >= 0 AND sort_order <= 9),
    alt_text TEXT CHECK (
        alt_text IS NULL OR char_length(alt_text) <= 200
    ),
    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT portfolio_photos_unique_path UNIQUE (storage_path)
);

CREATE INDEX IF NOT EXISTS idx_portfolio_photos_entry
    ON public.portfolio_photos(entry_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_photos_entry_sort
    ON public.portfolio_photos(entry_id, sort_order ASC);

COMMENT ON TABLE public.portfolio_photos IS 'صور المعرض العام — مسار التخزين والترتيب والنص البديل فقط، بلا مالية.';

-- ----------------------------------------------------------------------------
-- 3. حراس الاكتمال وحد الصور (أخطاء عربية P0001)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_portfolio_require_completed()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_status TEXT;
BEGIN
    SELECT status INTO v_status FROM public.projects WHERE id = NEW.project_id;
    IF NOT FOUND OR v_status IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'لا يمكن عرض مشروع غير مكتمل في معرض الأعمال' USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_portfolio_entries_completed_only ON public.portfolio_entries;
CREATE TRIGGER trg_portfolio_entries_completed_only
    BEFORE INSERT OR UPDATE OF project_id ON public.portfolio_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_portfolio_require_completed();

CREATE OR REPLACE FUNCTION public.trg_portfolio_photo_require_completed()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_status TEXT;
BEGIN
    SELECT p.status INTO v_status
    FROM public.portfolio_entries e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = NEW.entry_id;
    IF NOT FOUND OR v_status IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'لا يمكن إضافة صورة لمشروع غير مكتمل في معرض الأعمال' USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_portfolio_photos_completed_only ON public.portfolio_photos;
CREATE TRIGGER trg_portfolio_photos_completed_only
    BEFORE INSERT OR UPDATE OF entry_id ON public.portfolio_photos
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_portfolio_photo_require_completed();

CREATE OR REPLACE FUNCTION public.trg_portfolio_photo_limit()
RETURNS TRIGGER
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT count(*) INTO v_count FROM public.portfolio_photos
    WHERE entry_id = NEW.entry_id
      AND (TG_OP = 'INSERT' OR id IS DISTINCT FROM NEW.id);
    IF v_count >= 10 THEN
        RAISE EXCEPTION 'الحد الأقصى 10 صور للمشروع الواحد في معرض الأعمال' USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_portfolio_photos_max_ten ON public.portfolio_photos;
CREATE TRIGGER trg_portfolio_photos_max_ten
    BEFORE INSERT OR UPDATE OF entry_id ON public.portfolio_photos
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_portfolio_photo_limit();

REVOKE EXECUTE ON FUNCTION public.trg_portfolio_require_completed() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.trg_portfolio_require_completed() FROM anon;
REVOKE EXECUTE ON FUNCTION public.trg_portfolio_photo_require_completed() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.trg_portfolio_photo_require_completed() FROM anon;
REVOKE EXECUTE ON FUNCTION public.trg_portfolio_photo_limit() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.trg_portfolio_photo_limit() FROM anon;
-- ----------------------------------------------------------------------------
-- 4. الـView العام الوحيد — أعمدة مسماة فقط (بلا SELECT * وبلا مالية
--    وبلا project_id). الفلترة: مشروع completed + صورة واحدة على الأقل
--    (JOIN يفرض الاثنين). الترتيب: الأحدث اكتمالا أولا.
--    ملاحظة أمان: security_invoker=false مقصود هنا (عكس الـViews المالية
--    التي تستخدم true) — حتى يقرأ الزائر الـView مباشرة دون أي منح إضافي
--    على الجدولين الأساسيين، ودون أي سياسة عامة عليهما. المالك postgres
--    يتجاوز RLS داخل الـView، والـView نفسه يسرد 7 أعمدة عامة فقط.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_portfolio_gallery_public AS
SELECT
    e.id AS entry_id,
    e.display_title AS display_title,
    e.public_description AS public_description,
    ph.storage_path AS storage_path,
    ph.alt_text AS alt_text,
    ph.sort_order AS sort_order,
    e.completed_at AS completed_at
FROM public.portfolio_entries e
JOIN public.projects p ON p.id = e.project_id
JOIN public.portfolio_photos ph ON ph.entry_id = e.id
WHERE p.status = 'completed'
ORDER BY e.completed_at DESC, ph.sort_order ASC;

ALTER VIEW public.v_portfolio_gallery_public SET (security_invoker = false);

REVOKE ALL ON public.portfolio_entries FROM PUBLIC;
REVOKE ALL ON public.portfolio_entries FROM anon;
REVOKE ALL ON public.portfolio_photos FROM PUBLIC;
REVOKE ALL ON public.portfolio_photos FROM anon;
REVOKE SELECT ON public.v_portfolio_gallery_public FROM PUBLIC;
REVOKE SELECT ON public.v_portfolio_gallery_public FROM anon;
GRANT SELECT ON public.v_portfolio_gallery_public TO anon, authenticated;

COMMENT ON VIEW public.v_portfolio_gallery_public IS 'المنفذ العام الوحيد للمعرض: مشاريع مكتملة لها صور فقط — بلا مالية وبلا project_id.';
-- 5. RLS — الجدولان للموظفين فقط، ولا سياسة anon عليهما نهائيا
ALTER TABLE public.portfolio_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "portfolio_entries_select" ON public.portfolio_entries;
CREATE POLICY "portfolio_entries_select" ON public.portfolio_entries
    FOR SELECT TO authenticated USING (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_entries_insert" ON public.portfolio_entries;
CREATE POLICY "portfolio_entries_insert" ON public.portfolio_entries
    FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_entries_update" ON public.portfolio_entries;
CREATE POLICY "portfolio_entries_update" ON public.portfolio_entries
    FOR UPDATE TO authenticated
    USING (app_private.is_staff())
    WITH CHECK (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_entries_delete" ON public.portfolio_entries;
CREATE POLICY "portfolio_entries_delete" ON public.portfolio_entries
    FOR DELETE TO authenticated USING (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_photos_select" ON public.portfolio_photos;
CREATE POLICY "portfolio_photos_select" ON public.portfolio_photos
    FOR SELECT TO authenticated USING (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_photos_insert" ON public.portfolio_photos;
CREATE POLICY "portfolio_photos_insert" ON public.portfolio_photos
    FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_photos_update" ON public.portfolio_photos;
CREATE POLICY "portfolio_photos_update" ON public.portfolio_photos
    FOR UPDATE TO authenticated
    USING (app_private.is_staff())
    WITH CHECK (app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_photos_delete" ON public.portfolio_photos;
CREATE POLICY "portfolio_photos_delete" ON public.portfolio_photos
    FOR DELETE TO authenticated USING (app_private.is_staff());

-- 6. bucket واحد portfolio + سياسات storage.objects منفصلة (لا FOR ALL).
-- القراءة العامة للصور تتم عبر علامة public على الـbucket نفسه (خدمة
-- storage)، لا عبر سياسة عامة — لذا لا يوجد أي منح إضافي هنا
-- غير الاستثناء الوحيد للـView العام في القسم 4.
-- ملاحظة: حد 5MB وأنواع jpeg/png/webp مضبوطة على الـbucket نفسه أعلاه،
-- وشرط المسار completed/<uuid>/<file> في سياسة الإدراج أدناه.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'portfolio',
    'portfolio',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];
DROP POLICY IF EXISTS "portfolio_staff_read" ON storage.objects;
CREATE POLICY "portfolio_staff_read" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'portfolio' AND app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_staff_insert" ON storage.objects;
CREATE POLICY "portfolio_staff_insert" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'portfolio'
        AND app_private.is_staff()
        -- storage.foldername ترجع المجلدات فقط بلا اسم الملف:
        -- 'completed/<uuid>/<file>' تعطي {completed, uuid} أي عنصرين.
        AND (storage.foldername(name))[1] = 'completed'
        AND array_length(storage.foldername(name), 1) = 2
        AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'webp')
    );
DROP POLICY IF EXISTS "portfolio_staff_modify" ON storage.objects;
CREATE POLICY "portfolio_staff_modify" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'portfolio' AND app_private.is_staff())
    WITH CHECK (bucket_id = 'portfolio' AND app_private.is_staff());
DROP POLICY IF EXISTS "portfolio_staff_delete" ON storage.objects;
CREATE POLICY "portfolio_staff_delete" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'portfolio' AND app_private.is_staff());
