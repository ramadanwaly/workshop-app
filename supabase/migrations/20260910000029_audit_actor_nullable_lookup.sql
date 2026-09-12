-- =============================================================================
-- Migration: 20260910000029_audit_actor_nullable_lookup.sql
-- Purpose  : Harden P2-06: the audit trail must NEVER break a business
--            operation. append_audit_log() used auth.uid() directly against
--            the profiles FK; any staff identity without a profiles row
--            (e.g. test fixtures, a deleted-then-recreated profile) turned
--            every audited write (consume/scrap/voids/allocations) into an
--            FK violation. The writer now resolves the profile and records a
--            NULL actor when there is none (column already nullable) — the
--            event itself is always preserved.
--            Found by: scripts/verify-concurrency.sh after the P2-03 fixture
--            fix (consumer sessions authenticate via JWT without profiles).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

CREATE OR REPLACE FUNCTION app_private.append_audit_log(
    p_action TEXT,
    p_entity_table TEXT,
    p_entity_id UUID,
    p_reason TEXT DEFAULT NULL,
    p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
    v_actor UUID;
BEGIN
    SELECT id INTO v_actor FROM public.profiles WHERE id = auth.uid();
    INSERT INTO public.audit_log (actor_id, action, entity_table, entity_id, reason, details)
    VALUES (v_actor, p_action, p_entity_table, p_entity_id, p_reason, coalesce(p_details, '{}'::jsonb))
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION app_private.append_audit_log(TEXT, TEXT, UUID, TEXT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION app_private.append_audit_log(TEXT, TEXT, UUID, TEXT, JSONB) TO authenticated;
