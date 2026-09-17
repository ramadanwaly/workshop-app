-- ============================================================================
-- consumer.sql — One concurrent request against rpc_consume_surplus
-- Each concurrent session runs this identical script.
-- Two sessions each try to consume 70 of a surplus with quantity = 100,
-- so at most ONE can succeed; the loser must raise a guard error.
-- Accepts psql variables: c_user, c_project, c_surplus, c_tag
-- ============================================================================
\set ON_ERROR_STOP off
\pset tuples_only on
\pset format unaligned
\pset pager off

-- Impersonate the seeded owner so app_private.is_staff() passes.
SET request.jwt.claims = :'claims';

-- Both sessions align on ~the same instant before firing, so the two RPC
-- calls genuinely overlap and contend for the row lock.
SELECT pg_sleep(0.5);

\echo CONSUMER_:c_tag:_START
SELECT concat_ws(
    '|',
    :'c_tag',
    'mode='   || (rpc_consume_surplus(:'c_surplus'::uuid, :'c_project'::uuid, 70, 'concurrency test'))::text
);
\echo CONSUMER_:c_tag:_END