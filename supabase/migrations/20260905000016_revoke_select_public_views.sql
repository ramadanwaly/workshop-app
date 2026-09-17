-- ============================================================================
-- 20260905000016_revoke_select_public_views.sql
-- Hardening: revoke SELECT on ALL tables AND views in the public schema from
-- PUBLIC and anon.
--
-- Context: every public view (v_treasury_balance, v_project_direct_costs,
-- v_pending_liabilities, v_surplus_available) and every base table was readable
-- by the anon role (and PUBLIC had the default grant). Views are treated as
-- tables by PostgreSQL, so REVOKE SELECT ON ALL TABLES covers them too.
--
-- The application reads everything through the authenticated role; removing
-- the anon/PUBLIC grants does not affect logged-in users (RLS + their explicit
-- GRANTs stay intact).
-- ============================================================================

REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM anon;