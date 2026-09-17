-- ============================================================================
-- 20260905000014_cleanup_functions.sql
-- Manual / External Scheduled Cleanup Functions
-- (renumbered from 20260905000011 to resolve timestamp collision with
--  20260905000011_workers_rls_owner_only.sql — the duplicate version caused
--  this file to be silently skipped by the migration runner)
-- ============================================================================

-- 1. دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية
CREATE OR REPLACE FUNCTION public.cleanup_expired_idempotency_keys()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.idempotency_keys
    WHERE expires_at < NOW();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_expired_idempotency_keys() IS 'دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية، تُستدعى يدوياً أو بجدولة خارجية وتُعيد عدد الصفوف المحذوفة.';
