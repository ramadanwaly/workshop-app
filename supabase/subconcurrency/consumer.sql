-- ============================================================================
-- consumer.sql — One concurrent request against rpc_pay_subcontract
-- Each concurrent session runs this identical script.
-- Two sessions each try to pay 70 of an order with total_agreed_amount = 100,
-- so at most ONE can succeed; the loser must raise a guard error.
-- Accepts psql variables: c_user, c_project, c_order, c_tag
-- ============================================================================
\set ON_ERROR_STOP off
\pset tuples_only on
\pset format unaligned
\pset pager off

-- Impersonate the seeded owner so app_private.is_owner() passes.
SET request.jwt.claims = :'claims';

-- Both sessions align on ~the same instant before firing, so the two RPC
-- calls genuinely overlap and contend for the order row lock (FOR UPDATE).
SELECT pg_sleep(0.5);

\echo PAYER_:c_tag:_START
SELECT concat_ws(
    '|',
    :'c_tag',
    'mode='   || (rpc_pay_subcontract(:'c_order'::uuid, 70, CURRENT_DATE, 'concurrency pay'))::text
);
\echo PAYER_:c_tag:_END