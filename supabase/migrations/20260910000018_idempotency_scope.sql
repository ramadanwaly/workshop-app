-- =============================================================================
-- Migration: 20260910000018_idempotency_scope.sql
-- Purpose  : P1-04 — restrict idempotency_keys so that:
--              1. Users can only SELECT / INSERT their own rows (no DELETE/UPDATE
--                 from the client — completed status is written server-side only).
--              2. The combination (key, user_id, action) is unique, so an attacker
--                 cannot pre-reserve another user's key, and the same UUID can be
--                 reused safely across different actions by different users.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Drop the broad FOR ALL policy and replace with SELECT + INSERT only.
--    UPDATE is intentionally omitted: the server-side function (running under the
--    authenticated role) updates via .eq('key').eq('user_id') which passes RLS.
--    DELETE is intentionally omitted: completed keys must be immutable.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "idempotency_keys_user" ON public.idempotency_keys;

CREATE POLICY "idempotency_keys_select"
    ON public.idempotency_keys
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "idempotency_keys_insert"
    ON public.idempotency_keys
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- UPDATE is needed for markIdempotencyCompleted (sets status='completed').
-- Restrict to owner rows only, and only allow moving to 'completed' status.
CREATE POLICY "idempotency_keys_update_own_pending"
    ON public.idempotency_keys
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 2. Replace the global PRIMARY KEY on (key) alone with a composite key on
--    (key, user_id, action).
--    Why: the old PK made every UUID globally unique, so user B reusing the
--    same UUID (or an attacker pre-reserving victim's key) collided even with
--    different user_id/action. The composite key gives each user+action its
--    own idempotency slot.
--    Old transient rows without user_id/action cannot be scoped, so they are
--    removed first (idempotency keys expire after 24h anyway).
-- -----------------------------------------------------------------------------
DELETE FROM public.idempotency_keys WHERE user_id IS NULL OR action IS NULL;

ALTER TABLE public.idempotency_keys
    ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE public.idempotency_keys
    DROP CONSTRAINT IF EXISTS idempotency_keys_pkey;

ALTER TABLE public.idempotency_keys
    DROP CONSTRAINT IF EXISTS idempotency_keys_key_user_action_unique;

ALTER TABLE public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_pkey
    PRIMARY KEY (key, user_id, action);
