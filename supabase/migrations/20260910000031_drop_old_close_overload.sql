-- =============================================================================
-- Migration: 20260910000031_drop_old_close_overload.sql
-- Purpose  : Drop the superseded 2-argument overload of
--            rpc_close_subcontract_order left behind by migration 24
--            (same CREATE-OR-REPLACE-with-new-signature trap as migration 26:
--            it created an overload instead of replacing). The 3-argument
--            version (with mandatory p_reason) is the only one the app calls;
--            the stale overload made every positional 2-argument call
--            ambiguous ("function is not unique") and doubled the dashboard
--            linter warning.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

DROP FUNCTION IF EXISTS public.rpc_close_subcontract_order(UUID, TEXT);
