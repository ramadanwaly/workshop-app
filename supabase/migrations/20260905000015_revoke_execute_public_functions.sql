-- ============================================================================
-- 20260905000015_revoke_execute_public_functions.sql
-- Hardening: revoke EXECUTE on ALL public-schema functions from PUBLIC and anon.
--
-- Context: 11 public functions (RPCs + helpers) were executable by the anon
-- role and by PUBLIC by default, which violates least-privilege. The fix was
-- applied manually to the production database; this migration records that same
-- fix as a replayable, official migration.
--
-- Note: this is intentionally expressed as ALL FUNCTIONS (not a one-off
-- per-function list) so the invariant stays true for any function added later
-- to the public schema.
-- ============================================================================

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;