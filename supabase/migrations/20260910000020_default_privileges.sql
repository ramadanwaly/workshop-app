-- =============================================================================
-- Migration: 20260910000020_default_privileges.sql
-- Purpose  : P1-06 — deny-by-default for FUTURE objects in schema public.
--
-- Background: Supabase configures default privileges so that every table,
-- sequence or function created later by postgres/supabase_admin is
-- automatically granted to anon (and PUBLIC). Migrations 15/16 revoked those
-- grants on EXISTING objects only — any new table/function added by a future
-- migration would silently become callable/readable by anonymous users until
-- someone remembers to revoke. (Correction: the comment in migration 15
-- claiming ALL FUNCTIONS "stays true for any function added later" is wrong;
-- REVOKE ... ON ALL ... IN SCHEMA only touches objects existing at that
-- moment. This migration is the real forward-looking fix.)
--
-- What this does (future objects in public only; existing grants untouched):
--   1. FUNCTIONS: no EXECUTE for PUBLIC/anon. `authenticated` keeps the
--      default so new RPCs keep working for logged-in staff; per-RPC role
--      checks (app_private.is_owner()/is_staff()) + RLS stay mandatory by
--      convention and are covered by scripts/check-sql-hardening.sh.
--   2. TABLES/VIEWS: no privileges at all for PUBLIC/anon (covers SELECT,
--      INSERT, UPDATE, DELETE, ...). Future tables additionally REQUIRE an
--      explicit GRANT + RLS policies; the smoke suite already fails if any
--      public table lacks RLS.
--   3. SEQUENCES: no privileges for PUBLIC/anon (no nextval/currval probing).
--   service_role keeps its defaults (server-side jobs need it).
-- CRITICAL FINDING (verified live 2026-09-10 with probe functions):
-- schema-scoped REVOKE (IN SCHEMA public) is NOT enough for FUNCTIONS here:
-- a new function still got PUBLIC EXECUTE (the built-in function default
-- shines through the schema-scoped entry). Only the GLOBAL (schema-less)
-- REVOKE actually suppresses it — verified: probe function created after the
-- global revoke has proacl {postgres, authenticated, service_role} with NO
-- public entry, while anon-authenticated behavior is unchanged.
-- Therefore every rule below is applied BOTH globally and schema-scoped
-- (belt and suspenders; both are idempotent).
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Future FUNCTIONS: revoke EXECUTE from PUBLIC and anon (global + public).
--    `authenticated` keeps the default so new RPCs keep working for logged-in
--    staff; per-RPC role checks + RLS stay mandatory by convention (CI gate:
--    scripts/check-sql-hardening.sh).
-- ----------------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES FOR ROLE postgres
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;

-- ----------------------------------------------------------------------------
-- 2. Future TABLES (incl. views): revoke everything from PUBLIC/anon.
-- ----------------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES FOR ROLE postgres
    REVOKE ALL ON TABLES FROM PUBLIC, anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE ALL ON TABLES FROM PUBLIC, anon;

-- ----------------------------------------------------------------------------
-- 3. Future SEQUENCES: revoke everything from PUBLIC/anon.
-- ----------------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES FOR ROLE postgres
    REVOKE ALL ON SEQUENCES FROM PUBLIC, anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM PUBLIC, anon;

-- ----------------------------------------------------------------------------
-- NOTE on supabase_admin (verified live 2026-09-10): postgres is NOT a
-- superuser here (supabase_admin is), so defaults owned by supabase_admin
-- cannot be altered from a migration. Acceptable: Supabase platform objects
-- live in other schemas, every app object in public is created by postgres,
-- and dashboard SQL-editor objects are created as postgres by default.
-- ----------------------------------------------------------------------------
