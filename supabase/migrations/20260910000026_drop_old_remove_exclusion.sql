-- =============================================================================
-- Migration: 20260910000026_drop_old_remove_exclusion.sql
-- Purpose  : Drop the superseded 2-argument overload of
--            rpc_remove_operating_exclusion left behind by migration 24
--            (CREATE OR REPLACE with a new signature creates an overload
--            instead of replacing). The 3-argument version (with mandatory
--            p_reason) is the only one the app calls.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

DROP FUNCTION IF EXISTS public.rpc_remove_operating_exclusion(DATE, UUID);
