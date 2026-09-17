-- ==========================================================================
-- Migration: 20260911000033_idempotency_expiration.sql
-- C-02: Treat keys stuck in 'pending' for > 5 minutes as expired/failed
-- ==========================================================================

BEGIN;

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
    WHERE expires_at < NOW()
       OR (status = 'pending' AND created_at < NOW() - INTERVAL '5 minutes');

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_expired_idempotency_keys() IS 'دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية والمفاتيح المعلقة التي فشلت';

COMMIT;
