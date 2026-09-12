-- Migration: Revoke unnecessary EXECUTE grant on rpc_run_operating_allocation from anon
--
-- Context: The function is already protected internally via app_private.is_owner()
-- which rejects non-owners before any execution. However, granting EXECUTE to the
-- anon role is unnecessary and violates least-privilege best practice.
-- This migration adds a second layer of defense at the database permission level.

REVOKE EXECUTE ON FUNCTION rpc_run_operating_allocation(date) FROM anon;
