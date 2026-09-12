-- =============================================================================
-- Migration: 20260910000025_rate_limits.sql
-- Purpose  : P2-04 — shared rate-limit store (survives restarts, shared across
--            instances). One atomic UPSERT per check; old windows are cleaned
--            opportunistically inside the same call, so no cron is needed.
--            Direct table access is denied to everyone (RLS enabled, no
--            policies — the table owner postgres bypasses RLS); all traffic
--            goes through increment_rate_limit(), which only writes counters
--            for well-formed buckets and is explicitly granted to anon +
--            authenticated (this single deliberate grant is allowlisted in
--            scripts/check-sql-hardening.sh).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.rate_limits (
    bucket TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL,
    count INT NOT NULL DEFAULT 1 CHECK (count >= 0),
    PRIMARY KEY (bucket, window_start)
);

ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Atomic check-and-increment. Returns {allowed, count, retry_after}.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_rate_limit(
    p_bucket TEXT,
    p_limit INT,
    p_window_seconds INT DEFAULT 60
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_start TIMESTAMPTZ;
    v_count INT;
    v_retry INT;
BEGIN
    IF p_bucket IS NULL
        OR p_bucket !~ '^[A-Za-z0-9_:\-]{1,200}$' THEN
        RAISE EXCEPTION 'مفتاح التحديد غير صالح';
    END IF;

    IF p_limit IS NULL OR p_limit < 1 OR p_limit > 1000
        OR p_window_seconds IS NULL OR p_window_seconds < 10 OR p_window_seconds > 3600 THEN
        RAISE EXCEPTION 'حد التحديد غير صالح';
    END IF;

    v_start := to_timestamp(
        floor(extract(epoch from NOW()) / p_window_seconds) * p_window_seconds
    );

    INSERT INTO public.rate_limits (bucket, window_start, count)
    VALUES (p_bucket, v_start, 1)
    ON CONFLICT (bucket, window_start)
    DO UPDATE SET count = public.rate_limits.count + 1
    RETURNING public.rate_limits.count INTO v_count;

    -- Opportunistic cleanup: drop windows older than two full windows.
    DELETE FROM public.rate_limits
    WHERE window_start < NOW() - make_interval(secs => (p_window_seconds * 2)::double precision);

    v_retry := GREATEST(0, (extract(epoch from v_start) + p_window_seconds - extract(epoch from NOW()))::INT);

    RETURN jsonb_build_object(
        'allowed', v_count <= p_limit,
        'count', v_count,
        'retry_after', v_retry
    );
END;
$$ LANGUAGE plpgsql;

-- The single deliberate anon grant (API login posts are unauthenticated).
GRANT EXECUTE ON FUNCTION public.increment_rate_limit(TEXT, INT, INT) TO anon, authenticated;
