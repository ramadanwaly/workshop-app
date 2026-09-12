--
-- PostgreSQL database dump
--

\restrict nGCUiw1DmBshtb4gHNPApJfIIjo9O75qd7nuE17P5JOXuWcsMSDLifXMz7YKQxS

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _realtime; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA _realtime;


ALTER SCHEMA _realtime OWNER TO supabase_admin;

--
-- Name: app_private; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA app_private;


ALTER SCHEMA app_private OWNER TO postgres;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO supabase_admin;

--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA extensions;


ALTER SCHEMA extensions OWNER TO postgres;

--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql;


ALTER SCHEMA graphql OWNER TO supabase_admin;

--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql_public;


ALTER SCHEMA graphql_public OWNER TO supabase_admin;

--
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_net IS 'Async HTTP';


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: pgbouncer
--

CREATE SCHEMA pgbouncer;


ALTER SCHEMA pgbouncer OWNER TO pgbouncer;

--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA realtime;


ALTER SCHEMA realtime OWNER TO supabase_admin;

--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO supabase_admin;

--
-- Name: supabase_functions; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA supabase_functions;


ALTER SCHEMA supabase_functions OWNER TO supabase_admin;

--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA supabase_migrations;


ALTER SCHEMA supabase_migrations OWNER TO postgres;

--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA vault;


ALTER SCHEMA vault OWNER TO supabase_admin;

--
-- Name: hypopg; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hypopg WITH SCHEMA extensions;


--
-- Name: EXTENSION hypopg; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hypopg IS 'Hypothetical indexes for PostgreSQL';


--
-- Name: index_advisor; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS index_advisor WITH SCHEMA extensions;


--
-- Name: EXTENSION index_advisor; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION index_advisor IS 'Query index advisor';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE auth.aal_level OWNER TO supabase_auth_admin;

--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


ALTER TYPE auth.code_challenge_method OWNER TO supabase_auth_admin;

--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE auth.factor_status OWNER TO supabase_auth_admin;

--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE auth.oauth_authorization_status OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE auth.oauth_client_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE auth.oauth_registration_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


ALTER TYPE auth.oauth_response_type OWNER TO supabase_auth_admin;

--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE auth.one_time_token_type OWNER TO supabase_auth_admin;

--
-- Name: action; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


ALTER TYPE realtime.action OWNER TO supabase_admin;

--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


ALTER TYPE realtime.equality_op OWNER TO supabase_admin;

--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


ALTER TYPE realtime.user_defined_filter OWNER TO supabase_admin;

--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


ALTER TYPE realtime.wal_column OWNER TO supabase_admin;

--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


ALTER TYPE realtime.wal_rls OWNER TO supabase_admin;

--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


ALTER TYPE storage.buckettype OWNER TO supabase_storage_admin;

--
-- Name: append_audit_log(text, text, uuid, text, jsonb); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.append_audit_log(p_action text, p_entity_table text, p_entity_id uuid, p_reason text DEFAULT NULL::text, p_details jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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
$$;


ALTER FUNCTION app_private.append_audit_log(p_action text, p_entity_table text, p_entity_id uuid, p_reason text, p_details jsonb) OWNER TO postgres;

--
-- Name: current_user_role(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.current_user_role() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION app_private.current_user_role() OWNER TO postgres;

--
-- Name: is_owner(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.is_owner() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT (app_private.current_user_role() = 'owner');
$$;


ALTER FUNCTION app_private.is_owner() OWNER TO postgres;

--
-- Name: is_staff(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.is_staff() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT (app_private.current_user_role() IN ('owner', 'manager'));
$$;


ALTER FUNCTION app_private.is_staff() OWNER TO postgres;

--
-- Name: run_operating_allocation(date); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.run_operating_allocation(p_year_month date) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_month_start   DATE;
    v_month_end     DATE;
    v_total         NUMERIC(12,2);
    v_cycle_id      UUID;
    v_eligible      UUID[] := NULL;
    v_excluded      UUID[] := NULL;
    v_count         INT;
    v_total_cents   BIGINT;
    v_share_cents   BIGINT;
    v_remainder     INT;
    v_amt           NUMERIC(12,2);
    v_alloc_sum     NUMERIC(12,2) := 0;
    v_note          TEXT;
    i               INT;
BEGIN
    v_month_start := date_trunc('month', p_year_month)::date;
    v_month_end   := (v_month_start + INTERVAL '1 month')::date;

    -- 1. Idempotency: one non-voided cycle per month (partial unique index guarantees <= 1)
    SELECT c.id INTO v_cycle_id
    FROM public.operating_allocation_cycles c
    WHERE c.year_month = v_month_start AND NOT c.is_voided;

    IF v_cycle_id IS NOT NULL THEN
        RETURN jsonb_build_object('status', 'already_exists', 'cycle_id', v_cycle_id);
    END IF;

    -- 2. Lock + sum the month's valid operating expenses
    -- (FOR UPDATE cannot combine with SUM in PG 14+; lock rows first via temp table)
    CREATE TEMP TABLE _locked_operating AS
        SELECT tt.amount
        FROM public.treasury_transactions tt
        WHERE tt.category = 'workshop_operating'
          AND NOT tt.is_voided
          AND NOT tt.is_direct_owner_payment
          AND tt.created_at >= v_month_start
          AND tt.created_at <  v_month_end
        FOR UPDATE;
    SELECT COALESCE(SUM(amount), 0) INTO v_total FROM _locked_operating;
    DROP TABLE _locked_operating;

    IF v_total = 0 THEN
        INSERT INTO public.operating_allocation_cycles (year_month, status, total_amount, notes, created_by)
        VALUES (v_month_start, 'noop', 0, 'لا توجد مصاريف تشغيل لهذا الشهر', auth.uid())
        RETURNING id INTO v_cycle_id;
        RETURN jsonb_build_object('status', 'noop', 'month', v_month_start,
            'cycle_id', v_cycle_id, 'total_amount', 0, 'allocated_lines', 0);
    END IF;

    -- 3. Primary pool: projects with recorded activity DATED IN the month (cancelled excluded)
    SELECT ARRAY_AGG(p.id ORDER BY p.id)
    INTO v_eligible
    FROM public.projects p
    WHERE p.status <> 'cancelled'
      AND (
          EXISTS (SELECT 1 FROM public.worker_logs wl
                  WHERE wl.project_id = p.id AND wl.log_date >= v_month_start AND wl.log_date < v_month_end)
          OR EXISTS (SELECT 1 FROM public.treasury_transactions tt
                     WHERE tt.project_id = p.id AND NOT tt.is_voided
                       AND tt.created_at >= v_month_start AND tt.created_at < v_month_end)
          OR EXISTS (SELECT 1 FROM public.subcontract_orders so
                     WHERE so.project_id = p.id AND so.status <> 'cancelled'
                       AND so.created_at >= v_month_start AND so.created_at < v_month_end)
          OR EXISTS (SELECT 1 FROM public.project_cost_adjustments pca
                     WHERE pca.project_id = p.id AND NOT pca.is_voided
                       AND pca.created_at >= v_month_start AND pca.created_at < v_month_end)
          OR (p.created_at >= v_month_start AND p.created_at < v_month_end)
      );

    -- 4. Fallback pool when the activity pool is empty: completed/on_hold (never cancelled)
    IF v_eligible IS NULL OR cardinality(v_eligible) = 0 THEN
        SELECT ARRAY_AGG(p.id ORDER BY p.id)
        INTO v_eligible
        FROM public.projects p
        WHERE p.status IN ('completed', 'on_hold');
        v_note := 'حوض بديل: لا يوجد نشاط مسجل في الشهر';
    END IF;

    -- 5. Apply per-cycle exclusions; the excluded share is redistributed equally among the rest
    SELECT ARRAY_AGG(e.project_id)
    INTO v_excluded
    FROM public.operating_allocation_exclusions e
    WHERE e.year_month = v_month_start;

    IF v_excluded IS NOT NULL AND cardinality(v_excluded) > 0 THEN
        SELECT ARRAY(SELECT x FROM unnest(v_eligible) x
                     EXCEPT SELECT y FROM unnest(v_excluded) y
                     ORDER BY 1)
        INTO v_eligible;
    END IF;

    IF v_eligible IS NULL OR cardinality(v_eligible) = 0 THEN
        INSERT INTO public.operating_allocation_cycles (year_month, status, total_amount, notes, created_by)
        VALUES (v_month_start, 'noop', v_total, 'لا توجد مشاريع مؤهلة بعد الاستبعادات', auth.uid())
        RETURNING id INTO v_cycle_id;
        RETURN jsonb_build_object('status', 'noop', 'month', v_month_start,
            'cycle_id', v_cycle_id, 'total_amount', v_total, 'allocated_lines', 0);
    END IF;

    -- 6. Equal shares, exact cents: floor to 2 decimals, leftover as 0.01 to the first projects
    v_count       := cardinality(v_eligible);
    v_total_cents := (v_total * 100)::BIGINT;
    v_share_cents := FLOOR(v_total_cents::NUMERIC / v_count)::BIGINT;
    v_remainder   := (v_total_cents - v_share_cents * v_count)::INT;

    INSERT INTO public.operating_allocation_cycles
        (year_month, status, total_amount, eligible_project_ids, notes, created_by)
    VALUES (v_month_start, 'applied', v_total, v_eligible, v_note, auth.uid())
    RETURNING id INTO v_cycle_id;

    FOR i IN 1..v_count LOOP
        v_amt := (v_share_cents + CASE WHEN i <= v_remainder THEN 1 ELSE 0 END) / 100.0;
        INSERT INTO public.project_cost_adjustments
            (project_id, adjustment_type, amount, notes, operating_cycle_id)
        VALUES
            (v_eligible[i], 'operating_allocation', v_amt,
             'نصيب شهري من مصاريف تشغيل الورشة (' || to_char(v_month_start, 'YYYY-MM') || ')',
             v_cycle_id);
        v_alloc_sum := v_alloc_sum + v_amt;
    END LOOP;

    RETURN jsonb_build_object('status', 'applied', 'month', v_month_start, 'cycle_id', v_cycle_id,
        'total_amount', v_total, 'allocated_lines', v_count, 'allocated_sum', v_alloc_sum);
EXCEPTION
    WHEN unique_violation THEN
        -- concurrent run lost the race; the winner's commitment now exists
        RETURN jsonb_build_object('status', 'already_exists', 'note', 'concurrent run detected');
END;
$$;


ALTER FUNCTION app_private.run_operating_allocation(p_year_month date) OWNER TO postgres;

--
-- Name: trg_log_alloc_cycle_insert(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_alloc_cycle_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    PERFORM app_private.append_audit_log(
        'run_operating_allocation', 'operating_allocation_cycles', NEW.id, NEW.notes,
        jsonb_build_object(
            'year_month', NEW.year_month,
            'status', NEW.status,
            'total_amount', NEW.total_amount
        )
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_alloc_cycle_insert() OWNER TO postgres;

--
-- Name: trg_log_alloc_cycle_void(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_alloc_cycle_void() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_allocation_cycle', 'operating_allocation_cycles', NEW.id, NEW.void_reason,
            jsonb_build_object('year_month', NEW.year_month, 'total_amount', NEW.total_amount)
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_alloc_cycle_void() OWNER TO postgres;

--
-- Name: trg_log_cost_adj_insert(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_cost_adj_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_action TEXT;
BEGIN
    v_action := CASE NEW.adjustment_type
        WHEN 'surplus_return' THEN 'return_surplus'
        WHEN 'surplus_consumption' THEN 'consume_surplus'
        WHEN 'surplus_scrap' THEN 'scrap_surplus'
        ELSE NULL
    END;
    IF v_action IS NOT NULL THEN
        PERFORM app_private.append_audit_log(
            v_action, 'project_cost_adjustments', NEW.id, NEW.notes,
            jsonb_build_object(
                'adjustment_type', NEW.adjustment_type,
                'amount', NEW.amount,
                'project_id', NEW.project_id,
                'surplus_id', NEW.surplus_id,
                'operating_cycle_id', NEW.operating_cycle_id
            )
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_cost_adj_insert() OWNER TO postgres;

--
-- Name: trg_log_cost_adj_void(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_cost_adj_void() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE
        AND NEW.adjustment_type = 'operating_allocation' THEN
        PERFORM app_private.append_audit_log(
            'void_allocation_line', 'project_cost_adjustments', NEW.id, NEW.void_reason,
            jsonb_build_object('amount', NEW.amount, 'project_id', NEW.project_id)
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_cost_adj_void() OWNER TO postgres;

--
-- Name: trg_log_suborder_close(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_suborder_close() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF OLD.status = 'active' AND NEW.status IN ('completed', 'cancelled') THEN
        PERFORM app_private.append_audit_log(
            'close_subcontract_order', 'subcontract_orders', NEW.id, NEW.close_reason,
            jsonb_build_object('status', NEW.status, 'total_agreed_amount', NEW.total_agreed_amount)
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_suborder_close() OWNER TO postgres;

--
-- Name: trg_log_subpay_void(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_subpay_void() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_subcontract_payment', 'subcontract_payments', NEW.id, NEW.void_reason,
            jsonb_build_object('amount', NEW.amount, 'order_id', NEW.subcontract_order_id)
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_subpay_void() OWNER TO postgres;

--
-- Name: trg_log_treasury_void(); Type: FUNCTION; Schema: app_private; Owner: postgres
--

CREATE FUNCTION app_private.trg_log_treasury_void() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF OLD.is_voided IS NOT TRUE AND NEW.is_voided IS TRUE THEN
        PERFORM app_private.append_audit_log(
            'void_treasury', 'treasury_transactions', NEW.id, NEW.void_reason,
            jsonb_build_object(
                'amount', NEW.amount,
                'category', NEW.category,
                'transaction_type', NEW.transaction_type
            )
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION app_private.trg_log_treasury_void() OWNER TO postgres;

--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION auth.email() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION auth.jwt() OWNER TO supabase_auth_admin;

--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION auth.role() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION auth.uid() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_cron_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
begin
    if not exists (
        select 1
        from pg_event_trigger_ddl_commands() ev
        join pg_catalog.pg_extension e on ev.objid = e.oid
        where e.extname = 'pg_graphql'
    ) then
        return;
    end if;

    drop function if exists graphql_public.graphql;
    create or replace function graphql_public.graphql(
        "operationName" text default null,
        query text default null,
        variables jsonb default null,
        extensions jsonb default null
    )
        returns jsonb
        language sql
    as $$
        select graphql.resolve(
            query := query,
            variables := coalesce(variables, '{}'),
            "operationName" := "operationName",
            extensions := extensions
        );
    $$;

    -- Attach the wrapper to the extension so DROP EXTENSION cascades to it,
    -- which in turn triggers set_graphql_placeholder to reinstall the "not enabled" stub.
    alter extension pg_graphql add function graphql_public.graphql(text, text, jsonb, jsonb);

    grant usage on schema graphql to postgres, anon, authenticated, service_role;
    grant execute on function graphql.resolve to postgres, anon, authenticated, service_role;
    grant usage on schema graphql to postgres with grant option;
    grant usage on schema graphql_public to postgres with grant option;
end;
$_$;


ALTER FUNCTION extensions.grant_pg_graphql_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_net_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_ddl_watch() OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_drop_watch() OWNER TO supabase_admin;

--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


ALTER FUNCTION extensions.set_graphql_placeholder() OWNER TO supabase_admin;

--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: graphql(text, text, jsonb, jsonb); Type: FUNCTION; Schema: graphql_public; Owner: supabase_admin
--

CREATE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


ALTER FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) OWNER TO supabase_admin;

--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: supabase_admin
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


ALTER FUNCTION pgbouncer.get_auth(p_usename text) OWNER TO supabase_admin;

--
-- Name: cleanup_expired_idempotency_keys(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_expired_idempotency_keys() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.idempotency_keys
    WHERE expires_at < NOW();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$;


ALTER FUNCTION public.cleanup_expired_idempotency_keys() OWNER TO postgres;

--
-- Name: FUNCTION cleanup_expired_idempotency_keys(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.cleanup_expired_idempotency_keys() IS 'دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية، تُستدعى يدوياً أو بجدولة خارجية وتُعيد عدد الصفوف المحذوفة.';


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    users_count INT;
BEGIN
    SELECT COUNT(*) INTO users_count FROM public.profiles;

    IF users_count = 0 THEN
        INSERT INTO public.profiles (id, full_name, role)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
            'owner'
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: increment_rate_limit(text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer DEFAULT 60) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
    v_start TIMESTAMPTZ;
    v_count INT;
    v_retry INT;
BEGIN
    IF p_bucket IS NULL
        OR p_bucket !~ '^[A-Za-z0-9_:\-]{1,200}$' THEN
        RAISE EXCEPTION 'مفتاح التحديد غير صالح';
    END IF;

    IF p_limit IS NULL OR p_limit < 1 OR p_limit > 1000
        OR p_window_seconds IS NULL OR p_window_seconds < 10 OR p_window_seconds > 3600 THEN
        RAISE EXCEPTION 'حد التحديد غير صالح';
    END IF;

    v_start := to_timestamp(
        floor(extract(epoch from NOW()) / p_window_seconds) * p_window_seconds
    );

    INSERT INTO public.rate_limits (bucket, window_start, count)
    VALUES (p_bucket, v_start, 1)
    ON CONFLICT (bucket, window_start)
    DO UPDATE SET count = public.rate_limits.count + 1
    RETURNING public.rate_limits.count INTO v_count;

    -- Opportunistic cleanup: drop windows older than two full windows.
    DELETE FROM public.rate_limits
    WHERE window_start < NOW() - make_interval(secs => (p_window_seconds * 2)::double precision);

    v_retry := GREATEST(0, (extract(epoch from v_start) + p_window_seconds - extract(epoch from NOW()))::INT);

    RETURN jsonb_build_object(
        'allowed', v_count <= p_limit,
        'count', v_count,
        'retry_after', v_retry
    );
END;
$_$;


ALTER FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer) OWNER TO postgres;

--
-- Name: prevent_audit_log_mutation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_audit_log_mutation() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
    RAISE EXCEPTION 'سجل التدقيق دائم ولا يمكن تعديله أو حذفه';
END;
$$;


ALTER FUNCTION public.prevent_audit_log_mutation() OWNER TO postgres;

--
-- Name: prevent_treasury_update_tampering(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_treasury_update_tampering() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
    -- 1. A voided row can never be reopened.
    IF OLD.is_voided AND NOT NEW.is_voided THEN
        RAISE EXCEPTION 'هذه الحركة ملغاة ولا يمكن إعادة فتحها';
    END IF;

    -- 2. Money-routing columns are immutable on every update.
    --    Voiding flips only is_voided/voided_at/void_reason/voided_by.
    IF NEW.amount IS DISTINCT FROM OLD.amount
        OR NEW.transaction_type IS DISTINCT FROM OLD.transaction_type
        OR NEW.category IS DISTINCT FROM OLD.category
        OR NEW.project_id IS DISTINCT FROM OLD.project_id
        OR NEW.is_direct_owner_payment IS DISTINCT FROM OLD.is_direct_owner_payment
        OR NEW.created_by IS DISTINCT FROM OLD.created_by
        OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'تعديل بيانات الحركة المالية ممنوع — المتاح هو الإلغاء بسبب فقط';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_treasury_update_tampering() OWNER TO postgres;

--
-- Name: rpc_add_operating_exclusion(date, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;
    INSERT INTO public.operating_allocation_exclusions (year_month, project_id, reason, created_by)
    VALUES (date_trunc('month', p_year_month)::date, p_project_id, p_reason, auth.uid())
    ON CONFLICT (year_month, project_id) DO NOTHING;
    PERFORM app_private.append_audit_log(
        'add_operating_exclusion', 'operating_allocation_exclusions', p_project_id, p_reason,
        jsonb_build_object('year_month', date_trunc('month', p_year_month)::date, 'project_id', p_project_id)
    );
    RETURN jsonb_build_object('year_month', date_trunc('month', p_year_month)::date,
        'project_id', p_project_id, 'added', true);
END;
$$;


ALTER FUNCTION public.rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: rpc_close_subcontract_order(uuid, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_close_subcontract_order(p_order_id uuid, p_status text DEFAULT 'completed'::text, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_order RECORD;
    v_paid  NUMERIC(12,2);
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';
    END IF;

    IF p_status NOT IN ('completed', 'cancelled') THEN
        RAISE EXCEPTION 'حالة الإغلاق غير صالحة (يسمح فقط بـ completed أو cancelled)';
    END IF;

    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإغلاق (3 أحرف على الأقل)';
    END IF;

    SELECT * INTO v_order
    FROM public.subcontract_orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';
    END IF;

    IF v_order.status != 'active' THEN
        RAISE EXCEPTION 'الاتفاقية مغلقة بالفعل (حالتها: %)', v_order.status;
    END IF;

    IF p_status = 'completed' THEN
        v_paid := COALESCE((
            SELECT SUM(amount)
            FROM public.subcontract_payments
            WHERE subcontract_order_id = p_order_id
              AND NOT is_voided
        ), 0);

        IF v_paid <> v_order.total_agreed_amount THEN
            RAISE EXCEPTION
                'لا يمكن إغلاق الاتفاقية كـ completed: يوجد رصيد غير مدفوع (المتبقي %)',
                v_order.total_agreed_amount - v_paid;
        END IF;
    END IF;

    UPDATE public.subcontract_orders
    SET status = p_status,
        close_reason = p_reason
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'order_id', p_order_id,
        'status', p_status
    );
END;
$$;


ALTER FUNCTION public.rpc_close_subcontract_order(p_order_id uuid, p_status text, p_reason text) OWNER TO postgres;

--
-- Name: rpc_consume_surplus(uuid, uuid, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_surplus RECORD;
    v_consumed_value NUMERIC(12,2);
    v_child_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_consume_qty <= 0 THEN
        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'هذا العنصر غير متاح للاستهلاك (حالته: %)', v_surplus.status;
    END IF;

    IF v_surplus.source_project_id IS NOT NULL
        AND v_surplus.source_project_id = p_target_project_id THEN
        RAISE EXCEPTION 'لا يمكن استهلاك الفائض لنفس مشروع المصدر — اختر مشروعاً آخر';
    END IF;

    IF p_consume_qty > v_surplus.quantity THEN
        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity;
    END IF;

    IF p_consume_qty = v_surplus.quantity THEN
        v_consumed_value := v_surplus.estimated_value;

        UPDATE public.surplus_bank
        SET quantity = 0,
            estimated_value = 0,
            status = 'consumed'
        WHERE id = p_surplus_id;

        INSERT INTO public.project_cost_adjustments (
            project_id, adjustment_type, amount, surplus_id, notes
        ) VALUES (
            p_target_project_id, 'surplus_consumption', v_consumed_value, p_surplus_id, p_notes
        ) RETURNING id INTO v_adjustment_id;

        RETURN jsonb_build_object(
            'mode', 'full_consumption',
            'surplus_id', p_surplus_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value', v_consumed_value,
            'adjustment_id', v_adjustment_id
        );
    ELSE
        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);

        UPDATE public.surplus_bank
        SET quantity = quantity - p_consume_qty,
            estimated_value = estimated_value - v_consumed_value
        WHERE id = p_surplus_id;

        INSERT INTO public.surplus_bank (
            material_name, unit, quantity, initial_quantity, estimated_value,
            source_project_id, status, parent_surplus_id, notes
        ) VALUES (
            v_surplus.material_name, v_surplus.unit, p_consume_qty, p_consume_qty, v_consumed_value,
            v_surplus.source_project_id, 'consumed', v_surplus.id, p_notes
        ) RETURNING id INTO v_child_id;

        INSERT INTO public.project_cost_adjustments (
            project_id, adjustment_type, amount, surplus_id, notes
        ) VALUES (
            p_target_project_id, 'surplus_consumption', v_consumed_value, v_child_id, p_notes
        ) RETURNING id INTO v_adjustment_id;

        RETURN jsonb_build_object(
            'mode', 'partial_consumption',
            'parent_surplus_id', p_surplus_id,
            'child_surplus_id', v_child_id,
            'consumed_quantity', p_consume_qty,
            'consumed_value', v_consumed_value,
            'remaining_quantity', v_surplus.quantity - p_consume_qty,
            'remaining_value', v_surplus.estimated_value - v_consumed_value,
            'adjustment_id', v_adjustment_id
        );
    END IF;
END;
$$;


ALTER FUNCTION public.rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text) OWNER TO postgres;

--
-- Name: rpc_create_subcontract_order(uuid, text, text, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_order_id  UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';
    END IF;

    IF p_total_agreed_amount <= 0 THEN
        RAISE EXCEPTION 'المبلغ المتفق عليه يجب أن يكون أكبر من صفر';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;

    INSERT INTO public.subcontract_orders (
        project_id, contractor_name, description, total_agreed_amount, status
    ) VALUES (
        p_project_id, p_contractor_name, p_description, p_total_agreed_amount, 'active'
    ) RETURNING id INTO v_order_id;

    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'project_id', p_project_id,
        'contractor_name', p_contractor_name,
        'total_agreed_amount', p_total_agreed_amount,
        'status', 'active'
    );
END;
$$;


ALTER FUNCTION public.rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric) OWNER TO postgres;

--
-- Name: rpc_pay_subcontract(uuid, numeric, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_order       RECORD;
    v_paid        NUMERIC(12,2);
    v_payment_id  UUID;
    v_tx_id       UUID;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: سداد مقاولي الباطن مخصص لمالك الورشة فقط';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ الدفعة يجب أن يكون أكبر من صفر';
    END IF;

    SELECT * INTO v_order
    FROM public.subcontract_orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';
    END IF;

    IF v_order.status != 'active' THEN
        RAISE EXCEPTION 'لا يمكن سداد اتفاقية مغلقة (حالتها: %)', v_order.status;
    END IF;

    v_paid := COALESCE((
        SELECT SUM(amount)
        FROM public.subcontract_payments
        WHERE subcontract_order_id = p_order_id
          AND NOT is_voided
    ), 0);

    IF v_paid + p_amount > v_order.total_agreed_amount THEN
        RAISE EXCEPTION
            'دفعة مرفوضة: مجموع المدفوعات (%) + هذه الدفعة (%) يتجاوز المبلغ المتفق عليه (%)',
            v_paid, p_amount, v_order.total_agreed_amount;
    END IF;

    SELECT auth.uid() INTO v_current_user;

    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    ) VALUES (
        'out', 'subcontract_payment', p_amount,
        COALESCE(p_notes, 'دفعة لمقاول الباطن: ' || v_order.contractor_name || ' - ' || v_order.description),
        v_current_user
    ) RETURNING id INTO v_tx_id;

    INSERT INTO public.subcontract_payments (
        subcontract_order_id, amount, payment_date, treasury_transaction_id, notes
    ) VALUES (
        p_order_id, p_amount, p_payment_date, v_tx_id, p_notes
    ) RETURNING id INTO v_payment_id;

    RETURN jsonb_build_object(
        'payment_id', v_payment_id,
        'order_id', p_order_id,
        'amount', p_amount,
        'treasury_transaction_id', v_tx_id,
        'total_paid_after', v_paid + p_amount
    );
END;
$$;


ALTER FUNCTION public.rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text) OWNER TO postgres;

--
-- Name: rpc_record_advance(uuid, numeric, date, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_worker      RECORD;
    v_advance_id  UUID;
    v_tx_id       UUID;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إصدار السلف مخصص لمالك الورشة فقط';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'مبلغ السلفة يجب أن يكون أكبر من صفر';
    END IF;

    SELECT * INTO v_worker
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    SELECT auth.uid() INTO v_current_user;

    INSERT INTO public.treasury_transactions (
        transaction_type, category, amount, description, created_by
    ) VALUES (
        'out', 'advance', p_amount,
        COALESCE(p_notes, 'سلفة للعامل: ' || v_worker.name),
        v_current_user
    ) RETURNING id INTO v_tx_id;

    INSERT INTO public.worker_advances (
        worker_id, amount, advance_date, treasury_transaction_id, notes
    ) VALUES (
        p_worker_id, p_amount, p_advance_date, v_tx_id, p_notes
    ) RETURNING id INTO v_advance_id;

    RETURN jsonb_build_object(
        'advance_id', v_advance_id,
        'worker_id', p_worker_id,
        'amount', p_amount,
        'treasury_transaction_id', v_tx_id
    );
END;
$$;


ALTER FUNCTION public.rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text) OWNER TO postgres;

--
-- Name: rpc_record_attendance(uuid, uuid, date, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_worker      RECORD;
    v_daily_rate  NUMERIC(10,2);
    v_amount      NUMERIC(10,2);
    v_log_id      UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_fraction NOT IN (0.25, 0.50, 1.00) THEN
        RAISE EXCEPTION 'نسبة العمل غير صالحة (يسمح فقط بـ 0.25 أو 0.50 أو 1.00)';
    END IF;

    IF p_project_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN
        RAISE EXCEPTION 'المشروع غير موجود';
    END IF;

    SELECT * INTO v_worker
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    IF NOT v_worker.is_active THEN
        RAISE EXCEPTION 'العامل غير نشط ولا يمكن تسجيل حضور له';
    END IF;

    v_daily_rate := v_worker.daily_rate;
    v_amount     := ROUND(v_daily_rate * p_fraction, 2);

    INSERT INTO public.worker_logs (
        worker_id, project_id, log_date, fraction, daily_rate
    ) VALUES (
        p_worker_id, p_project_id, p_work_date, p_fraction, v_daily_rate
    ) RETURNING id INTO v_log_id;

    RETURN jsonb_build_object(
        'worker_log_id', v_log_id,
        'worker_id', p_worker_id,
        'project_id', p_project_id,
        'fraction', p_fraction,
        'daily_rate', v_daily_rate,
        'calculated_amount', v_amount
    );
END;
$$;


ALTER FUNCTION public.rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric) OWNER TO postgres;

--
-- Name: rpc_remove_operating_exclusion(date, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إدارة استبعادات توزيع مصاريف التشغيل مخصصة لمالك الورشة فقط';
    END IF;
    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإزالة (3 أحرف على الأقل)';
    END IF;
    PERFORM app_private.append_audit_log(
        'remove_operating_exclusion', 'operating_allocation_exclusions', p_project_id, p_reason,
        jsonb_build_object('year_month', date_trunc('month', p_year_month)::date, 'project_id', p_project_id)
    );
    DELETE FROM public.operating_allocation_exclusions
    WHERE year_month = date_trunc('month', p_year_month)::date AND project_id = p_project_id;
    RETURN jsonb_build_object('removed', true, 'reason', p_reason);
END;
$$;


ALTER FUNCTION public.rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: rpc_return_surplus(uuid, text, text, numeric, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_surplus_id UUID;
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر';
    END IF;
    IF p_estimated_value < 0 THEN
        RAISE EXCEPTION 'القيمة التقديرية لا يمكن أن تكون سالبة';
    END IF;

    INSERT INTO public.surplus_bank (
        material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, notes
    ) VALUES (
        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value, p_project_id, 'available', p_notes
    ) RETURNING id INTO v_surplus_id;

    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        p_project_id, 'surplus_return', p_estimated_value, v_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id', v_surplus_id,
        'adjustment_id', v_adjustment_id,
        'quantity', p_quantity,
        'estimated_value', p_estimated_value
    );
END;
$$;


ALTER FUNCTION public.rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text) OWNER TO postgres;

--
-- Name: rpc_run_operating_allocation(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_run_operating_allocation(p_year_month date) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: تشغيل توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;
    RETURN app_private.run_operating_allocation(p_year_month);
END;
$$;


ALTER FUNCTION public.rpc_run_operating_allocation(p_year_month date) OWNER TO postgres;

--
-- Name: rpc_scrap_surplus(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_scrap_surplus(p_surplus_id uuid, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_surplus RECORD;
    v_scrap_value NUMERIC(12,2);
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
    END IF;

    IF coalesce(char_length(trim(coalesce(p_notes, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإتلاف (3 أحرف على الأقل)';
    END IF;

    SELECT * INTO v_surplus
    FROM public.surplus_bank
    WHERE id = p_surplus_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'عنصر الفائض غير موجود';
    END IF;

    IF v_surplus.status != 'available' THEN
        RAISE EXCEPTION 'لا يمكن إتلاف عنصر غير متاح (حالته: %)', v_surplus.status;
    END IF;

    v_scrap_value := v_surplus.estimated_value;

    UPDATE public.surplus_bank
    SET status = 'scrapped',
        quantity = 0
    WHERE id = p_surplus_id;

    INSERT INTO public.project_cost_adjustments (
        project_id, adjustment_type, amount, surplus_id, notes
    ) VALUES (
        NULL, 'surplus_scrap', v_scrap_value, p_surplus_id, p_notes
    ) RETURNING id INTO v_adjustment_id;

    RETURN jsonb_build_object(
        'surplus_id', p_surplus_id,
        'status', 'scrapped',
        'scrapped_value', v_scrap_value,
        'adjustment_id', v_adjustment_id
    );
END;
$$;


ALTER FUNCTION public.rpc_scrap_surplus(p_surplus_id uuid, p_notes text) OWNER TO postgres;

--
-- Name: rpc_settle_worker(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_settle_worker(p_worker_id uuid, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_earned      NUMERIC(10,2);
    v_advances    NUMERIC(10,2);
    v_net         NUMERIC(10,2);
    v_tx_id       UUID;
    v_worker_name TEXT;
    v_current_user UUID;
    v_carry_id    UUID;
    v_count       INT;
    v_orig_adv    NUMERIC(10,2);
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: تسوية العمال مخصصة لمالك الورشة فقط';
    END IF;

    SELECT name INTO v_worker_name
    FROM public.workers
    WHERE id = p_worker_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'العامل غير موجود';
    END IF;

    v_earned := COALESCE((
        SELECT SUM(calculated_amount)
        FROM public.worker_logs
        WHERE worker_id = p_worker_id AND NOT is_settled
    ), 0);

    v_advances := COALESCE((
        SELECT SUM(amount)
        FROM public.worker_advances
        WHERE worker_id = p_worker_id AND NOT is_settled
    ), 0);

    v_net := ROUND(v_earned - v_advances, 2);

    SELECT auth.uid() INTO v_current_user;

    IF v_net > 0 THEN
        -- treasury OUT for the net payable, then settle everything
        INSERT INTO public.treasury_transactions (
            transaction_type, category, amount, description, created_by
        ) VALUES (
            'out', 'settlement', v_net,
            COALESCE(p_notes, 'تسوية أجر العامل: ' || v_worker_name),
            v_current_user
        ) RETURNING id INTO v_tx_id;

        UPDATE public.worker_logs
        SET is_settled = true, settlement_id = v_tx_id
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = v_tx_id
        WHERE worker_id = p_worker_id AND NOT is_settled;

        RETURN jsonb_build_object(
            'mode', 'cash_settlement',
            'worker_id', p_worker_id,
            'earned_wages', v_earned,
            'unsettled_advances', v_advances,
            'net_payable', v_net,
            'treasury_transaction_id', v_tx_id,
            'carried_forward_advance', 0
        );
    ELSE
        -- advances exceeded wages: no cash out; carry the excess forward as
        -- a new opening record so the worker credit stays active & auditable.
        v_orig_adv := v_advances;   -- preserve original unsettled advances
        v_advances := ABS(v_net);   -- the excess (advances - earned)

        UPDATE public.worker_logs
        SET is_settled = true, settlement_id = NULL
        WHERE worker_id = p_worker_id AND NOT is_settled;

        UPDATE public.worker_advances
        SET is_settled = true, settlement_id = NULL
        WHERE worker_id = p_worker_id AND NOT is_settled;

        IF v_advances > 0 THEN
            INSERT INTO public.worker_advances (
                worker_id, amount, advance_date,
                is_settled, is_carried_forward, notes
            ) VALUES (
                p_worker_id, v_advances, CURRENT_DATE,
                false, true,
                COALESCE(p_notes, 'سلفة محمولة من فترة سابقة (تجاوز الأجر)')
            ) RETURNING id INTO v_carry_id;
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM public.worker_advances
        WHERE worker_id = p_worker_id AND NOT is_settled;

        RETURN jsonb_build_object(
            'mode', 'credit_carry_forward',
            'worker_id', p_worker_id,
            'earned_wages', v_earned,
            'unsettled_advances', v_orig_adv,   -- original advances
            'net_payable', 0,
            'treasury_transaction_id', NULL,
            'carried_forward_advance', v_advances,
            'carried_forward_id', v_carry_id,
            'open_advance_record_count', v_count
        );
    END IF;
END;
$$;


ALTER FUNCTION public.rpc_settle_worker(p_worker_id uuid, p_notes text) OWNER TO postgres;

--
-- Name: rpc_void_allocation_cycle(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_cycle RECORD;
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء دورة توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;

    SELECT * INTO v_cycle
    FROM public.operating_allocation_cycles
    WHERE id = p_cycle_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'دورة التوزيع غير موجودة'; END IF;
    IF v_cycle.is_voided THEN RAISE EXCEPTION 'هذه الدورة ملغاة بالفعل مسبقاً'; END IF;

    UPDATE public.project_cost_adjustments
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء كامل لدورة التوزيع الشهري'),
        voided_by = auth.uid()
    WHERE operating_cycle_id = p_cycle_id AND NOT is_voided;

    UPDATE public.operating_allocation_cycles
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء دورة التوزيع الشهري'),
        voided_by = auth.uid()
    WHERE id = p_cycle_id;

    RETURN jsonb_build_object('cycle_id', p_cycle_id, 'voided', true);
END;
$$;


ALTER FUNCTION public.rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: rpc_void_allocation_line(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_void_allocation_line(p_adjustment_id uuid, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_adj public.project_cost_adjustments%ROWTYPE;
BEGIN
    IF app_private.is_owner() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء أسطر توزيع مصاريف التشغيل مخصص لمالك الورشة فقط';
    END IF;

    SELECT * INTO v_adj
    FROM public.project_cost_adjustments
    WHERE id = p_adjustment_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'سطر التوزيع غير موجود'; END IF;
    IF v_adj.adjustment_type <> 'operating_allocation' THEN
        RAISE EXCEPTION 'هذا السطر ليس سطر توزيع مصاريف تشغيل';
    END IF;
    IF v_adj.is_voided THEN RAISE EXCEPTION 'هذا السطر ملغى بالفعل مسبقاً'; END IF;

    UPDATE public.project_cost_adjustments
    SET is_voided = true, voided_at = NOW(),
        void_reason = COALESCE(p_reason, 'إلغاء سطر توزيع'),
        voided_by = auth.uid()
    WHERE id = p_adjustment_id;

    RETURN jsonb_build_object('adjustment_id', p_adjustment_id, 'voided', true);
END;
$$;


ALTER FUNCTION public.rpc_void_allocation_line(p_adjustment_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: rpc_void_subcontract_payment(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rpc_void_subcontract_payment(p_payment_id uuid, p_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
    v_payment RECORD;
    v_current_user UUID;
BEGIN
    IF NOT app_private.is_owner() THEN
        RAISE EXCEPTION 'غير مصرح: إلغاء دفعات مقاولي الباطن مخصص لمالك الورشة فقط';
    END IF;

    IF coalesce(char_length(trim(coalesce(p_reason, ''))), 0) < 3 THEN
        RAISE EXCEPTION 'يجب كتابة سبب الإلغاء (3 أحرف على الأقل)';
    END IF;

    SELECT * INTO v_payment
    FROM public.subcontract_payments
    WHERE id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الدفعة غير موجودة';
    END IF;

    IF v_payment.is_voided THEN
        RAISE EXCEPTION 'هذه الدفعة ملغاة بالفعل مسبقاً';
    END IF;

    SELECT auth.uid() INTO v_current_user;

    UPDATE public.subcontract_payments
    SET is_voided = true,
        void_reason = p_reason
    WHERE id = p_payment_id;

    IF v_payment.treasury_transaction_id IS NOT NULL THEN
        UPDATE public.treasury_transactions
        SET is_voided = true,
            voided_at = NOW(),
            void_reason = p_reason,
            voided_by = v_current_user
        WHERE id = v_payment.treasury_transaction_id;
    END IF;

    RETURN jsonb_build_object(
        'payment_id', p_payment_id,
        'order_id', v_payment.subcontract_order_id,
        'voided', true,
        'treasury_transaction_id', v_payment.treasury_transaction_id
    );
END;
$$;


ALTER FUNCTION public.rpc_void_subcontract_payment(p_payment_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = clock_timestamp();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp() OWNER TO postgres;

--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
    -- Regclass of the table e.g. public.notes
    entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

    -- I, U, D, T: insert, update ...
    action realtime.action = (
        case wal ->> 'action'
            when 'I' then 'INSERT'
            when 'U' then 'UPDATE'
            when 'D' then 'DELETE'
            else 'ERROR'
        end
    );

    -- Is row level security enabled for the table
    is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

    subscriptions realtime.subscription[] = array_agg(subs)
        from
            realtime.subscription subs
        where
            subs.entity = entity_
            -- Filter by action early - only get subscriptions interested in this action
            -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
            and (subs.action_filter = '*' or subs.action_filter = action::text);

    -- Subscription vars
    working_role regrole;
    working_selected_columns text[];
    claimed_role regrole;
    claims jsonb;

    subscription_id uuid;
    subscription_has_access bool;
    visible_to_subscription_ids uuid[] = '{}';

    -- structured info for wal's columns
    columns realtime.wal_column[];
    -- previous identity values for update/delete
    old_columns realtime.wal_column[];

    error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

    -- Primary jsonb output for record
    output jsonb;

    -- Loop record for iterating unique roles (outer loop)
    role_record record;
    -- Loop record for iterating unique selected_columns within a role (inner loop)
    cols_record record;
    -- Subscription ids visible at the role level (before fanning out by selected_columns)
    visible_role_sub_ids uuid[] = '{}';

begin
    perform set_config('role', null, true);

    columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'columns') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    old_columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'identity') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    for role_record in
        select claims_role
        from (select distinct claims_role from unnest(subscriptions)) t
        order by claims_role::text
    loop
        working_role := role_record.claims_role;

        -- Update `is_selectable` for columns and old_columns (once per role)
        columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(columns) c;

        old_columns =
                array_agg(
                    (
                        c.name,
                        c.type_name,
                        c.type_oid,
                        c.value,
                        c.is_pkey,
                        pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                    )::realtime.wal_column
                )
                from
                    unnest(old_columns) c;

        if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
            -- Fan out 400 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 400: Bad Request, no primary key']
                )::realtime.wal_rls;
            end loop;

        -- The claims role does not have SELECT permission to the primary key of entity
        elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
            -- Fan out 401 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 401: Unauthorized']
                )::realtime.wal_rls;
            end loop;

        else
            -- Create the prepared statement (once per role)
            if is_rls_enabled and action <> 'DELETE' then
                if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                    deallocate walrus_rls_stmt;
                end if;
                execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
            end if;

            -- Collect all visible subscription IDs for this role (filter check + RLS check)
            visible_role_sub_ids = '{}';

            for subscription_id, claims in (
                    select
                        subs.subscription_id,
                        subs.claims
                    from
                        unnest(subscriptions) subs
                    where
                        subs.entity = entity_
                        and subs.claims_role = working_role
                        and (
                            realtime.is_visible_through_filters(columns, subs.filters)
                            or (
                              action = 'DELETE'
                              and realtime.is_visible_through_filters(old_columns, subs.filters)
                            )
                        )
            ) loop

                if not is_rls_enabled or action = 'DELETE' then
                    visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                else
                    -- Check if RLS allows the role to see the record
                    perform
                        -- Trim leading and trailing quotes from working_role because set_config
                        -- doesn't recognize the role as valid if they are included
                        set_config('role', trim(both '"' from working_role::text), true),
                        set_config('request.jwt.claims', claims::text, true);

                    execute 'execute walrus_rls_stmt' into subscription_has_access;

                    if subscription_has_access then
                        visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                    end if;
                end if;
            end loop;

            perform set_config('role', null, true);

            -- Inner loop: per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;

                output = jsonb_build_object(
                    'schema', wal ->> 'schema',
                    'table', wal ->> 'table',
                    'type', action,
                    'commit_timestamp', to_char(
                        ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
                    ),
                    'columns', (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'name', pa.attname,
                                    'type', pt.typname
                                )
                                order by pa.attnum asc
                            )
                        from
                            pg_attribute pa
                            join pg_type pt
                                on pa.atttypid = pt.oid
                            left join (
                                select unnest(conkey) as pkey_attnum
                                from pg_constraint
                                where conrelid = entity_ and contype = 'p'
                            ) pk on pk.pkey_attnum = pa.attnum
                        where
                            attrelid = entity_
                            and attnum > 0
                            and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
                            and (working_selected_columns is null or pa.attname = any(working_selected_columns) or pk.pkey_attnum is not null)
                    )
                )
                -- Add "record" key for insert and update
                || case
                    when action in ('INSERT', 'UPDATE') then
                        jsonb_build_object(
                            'record',
                            (
                                select
                                    jsonb_object_agg(
                                        -- if unchanged toast, get column name and value from old record
                                        coalesce((c).name, (oc).name),
                                        case
                                            when (c).name is null then (oc).value
                                            else (c).value
                                        end
                                    )
                                from
                                    unnest(columns) c
                                    full outer join unnest(old_columns) oc
                                        on (c).name = (oc).name
                                where
                                    coalesce((c).is_selectable, (oc).is_selectable)
                                    and (working_selected_columns is null or coalesce((c).name, (oc).name) = any(working_selected_columns) or coalesce((c).is_pkey, (oc).is_pkey))
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            )
                        )
                    else '{}'::jsonb
                end
                -- Add "old_record" key for update and delete
                || case
                    when action = 'UPDATE' then
                        jsonb_build_object(
                                'old_record',
                                (
                                    select jsonb_object_agg((c).name, (c).value)
                                    from unnest(old_columns) c
                                    where
                                        (c).is_selectable
                                        and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                        and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                )
                            )
                    when action = 'DELETE' then
                        jsonb_build_object(
                            'old_record',
                            (
                                select jsonb_object_agg((c).name, (c).value)
                                from unnest(old_columns) c
                                where
                                    (c).is_selectable
                                    and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                    and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                            )
                        )
                    else '{}'::jsonb
                end;

                -- Filter visible_role_sub_ids to those matching the current selected_columns group
                visible_to_subscription_ids = coalesce(
                    (
                        select array_agg(s.subscription_id)
                        from unnest(subscriptions) s
                        where s.claims_role = working_role
                          and (s.selected_columns is not distinct from working_selected_columns)
                          and s.subscription_id = any(visible_role_sub_ids)
                    ),
                    '{}'::uuid[]
                );

                return next (
                    output,
                    is_rls_enabled,
                    visible_to_subscription_ids,
                    case
                        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                        else '{}'
                    end
                )::realtime.wal_rls;
            end loop;

        end if;
    end loop;

    perform set_config('role', null, true);
end;
$$;


ALTER FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


ALTER FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) OWNER TO supabase_admin;

--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


ALTER FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) OWNER TO supabase_admin;

--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


ALTER FUNCTION realtime."cast"(val text, type_ regtype) OWNER TO supabase_admin;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) OWNER TO supabase_admin;

--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


ALTER FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) OWNER TO supabase_admin;

--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


ALTER FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    realtime.wal2json_escape_identifier(nsp.nspname::text)
    || '.'
    || realtime.wal2json_escape_identifier(pc.relname::text)
  FROM pg_class pc
  JOIN pg_namespace nsp ON pc.relnamespace = nsp.oid
  WHERE pc.oid = entity
$$;


ALTER FUNCTION realtime.quote_wal2json(entity regclass) OWNER TO supabase_admin;

--
-- Name: send(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.send(payload bytea, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, binary_payload, event, topic, private, extension)
    VALUES (generated_id, payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send(payload bytea, event text, topic text, private boolean) OWNER TO supabase_admin;

--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) OWNER TO supabase_admin;

--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(c.column_name order by c.ordinal_position),
            '{}'::text[]
        )
        from
            information_schema.columns c
        where
            format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                format('%I.%I', c.table_schema, c.table_name)::regclass,
                c.column_name,
                'SELECT'
            );
    table_col_names text[] = coalesce(
            array_agg(pa.attname),
            '{}'::text[]
        )
        from
            pg_attribute pa
        where
            pa.attrelid = new.entity
            and pa.attnum > 0;
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        -- Filtered column is valid
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        -- Type is sanitized and safe for string interpolation
        col_type = (
            select atttypid::regtype
            from pg_catalog.pg_attribute
            where attrelid = new.entity
                  and attname = filter.column_name
        );
        if col_type is null then
            raise exception 'failed to lookup type for column %', filter.column_name;
        end if;
        if filter.op = 'in'::realtime.equality_op then
            in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
            if coalesce(jsonb_array_length(in_val), 0) > 100 then
                raise exception 'too many values for `in` filter. Maximum 100';
            end if;
        else
            -- raises an exception if value is not coercable to type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    -- Validate that selected_columns reference columns the role can SELECT
    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint on
    -- (subscription_id, entity, filters) can't be tricked by a different filter order
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value),
        '{}'
    ) from unnest(new.filters) f;

    -- Normalize selected_columns order so ARRAY['a','b'] and ARRAY['b','a'] are
    -- treated as the same subscription group in apply_rls
    new.selected_columns = (
        select array_agg(c order by c)
        from unnest(new.selected_columns) c
    );

    return new;
end;
$$;


ALTER FUNCTION realtime.subscription_check_filters() OWNER TO supabase_admin;

--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


ALTER FUNCTION realtime.to_regrole(role_name text) OWNER TO supabase_admin;

--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


ALTER FUNCTION realtime.topic() OWNER TO supabase_realtime_admin;

--
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


ALTER FUNCTION realtime.wal2json_escape_identifier(name text) OWNER TO supabase_admin;

--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


ALTER FUNCTION storage.allow_any_operation(expected_operations text[]) OWNER TO supabase_storage_admin;

--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


ALTER FUNCTION storage.allow_only_operation(expected_operation text) OWNER TO supabase_storage_admin;

--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) OWNER TO supabase_storage_admin;

--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION storage.enforce_bucket_name_length() OWNER TO supabase_storage_admin;

--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION storage.extension(name text) OWNER TO supabase_storage_admin;

--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION storage.filename(name text) OWNER TO supabase_storage_admin;

--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION storage.foldername(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


ALTER FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) OWNER TO supabase_storage_admin;

--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION storage.get_size_by_bucket() OWNER TO supabase_storage_admin;

--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text) OWNER TO supabase_storage_admin;

--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer, start_after text, next_token text, sort_order text) OWNER TO supabase_storage_admin;

--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION storage.operation() OWNER TO supabase_storage_admin;

--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION storage.protect_delete() OWNER TO supabase_storage_admin;

--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) OWNER TO supabase_storage_admin;

--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


ALTER FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) OWNER TO supabase_storage_admin;

--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


ALTER FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer, levels integer, start_after text, sort_order text, sort_column text, sort_column_after text) OWNER TO supabase_storage_admin;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION storage.update_updated_at_column() OWNER TO supabase_storage_admin;

--
-- Name: http_request(); Type: FUNCTION; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE FUNCTION supabase_functions.http_request() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'supabase_functions'
    AS $$
    DECLARE
      request_id bigint;
      payload jsonb;
      url text := TG_ARGV[0]::text;
      method text := TG_ARGV[1]::text;
      headers jsonb DEFAULT '{}'::jsonb;
      params jsonb DEFAULT '{}'::jsonb;
      timeout_ms integer DEFAULT 1000;
    BEGIN
      IF url IS NULL OR url = 'null' THEN
        RAISE EXCEPTION 'url argument is missing';
      END IF;

      IF method IS NULL OR method = 'null' THEN
        RAISE EXCEPTION 'method argument is missing';
      END IF;

      IF TG_ARGV[2] IS NULL OR TG_ARGV[2] = 'null' THEN
        headers = '{"Content-Type": "application/json"}'::jsonb;
      ELSE
        headers = TG_ARGV[2]::jsonb;
      END IF;

      IF TG_ARGV[3] IS NULL OR TG_ARGV[3] = 'null' THEN
        params = '{}'::jsonb;
      ELSE
        params = TG_ARGV[3]::jsonb;
      END IF;

      IF TG_ARGV[4] IS NULL OR TG_ARGV[4] = 'null' THEN
        timeout_ms = 1000;
      ELSE
        timeout_ms = TG_ARGV[4]::integer;
      END IF;

      CASE
        WHEN method = 'GET' THEN
          SELECT http_get INTO request_id FROM net.http_get(
            url,
            params,
            headers,
            timeout_ms
          );
        WHEN method = 'POST' THEN
          payload = jsonb_build_object(
            'old_record', OLD,
            'record', NEW,
            'type', TG_OP,
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA
          );

          SELECT http_post INTO request_id FROM net.http_post(
            url,
            payload,
            params,
            headers,
            timeout_ms
          );
        ELSE
          RAISE EXCEPTION 'method argument % is invalid', method;
      END CASE;

      INSERT INTO supabase_functions.hooks
        (hook_table_id, hook_name, request_id)
      VALUES
        (TG_RELID, TG_NAME, request_id);

      RETURN NEW;
    END
  $$;


ALTER FUNCTION supabase_functions.http_request() OWNER TO supabase_functions_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: extensions; Type: TABLE; Schema: _realtime; Owner: supabase_admin
--

CREATE TABLE _realtime.extensions (
    id uuid NOT NULL,
    type text,
    settings jsonb,
    tenant_external_id text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


ALTER TABLE _realtime.extensions OWNER TO supabase_admin;

--
-- Name: feature_flags; Type: TABLE; Schema: _realtime; Owner: supabase_admin
--

CREATE TABLE _realtime.feature_flags (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


ALTER TABLE _realtime.feature_flags OWNER TO supabase_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: _realtime; Owner: supabase_admin
--

CREATE TABLE _realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE _realtime.schema_migrations OWNER TO supabase_admin;

--
-- Name: tenants; Type: TABLE; Schema: _realtime; Owner: supabase_admin
--

CREATE TABLE _realtime.tenants (
    id uuid NOT NULL,
    name text,
    external_id text,
    jwt_secret text,
    max_concurrent_users integer DEFAULT 200 NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    max_events_per_second integer DEFAULT 100 NOT NULL,
    postgres_cdc_default text DEFAULT 'postgres_cdc_rls'::text,
    max_bytes_per_second integer DEFAULT 100000 NOT NULL,
    max_channels_per_client integer DEFAULT 100 NOT NULL,
    max_joins_per_second integer DEFAULT 500 NOT NULL,
    suspend boolean DEFAULT false,
    jwt_jwks jsonb,
    notify_private_alpha boolean DEFAULT false,
    private_only boolean DEFAULT false NOT NULL,
    migrations_ran integer DEFAULT 0,
    broadcast_adapter character varying(255) DEFAULT 'gen_rpc'::character varying,
    max_presence_events_per_second integer DEFAULT 1000,
    max_payload_size_in_kb integer DEFAULT 3000,
    max_client_presence_events_per_window integer,
    client_presence_window_ms integer,
    presence_enabled boolean DEFAULT false NOT NULL,
    feature_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT jwt_secret_or_jwt_jwks_required CHECK (((jwt_secret IS NOT NULL) OR (jwt_jwks IS NOT NULL)))
);


ALTER TABLE _realtime.tenants OWNER TO supabase_admin;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;

--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


ALTER TABLE auth.custom_oauth_providers OWNER TO supabase_auth_admin;

--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


ALTER TABLE auth.flow_state OWNER TO supabase_auth_admin;

--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.instances OWNER TO supabase_auth_admin;

--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


ALTER TABLE auth.mfa_amr_claims OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


ALTER TABLE auth.mfa_challenges OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


ALTER TABLE auth.mfa_factors OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


ALTER TABLE auth.oauth_authorizations OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE auth.oauth_client_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


ALTER TABLE auth.oauth_clients OWNER TO supabase_auth_admin;

--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


ALTER TABLE auth.oauth_consents OWNER TO supabase_auth_admin;

--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


ALTER TABLE auth.one_time_tokens OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;

--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: supabase_auth_admin
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auth.refresh_tokens_id_seq OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: supabase_auth_admin
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


ALTER TABLE auth.saml_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


ALTER TABLE auth.saml_relay_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


ALTER TABLE auth.sessions OWNER TO supabase_auth_admin;

--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


ALTER TABLE auth.sso_domains OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


ALTER TABLE auth.sso_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


ALTER TABLE auth.users OWNER TO supabase_auth_admin;

--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


ALTER TABLE auth.webauthn_challenges OWNER TO supabase_auth_admin;

--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


ALTER TABLE auth.webauthn_credentials OWNER TO supabase_auth_admin;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_id uuid,
    action text NOT NULL,
    entity_table text NOT NULL,
    entity_id uuid,
    reason text,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audit_log_action_check CHECK ((action = ANY (ARRAY['void_treasury'::text, 'void_subcontract_payment'::text, 'close_subcontract_order'::text, 'return_surplus'::text, 'consume_surplus'::text, 'scrap_surplus'::text, 'run_operating_allocation'::text, 'void_allocation_cycle'::text, 'void_allocation_line'::text, 'add_operating_exclusion'::text, 'remove_operating_exclusion'::text]))),
    CONSTRAINT audit_log_entity_table_check CHECK ((entity_table = ANY (ARRAY['treasury_transactions'::text, 'subcontract_payments'::text, 'subcontract_orders'::text, 'surplus_bank'::text, 'project_cost_adjustments'::text, 'operating_allocation_cycles'::text, 'operating_allocation_exclusions'::text]))),
    CONSTRAINT audit_log_reason_bounds CHECK ((char_length(COALESCE(reason, ''::text)) <= 1000))
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: general_expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.general_expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    expense_date date DEFAULT CURRENT_DATE NOT NULL,
    amount numeric(10,2) NOT NULL,
    category text NOT NULL,
    description text NOT NULL,
    treasury_transaction_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT general_expenses_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT general_expenses_amount_upper_bound CHECK ((amount <= 99999999.99))
);


ALTER TABLE public.general_expenses OWNER TO postgres;

--
-- Name: idempotency_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.idempotency_keys (
    key text NOT NULL,
    user_id uuid NOT NULL,
    action text NOT NULL,
    status text NOT NULL,
    response_payload jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '24:00:00'::interval) NOT NULL,
    CONSTRAINT idempotency_key_uuid_format CHECK ((key ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'::text)),
    CONSTRAINT idempotency_keys_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text])))
);


ALTER TABLE public.idempotency_keys OWNER TO postgres;

--
-- Name: operating_allocation_cycles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operating_allocation_cycles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_month date NOT NULL,
    status text NOT NULL,
    total_amount numeric(12,2) DEFAULT 0 NOT NULL,
    eligible_project_ids uuid[],
    notes text,
    created_by uuid,
    is_voided boolean DEFAULT false NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT operating_allocation_cycles_status_check CHECK ((status = ANY (ARRAY['applied'::text, 'noop'::text]))),
    CONSTRAINT operating_allocation_cycles_total_amount_check CHECK ((total_amount >= (0)::numeric)),
    CONSTRAINT operating_allocation_cycles_year_month_check CHECK ((year_month = (date_trunc('month'::text, (year_month)::timestamp with time zone))::date)),
    CONSTRAINT operating_cycles_text_bounds CHECK (((char_length(COALESCE(notes, ''::text)) <= 1000) AND (char_length(COALESCE(void_reason, ''::text)) <= 1000)))
);


ALTER TABLE public.operating_allocation_cycles OWNER TO postgres;

--
-- Name: operating_allocation_exclusions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operating_allocation_exclusions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_month date NOT NULL,
    project_id uuid NOT NULL,
    reason text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT operating_allocation_exclusions_year_month_check CHECK ((year_month = (date_trunc('month'::text, (year_month)::timestamp with time zone))::date)),
    CONSTRAINT operating_exclusions_text_bounds CHECK ((char_length(COALESCE(reason, ''::text)) <= 1000))
);


ALTER TABLE public.operating_allocation_exclusions OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'manager'::text])))
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: project_cost_adjustments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_cost_adjustments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid,
    adjustment_type text NOT NULL,
    amount numeric(12,2) NOT NULL,
    surplus_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_voided boolean DEFAULT false NOT NULL,
    voided_at timestamp with time zone,
    void_reason text,
    voided_by uuid,
    operating_cycle_id uuid,
    CONSTRAINT check_scrap_no_project CHECK ((((adjustment_type = 'surplus_scrap'::text) AND (project_id IS NULL)) OR ((adjustment_type <> 'surplus_scrap'::text) AND (project_id IS NOT NULL)))),
    CONSTRAINT cost_adj_amount_upper_bound CHECK ((amount <= 9999999999.99)),
    CONSTRAINT cost_adj_text_bounds CHECK ((char_length(COALESCE(notes, ''::text)) <= 1000)),
    CONSTRAINT project_cost_adjustments_adjustment_type_check CHECK ((adjustment_type = ANY (ARRAY['surplus_return'::text, 'surplus_consumption'::text, 'surplus_scrap'::text, 'operating_allocation'::text]))),
    CONSTRAINT project_cost_adjustments_amount_check CHECK ((amount >= (0)::numeric))
);


ALTER TABLE public.project_cost_adjustments OWNER TO postgres;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT projects_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'on_hold'::text, 'cancelled'::text]))),
    CONSTRAINT projects_text_bounds CHECK (((char_length(name) <= 200) AND (char_length(COALESCE(description, ''::text)) <= 1000)))
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: rate_limits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rate_limits (
    bucket text NOT NULL,
    window_start timestamp with time zone NOT NULL,
    count integer DEFAULT 1 NOT NULL,
    CONSTRAINT rate_limits_count_check CHECK ((count >= 0))
);


ALTER TABLE public.rate_limits OWNER TO postgres;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    overhead_percentage numeric(5,2) DEFAULT 10.00 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT settings_overhead_percentage_check CHECK ((overhead_percentage >= (0)::numeric))
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: subcontract_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subcontract_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    contractor_name text NOT NULL,
    description text NOT NULL,
    total_agreed_amount numeric(12,2) NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    close_reason text,
    CONSTRAINT subcontract_orders_amount_upper_bound CHECK ((total_agreed_amount <= 9999999999.99)),
    CONSTRAINT subcontract_orders_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'cancelled'::text]))),
    CONSTRAINT subcontract_orders_text_bounds CHECK (((char_length(contractor_name) <= 200) AND (char_length(description) <= 1000))),
    CONSTRAINT subcontract_orders_total_agreed_amount_check CHECK ((total_agreed_amount > (0)::numeric))
);


ALTER TABLE public.subcontract_orders OWNER TO postgres;

--
-- Name: subcontract_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subcontract_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subcontract_order_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    treasury_transaction_id uuid,
    is_voided boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    void_reason text,
    CONSTRAINT subcontract_payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT subcontract_payments_amount_upper_bound CHECK ((amount <= 9999999999.99)),
    CONSTRAINT subcontract_payments_text_bounds CHECK ((char_length(COALESCE(notes, ''::text)) <= 1000))
);


ALTER TABLE public.subcontract_payments OWNER TO postgres;

--
-- Name: surplus_bank; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.surplus_bank (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    material_name text NOT NULL,
    unit text NOT NULL,
    quantity numeric(12,2) NOT NULL,
    initial_quantity numeric(12,2) NOT NULL,
    estimated_value numeric(12,2) NOT NULL,
    source_project_id uuid,
    status text DEFAULT 'available'::text NOT NULL,
    parent_surplus_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT surplus_bank_amounts_upper_bound CHECK (((quantity <= 9999999999.99) AND (initial_quantity <= 9999999999.99) AND (estimated_value <= 9999999999.99))),
    CONSTRAINT surplus_bank_estimated_value_check CHECK ((estimated_value >= (0)::numeric)),
    CONSTRAINT surplus_bank_initial_quantity_check CHECK ((initial_quantity > (0)::numeric)),
    CONSTRAINT surplus_bank_quantity_check CHECK ((quantity >= (0)::numeric)),
    CONSTRAINT surplus_bank_status_check CHECK ((status = ANY (ARRAY['available'::text, 'consumed'::text, 'scrapped'::text]))),
    CONSTRAINT surplus_bank_text_bounds CHECK (((char_length(material_name) <= 200) AND (char_length(unit) <= 30) AND (char_length(COALESCE(notes, ''::text)) <= 1000)))
);


ALTER TABLE public.surplus_bank OWNER TO postgres;

--
-- Name: treasury_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.treasury_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_type text NOT NULL,
    category text NOT NULL,
    amount numeric(12,2) NOT NULL,
    description text,
    project_id uuid,
    is_direct_owner_payment boolean DEFAULT false NOT NULL,
    is_voided boolean DEFAULT false NOT NULL,
    voided_at timestamp with time zone,
    void_reason text,
    voided_by uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    subcategory text,
    CONSTRAINT check_direct_owner_payment_type CHECK (((NOT is_direct_owner_payment) OR (transaction_type = 'out'::text))),
    CONSTRAINT check_workshop_operating_no_project CHECK (((category <> 'workshop_operating'::text) OR (project_id IS NULL))),
    CONSTRAINT treasury_amount_upper_bound CHECK ((amount <= 9999999999.99)),
    CONSTRAINT treasury_subcategory_pairing CHECK (((subcategory IS NULL) OR ((category = 'material'::text) AND (subcategory = ANY (ARRAY['wood_boards'::text, 'upholstery_fabric_textile'::text, 'foam_filling'::text, 'hardware_hinges'::text, 'glue_adhesives'::text, 'paints_varnishes'::text, 'glass_mirrors'::text, 'small_fasteners'::text, 'consumables_tools'::text, 'machine_maintenance'::text]))) OR ((category = 'freight'::text) AND (subcategory = ANY (ARRAY['site_transport'::text, 'merchant_transport'::text, 'workshop_machine_transport'::text, 'tools_site_transport'::text, 'completed_work_transport'::text]))) OR ((category = 'workshop_operating'::text) AND (subcategory = ANY (ARRAY['electricity'::text, 'rent'::text, 'waste_collection'::text]))))),
    CONSTRAINT treasury_subcategory_required CHECK (((category <> ALL (ARRAY['material'::text, 'freight'::text, 'workshop_operating'::text])) OR (subcategory IS NOT NULL))),
    CONSTRAINT treasury_text_bounds CHECK (((char_length(COALESCE(description, ''::text)) <= 1000) AND (char_length(COALESCE(void_reason, ''::text)) <= 1000))),
    CONSTRAINT treasury_transactions_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT treasury_transactions_category_check CHECK ((category = ANY (ARRAY['owner_funding'::text, 'material'::text, 'freight'::text, 'advance'::text, 'settlement'::text, 'subcontract_payment'::text, 'general_expense'::text, 'carried_forward_advance'::text, 'other'::text, 'workshop_operating'::text]))),
    CONSTRAINT treasury_transactions_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['in'::text, 'out'::text])))
);


ALTER TABLE public.treasury_transactions OWNER TO postgres;

--
-- Name: worker_advances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.worker_advances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id uuid NOT NULL,
    amount numeric(10,2) NOT NULL,
    advance_date date DEFAULT CURRENT_DATE NOT NULL,
    treasury_transaction_id uuid,
    is_settled boolean DEFAULT false NOT NULL,
    settlement_id uuid,
    is_carried_forward boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT worker_advances_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT worker_advances_amount_upper_bound CHECK ((amount <= 99999999.99)),
    CONSTRAINT worker_advances_text_bounds CHECK ((char_length(COALESCE(notes, ''::text)) <= 1000))
);


ALTER TABLE public.worker_advances OWNER TO postgres;

--
-- Name: worker_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.worker_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id uuid NOT NULL,
    project_id uuid,
    log_date date DEFAULT CURRENT_DATE NOT NULL,
    fraction numeric(3,2) NOT NULL,
    daily_rate numeric(10,2) NOT NULL,
    calculated_amount numeric(10,2) GENERATED ALWAYS AS ((daily_rate * fraction)) STORED NOT NULL,
    is_settled boolean DEFAULT false NOT NULL,
    settlement_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT worker_logs_daily_rate_check CHECK ((daily_rate > (0)::numeric)),
    CONSTRAINT worker_logs_fraction_check CHECK ((fraction = ANY (ARRAY[0.25, 0.50, 1.00]))),
    CONSTRAINT worker_logs_rate_upper_bound CHECK ((daily_rate <= 99999999.99)),
    CONSTRAINT worker_logs_text_bounds CHECK ((char_length(COALESCE(notes, ''::text)) <= 1000))
);


ALTER TABLE public.worker_logs OWNER TO postgres;

--
-- Name: workers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    phone text,
    daily_rate numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT workers_daily_rate_check CHECK ((daily_rate > (0)::numeric)),
    CONSTRAINT workers_rate_upper_bound CHECK ((daily_rate <= 99999999.99)),
    CONSTRAINT workers_text_bounds CHECK (((char_length(name) <= 200) AND (char_length(COALESCE(phone, ''::text)) <= 30)))
);


ALTER TABLE public.workers OWNER TO postgres;

--
-- Name: v_worker_liabilities; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_worker_liabilities WITH (security_invoker='true') AS
 WITH worker_unsettled_wages AS (
         SELECT worker_logs.worker_id,
            COALESCE(sum(worker_logs.calculated_amount), (0)::numeric) AS total_wages
           FROM public.worker_logs
          WHERE (NOT worker_logs.is_settled)
          GROUP BY worker_logs.worker_id
        ), worker_unsettled_advances AS (
         SELECT worker_advances.worker_id,
            COALESCE(sum(worker_advances.amount), (0)::numeric) AS total_advances
           FROM public.worker_advances
          WHERE (NOT worker_advances.is_settled)
          GROUP BY worker_advances.worker_id
        )
 SELECT w.id AS worker_id,
    COALESCE(uw.total_wages, (0)::numeric) AS unsettled_wages,
    COALESCE(ua.total_advances, (0)::numeric) AS unsettled_advances,
    GREATEST((0)::numeric, (COALESCE(uw.total_wages, (0)::numeric) - COALESCE(ua.total_advances, (0)::numeric))) AS net_payable,
    GREATEST((0)::numeric, (COALESCE(ua.total_advances, (0)::numeric) - COALESCE(uw.total_wages, (0)::numeric))) AS carried_forward_credit
   FROM ((public.workers w
     LEFT JOIN worker_unsettled_wages uw ON ((w.id = uw.worker_id)))
     LEFT JOIN worker_unsettled_advances ua ON ((w.id = ua.worker_id)));


ALTER VIEW public.v_worker_liabilities OWNER TO postgres;

--
-- Name: VIEW v_worker_liabilities; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_worker_liabilities IS 'التزامات العامل غير المسددة لكل عامل على حدة (أجور/سلف/صافي/رصيد محمول) — تُحسب في قاعدة البيانات فقط.';


--
-- Name: v_pending_liabilities; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pending_liabilities WITH (security_invoker='true') AS
 WITH worker_net_liabilities AS (
         SELECT v_worker_liabilities.worker_id,
            v_worker_liabilities.unsettled_wages,
            v_worker_liabilities.unsettled_advances,
            v_worker_liabilities.net_payable,
            v_worker_liabilities.carried_forward_credit
           FROM public.v_worker_liabilities
        ), subcontract_balances AS (
         SELECT so.id AS subcontract_order_id,
            so.total_agreed_amount,
            COALESCE(sum(sp.amount) FILTER (WHERE (NOT sp.is_voided)), (0)::numeric) AS total_paid,
            (so.total_agreed_amount - COALESCE(sum(sp.amount) FILTER (WHERE (NOT sp.is_voided)), (0)::numeric)) AS remaining_balance
           FROM (public.subcontract_orders so
             LEFT JOIN public.subcontract_payments sp ON ((so.id = sp.subcontract_order_id)))
          WHERE (so.status = 'active'::text)
          GROUP BY so.id, so.total_agreed_amount
        )
 SELECT COALESCE(sum(net_payable), (0)::numeric) AS total_worker_liabilities,
    COALESCE(( SELECT sum(subcontract_balances.remaining_balance) AS sum
           FROM subcontract_balances), (0)::numeric) AS total_subcontract_liabilities,
    (COALESCE(sum(net_payable), (0)::numeric) + COALESCE(( SELECT sum(subcontract_balances.remaining_balance) AS sum
           FROM subcontract_balances), (0)::numeric)) AS total_pending_liabilities
   FROM worker_net_liabilities;


ALTER VIEW public.v_pending_liabilities OWNER TO postgres;

--
-- Name: v_project_direct_costs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_project_direct_costs WITH (security_invoker='true') AS
 WITH project_materials AS (
         SELECT treasury_transactions.project_id,
            COALESCE(sum(treasury_transactions.amount), (0)::numeric) AS material_cost
           FROM public.treasury_transactions
          WHERE ((treasury_transactions.category = 'material'::text) AND (NOT treasury_transactions.is_voided) AND (treasury_transactions.project_id IS NOT NULL))
          GROUP BY treasury_transactions.project_id
        ), project_freight AS (
         SELECT treasury_transactions.project_id,
            COALESCE(sum(treasury_transactions.amount), (0)::numeric) AS freight_cost
           FROM public.treasury_transactions
          WHERE ((treasury_transactions.category = 'freight'::text) AND (NOT treasury_transactions.is_voided) AND (treasury_transactions.project_id IS NOT NULL))
          GROUP BY treasury_transactions.project_id
        ), project_labor AS (
         SELECT worker_logs.project_id,
            COALESCE(sum(worker_logs.calculated_amount), (0)::numeric) AS labor_cost
           FROM public.worker_logs
          WHERE (worker_logs.project_id IS NOT NULL)
          GROUP BY worker_logs.project_id
        ), project_subcontracts AS (
         SELECT subcontract_orders.project_id,
            COALESCE(sum(subcontract_orders.total_agreed_amount), (0)::numeric) AS subcontract_cost
           FROM public.subcontract_orders
          WHERE (subcontract_orders.status = ANY (ARRAY['active'::text, 'completed'::text]))
          GROUP BY subcontract_orders.project_id
        ), cancelled_subcontract_cost AS (
         SELECT so.project_id,
            COALESCE(sum(sp.amount), (0)::numeric) AS paid_cost
           FROM (public.subcontract_orders so
             LEFT JOIN public.subcontract_payments sp ON (((sp.subcontract_order_id = so.id) AND (NOT sp.is_voided))))
          WHERE (so.status = 'cancelled'::text)
          GROUP BY so.project_id
        ), project_surplus AS (
         SELECT project_cost_adjustments.project_id,
            COALESCE(sum(
                CASE
                    WHEN (project_cost_adjustments.adjustment_type = 'surplus_return'::text) THEN project_cost_adjustments.amount
                    ELSE (0)::numeric
                END), (0)::numeric) AS surplus_returns,
            COALESCE(sum(
                CASE
                    WHEN (project_cost_adjustments.adjustment_type = 'surplus_consumption'::text) THEN project_cost_adjustments.amount
                    ELSE (0)::numeric
                END), (0)::numeric) AS surplus_consumptions
           FROM public.project_cost_adjustments
          WHERE ((project_cost_adjustments.project_id IS NOT NULL) AND (NOT project_cost_adjustments.is_voided))
          GROUP BY project_cost_adjustments.project_id
        ), project_operating AS (
         SELECT project_cost_adjustments.project_id,
            COALESCE(sum(project_cost_adjustments.amount), (0)::numeric) AS operating_cost
           FROM public.project_cost_adjustments
          WHERE ((project_cost_adjustments.adjustment_type = 'operating_allocation'::text) AND (NOT project_cost_adjustments.is_voided) AND (project_cost_adjustments.project_id IS NOT NULL))
          GROUP BY project_cost_adjustments.project_id
        ), current_settings AS (
         SELECT settings.overhead_percentage
           FROM public.settings
          ORDER BY settings.created_at DESC
         LIMIT 1
        )
 SELECT p.id AS project_id,
    p.name AS project_name,
    p.status AS project_status,
    COALESCE(pm.material_cost, (0)::numeric) AS material_cost,
    COALESCE(pf.freight_cost, (0)::numeric) AS freight_cost,
    COALESCE(pl.labor_cost, (0)::numeric) AS labor_cost,
    (COALESCE(psub.subcontract_cost, (0)::numeric) + COALESCE(csc.paid_cost, (0)::numeric)) AS subcontract_cost,
    COALESCE(psurp.surplus_returns, (0)::numeric) AS surplus_returns,
    COALESCE(psurp.surplus_consumptions, (0)::numeric) AS surplus_consumptions,
    COALESCE(pop.operating_cost, (0)::numeric) AS operating_cost,
    (((((((COALESCE(pm.material_cost, (0)::numeric) + COALESCE(pf.freight_cost, (0)::numeric)) + COALESCE(pl.labor_cost, (0)::numeric)) + COALESCE(psub.subcontract_cost, (0)::numeric)) + COALESCE(csc.paid_cost, (0)::numeric)) - COALESCE(psurp.surplus_returns, (0)::numeric)) + COALESCE(psurp.surplus_consumptions, (0)::numeric)) + COALESCE(pop.operating_cost, (0)::numeric)) AS direct_project_cost,
    s.overhead_percentage,
    round(((((((((COALESCE(pm.material_cost, (0)::numeric) + COALESCE(pf.freight_cost, (0)::numeric)) + COALESCE(pl.labor_cost, (0)::numeric)) + COALESCE(psub.subcontract_cost, (0)::numeric)) + COALESCE(csc.paid_cost, (0)::numeric)) - COALESCE(psurp.surplus_returns, (0)::numeric)) + COALESCE(psurp.surplus_consumptions, (0)::numeric)) + COALESCE(pop.operating_cost, (0)::numeric)) * ((1)::numeric + (s.overhead_percentage / 100.0))), 2) AS estimated_total_cost
   FROM ((((((((public.projects p
     CROSS JOIN current_settings s)
     LEFT JOIN project_materials pm ON ((p.id = pm.project_id)))
     LEFT JOIN project_freight pf ON ((p.id = pf.project_id)))
     LEFT JOIN project_labor pl ON ((p.id = pl.project_id)))
     LEFT JOIN project_subcontracts psub ON ((p.id = psub.project_id)))
     LEFT JOIN cancelled_subcontract_cost csc ON ((p.id = csc.project_id)))
     LEFT JOIN project_surplus psurp ON ((p.id = psurp.project_id)))
     LEFT JOIN project_operating pop ON ((p.id = pop.project_id)));


ALTER VIEW public.v_project_direct_costs OWNER TO postgres;

--
-- Name: v_surplus_available; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_surplus_available WITH (security_invoker='true') AS
 SELECT COALESCE(sum(estimated_value), (0)::numeric) AS total_surplus_value,
    COALESCE(sum(quantity), (0)::numeric) AS total_surplus_quantity,
    count(*) FILTER (WHERE (status = 'available'::text)) AS item_count
   FROM public.surplus_bank
  WHERE (status = 'available'::text);


ALTER VIEW public.v_surplus_available OWNER TO postgres;

--
-- Name: v_treasury_balance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_treasury_balance WITH (security_invoker='true') AS
 SELECT COALESCE(sum(amount) FILTER (WHERE ((transaction_type = 'in'::text) AND (NOT is_voided) AND (NOT is_direct_owner_payment))), (0)::numeric) AS total_in,
    COALESCE(sum(amount) FILTER (WHERE ((transaction_type = 'out'::text) AND (NOT is_voided) AND (NOT is_direct_owner_payment))), (0)::numeric) AS total_out,
    COALESCE(sum(
        CASE
            WHEN (transaction_type = 'in'::text) THEN amount
            WHEN (transaction_type = 'out'::text) THEN (- amount)
            ELSE (0)::numeric
        END) FILTER (WHERE ((NOT is_voided) AND (NOT is_direct_owner_payment))), (0)::numeric) AS current_balance
   FROM public.treasury_transactions;


ALTER VIEW public.v_treasury_balance OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea
)
PARTITION BY RANGE (inserted_at);


ALTER TABLE realtime.messages OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_09_04; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2026_09_04 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_09_04 OWNER TO supabase_admin;

--
-- Name: messages_2026_09_05; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2026_09_05 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_09_05 OWNER TO supabase_admin;

--
-- Name: messages_2026_09_06; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2026_09_06 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_09_06 OWNER TO supabase_admin;

--
-- Name: messages_2026_09_07; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2026_09_07 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_09_07 OWNER TO supabase_admin;

--
-- Name: messages_2026_09_08; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.messages_2026_09_08 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_09_08 OWNER TO supabase_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE realtime.schema_migrations OWNER TO supabase_admin;

--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    selected_columns text[],
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


ALTER TABLE realtime.subscription OWNER TO supabase_admin;

--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE storage.buckets_analytics OWNER TO supabase_storage_admin;

--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.buckets_vectors OWNER TO supabase_storage_admin;

--
-- Name: iceberg_namespaces; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.iceberg_namespaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_name text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    catalog_id uuid NOT NULL
);


ALTER TABLE storage.iceberg_namespaces OWNER TO supabase_storage_admin;

--
-- Name: iceberg_tables; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.iceberg_tables (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    bucket_name text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    location text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    remote_table_id text,
    shard_key text,
    shard_id text,
    catalog_id uuid NOT NULL
);


ALTER TABLE storage.iceberg_tables OWNER TO supabase_storage_admin;

--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

--
-- Name: objects; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


ALTER TABLE storage.objects OWNER TO supabase_storage_admin;

--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


ALTER TABLE storage.s3_multipart_uploads OWNER TO supabase_storage_admin;

--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.s3_multipart_uploads_parts OWNER TO supabase_storage_admin;

--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.vector_indexes OWNER TO supabase_storage_admin;

--
-- Name: hooks; Type: TABLE; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE TABLE supabase_functions.hooks (
    id bigint NOT NULL,
    hook_table_id integer NOT NULL,
    hook_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    request_id bigint
);


ALTER TABLE supabase_functions.hooks OWNER TO supabase_functions_admin;

--
-- Name: TABLE hooks; Type: COMMENT; Schema: supabase_functions; Owner: supabase_functions_admin
--

COMMENT ON TABLE supabase_functions.hooks IS 'Supabase Functions Hooks: Audit trail for triggered hooks.';


--
-- Name: hooks_id_seq; Type: SEQUENCE; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE SEQUENCE supabase_functions.hooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE supabase_functions.hooks_id_seq OWNER TO supabase_functions_admin;

--
-- Name: hooks_id_seq; Type: SEQUENCE OWNED BY; Schema: supabase_functions; Owner: supabase_functions_admin
--

ALTER SEQUENCE supabase_functions.hooks_id_seq OWNED BY supabase_functions.hooks.id;


--
-- Name: migrations; Type: TABLE; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE TABLE supabase_functions.migrations (
    version text NOT NULL,
    inserted_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE supabase_functions.migrations OWNER TO supabase_functions_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: postgres
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text,
    sha256 text,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE supabase_migrations.schema_migrations OWNER TO postgres;

--
-- Name: messages_2026_09_04; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_09_04 FOR VALUES FROM ('2026-09-04 00:00:00') TO ('2026-09-05 00:00:00');


--
-- Name: messages_2026_09_05; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_09_05 FOR VALUES FROM ('2026-09-05 00:00:00') TO ('2026-09-06 00:00:00');


--
-- Name: messages_2026_09_06; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_09_06 FOR VALUES FROM ('2026-09-06 00:00:00') TO ('2026-09-07 00:00:00');


--
-- Name: messages_2026_09_07; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_09_07 FOR VALUES FROM ('2026-09-07 00:00:00') TO ('2026-09-08 00:00:00');


--
-- Name: messages_2026_09_08; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_09_08 FOR VALUES FROM ('2026-09-08 00:00:00') TO ('2026-09-09 00:00:00');


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: hooks id; Type: DEFAULT; Schema: supabase_functions; Owner: supabase_functions_admin
--

ALTER TABLE ONLY supabase_functions.hooks ALTER COLUMN id SET DEFAULT nextval('supabase_functions.hooks_id_seq'::regclass);


--
-- Data for Name: extensions; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.extensions (id, type, settings, tenant_external_id, inserted_at, updated_at) FROM stdin;
c2928f69-3b72-4687-975d-3b17413ef445	postgres_cdc_rls	{"region": "us-east-1", "db_host": "/zzKEi+jHkdm1ZK3Ynex1Q==", "db_name": "NbkP5chz9WMuwHhCTVTAdA==", "db_port": "FNOiXo5mWb0ScGw9XdAnWA==", "db_user": "mps0MB+Fc3ykbcyojnjAkw==", "slot_name": "supabase_realtime_replication_slot", "db_password": "ZVv9BwbA+9rortKqPp/I8C8I1GMm7wOr9u0fxqfpJj3h2KIhuTTQdWrDGyhgnmwd", "publication": "supabase_realtime", "ssl_enforced": false, "poll_interval_ms": 100, "poll_max_changes": 100, "poll_max_record_bytes": 1048576}	realtime-dev	2026-09-05 08:57:57	2026-09-05 08:57:57
\.


--
-- Data for Name: feature_flags; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.feature_flags (id, name, enabled, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.schema_migrations (version, inserted_at) FROM stdin;
20210706140551	2026-09-05 08:57:45
20220329161857	2026-09-05 08:57:45
20220410212326	2026-09-05 08:57:45
20220506102948	2026-09-05 08:57:46
20220527210857	2026-09-05 08:57:46
20220815211129	2026-09-05 08:57:46
20220815215024	2026-09-05 08:57:46
20220818141501	2026-09-05 08:57:46
20221018173709	2026-09-05 08:57:46
20221102172703	2026-09-05 08:57:46
20221223010058	2026-09-05 08:57:47
20230110180046	2026-09-05 08:57:47
20230810220907	2026-09-05 08:57:47
20230810220924	2026-09-05 08:57:47
20231024094642	2026-09-05 08:57:47
20240306114423	2026-09-05 08:57:47
20240418082835	2026-09-05 08:57:47
20240625211759	2026-09-05 08:57:47
20240704172020	2026-09-05 08:57:47
20240902173232	2026-09-05 08:57:47
20241106103258	2026-09-05 08:57:47
20250424203323	2026-09-05 08:57:47
20250613072131	2026-09-05 08:57:47
20250711044927	2026-09-05 08:57:47
20250811121559	2026-09-05 08:57:47
20250926223044	2026-09-05 08:57:48
20251204170944	2026-09-05 08:57:48
20251218000543	2026-09-05 08:57:48
20260209232800	2026-09-05 08:57:48
20260304000000	2026-09-05 08:57:48
20260422000000	2026-09-05 08:57:48
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: _realtime; Owner: supabase_admin
--

COPY _realtime.tenants (id, name, external_id, jwt_secret, max_concurrent_users, inserted_at, updated_at, max_events_per_second, postgres_cdc_default, max_bytes_per_second, max_channels_per_client, max_joins_per_second, suspend, jwt_jwks, notify_private_alpha, private_only, migrations_ran, broadcast_adapter, max_presence_events_per_second, max_payload_size_in_kb, max_client_presence_events_per_window, client_presence_window_ms, presence_enabled, feature_flags) FROM stdin;
623f8621-b316-4ab6-ba83-5d8220f45932	realtime-dev	realtime-dev	1J0sJBBedT31Vz8d4vw8ZwrE6vz45QconlAPXS829OaGeENpediKZxd4+ng8rkwy	200	2026-09-05 08:57:57	2026-09-05 08:58:00	100	postgres_cdc_rls	100000	100	100	f	{"keys": [{"x": "hXPwc06NfZDzuWdN1NJlOzXaOidru6hToBbfighaSng", "y": "29CunvY3MVghzNreqt0_FGIkTH84DZw4M-J12R2Njzo", "alg": "ES256", "crv": "P-256", "ext": true, "kid": "e18595d9-97d0-492d-a495-070e4cd4cf51", "kty": "EC", "use": "sig", "key_ops": ["verify"]}, {"k": "VGx6aWxlR0MzUnlsSUpXSWJ2UDVyaE5ySzN1bTRNSVBpL014Sm5aUg", "alg": "HS256", "kty": "oct"}]}	f	f	72	gen_rpc	1000	3000	\N	\N	f	{}
\.


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	354e25ff-0a26-4ff0-978a-f50a3bddd25f	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"test@cost-sheet.local","user_id":"abb8fb46-37fe-4c50-a1ac-51ec4d42db75","user_phone":""}}	2026-09-05 15:39:24.083386+00	
00000000-0000-0000-0000-000000000000	09190f54-2b76-4d1d-9080-6b4f57c52c15	{"action":"login","actor_id":"abb8fb46-37fe-4c50-a1ac-51ec4d42db75","actor_name":"مستخدم تجريبي","actor_username":"test@cost-sheet.local","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-05 15:39:33.340093+00	
00000000-0000-0000-0000-000000000000	26f5a431-626b-4a9e-a6b8-125e9c8cebec	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"provider":"email","user_email":"ramadan.waly@outlook.com","user_id":"56374db6-7dbd-4d51-997c-bec08d90630f","user_phone":""}}	2026-09-05 16:51:46.538152+00	
00000000-0000-0000-0000-000000000000	76d8ce9f-43a5-4852-8188-a2ad611eccbb	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-05 17:02:04.693+00	
00000000-0000-0000-0000-000000000000	7db6081d-f731-4a17-870b-d2c2579646ba	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 10:52:51.530654+00	
00000000-0000-0000-0000-000000000000	6b93545e-771d-48b3-9d0e-0e7250e2deb6	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 10:52:51.531972+00	
00000000-0000-0000-0000-000000000000	4b119c1b-7302-4403-9003-3319c2d40553	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 10:52:52.67888+00	
00000000-0000-0000-0000-000000000000	6aa6f4c0-9584-4e50-9a22-f971d7b8ef5a	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 11:36:47.339986+00	
00000000-0000-0000-0000-000000000000	5c165ea6-4b07-465e-82bf-278ae0381b60	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 12:35:18.70512+00	
00000000-0000-0000-0000-000000000000	f3f31abf-3ecb-436f-82ba-c7efe92dc08b	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 12:35:18.706778+00	
00000000-0000-0000-0000-000000000000	a2896ee6-6b31-4cac-bf63-d690f553e9c1	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 14:31:45.029484+00	
00000000-0000-0000-0000-000000000000	34252f54-6db7-4d73-b8c8-79bda5f25394	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 14:31:45.031013+00	
00000000-0000-0000-0000-000000000000	d629b638-2d48-4b54-81fb-b7e5e73cfb3d	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 15:30:19.473429+00	
00000000-0000-0000-0000-000000000000	6c78e648-b9e3-4f8b-9e48-2e20f5528023	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-06 15:30:19.47471+00	
00000000-0000-0000-0000-000000000000	0f92b88c-4c9c-491d-8619-5458b3e4c404	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 15:38:27.607881+00	
00000000-0000-0000-0000-000000000000	c0e7b04b-59be-4677-ba01-7b18f4e4be2b	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 15:38:52.791767+00	
00000000-0000-0000-0000-000000000000	5e0ddd36-9611-4220-ad94-039f037c9c42	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 15:50:38.57996+00	
00000000-0000-0000-0000-000000000000	28e7bd32-6159-41d4-9acf-8472e1492b44	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 15:51:01.988134+00	
00000000-0000-0000-0000-000000000000	ae277319-9542-4a3e-8fd1-d66be22ac88a	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 16:30:07.299524+00	
00000000-0000-0000-0000-000000000000	30029aec-111f-4384-9998-ba909e4391eb	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 17:44:39.195966+00	
00000000-0000-0000-0000-000000000000	87e6ee84-7314-4cb5-a471-2fa9439c9a2e	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 17:48:23.261458+00	
00000000-0000-0000-0000-000000000000	8ff5dc2c-7a09-4967-92c1-4fb655f45c74	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 18:48:21.064592+00	
00000000-0000-0000-0000-000000000000	1fb09404-4058-4c47-bef4-4e9e8a045d5e	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 18:50:30.490764+00	
00000000-0000-0000-0000-000000000000	d02a251d-c6ad-4130-b5ae-90ac19c87d19	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 21:07:43.119641+00	
00000000-0000-0000-0000-000000000000	c2feb7f8-95bc-4cd9-b334-fafce3459bb0	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 21:10:49.724078+00	
00000000-0000-0000-0000-000000000000	551483d8-8a85-4479-bfe0-87edae0e2edd	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-06 21:12:46.684166+00	
00000000-0000-0000-0000-000000000000	ce1b9fba-3b11-4033-b26e-f532464c8029	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-06 21:14:44.129769+00	
00000000-0000-0000-0000-000000000000	4cd986eb-f897-439e-bf2d-45ff8fb08479	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-07 08:21:40.961777+00	
00000000-0000-0000-0000-000000000000	0ea3b3fc-3f54-4aff-94c1-34476f2a6a75	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-07 09:23:30.397517+00	
00000000-0000-0000-0000-000000000000	a20ede0d-9861-46a4-9635-71612634f171	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-07 09:23:30.39903+00	
00000000-0000-0000-0000-000000000000	2d24372f-6a34-4bef-9bee-fc270c8d5cf1	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-09 12:16:09.04043+00	
00000000-0000-0000-0000-000000000000	ff6fa409-6e3a-4031-840d-1f06c6c05762	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-09 12:16:09.071848+00	
00000000-0000-0000-0000-000000000000	9d39d680-bbe5-4e18-a55c-f519e3404fe3	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 08:45:29.578252+00	
00000000-0000-0000-0000-000000000000	c6c4cff1-31c5-4ba2-a935-5de65cb1b08b	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 08:45:29.579644+00	
00000000-0000-0000-0000-000000000000	a5c3a72b-6bcd-41c1-9cb8-42d4f5d72927	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 09:52:00.092245+00	
00000000-0000-0000-0000-000000000000	eed7ad54-0f81-42f3-be29-5c22e2c8e63e	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 09:52:00.093648+00	
00000000-0000-0000-0000-000000000000	8bee3987-a9cd-4725-8dcb-5167e45e574f	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 10:52:04.710375+00	
00000000-0000-0000-0000-000000000000	f49c8801-d4a7-4405-bf20-9d04420e2500	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 10:52:04.711844+00	
00000000-0000-0000-0000-000000000000	9dd6db6f-cb1e-4011-99b9-9f46bf677d0c	{"action":"token_refreshed","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 11:52:34.830238+00	
00000000-0000-0000-0000-000000000000	ef319843-ece2-4849-a203-835343245b99	{"action":"token_revoked","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"token"}	2026-09-10 11:52:34.831752+00	
00000000-0000-0000-0000-000000000000	1fa5e2b0-73e2-417e-8e25-0b706b3a75c9	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-10 12:38:51.495455+00	
00000000-0000-0000-0000-000000000000	d1aa73e0-0724-42f8-8842-fd1c7581d65c	{"action":"login","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2026-09-11 00:27:47.214132+00	
00000000-0000-0000-0000-000000000000	4b2d9532-1d3b-48d9-875b-95f9194c35d3	{"action":"logout","actor_id":"56374db6-7dbd-4d51-997c-bec08d90630f","actor_username":"ramadan.waly@outlook.com","actor_via_sso":false,"log_type":"account"}	2026-09-11 01:16:10.536557+00	
\.


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.custom_oauth_providers (id, provider_type, identifier, name, client_id, client_secret, acceptable_client_ids, scopes, pkce_enabled, attribute_mapping, authorization_params, enabled, email_optional, issuer, discovery_url, skip_nonce_check, cached_discovery, discovery_cached_at, authorization_url, token_url, userinfo_url, jwks_uri, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
56374db6-7dbd-4d51-997c-bec08d90630f	56374db6-7dbd-4d51-997c-bec08d90630f	{"sub": "56374db6-7dbd-4d51-997c-bec08d90630f", "email": "ramadan.waly@outlook.com", "email_verified": false, "phone_verified": false}	email	2026-09-05 16:51:46.53648+00	2026-09-05 16:51:46.536574+00	2026-09-05 16:51:46.536574+00	1e1bde51-cf24-40f3-87cb-25d4aab3f04f
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
20260219120000
20260302000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	56374db6-7dbd-4d51-997c-bec08d90630f	authenticated	authenticated	ramadan.waly@outlook.com	$2a$10$xqPDJa1bySYYbr3z63eqVu8mdNnvcfWOLtJw2Rdtfp3FPJ.m5Nfym	2026-09-05 16:51:46.5408+00	\N		\N		\N			\N	2026-09-11 00:27:47.216282+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-09-05 16:51:46.530786+00	2026-09-11 00:27:47.235821+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.webauthn_challenges (id, user_id, challenge_type, session_data, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.webauthn_credentials (id, user_id, credential_id, public_key, attestation_type, aaguid, sign_count, transports, backup_eligible, backed_up, friendly_name, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, occurred_at, actor_id, action, entity_table, entity_id, reason, details, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: general_expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.general_expenses (id, expense_date, amount, category, description, treasury_transaction_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: idempotency_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.idempotency_keys (key, user_id, action, status, response_payload, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: operating_allocation_cycles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operating_allocation_cycles (id, year_month, status, total_amount, eligible_project_ids, notes, created_by, is_voided, voided_at, voided_by, void_reason, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: operating_allocation_exclusions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operating_allocation_exclusions (id, year_month, project_id, reason, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profiles (id, full_name, role, created_at, updated_at) FROM stdin;
56374db6-7dbd-4d51-997c-bec08d90630f	ramadan	owner	2026-09-05 16:51:46.530157+00	2026-09-05 17:00:19.315183+00
\.


--
-- Data for Name: project_cost_adjustments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_cost_adjustments (id, project_id, adjustment_type, amount, surplus_id, notes, created_at, updated_at, is_voided, voided_at, void_reason, voided_by, operating_cycle_id) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, name, description, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rate_limits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rate_limits (bucket, window_start, count) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (id, overhead_percentage, created_at, updated_at) FROM stdin;
5953d4f2-9c92-47a1-a6a0-e2a065b4f098	10.00	2026-09-05 10:40:54.132927+00	2026-09-05 15:43:21.176462+00
\.


--
-- Data for Name: subcontract_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subcontract_orders (id, project_id, contractor_name, description, total_agreed_amount, status, created_at, updated_at, close_reason) FROM stdin;
\.


--
-- Data for Name: subcontract_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subcontract_payments (id, subcontract_order_id, amount, payment_date, treasury_transaction_id, is_voided, notes, created_at, updated_at, void_reason) FROM stdin;
\.


--
-- Data for Name: surplus_bank; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.surplus_bank (id, material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, parent_surplus_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: treasury_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.treasury_transactions (id, transaction_type, category, amount, description, project_id, is_direct_owner_payment, is_voided, voided_at, void_reason, voided_by, created_by, created_at, updated_at, subcategory) FROM stdin;
\.


--
-- Data for Name: worker_advances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.worker_advances (id, worker_id, amount, advance_date, treasury_transaction_id, is_settled, settlement_id, is_carried_forward, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: worker_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.worker_logs (id, worker_id, project_id, log_date, fraction, daily_rate, is_settled, settlement_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workers (id, name, phone, daily_rate, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: messages_2026_09_04; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2026_09_04 (topic, extension, payload, event, private, updated_at, inserted_at, id, binary_payload) FROM stdin;
\.


--
-- Data for Name: messages_2026_09_05; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2026_09_05 (topic, extension, payload, event, private, updated_at, inserted_at, id, binary_payload) FROM stdin;
\.


--
-- Data for Name: messages_2026_09_06; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2026_09_06 (topic, extension, payload, event, private, updated_at, inserted_at, id, binary_payload) FROM stdin;
\.


--
-- Data for Name: messages_2026_09_07; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2026_09_07 (topic, extension, payload, event, private, updated_at, inserted_at, id, binary_payload) FROM stdin;
\.


--
-- Data for Name: messages_2026_09_08; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.messages_2026_09_08 (topic, extension, payload, event, private, updated_at, inserted_at, id, binary_payload) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2026-09-05 08:57:57
20211116045059	2026-09-05 08:57:57
20211116050929	2026-09-05 08:57:57
20211116051442	2026-09-05 08:57:58
20211116212300	2026-09-05 08:57:58
20211116213355	2026-09-05 08:57:58
20211116213934	2026-09-05 08:57:58
20211116214523	2026-09-05 08:57:58
20211122062447	2026-09-05 08:57:58
20211124070109	2026-09-05 08:57:58
20211202204204	2026-09-05 08:57:58
20211202204605	2026-09-05 08:57:58
20211210212804	2026-09-05 08:57:58
20211228014915	2026-09-05 08:57:58
20220107221237	2026-09-05 08:57:58
20220228202821	2026-09-05 08:57:58
20220312004840	2026-09-05 08:57:58
20220603231003	2026-09-05 08:57:58
20220603232444	2026-09-05 08:57:58
20220615214548	2026-09-05 08:57:58
20220712093339	2026-09-05 08:57:58
20220908172859	2026-09-05 08:57:58
20220916233421	2026-09-05 08:57:58
20230119133233	2026-09-05 08:57:58
20230128025114	2026-09-05 08:57:58
20230128025212	2026-09-05 08:57:58
20230227211149	2026-09-05 08:57:58
20230228184745	2026-09-05 08:57:58
20230308225145	2026-09-05 08:57:58
20230328144023	2026-09-05 08:57:58
20231018144023	2026-09-05 08:57:58
20231204144023	2026-09-05 08:57:58
20231204144024	2026-09-05 08:57:58
20231204144025	2026-09-05 08:57:58
20240108234812	2026-09-05 08:57:58
20240109165339	2026-09-05 08:57:58
20240227174441	2026-09-05 08:57:58
20240311171622	2026-09-05 08:57:59
20240321100241	2026-09-05 08:57:59
20240401105812	2026-09-05 08:57:59
20240418121054	2026-09-05 08:57:59
20240523004032	2026-09-05 08:57:59
20240618124746	2026-09-05 08:57:59
20240801235015	2026-09-05 08:57:59
20240805133720	2026-09-05 08:57:59
20240827160934	2026-09-05 08:57:59
20240919163303	2026-09-05 08:57:59
20240919163305	2026-09-05 08:57:59
20241019105805	2026-09-05 08:57:59
20241030150047	2026-09-05 08:57:59
20241108114728	2026-09-05 08:58:00
20241121104152	2026-09-05 08:58:00
20241130184212	2026-09-05 08:58:00
20241220035512	2026-09-05 08:58:00
20241220123912	2026-09-05 08:58:00
20241224161212	2026-09-05 08:58:00
20250107150512	2026-09-05 08:58:00
20250110162412	2026-09-05 08:58:00
20250123174212	2026-09-05 08:58:00
20250128220012	2026-09-05 08:58:00
20250506224012	2026-09-05 08:58:00
20250523164012	2026-09-05 08:58:00
20250714121412	2026-09-05 08:58:00
20250905041441	2026-09-05 08:58:00
20251103001201	2026-09-05 08:58:00
20251120212548	2026-09-05 08:58:00
20251120215549	2026-09-05 08:58:00
20260218120000	2026-09-05 08:58:00
20260326120000	2026-09-05 08:58:00
20260514120000	2026-09-05 08:58:00
20260527120000	2026-09-05 08:58:00
20260528120000	2026-09-05 08:58:00
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter, selected_columns) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_analytics (name, type, format, created_at, updated_at, id, deleted_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: iceberg_namespaces; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.iceberg_namespaces (id, bucket_name, name, created_at, updated_at, metadata, catalog_id) FROM stdin;
\.


--
-- Data for Name: iceberg_tables; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.iceberg_tables (id, namespace_id, bucket_name, name, location, created_at, updated_at, remote_table_id, shard_key, shard_id, catalog_id) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2026-09-05 08:57:53.674981
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2026-09-05 08:57:53.707795
2	storage-schema	f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd	2026-09-05 08:57:53.780228
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2026-09-05 08:57:53.850266
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2026-09-05 08:57:54.018019
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2026-09-05 08:57:54.222658
6	change-column-name-in-get-size	ded78e2f1b5d7e616117897e6443a925965b30d2	2026-09-05 08:57:54.427769
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2026-09-05 08:57:54.533854
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2026-09-05 08:57:54.650668
9	fix-search-function	af597a1b590c70519b464a4ab3be54490712796b	2026-09-05 08:57:54.700692
10	search-files-search-function	b595f05e92f7e91211af1bbfe9c6a13bb3391e16	2026-09-05 08:57:54.792321
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2026-09-05 08:57:55.012032
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2026-09-05 08:57:55.178304
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2026-09-05 08:57:55.264009
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2026-09-05 08:57:55.401701
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2026-09-05 08:57:55.510137
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2026-09-05 08:57:55.609274
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2026-09-05 08:57:55.692408
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2026-09-05 08:57:55.885563
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2026-09-05 08:57:55.992524
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2026-09-05 08:57:56.125999
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2026-09-05 08:57:56.184202
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2026-09-05 08:57:56.243132
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2026-09-05 08:57:56.294818
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2026-09-05 08:57:56.343557
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2026-09-05 08:57:56.39374
26	objects-prefixes	215cabcb7f78121892a5a2037a09fedf9a1ae322	2026-09-05 08:57:56.435439
27	search-v2	859ba38092ac96eb3964d83bf53ccc0b141663a6	2026-09-05 08:57:56.485579
28	object-bucket-name-sorting	c73a2b5b5d4041e39705814fd3a1b95502d38ce4	2026-09-05 08:57:56.52703
29	create-prefixes	ad2c1207f76703d11a9f9007f821620017a66c21	2026-09-05 08:57:56.568661
30	update-object-levels	2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6	2026-09-05 08:57:56.618567
31	objects-level-index	b40367c14c3440ec75f19bbce2d71e914ddd3da0	2026-09-05 08:57:56.66853
32	backward-compatible-index-on-objects	e0c37182b0f7aee3efd823298fb3c76f1042c0f7	2026-09-05 08:57:56.693541
33	backward-compatible-index-on-prefixes	b480e99ed951e0900f033ec4eb34b5bdcb4e3d49	2026-09-05 08:57:56.735146
34	optimize-search-function-v1	ca80a3dc7bfef894df17108785ce29a7fc8ee456	2026-09-05 08:57:56.872361
35	add-insert-trigger-prefixes	458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc	2026-09-05 08:57:56.950507
36	optimise-existing-functions	6ae5fca6af5c55abe95369cd4f93985d1814ca8f	2026-09-05 08:57:56.993654
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2026-09-05 08:57:57.043524
38	iceberg-catalog-flag-on-buckets	02716b81ceec9705aed84aa1501657095b32e5c5	2026-09-05 08:57:57.052339
39	add-search-v2-sort-support	6706c5f2928846abee18461279799ad12b279b78	2026-09-05 08:57:57.20432
40	fix-prefix-race-conditions-optimized	7ad69982ae2d372b21f48fc4829ae9752c518f6b	2026-09-05 08:57:57.212008
41	add-object-level-update-trigger	07fcf1a22165849b7a029deed059ffcde08d1ae0	2026-09-05 08:57:57.220367
42	rollback-prefix-triggers	771479077764adc09e2ea2043eb627503c034cd4	2026-09-05 08:57:57.28743
43	fix-object-level	84b35d6caca9d937478ad8a797491f38b8c2979f	2026-09-05 08:57:57.295433
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2026-09-05 08:57:57.303841
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2026-09-05 08:57:57.312011
46	buckets-objects-grants	fedeb96d60fefd8e02ab3ded9fbde05632f84aed	2026-09-05 08:57:57.337935
47	iceberg-table-metadata	649df56855c24d8b36dd4cc1aeb8251aa9ad42c2	2026-09-05 08:57:57.345821
48	iceberg-catalog-ids	e0e8b460c609b9999ccd0df9ad14294613eed939	2026-09-05 08:57:57.354234
49	buckets-objects-grants-postgres	072b1195d0d5a2f888af6b2302a1938dd94b8b3d	2026-09-05 08:57:57.422435
50	search-v2-optimised	6323ac4f850aa14e7387eb32102869578b5bd478	2026-09-05 08:57:57.463314
51	index-backward-compatible-search	2ee395d433f76e38bcd3856debaf6e0e5b674011	2026-09-05 08:57:57.630219
52	drop-not-used-indexes-and-functions	5cc44c8696749ac11dd0dc37f2a3802075f3a171	2026-09-05 08:57:57.638244
53	drop-index-lower-name	d0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854	2026-09-05 08:57:57.705771
54	drop-index-object-level	6289e048b1472da17c31a7eba1ded625a6457e67	2026-09-05 08:57:57.713965
55	prevent-direct-deletes	262a4798d5e0f2e7c8970232e03ce8be695d5819	2026-09-05 08:57:57.721668
56	fix-optimized-search-function	b823ed1e418101032fa01374edc9a436e54e3ed4	2026-09-05 08:57:57.730122
57	s3-multipart-uploads-metadata	f127886e00d1b374fadbc7c6b31e09336aad5287	2026-09-05 08:57:57.738556
58	operation-ergonomics	00ca5d483b3fe0d522133d9002ccc5df98365120	2026-09-05 08:57:57.746856
59	drop-unused-functions	38456f13e39691c2bbb4b5151d0d1cdbabd4a8c4	2026-09-05 08:57:57.755446
60	optimize-existing-functions-again	db35e1c91a9201e59f4fef8d972c2f277d68b157	2026-09-05 08:57:57.763479
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata, metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hooks; Type: TABLE DATA; Schema: supabase_functions; Owner: supabase_functions_admin
--

COPY supabase_functions.hooks (id, hook_table_id, hook_name, created_at, request_id) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: supabase_functions; Owner: supabase_functions_admin
--

COPY supabase_functions.migrations (version, inserted_at) FROM stdin;
initial	2026-09-05 08:57:13.318929+00
20210809183423_update_grants	2026-09-05 08:57:13.318929+00
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: postgres
--

COPY supabase_migrations.schema_migrations (version, statements, name, sha256, applied_at) FROM stdin;
20260905000010	\N	20260905000010_harden_auth_trigger.sql	09280972205e6e601ec12b93517c44e5ffc6c2e2e20816b411298fc49b205f44	2026-09-10 10:06:58.29101+00
20260905000001	{"-- ============================================================================\n-- 20260905000001_initial_schema.sql\n-- PHASE 1: Complete PostgreSQL Schema for Workshop Management System\n-- ============================================================================\n\n-- 1. Helper Function: Update timestamps trigger\nCREATE OR REPLACE FUNCTION trigger_set_timestamp()\nRETURNS TRIGGER AS $$\nBEGIN\n  NEW.updated_at = NOW();\n  RETURN NEW;\nEND;\n$$ LANGUAGE plpgsql","-- ----------------------------------------------------------------------------\n-- 2. Table: settings\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.settings (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    overhead_percentage NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (overhead_percentage >= 0),\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE TRIGGER set_timestamp_settings\n    BEFORE UPDATE ON public.settings\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 3. Table: profiles (Extends auth.users)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.profiles (\n    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,\n    full_name TEXT NOT NULL,\n    role TEXT NOT NULL CHECK (role IN ('owner', 'manager')),\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE TRIGGER set_timestamp_profiles\n    BEFORE UPDATE ON public.profiles\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 4. Table: projects\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.projects (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    name TEXT NOT NULL,\n    description TEXT,\n    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'on_hold', 'cancelled')),\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE TRIGGER set_timestamp_projects\n    BEFORE UPDATE ON public.projects\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 5. Table: treasury_transactions (Pure Cash Movement Log)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.treasury_transactions (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('in', 'out')),\n    category TEXT NOT NULL CHECK (\n        category IN (\n            'owner_funding',\n            'material',\n            'freight',\n            'advance',\n            'settlement',\n            'subcontract_payment',\n            'general_expense',\n            'carried_forward_advance',\n            'other'\n        )\n    ),\n    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),\n    description TEXT,\n    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,\n    is_direct_owner_payment BOOLEAN NOT NULL DEFAULT false,\n    is_voided BOOLEAN NOT NULL DEFAULT false,\n    voided_at TIMESTAMPTZ,\n    void_reason TEXT,\n    voided_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,\n    created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    -- Constraint: Direct owner payments are non-cash for treasury, always type 'out' logically\n    CONSTRAINT check_direct_owner_payment_type CHECK (\n        NOT is_direct_owner_payment OR transaction_type = 'out'\n    )\n)","CREATE INDEX idx_treasury_transactions_category ON public.treasury_transactions(category)","CREATE INDEX idx_treasury_transactions_project_id ON public.treasury_transactions(project_id)","CREATE INDEX idx_treasury_transactions_is_voided ON public.treasury_transactions(is_voided)","CREATE TRIGGER set_timestamp_treasury_transactions\n    BEFORE UPDATE ON public.treasury_transactions\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 6. Table: surplus_bank (Inventory of Reusable Materials)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.surplus_bank (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    material_name TEXT NOT NULL,\n    unit TEXT NOT NULL,\n    quantity NUMERIC(12,2) NOT NULL CHECK (quantity >= 0),\n    initial_quantity NUMERIC(12,2) NOT NULL CHECK (initial_quantity > 0),\n    estimated_value NUMERIC(12,2) NOT NULL CHECK (estimated_value >= 0),\n    source_project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,\n    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'consumed', 'scrapped')),\n    parent_surplus_id UUID REFERENCES public.surplus_bank(id) ON DELETE RESTRICT,\n    notes TEXT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE INDEX idx_surplus_bank_status ON public.surplus_bank(status)","CREATE INDEX idx_surplus_bank_source_project ON public.surplus_bank(source_project_id)","CREATE TRIGGER set_timestamp_surplus_bank\n    BEFORE UPDATE ON public.surplus_bank\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 7. Table: project_cost_adjustments (Surplus Returns, Consumptions & Scraps)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.project_cost_adjustments (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,\n    adjustment_type TEXT NOT NULL CHECK (\n        adjustment_type IN ('surplus_return', 'surplus_consumption', 'surplus_scrap')\n    ),\n    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),\n    surplus_id UUID REFERENCES public.surplus_bank(id) ON DELETE RESTRICT,\n    notes TEXT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    -- Invariant: Scrap write-offs must not be linked to any project (general workshop loss)\n    CONSTRAINT check_scrap_no_project CHECK (\n        (adjustment_type = 'surplus_scrap' AND project_id IS NULL) OR\n        (adjustment_type != 'surplus_scrap' AND project_id IS NOT NULL)\n    )\n)","CREATE INDEX idx_project_cost_adjustments_project_id ON public.project_cost_adjustments(project_id)","CREATE TRIGGER set_timestamp_project_cost_adjustments\n    BEFORE UPDATE ON public.project_cost_adjustments\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 8. Table: workers\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.workers (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    name TEXT NOT NULL,\n    phone TEXT,\n    daily_rate NUMERIC(10,2) NOT NULL CHECK (daily_rate > 0),\n    is_active BOOLEAN NOT NULL DEFAULT true,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE TRIGGER set_timestamp_workers\n    BEFORE UPDATE ON public.workers\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 9. Table: worker_logs (Daily Attendance & Wage Calculation)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.worker_logs (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE RESTRICT,\n    project_id UUID REFERENCES public.projects(id) ON DELETE RESTRICT,\n    log_date DATE NOT NULL DEFAULT CURRENT_DATE,\n    fraction NUMERIC(3,2) NOT NULL CHECK (fraction IN (0.25, 0.50, 1.00)),\n    daily_rate NUMERIC(10,2) NOT NULL CHECK (daily_rate > 0),\n    calculated_amount NUMERIC(10,2) NOT NULL GENERATED ALWAYS AS (daily_rate * fraction) STORED,\n    is_settled BOOLEAN NOT NULL DEFAULT false,\n    settlement_id UUID,\n    notes TEXT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE INDEX idx_worker_logs_worker_id ON public.worker_logs(worker_id)","CREATE INDEX idx_worker_logs_is_settled ON public.worker_logs(is_settled)","CREATE INDEX idx_worker_logs_project_id ON public.worker_logs(project_id)","CREATE TRIGGER set_timestamp_worker_logs\n    BEFORE UPDATE ON public.worker_logs\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 10. Table: worker_advances\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.worker_advances (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE RESTRICT,\n    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),\n    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,\n    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,\n    is_settled BOOLEAN NOT NULL DEFAULT false,\n    settlement_id UUID,\n    is_carried_forward BOOLEAN NOT NULL DEFAULT false,\n    notes TEXT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE INDEX idx_worker_advances_worker_id ON public.worker_advances(worker_id)","CREATE INDEX idx_worker_advances_is_settled ON public.worker_advances(is_settled)","CREATE TRIGGER set_timestamp_worker_advances\n    BEFORE UPDATE ON public.worker_advances\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 11. Table: subcontract_orders (Accrual Point for Subcontracts)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.subcontract_orders (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE RESTRICT,\n    contractor_name TEXT NOT NULL,\n    description TEXT NOT NULL,\n    total_agreed_amount NUMERIC(12,2) NOT NULL CHECK (total_agreed_amount > 0),\n    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE INDEX idx_subcontract_orders_project_id ON public.subcontract_orders(project_id)","CREATE TRIGGER set_timestamp_subcontract_orders\n    BEFORE UPDATE ON public.subcontract_orders\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 12. Table: subcontract_payments (Cash Reductions of Liability)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.subcontract_payments (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    subcontract_order_id UUID NOT NULL REFERENCES public.subcontract_orders(id) ON DELETE RESTRICT,\n    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),\n    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,\n    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,\n    is_voided BOOLEAN NOT NULL DEFAULT false,\n    notes TEXT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE INDEX idx_subcontract_payments_order_id ON public.subcontract_payments(subcontract_order_id)","CREATE TRIGGER set_timestamp_subcontract_payments\n    BEFORE UPDATE ON public.subcontract_payments\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 13. Table: general_expenses (Non-project overheads paid from Treasury)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.general_expenses (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,\n    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),\n    category TEXT NOT NULL,\n    description TEXT NOT NULL,\n    treasury_transaction_id UUID REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()\n)","CREATE TRIGGER set_timestamp_general_expenses\n    BEFORE UPDATE ON public.general_expenses\n    FOR EACH ROW\n    EXECUTE FUNCTION trigger_set_timestamp()","-- ----------------------------------------------------------------------------\n-- 14. Table: idempotency_keys (Double-Submit & Concurrency Guard)\n-- ----------------------------------------------------------------------------\nCREATE TABLE IF NOT EXISTS public.idempotency_keys (\n    key TEXT PRIMARY KEY,\n    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,\n    action TEXT NOT NULL,\n    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),\n    response_payload JSONB,\n    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),\n    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')\n)","CREATE INDEX idx_idempotency_keys_expires_at ON public.idempotency_keys(expires_at)","-- ----------------------------------------------------------------------------\n-- 15. Idempotent Profile Creation Trigger on auth.users\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.handle_new_user()\nRETURNS TRIGGER AS $$\nDECLARE\n    users_count INT;\n    assigned_role TEXT;\nBEGIN\n    SELECT COUNT(*) INTO users_count FROM public.profiles;\n    IF users_count = 0 THEN\n        assigned_role := 'owner';\n    ELSE\n        assigned_role := 'manager';\n    END IF;\n\n    INSERT INTO public.profiles (id, full_name, role)\n    VALUES (\n        NEW.id,\n        COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),\n        assigned_role\n    )\n    ON CONFLICT (id) DO NOTHING;\n\n    RETURN NEW;\nEND;\n$$ LANGUAGE plpgsql SECURITY DEFINER","DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users","CREATE TRIGGER on_auth_user_created\n    AFTER INSERT ON auth.users\n    FOR EACH ROW\n    EXECUTE FUNCTION public.handle_new_user()","-- Insert default settings row if not exists\nINSERT INTO public.settings (overhead_percentage)\nVALUES (10.00)\nON CONFLICT DO NOTHING"}	20260905000001_initial_schema.sql	8132522cbcc7f7acaea1a5bfbd1f173c13b77360b24008a67b839555aa8d75c5	2026-09-10 10:06:58.29101+00
20260905000002	{"-- ============================================================================\n-- 20260905000002_financial_views.sql\n-- PHASE 1.1: Authoritative Financial Views\n-- ============================================================================\n\n-- ----------------------------------------------------------------------------\n-- 1. View: v_treasury_balance\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE VIEW public.v_treasury_balance AS\nSELECT\n    COALESCE(SUM(amount) FILTER (\n        WHERE transaction_type = 'in'\n          AND NOT is_voided\n          AND NOT is_direct_owner_payment\n    ), 0) AS total_in,\n\n    COALESCE(SUM(amount) FILTER (\n        WHERE transaction_type = 'out'\n          AND NOT is_voided\n          AND NOT is_direct_owner_payment\n    ), 0) AS total_out,\n\n    COALESCE(SUM(\n        CASE\n            WHEN transaction_type = 'in' THEN amount\n            WHEN transaction_type = 'out' THEN -amount\n            ELSE 0\n        END\n    ) FILTER (\n        WHERE NOT is_voided\n          AND NOT is_direct_owner_payment\n    ), 0) AS current_balance\nFROM public.treasury_transactions","-- ----------------------------------------------------------------------------\n-- 2. View: v_project_direct_costs\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE VIEW public.v_project_direct_costs AS\nWITH project_materials AS (\n    -- المواد تشمل الكاش والدفع المباشر طالما ليست ملغاة\n    SELECT\n        project_id,\n        COALESCE(SUM(amount), 0) AS material_cost\n    FROM public.treasury_transactions\n    WHERE category = 'material'\n      AND NOT is_voided\n      AND project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_freight AS (\n    -- النولون المربوط بالمشروع حصراً\n    SELECT\n        project_id,\n        COALESCE(SUM(amount), 0) AS freight_cost\n    FROM public.treasury_transactions\n    WHERE category = 'freight'\n      AND NOT is_voided\n      AND project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_labor AS (\n    -- أجور العمال المربوطة بالمشروع\n    SELECT\n        project_id,\n        COALESCE(SUM(calculated_amount), 0) AS labor_cost\n    FROM public.worker_logs\n    WHERE project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_subcontracts AS (\n    -- تكلفة مقاولي الباطن تعتمد عند توقيع الاتفاق (Accrual basis)\n    SELECT\n        project_id,\n        COALESCE(SUM(total_agreed_amount), 0) AS subcontract_cost\n    FROM public.subcontract_orders\n    WHERE status != 'cancelled'\n    GROUP BY project_id\n),\nproject_surplus AS (\n    -- عوائد الفائض تطرح، واستهلاك الفائض يضاف\n    SELECT\n        project_id,\n        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_return' THEN amount ELSE 0 END), 0) AS surplus_returns,\n        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_consumption' THEN amount ELSE 0 END), 0) AS surplus_consumptions\n    FROM public.project_cost_adjustments\n    WHERE project_id IS NOT NULL\n    GROUP BY project_id\n),\ncurrent_settings AS (\n    SELECT overhead_percentage\n    FROM public.settings\n    ORDER BY created_at DESC\n    LIMIT 1\n)\nSELECT\n    p.id AS project_id,\n    p.name AS project_name,\n    p.status AS project_status,\n    COALESCE(pm.material_cost, 0) AS material_cost,\n    COALESCE(pf.freight_cost, 0) AS freight_cost,\n    COALESCE(pl.labor_cost, 0) AS labor_cost,\n    COALESCE(psub.subcontract_cost, 0) AS subcontract_cost,\n    COALESCE(psurp.surplus_returns, 0) AS surplus_returns,\n    COALESCE(psurp.surplus_consumptions, 0) AS surplus_consumptions,\n    -- Direct Cost Equation:\n    -- materials + freight + labor + subcontracts - surplus_returns + surplus_consumptions\n    (\n        COALESCE(pm.material_cost, 0) +\n        COALESCE(pf.freight_cost, 0) +\n        COALESCE(pl.labor_cost, 0) +\n        COALESCE(psub.subcontract_cost, 0) -\n        COALESCE(psurp.surplus_returns, 0) +\n        COALESCE(psurp.surplus_consumptions, 0)\n    ) AS direct_project_cost,\n    s.overhead_percentage,\n    ROUND(\n        (\n            COALESCE(pm.material_cost, 0) +\n            COALESCE(pf.freight_cost, 0) +\n            COALESCE(pl.labor_cost, 0) +\n            COALESCE(psub.subcontract_cost, 0) -\n            COALESCE(psurp.surplus_returns, 0) +\n            COALESCE(psurp.surplus_consumptions, 0)\n        ) * (1 + s.overhead_percentage / 100.0),\n        2\n    ) AS estimated_total_cost\nFROM public.projects p\nCROSS JOIN current_settings s\nLEFT JOIN project_materials pm ON p.id = pm.project_id\nLEFT JOIN project_freight pf ON p.id = pf.project_id\nLEFT JOIN project_labor pl ON p.id = pl.project_id\nLEFT JOIN project_subcontracts psub ON p.id = psub.project_id\nLEFT JOIN project_surplus psurp ON p.id = psurp.project_id","-- ----------------------------------------------------------------------------\n-- 3. View: v_pending_liabilities (Worker Net Liabilities + Subcontract Balances)\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE VIEW public.v_pending_liabilities AS\nWITH worker_unsettled_wages AS (\n    SELECT\n        worker_id,\n        COALESCE(SUM(calculated_amount), 0) AS total_wages\n    FROM public.worker_logs\n    WHERE NOT is_settled\n    GROUP BY worker_id\n),\nworker_unsettled_advances AS (\n    SELECT\n        worker_id,\n        COALESCE(SUM(amount), 0) AS total_advances\n    FROM public.worker_advances\n    WHERE NOT is_settled\n    GROUP BY worker_id\n),\nworker_net_liabilities AS (\n    -- التسوية لكل عامل على حدة: Net Payable = MAX(0, Wages - Advances)\n    SELECT\n        w.id AS worker_id,\n        COALESCE(uw.total_wages, 0) AS unsettled_wages,\n        COALESCE(ua.total_advances, 0) AS unsettled_advances,\n        GREATEST(0, COALESCE(uw.total_wages, 0) - COALESCE(ua.total_advances, 0)) AS net_payable,\n        GREATEST(0, COALESCE(ua.total_advances, 0) - COALESCE(uw.total_wages, 0)) AS carried_forward_credit\n    FROM public.workers w\n    LEFT JOIN worker_unsettled_wages uw ON w.id = uw.worker_id\n    LEFT JOIN worker_unsettled_advances ua ON w.id = ua.worker_id\n),\nsubcontract_balances AS (\n    -- رصيد مقاول الباطن المتبقي = المتفق عليه - المسدد غير الملغى\n    SELECT\n        so.id AS subcontract_order_id,\n        so.total_agreed_amount,\n        COALESCE(SUM(sp.amount) FILTER (WHERE NOT sp.is_voided), 0) AS total_paid,\n        (so.total_agreed_amount - COALESCE(SUM(sp.amount) FILTER (WHERE NOT sp.is_voided), 0)) AS remaining_balance\n    FROM public.subcontract_orders so\n    LEFT JOIN public.subcontract_payments sp ON so.id = sp.subcontract_order_id\n    WHERE so.status = 'active'\n    GROUP BY so.id, so.total_agreed_amount\n)\nSELECT\n    COALESCE(SUM(net_payable), 0) AS total_worker_liabilities,\n    COALESCE((SELECT SUM(remaining_balance) FROM subcontract_balances), 0) AS total_subcontract_liabilities,\n    (\n        COALESCE(SUM(net_payable), 0) +\n        COALESCE((SELECT SUM(remaining_balance) FROM subcontract_balances), 0)\n    ) AS total_pending_liabilities\nFROM worker_net_liabilities"}	20260905000002_financial_views.sql	5fce4408f8df3a6f6b1e8b7dc4a9bec8ab09a5c403cb533aeb7c12cd66791b5a	2026-09-10 10:06:58.29101+00
20260905000003	{"-- ============================================================================\n-- 20260905000003_rls_policies.sql\n-- PHASE 1.2: Row-Level Security (RLS) & Role-Based Authorization\n-- ============================================================================\n\n-- 1. Helper function to get the current user's role securely\nCREATE OR REPLACE FUNCTION public.current_user_role()\nRETURNS TEXT AS $$\n    SELECT role FROM public.profiles WHERE id = auth.uid();\n$$ LANGUAGE sql STABLE SECURITY DEFINER","-- 2. Helper function to check if user is owner\nCREATE OR REPLACE FUNCTION public.is_owner()\nRETURNS BOOLEAN AS $$\n    SELECT (public.current_user_role() = 'owner');\n$$ LANGUAGE sql STABLE SECURITY DEFINER","-- 3. Helper function to check if user is manager or owner\nCREATE OR REPLACE FUNCTION public.is_staff()\nRETURNS BOOLEAN AS $$\n    SELECT (public.current_user_role() IN ('owner', 'manager'));\n$$ LANGUAGE sql STABLE SECURITY DEFINER","-- ----------------------------------------------------------------------------\n-- Enable RLS on ALL Application Tables\n-- ----------------------------------------------------------------------------\nALTER TABLE public.settings ENABLE ROW LEVEL SECURITY","ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY","ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY","ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY","ALTER TABLE public.surplus_bank ENABLE ROW LEVEL SECURITY","ALTER TABLE public.project_cost_adjustments ENABLE ROW LEVEL SECURITY","ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY","ALTER TABLE public.worker_logs ENABLE ROW LEVEL SECURITY","ALTER TABLE public.worker_advances ENABLE ROW LEVEL SECURITY","ALTER TABLE public.subcontract_orders ENABLE ROW LEVEL SECURITY","ALTER TABLE public.subcontract_payments ENABLE ROW LEVEL SECURITY","ALTER TABLE public.general_expenses ENABLE ROW LEVEL SECURITY","ALTER TABLE public.idempotency_keys ENABLE ROW LEVEL SECURITY","-- Ensure Views respect RLS\nALTER VIEW public.v_treasury_balance SET (security_invoker = true)","ALTER VIEW public.v_project_direct_costs SET (security_invoker = true)","ALTER VIEW public.v_pending_liabilities SET (security_invoker = true)","-- ----------------------------------------------------------------------------\n-- POLICIES: settings\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"settings_select\\" ON public.settings\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"settings_modify_owner_only\\" ON public.settings\n    FOR ALL TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","-- ----------------------------------------------------------------------------\n-- POLICIES: profiles\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"profiles_select\\" ON public.profiles\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"profiles_update\\" ON public.profiles\n    FOR UPDATE TO authenticated\n    USING (public.is_owner() OR id = auth.uid())\n    WITH CHECK (\n        -- User can update their name, but cannot self-promote to owner\n        public.is_owner() OR (\n            id = auth.uid() AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())\n        )\n    )","-- ----------------------------------------------------------------------------\n-- POLICIES: projects\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"projects_select\\" ON public.projects\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"projects_insert\\" ON public.projects\n    FOR INSERT TO authenticated WITH CHECK (public.is_staff())","CREATE POLICY \\"projects_update\\" ON public.projects\n    FOR UPDATE TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff())","-- ----------------------------------------------------------------------------\n-- POLICIES: treasury_transactions\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"treasury_select\\" ON public.treasury_transactions\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"treasury_insert\\" ON public.treasury_transactions\n    FOR INSERT TO authenticated\n    WITH CHECK (\n        public.is_staff() AND (\n            -- Owner funding, advances, and settlements require owner role\n            (category NOT IN ('owner_funding', 'advance', 'settlement')) OR public.is_owner()\n        )\n    )","CREATE POLICY \\"treasury_update_void_owner_only\\" ON public.treasury_transactions\n    FOR UPDATE TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","-- NO DELETE POLICY on treasury_transactions (Hard delete prohibited)\n\n-- ----------------------------------------------------------------------------\n-- POLICIES: surplus_bank & project_cost_adjustments\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"surplus_bank_select\\" ON public.surplus_bank\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"surplus_bank_insert_update\\" ON public.surplus_bank\n    FOR ALL TO authenticated\n    USING (public.is_staff())\n    WITH CHECK (public.is_staff())","CREATE POLICY \\"cost_adj_select\\" ON public.project_cost_adjustments\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"cost_adj_insert\\" ON public.project_cost_adjustments\n    FOR INSERT TO authenticated WITH CHECK (public.is_staff())","-- ----------------------------------------------------------------------------\n-- POLICIES: workers & worker_logs\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"workers_select\\" ON public.workers\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"workers_insert_update\\" ON public.workers\n    FOR ALL TO authenticated\n    USING (public.is_staff())\n    WITH CHECK (public.is_staff())","CREATE POLICY \\"worker_logs_select\\" ON public.worker_logs\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"worker_logs_insert_update\\" ON public.worker_logs\n    FOR ALL TO authenticated\n    USING (public.is_staff())\n    WITH CHECK (public.is_staff())","-- ----------------------------------------------------------------------------\n-- POLICIES: worker_advances (Owner Only for mutations)\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"worker_advances_select\\" ON public.worker_advances\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"worker_advances_insert_update\\" ON public.worker_advances\n    FOR ALL TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","-- ----------------------------------------------------------------------------\n-- POLICIES: subcontract_orders & subcontract_payments (Owner Only for mutations)\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"subcontract_orders_select\\" ON public.subcontract_orders\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"subcontract_orders_modify\\" ON public.subcontract_orders\n    FOR ALL TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","CREATE POLICY \\"subcontract_payments_select\\" ON public.subcontract_payments\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"subcontract_payments_modify\\" ON public.subcontract_payments\n    FOR ALL TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","-- ----------------------------------------------------------------------------\n-- POLICIES: general_expenses\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"general_expenses_select\\" ON public.general_expenses\n    FOR SELECT TO authenticated USING (public.is_staff())","CREATE POLICY \\"general_expenses_insert\\" ON public.general_expenses\n    FOR INSERT TO authenticated WITH CHECK (public.is_staff())","CREATE POLICY \\"general_expenses_modify\\" ON public.general_expenses\n    FOR ALL TO authenticated\n    USING (public.is_owner())\n    WITH CHECK (public.is_owner())","-- ----------------------------------------------------------------------------\n-- POLICIES: idempotency_keys\n-- ----------------------------------------------------------------------------\nCREATE POLICY \\"idempotency_keys_user\\" ON public.idempotency_keys\n    FOR ALL TO authenticated\n    USING (user_id = auth.uid())\n    WITH CHECK (user_id = auth.uid())"}	20260905000003_rls_policies.sql	c22897dc1ff6e562aef3422a7fc6de4da53bd909aa71e4260e4b6b7acfde74dc	2026-09-10 10:06:58.29101+00
20260905000004	{"-- ============================================================================\n-- 20260905000004_surplus_rpcs.sql\n-- PHASE 3: Atomic Surplus Operations with Concurrency Locking\n-- ============================================================================\n\n-- 1. دالة إرجاع الفائض لبنك المواد وتخفيض تكلفة المشروع\nCREATE OR REPLACE FUNCTION public.rpc_return_surplus(\n    p_project_id UUID,\n    p_material_name TEXT,\n    p_unit TEXT,\n    p_quantity NUMERIC,\n    p_estimated_value NUMERIC,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB AS $$\nDECLARE\n    v_surplus_id UUID;\n    v_adjustment_id UUID;\nBEGIN\n    IF p_quantity <= 0 THEN\n        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر';\n    END IF;\n    IF p_estimated_value < 0 THEN\n        RAISE EXCEPTION 'القيمة التقديرية لا يمكن أن تكون سالبة';\n    END IF;\n\n    -- أ. إضافة المواد في بنك الفائض\n    INSERT INTO public.surplus_bank (\n        material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, notes\n    ) VALUES (\n        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value, p_project_id, 'available', p_notes\n    ) RETURNING id INTO v_surplus_id;\n\n    -- ب. تخفيض تكلفة المشروع المصدر بنفس القيمة\n    INSERT INTO public.project_cost_adjustments (\n        project_id, adjustment_type, amount, surplus_id, notes\n    ) VALUES (\n        p_project_id, 'surplus_return', p_estimated_value, v_surplus_id, p_notes\n    ) RETURNING id INTO v_adjustment_id;\n\n    RETURN jsonb_build_object(\n        'surplus_id', v_surplus_id,\n        'adjustment_id', v_adjustment_id,\n        'quantity', p_quantity,\n        'estimated_value', p_estimated_value\n    );\nEND;\n$$ LANGUAGE plpgsql SECURITY DEFINER","-- 2. دالة استهلاك الفائض مع قفل الصفوف (Row-Level Locking)\nCREATE OR REPLACE FUNCTION public.rpc_consume_surplus(\n    p_surplus_id UUID,\n    p_target_project_id UUID,\n    p_consume_qty NUMERIC,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB AS $$\nDECLARE\n    v_surplus RECORD;\n    v_consumed_value NUMERIC(12,2);\n    v_child_id UUID;\n    v_adjustment_id UUID;\nBEGIN\n    IF p_consume_qty <= 0 THEN\n        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر';\n    END IF;\n\n    -- قفل الصف حصرياً لمنع التزامن والسباق (Race Conditions)\n    SELECT * INTO v_surplus\n    FROM public.surplus_bank\n    WHERE id = p_surplus_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'عنصر الفائض غير موجود';\n    END IF;\n\n    IF v_surplus.status != 'available' THEN\n        RAISE EXCEPTION 'هذا العنصر غير متاح للاستهلاك (حالته: %)', v_surplus.status;\n    END IF;\n\n    IF p_consume_qty > v_surplus.quantity THEN\n        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity;\n    END IF;\n\n    -- احتساب القيمة المستهلكة\n    IF p_consume_qty = v_surplus.quantity THEN\n        -- استهلاك كامل (تجنب كسور التقريب)\n        v_consumed_value := v_surplus.estimated_value;\n\n        UPDATE public.surplus_bank\n        SET quantity = 0,\n            estimated_value = 0,\n            status = 'consumed'\n        WHERE id = p_surplus_id;\n\n        INSERT INTO public.project_cost_adjustments (\n            project_id, adjustment_type, amount, surplus_id, notes\n        ) VALUES (\n            p_target_project_id, 'surplus_consumption', v_consumed_value, p_surplus_id, p_notes\n        ) RETURNING id INTO v_adjustment_id;\n\n        RETURN jsonb_build_object(\n            'mode', 'full_consumption',\n            'surplus_id', p_surplus_id,\n            'consumed_quantity', p_consume_qty,\n            'consumed_value', v_consumed_value,\n            'adjustment_id', v_adjustment_id\n        );\n    ELSE\n        -- استهلاك جزئي: خصم الكمية من الأصل وإنشاء سجل ابن\n        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);\n\n        UPDATE public.surplus_bank\n        SET quantity = quantity - p_consume_qty,\n            estimated_value = estimated_value - v_consumed_value\n        WHERE id = p_surplus_id;\n\n        -- إنشاء سجل ابن بحالة consumed\n        INSERT INTO public.surplus_bank (\n            material_name, unit, quantity, initial_quantity, estimated_value,\n            source_project_id, status, parent_surplus_id, notes\n        ) VALUES (\n            v_surplus.material_name, v_surplus.unit, p_consume_qty, p_consume_qty, v_consumed_value,\n            v_surplus.source_project_id, 'consumed', v_surplus.id, p_notes\n        ) RETURNING id INTO v_child_id;\n\n        INSERT INTO public.project_cost_adjustments (\n            project_id, adjustment_type, amount, surplus_id, notes\n        ) VALUES (\n            p_target_project_id, 'surplus_consumption', v_consumed_value, v_child_id, p_notes\n        ) RETURNING id INTO v_adjustment_id;\n\n        RETURN jsonb_build_object(\n            'mode', 'partial_consumption',\n            'parent_surplus_id', p_surplus_id,\n            'child_surplus_id', v_child_id,\n            'consumed_quantity', p_consume_qty,\n            'consumed_value', v_consumed_value,\n            'remaining_quantity', v_surplus.quantity - p_consume_qty,\n            'remaining_value', v_surplus.estimated_value - v_consumed_value,\n            'adjustment_id', v_adjustment_id\n        );\n    END IF;\nEND;\n$$ LANGUAGE plpgsql SECURITY DEFINER","-- 3. دالة كهنة / إتلاف الفائض (Surplus Scrap)\nCREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(\n    p_surplus_id UUID,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB AS $$\nDECLARE\n    v_surplus RECORD;\n    v_scrap_value NUMERIC(12,2);\n    v_adjustment_id UUID;\nBEGIN\n    -- قفل الصف\n    SELECT * INTO v_surplus\n    FROM public.surplus_bank\n    WHERE id = p_surplus_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'عنصر الفائض غير موجود';\n    END IF;\n\n    IF v_surplus.status != 'available' THEN\n        RAISE EXCEPTION 'لا يمكن إتلاف عنصر غير متاح (حالته: %)', v_surplus.status;\n    END IF;\n\n    v_scrap_value := v_surplus.estimated_value;\n\n    -- تحويل الحالة إلى scrapped وتصفير الكمية\n    UPDATE public.surplus_bank\n    SET status = 'scrapped',\n        quantity = 0\n    WHERE id = p_surplus_id;\n\n    -- تسجيل تسوية هالك عام (project_id = NULL)\n    INSERT INTO public.project_cost_adjustments (\n        project_id, adjustment_type, amount, surplus_id, notes\n    ) VALUES (\n        NULL, 'surplus_scrap', v_scrap_value, p_surplus_id, p_notes\n    ) RETURNING id INTO v_adjustment_id;\n\n    RETURN jsonb_build_object(\n        'surplus_id', p_surplus_id,\n        'status', 'scrapped',\n        'scrapped_value', v_scrap_value,\n        'adjustment_id', v_adjustment_id\n    );\nEND;\n$$ LANGUAGE plpgsql SECURITY DEFINER"}	20260905000004_surplus_rpcs.sql	0896110fd436abcd1d31341926645f87909bc13b94660f9bcea2f997ce2cec24	2026-09-10 10:06:58.29101+00
20260905000005	{"-- ============================================================================\n-- Resolve All Lint 0029 Warnings\n-- 1. Switch RPCs to SECURITY INVOKER\n-- 2. Move RLS helpers to private schema (app_private)\n-- ============================================================================\n\n-- ----------------------------------------------------------------------------\n-- الخطوة 1: إنشاء المخطط الداخلي الخاص app_private\n-- ----------------------------------------------------------------------------\nCREATE SCHEMA IF NOT EXISTS app_private","-- منح المستخدمين المسجلين صلاحية استخدام المخطط الداخلي لقراءة السياسات\nGRANT USAGE ON SCHEMA app_private TO authenticated","-- نقل دوال فحص الصلاحيات إلى المخطط الداخلي\nCREATE OR REPLACE FUNCTION app_private.current_user_role()\nRETURNS TEXT \nSECURITY DEFINER\nSET search_path = public\nAS $$\n    SELECT role FROM public.profiles WHERE id = auth.uid();\n$$ LANGUAGE sql STABLE","CREATE OR REPLACE FUNCTION app_private.is_owner()\nRETURNS BOOLEAN \nSECURITY DEFINER\nSET search_path = public\nAS $$\n    SELECT (app_private.current_user_role() = 'owner');\n$$ LANGUAGE sql STABLE","CREATE OR REPLACE FUNCTION app_private.is_staff()\nRETURNS BOOLEAN \nSECURITY DEFINER\nSET search_path = public\nAS $$\n    SELECT (app_private.current_user_role() IN ('owner', 'manager'));\n$$ LANGUAGE sql STABLE","GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_private TO authenticated","-- ----------------------------------------------------------------------------\n-- الخطوة 2: تحديث سياسات الـ RLS لاستخدام الدوال الخاصة من app_private\n-- ----------------------------------------------------------------------------\n-- settings\nDROP POLICY IF EXISTS \\"settings_select\\" ON public.settings","DROP POLICY IF EXISTS \\"settings_modify_owner_only\\" ON public.settings","CREATE POLICY \\"settings_select\\" ON public.settings FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"settings_modify_owner_only\\" ON public.settings FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","-- profiles\nDROP POLICY IF EXISTS \\"profiles_select\\" ON public.profiles","DROP POLICY IF EXISTS \\"profiles_update\\" ON public.profiles","CREATE POLICY \\"profiles_select\\" ON public.profiles FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"profiles_update\\" ON public.profiles FOR UPDATE TO authenticated USING (app_private.is_owner() OR id = auth.uid()) WITH CHECK (app_private.is_owner() OR (id = auth.uid() AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())))","-- projects\nDROP POLICY IF EXISTS \\"projects_select\\" ON public.projects","DROP POLICY IF EXISTS \\"projects_insert\\" ON public.projects","DROP POLICY IF EXISTS \\"projects_update\\" ON public.projects","CREATE POLICY \\"projects_select\\" ON public.projects FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"projects_insert\\" ON public.projects FOR INSERT TO authenticated WITH CHECK (app_private.is_staff())","CREATE POLICY \\"projects_update\\" ON public.projects FOR UPDATE TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff())","-- treasury_transactions\nDROP POLICY IF EXISTS \\"treasury_select\\" ON public.treasury_transactions","DROP POLICY IF EXISTS \\"treasury_insert\\" ON public.treasury_transactions","DROP POLICY IF EXISTS \\"treasury_update_void_owner_only\\" ON public.treasury_transactions","CREATE POLICY \\"treasury_select\\" ON public.treasury_transactions FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"treasury_insert\\" ON public.treasury_transactions FOR INSERT TO authenticated WITH CHECK (app_private.is_staff() AND ((category NOT IN ('owner_funding', 'advance', 'settlement')) OR app_private.is_owner()))","CREATE POLICY \\"treasury_update_void_owner_only\\" ON public.treasury_transactions FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","-- surplus_bank & adjustments\nDROP POLICY IF EXISTS \\"surplus_bank_select\\" ON public.surplus_bank","DROP POLICY IF EXISTS \\"surplus_bank_insert_update\\" ON public.surplus_bank","DROP POLICY IF EXISTS \\"cost_adj_select\\" ON public.project_cost_adjustments","DROP POLICY IF EXISTS \\"cost_adj_insert\\" ON public.project_cost_adjustments","CREATE POLICY \\"surplus_bank_select\\" ON public.surplus_bank FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"surplus_bank_insert_update\\" ON public.surplus_bank FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff())","CREATE POLICY \\"cost_adj_select\\" ON public.project_cost_adjustments FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"cost_adj_insert\\" ON public.project_cost_adjustments FOR INSERT TO authenticated WITH CHECK (app_private.is_staff())","-- workers & logs\nDROP POLICY IF EXISTS \\"workers_select\\" ON public.workers","DROP POLICY IF EXISTS \\"workers_insert_update\\" ON public.workers","DROP POLICY IF EXISTS \\"worker_logs_select\\" ON public.worker_logs","DROP POLICY IF EXISTS \\"worker_logs_insert_update\\" ON public.worker_logs","CREATE POLICY \\"workers_select\\" ON public.workers FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"workers_insert_update\\" ON public.workers FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff())","CREATE POLICY \\"worker_logs_select\\" ON public.worker_logs FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"worker_logs_insert_update\\" ON public.worker_logs FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff())","-- worker_advances\nDROP POLICY IF EXISTS \\"worker_advances_select\\" ON public.worker_advances","DROP POLICY IF EXISTS \\"worker_advances_insert_update\\" ON public.worker_advances","CREATE POLICY \\"worker_advances_select\\" ON public.worker_advances FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"worker_advances_insert_update\\" ON public.worker_advances FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","-- subcontracts\nDROP POLICY IF EXISTS \\"subcontract_orders_select\\" ON public.subcontract_orders","DROP POLICY IF EXISTS \\"subcontract_orders_modify\\" ON public.subcontract_orders","DROP POLICY IF EXISTS \\"subcontract_payments_select\\" ON public.subcontract_payments","DROP POLICY IF EXISTS \\"subcontract_payments_modify\\" ON public.subcontract_payments","CREATE POLICY \\"subcontract_orders_select\\" ON public.subcontract_orders FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"subcontract_orders_modify\\" ON public.subcontract_orders FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","CREATE POLICY \\"subcontract_payments_select\\" ON public.subcontract_payments FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"subcontract_payments_modify\\" ON public.subcontract_payments FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","-- general_expenses\nDROP POLICY IF EXISTS \\"general_expenses_select\\" ON public.general_expenses","DROP POLICY IF EXISTS \\"general_expenses_insert\\" ON public.general_expenses","DROP POLICY IF EXISTS \\"general_expenses_modify\\" ON public.general_expenses","CREATE POLICY \\"general_expenses_select\\" ON public.general_expenses FOR SELECT TO authenticated USING (app_private.is_staff())","CREATE POLICY \\"general_expenses_insert\\" ON public.general_expenses FOR INSERT TO authenticated WITH CHECK (app_private.is_staff())","CREATE POLICY \\"general_expenses_modify\\" ON public.general_expenses FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner())","-- حذف الدوال القديمة من public حتى لا تظهر في الـ API نهائياً\nDROP FUNCTION IF EXISTS public.current_user_role()","DROP FUNCTION IF EXISTS public.is_owner()","DROP FUNCTION IF EXISTS public.is_staff()","-- ----------------------------------------------------------------------------\n-- الخطوة 3: إعادة بناء دوال الفائض كـ SECURITY INVOKER (تنفذ بصلاحيات المستخدم RLS)\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.rpc_return_surplus(\n    p_project_id UUID,\n    p_material_name TEXT,\n    p_unit TEXT,\n    p_quantity NUMERIC,\n    p_estimated_value NUMERIC,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB \nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_surplus_id UUID;\n    v_adjustment_id UUID;\nBEGIN\n    IF NOT app_private.is_staff() THEN\n        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';\n    END IF;\n\n    IF p_quantity <= 0 THEN\n        RAISE EXCEPTION 'الكمية يجب أن تكون أكبر من صفر';\n    END IF;\n    IF p_estimated_value < 0 THEN\n        RAISE EXCEPTION 'القيمة التقديرية لا يمكن أن تكون سالبة';\n    END IF;\n\n    INSERT INTO public.surplus_bank (\n        material_name, unit, quantity, initial_quantity, estimated_value, source_project_id, status, notes\n    ) VALUES (\n        p_material_name, p_unit, p_quantity, p_quantity, p_estimated_value, p_project_id, 'available', p_notes\n    ) RETURNING id INTO v_surplus_id;\n\n    INSERT INTO public.project_cost_adjustments (\n        project_id, adjustment_type, amount, surplus_id, notes\n    ) VALUES (\n        p_project_id, 'surplus_return', p_estimated_value, v_surplus_id, p_notes\n    ) RETURNING id INTO v_adjustment_id;\n\n    RETURN jsonb_build_object(\n        'surplus_id', v_surplus_id,\n        'adjustment_id', v_adjustment_id,\n        'quantity', p_quantity,\n        'estimated_value', p_estimated_value\n    );\nEND;\n$$ LANGUAGE plpgsql","CREATE OR REPLACE FUNCTION public.rpc_consume_surplus(\n    p_surplus_id UUID,\n    p_target_project_id UUID,\n    p_consume_qty NUMERIC,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB \nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_surplus RECORD;\n    v_consumed_value NUMERIC(12,2);\n    v_child_id UUID;\n    v_adjustment_id UUID;\nBEGIN\n    IF NOT app_private.is_staff() THEN\n        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';\n    END IF;\n\n    IF p_consume_qty <= 0 THEN\n        RAISE EXCEPTION 'الكمية المستهلكة يجب أن تكون أكبر من صفر';\n    END IF;\n\n    SELECT * INTO v_surplus\n    FROM public.surplus_bank\n    WHERE id = p_surplus_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'عنصر الفائض غير موجود';\n    END IF;\n\n    IF v_surplus.status != 'available' THEN\n        RAISE EXCEPTION 'هذا العنصر غير متاح للاستهلاك (حالته: %)', v_surplus.status;\n    END IF;\n\n    IF p_consume_qty > v_surplus.quantity THEN\n        RAISE EXCEPTION 'الكمية المطلوبة (%) أكبر من الكمية المتاحة (%)', p_consume_qty, v_surplus.quantity;\n    END IF;\n\n    IF p_consume_qty = v_surplus.quantity THEN\n        v_consumed_value := v_surplus.estimated_value;\n\n        UPDATE public.surplus_bank\n        SET quantity = 0,\n            estimated_value = 0,\n            status = 'consumed'\n        WHERE id = p_surplus_id;\n\n        INSERT INTO public.project_cost_adjustments (\n            project_id, adjustment_type, amount, surplus_id, notes\n        ) VALUES (\n            p_target_project_id, 'surplus_consumption', v_consumed_value, p_surplus_id, p_notes\n        ) RETURNING id INTO v_adjustment_id;\n\n        RETURN jsonb_build_object(\n            'mode', 'full_consumption',\n            'surplus_id', p_surplus_id,\n            'consumed_quantity', p_consume_qty,\n            'consumed_value', v_consumed_value,\n            'adjustment_id', v_adjustment_id\n        );\n    ELSE\n        v_consumed_value := ROUND((v_surplus.estimated_value / v_surplus.quantity) * p_consume_qty, 2);\n\n        UPDATE public.surplus_bank\n        SET quantity = quantity - p_consume_qty,\n            estimated_value = estimated_value - v_consumed_value\n        WHERE id = p_surplus_id;\n\n        INSERT INTO public.surplus_bank (\n            material_name, unit, quantity, initial_quantity, estimated_value,\n            source_project_id, status, parent_surplus_id, notes\n        ) VALUES (\n            v_surplus.material_name, v_surplus.unit, p_consume_qty, p_consume_qty, v_consumed_value,\n            v_surplus.source_project_id, 'consumed', v_surplus.id, p_notes\n        ) RETURNING id INTO v_child_id;\n\n        INSERT INTO public.project_cost_adjustments (\n            project_id, adjustment_type, amount, surplus_id, notes\n        ) VALUES (\n            p_target_project_id, 'surplus_consumption', v_consumed_value, v_child_id, p_notes\n        ) RETURNING id INTO v_adjustment_id;\n\n        RETURN jsonb_build_object(\n            'mode', 'partial_consumption',\n            'parent_surplus_id', p_surplus_id,\n            'child_surplus_id', v_child_id,\n            'consumed_quantity', p_consume_qty,\n            'consumed_value', v_consumed_value,\n            'remaining_quantity', v_surplus.quantity - p_consume_qty,\n            'remaining_value', v_surplus.estimated_value - v_consumed_value,\n            'adjustment_id', v_adjustment_id\n        );\n    END IF;\nEND;\n$$ LANGUAGE plpgsql","CREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(\n    p_surplus_id UUID,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB \nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_surplus RECORD;\n    v_scrap_value NUMERIC(12,2);\n    v_adjustment_id UUID;\nBEGIN\n    IF NOT app_private.is_staff() THEN\n        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';\n    END IF;\n\n    SELECT * INTO v_surplus\n    FROM public.surplus_bank\n    WHERE id = p_surplus_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'عنصر الفائض غير موجود';\n    END IF;\n\n    IF v_surplus.status != 'available' THEN\n        RAISE EXCEPTION 'لا يمكن إتلاف عنصر غير متاح (حالته: %)', v_surplus.status;\n    END IF;\n\n    v_scrap_value := v_surplus.estimated_value;\n\n    UPDATE public.surplus_bank\n    SET status = 'scrapped',\n        quantity = 0\n    WHERE id = p_surplus_id;\n\n    INSERT INTO public.project_cost_adjustments (\n        project_id, adjustment_type, amount, surplus_id, notes\n    ) VALUES (\n        NULL, 'surplus_scrap', v_scrap_value, p_surplus_id, p_notes\n    ) RETURNING id INTO v_adjustment_id;\n\n    RETURN jsonb_build_object(\n        'surplus_id', p_surplus_id,\n        'status', 'scrapped',\n        'scrapped_value', v_scrap_value,\n        'adjustment_id', v_adjustment_id\n    );\nEND;\n$$ LANGUAGE plpgsql"}	20260905000005_fix_security_lints.sql	2d9251922a5756fcfb623bc7c543aad25107644bb1c71c02f1dd1098497704bf	2026-09-10 10:06:58.29101+00
20260905000006	{"created labor rpcs"}	20260905000006_labor_rpcs.sql	9dc7fc99a08b81933ecb0afd94ea05c921c4555b3c7af1094bca0595fcdf57b0	2026-09-10 10:06:58.29101+00
20260905000007	{"-- ============================================================================\n-- 20260905000007_subcontract_rpcs.sql\n-- PHASE 5: Subcontracting — with Concurrency Protection\n--   rpc_create_subcontract_order  (owner-only) — accrual point for cost/liability\n--   rpc_pay_subcontract           (owner-only) — atomic, SELECT ... FOR UPDATE\n--   rpc_void_subcontract_payment  (owner-only) — reversal (never hard delete)\n--   rpc_close_subcontract_order   (owner-only) — completed must be fully paid\n--\n-- The existing views already make order cost/liability authoritative:\n--   v_project_direct_costs  : subcontract_cost = SUM(total_agreed) of non-cancelled\n--   v_pending_liabilities   : remaining = total_agreed - SUM(not-voided payments)\n-- These RPCs only write rows; the views always derive totals from DB truth.\n-- ============================================================================\n\n-- ----------------------------------------------------------------------------\n-- 1. rpc_create_subcontract_order — owner only\n--    Creates an ACTIVE order. Immediately (via views) raises project cost and\n--    liability by total_agreed_amount. Treasury unchanged at this point.\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.rpc_create_subcontract_order(\n    p_project_id UUID,\n    p_contractor_name TEXT,\n    p_description TEXT,\n    p_total_agreed_amount NUMERIC\n)\nRETURNS JSONB\nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_order_id  UUID;\nBEGIN\n    IF NOT app_private.is_owner() THEN\n        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';\n    END IF;\n\n    IF p_total_agreed_amount <= 0 THEN\n        RAISE EXCEPTION 'المبلغ المتفق عليه يجب أن يكون أكبر من صفر';\n    END IF;\n\n    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = p_project_id) THEN\n        RAISE EXCEPTION 'المشروع غير موجود';\n    END IF;\n\n    INSERT INTO public.subcontract_orders (\n        project_id, contractor_name, description, total_agreed_amount, status\n    ) VALUES (\n        p_project_id, p_contractor_name, p_description, p_total_agreed_amount, 'active'\n    ) RETURNING id INTO v_order_id;\n\n    RETURN jsonb_build_object(\n        'order_id', v_order_id,\n        'project_id', p_project_id,\n        'contractor_name', p_contractor_name,\n        'total_agreed_amount', p_total_agreed_amount,\n        'status', 'active'\n    );\nEND;\n$$ LANGUAGE plpgsql","-- ----------------------------------------------------------------------------\n-- 2. rpc_pay_subcontract — owner only, atomic, row-locked, authoritative\n--    Locks the order row FOR UPDATE and validates BEFORE writing:\n--      payment > 0\n--      SUM(valid, non-voided payments) + payment <= total_agreed_amount\n--    Blocks payment on a non-active (closed/cancelled) order.\n--    Writes: subcontract_payment + treasury OUT (category 'subcontract_payment').\n--    Project cost NOT increased again (accrual already recorded at agreement).\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.rpc_pay_subcontract(\n    p_order_id UUID,\n    p_amount NUMERIC,\n    p_payment_date DATE,\n    p_notes TEXT DEFAULT NULL\n)\nRETURNS JSONB\nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_order       RECORD;\n    v_paid        NUMERIC(12,2);\n    v_payment_id  UUID;\n    v_tx_id       UUID;\n    v_current_user UUID;\nBEGIN\n    IF NOT app_private.is_owner() THEN\n        RAISE EXCEPTION 'غير مصرح: سداد مقاولي الباطن مخصص لمالك الورشة فقط';\n    END IF;\n\n    IF p_amount <= 0 THEN\n        RAISE EXCEPTION 'مبلغ الدفعة يجب أن يكون أكبر من صفر';\n    END IF;\n\n    SELECT * INTO v_order\n    FROM public.subcontract_orders\n    WHERE id = p_order_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';\n    END IF;\n\n    IF v_order.status != 'active' THEN\n        RAISE EXCEPTION 'لا يمكن سداد اتفاقية مغلقة (حالتها: %)', v_order.status;\n    END IF;\n\n    v_paid := COALESCE((\n        SELECT SUM(amount)\n        FROM public.subcontract_payments\n        WHERE subcontract_order_id = p_order_id\n          AND NOT is_voided\n    ), 0);\n\n    IF v_paid + p_amount > v_order.total_agreed_amount THEN\n        RAISE EXCEPTION\n            'دفعة مرفوضة: مجموع المدفوعات (%) + هذه الدفعة (%) يتجاوز المبلغ المتفق عليه (%)',\n            v_paid, p_amount, v_order.total_agreed_amount;\n    END IF;\n\n    SELECT auth.uid() INTO v_current_user;\n\n    INSERT INTO public.treasury_transactions (\n        transaction_type, category, amount, description, created_by\n    ) VALUES (\n        'out', 'subcontract_payment', p_amount,\n        COALESCE(p_notes, 'دفعة لمقاول الباطن: ' || v_order.contractor_name || ' - ' || v_order.description),\n        v_current_user\n    ) RETURNING id INTO v_tx_id;\n\n    INSERT INTO public.subcontract_payments (\n        subcontract_order_id, amount, payment_date, treasury_transaction_id, notes\n    ) VALUES (\n        p_order_id, p_amount, p_payment_date, v_tx_id, p_notes\n    ) RETURNING id INTO v_payment_id;\n\n    RETURN jsonb_build_object(\n        'payment_id', v_payment_id,\n        'order_id', p_order_id,\n        'amount', p_amount,\n        'treasury_transaction_id', v_tx_id,\n        'total_paid_after', v_paid + p_amount\n    );\nEND;\n$$ LANGUAGE plpgsql","-- ----------------------------------------------------------------------------\n-- 3. rpc_void_subcontract_payment — owner only, reversal (never hard delete)\n--    Marks the payment is_voided = true AND voids its linked treasury OUT, so:\n--      treasury balance is restored (view excludes voided)\n--      the amount no longer counts against the paid sum (liability back up)\n--      payment is still visible/historical for audit\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.rpc_void_subcontract_payment(\n    p_payment_id UUID,\n    p_reason TEXT DEFAULT NULL\n)\nRETURNS JSONB\nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_payment RECORD;\n    v_current_user UUID;\nBEGIN\n    IF NOT app_private.is_owner() THEN\n        RAISE EXCEPTION 'غير مصرح: إلغاء دفعات مقاولي الباطن مخصص لمالك الورشة فقط';\n    END IF;\n\n    SELECT * INTO v_payment\n    FROM public.subcontract_payments\n    WHERE id = p_payment_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'الدفعة غير موجودة';\n    END IF;\n\n    IF v_payment.is_voided THEN\n        RAISE EXCEPTION 'هذه الدفعة ملغاة بالفعل مسبقاً';\n    END IF;\n\n    SELECT auth.uid() INTO v_current_user;\n\n    UPDATE public.subcontract_payments\n    SET is_voided = true,\n        notes = COALESCE(p_reason, notes)\n    WHERE id = p_payment_id;\n\n    IF v_payment.treasury_transaction_id IS NOT NULL THEN\n        UPDATE public.treasury_transactions\n        SET is_voided = true,\n            voided_at = NOW(),\n            void_reason = COALESCE(p_reason, 'إلغاء دفعة مقاول باطن'),\n            voided_by = v_current_user\n        WHERE id = v_payment.treasury_transaction_id;\n    END IF;\n\n    RETURN jsonb_build_object(\n        'payment_id', p_payment_id,\n        'order_id', v_payment.subcontract_order_id,\n        'voided', true,\n        'treasury_transaction_id', v_payment.treasury_transaction_id\n    );\nEND;\n$$ LANGUAGE plpgsql","-- ----------------------------------------------------------------------------\n-- 4. rpc_close_subcontract_order — owner only\n--    status = 'completed' : requires fully paid (remaining = 0) per invariant\n--                           \\"a closed order must not retain an unexplained\n--                            unpaid balance\\" (payments are blocked once closed)\n--    status = 'cancelled' : no full-payment requirement (unpaid is explained by\n--                           the cancellation itself)\n-- ----------------------------------------------------------------------------\nCREATE OR REPLACE FUNCTION public.rpc_close_subcontract_order(\n    p_order_id UUID,\n    p_status TEXT DEFAULT 'completed'\n)\nRETURNS JSONB\nSECURITY INVOKER\nSET search_path = public\nAS $$\nDECLARE\n    v_order RECORD;\n    v_paid  NUMERIC(12,2);\nBEGIN\n    IF NOT app_private.is_owner() THEN\n        RAISE EXCEPTION 'غير مصرح: إدارة اتفاقيات مقاولي الباطن مخصصة لمالك الورشة فقط';\n    END IF;\n\n    IF p_status NOT IN ('completed', 'cancelled') THEN\n        RAISE EXCEPTION 'حالة الإغلاق غير صالحة (يسمح فقط بـ completed أو cancelled)';\n    END IF;\n\n    SELECT * INTO v_order\n    FROM public.subcontract_orders\n    WHERE id = p_order_id\n    FOR UPDATE;\n\n    IF NOT FOUND THEN\n        RAISE EXCEPTION 'اتفاقية مقاول الباطن غير موجودة';\n    END IF;\n\n    IF v_order.status != 'active' THEN\n        RAISE EXCEPTION 'الاتفاقية مغلقة بالفعل (حالتها: %)', v_order.status;\n    END IF;\n\n    IF p_status = 'completed' THEN\n        v_paid := COALESCE((\n            SELECT SUM(amount)\n            FROM public.subcontract_payments\n            WHERE subcontract_order_id = p_order_id\n              AND NOT is_voided\n        ), 0);\n\n        IF v_paid <> v_order.total_agreed_amount THEN\n            RAISE EXCEPTION\n                'لا يمكن إغلاق الاتفاقية كـ completed: يوجد رصيد غير مدفوع (المتبقي %)',\n                v_order.total_agreed_amount - v_paid;\n        END IF;\n    END IF;\n\n    UPDATE public.subcontract_orders\n    SET status = p_status\n    WHERE id = p_order_id;\n\n    RETURN jsonb_build_object(\n        'order_id', p_order_id,\n        'status', p_status\n    );\nEND;\n$$ LANGUAGE plpgsql"}	20260905000007_subcontract_rpcs.sql	5347461bd918d8c715c54451ba0c323479c885c33da957374dc81739acacd9d0	2026-09-10 10:06:58.29101+00
20260905000008	{"-- ============================================================================\n-- 20260905000008_fix_cancelled_subcontract_cost.sql\n-- PHASE 5 FIX: Correct project cost for a CANCELLED subcontract order.\n--\n-- Old behaviour (bug): v_project_direct_costs excluded a cancelled order\n-- entirely (status != 'cancelled'), dropping the FULL agreed amount from\n-- project cost — including the portion that was actually paid.\n--\n-- New behaviour (financially correct): a cancelled order contributes ONLY its\n-- valid (non-voided) paid portion to project cost; the unpaid obligation is\n-- reversed at cancellation (it was an estimated recognition that no longer\n-- applies). v_pending_liabilities already excludes non-active orders, so the\n-- unpaid portion correctly stops being a pending liability on cancellation.\n-- ============================================================================\n\nCREATE OR REPLACE VIEW public.v_project_direct_costs AS\nWITH project_materials AS (\n    -- المواد تشمل الكاش والدفع المباشر طالما ليست ملغاة\n    SELECT\n        project_id,\n        COALESCE(SUM(amount), 0) AS material_cost\n    FROM public.treasury_transactions\n    WHERE category = 'material'\n      AND NOT is_voided\n      AND project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_freight AS (\n    -- النولون المربوط بالمشروع حصراً\n    SELECT\n        project_id,\n        COALESCE(SUM(amount), 0) AS freight_cost\n    FROM public.treasury_transactions\n    WHERE category = 'freight'\n      AND NOT is_voided\n      AND project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_labor AS (\n    -- أجور العمال المربوطة بالمشروع\n    SELECT\n        project_id,\n        COALESCE(SUM(calculated_amount), 0) AS labor_cost\n    FROM public.worker_logs\n    WHERE project_id IS NOT NULL\n    GROUP BY project_id\n),\nproject_subcontracts AS (\n    -- تكلفة مقاولي الباطن تعتمد عند توقيع الاتفاق (Accrual basis)\n    -- للمتفق عليه في الاتفاقيات النشطة أو المكتملة\n    SELECT\n        project_id,\n        COALESCE(SUM(total_agreed_amount), 0) AS subcontract_cost\n    FROM public.subcontract_orders\n    WHERE status IN ('active', 'completed')\n    GROUP BY project_id\n),\ncancelled_subcontract_cost AS (\n    -- الاتفاقية الملغاة: يبقى فقط الجزء المدفوع فعلاً (غير الملغى) حقيقياً\n    -- على المشروع، ويُرجع الجزء غير المدفوع (لم يعد التزاماً ولا تكلفة حقيقية)\n    SELECT\n        so.project_id,\n        COALESCE(SUM(sp.amount), 0) AS paid_cost\n    FROM public.subcontract_orders so\n    LEFT JOIN public.subcontract_payments sp\n        ON sp.subcontract_order_id = so.id\n       AND NOT sp.is_voided\n    WHERE so.status = 'cancelled'\n    GROUP BY so.project_id\n),\nproject_surplus AS (\n    -- عوائد الفائض تطرح، واستهلاك الفائض يضاف\n    SELECT\n        project_id,\n        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_return' THEN amount ELSE 0 END), 0) AS surplus_returns,\n        COALESCE(SUM(CASE WHEN adjustment_type = 'surplus_consumption' THEN amount ELSE 0 END), 0) AS surplus_consumptions\n    FROM public.project_cost_adjustments\n    WHERE project_id IS NOT NULL\n    GROUP BY project_id\n),\ncurrent_settings AS (\n    SELECT overhead_percentage\n    FROM public.settings\n    ORDER BY created_at DESC\n    LIMIT 1\n)\nSELECT\n    p.id AS project_id,\n    p.name AS project_name,\n    p.status AS project_status,\n    COALESCE(pm.material_cost, 0) AS material_cost,\n    COALESCE(pf.freight_cost, 0) AS freight_cost,\n    COALESCE(pl.labor_cost, 0) AS labor_cost,\n    COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) AS subcontract_cost,\n    COALESCE(psurp.surplus_returns, 0) AS surplus_returns,\n    COALESCE(psurp.surplus_consumptions, 0) AS surplus_consumptions,\n    -- Direct Cost Equation:\n    -- materials + freight + labor + subcontracts - surplus_returns + surplus_consumptions\n    (\n        COALESCE(pm.material_cost, 0) +\n        COALESCE(pf.freight_cost, 0) +\n        COALESCE(pl.labor_cost, 0) +\n        COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -\n        COALESCE(psurp.surplus_returns, 0) +\n        COALESCE(psurp.surplus_consumptions, 0)\n    ) AS direct_project_cost,\n    s.overhead_percentage,\n    ROUND(\n        (\n            COALESCE(pm.material_cost, 0) +\n            COALESCE(pf.freight_cost, 0) +\n            COALESCE(pl.labor_cost, 0) +\n            COALESCE(psub.subcontract_cost, 0) + COALESCE(csc.paid_cost, 0) -\n            COALESCE(psurp.surplus_returns, 0) +\n            COALESCE(psurp.surplus_consumptions, 0)\n        ) * (1 + s.overhead_percentage / 100.0),\n        2\n    ) AS estimated_total_cost\nFROM public.projects p\nCROSS JOIN current_settings s\nLEFT JOIN project_materials pm ON p.id = pm.project_id\nLEFT JOIN project_freight pf ON p.id = pf.project_id\nLEFT JOIN project_labor pl ON p.id = pl.project_id\nLEFT JOIN project_subcontracts psub ON p.id = psub.project_id\nLEFT JOIN cancelled_subcontract_cost csc ON p.id = csc.project_id\nLEFT JOIN project_surplus psurp ON p.id = psurp.project_id","-- CREATE OR REPLACE VIEW resets options to defaults; re-assert security_invoker\n-- so base-table RLS still applies to the view (financial audit requirement).\nALTER VIEW public.v_project_direct_costs SET (security_invoker = true)"}	20260905000008_fix_cancelled_subcontract_cost.sql	1e416498fd6d16a6daeaa689c8bcec8f63f6057a4299c6f15b338e87ec3a7bc8	2026-09-10 10:06:58.29101+00
20260905000009	{"-- ============================================================================\n-- 20260905000009_dashboard_views.sql\n-- PHASE 6: Dashboard Views\n-- ============================================================================\n\n-- View: Available Surplus Value\n-- مجموع الفائض المتاح (status = 'available')\nCREATE OR REPLACE VIEW public.v_surplus_available AS\nSELECT\n    COALESCE(SUM(estimated_value), 0) AS total_surplus_value,\n    COALESCE(SUM(quantity), 0) AS total_surplus_quantity,\n    COUNT(*) FILTER (WHERE status = 'available') AS item_count\nFROM public.surplus_bank\nWHERE status = 'available'","-- Enable RLS security_invoker\nALTER VIEW public.v_surplus_available SET (security_invoker = true)"}	20260905000009_dashboard_views.sql	ba1829ea6daac015188b09bc49477845fe0d68cd6b8441c91f2a04aae2f8b4db	2026-09-10 10:06:58.29101+00
20260905000011	\N	20260905000011_workers_rls_owner_only.sql	8a2597818ea0e1abc927638abdf5a611e51cbb222d0b7935c70aa24fd44eaa85	2026-09-10 10:06:58.29101+00
20260905000012	\N	20260905000012_operating_allocation.sql	95632c938eb3de1abe68c1657bd695e3934b583ccf095d367babd6a2c9b3d33e	2026-09-10 10:06:58.29101+00
20260905000013	{"REVOKE EXECUTE ON FUNCTION rpc_run_operating_allocation(date) FROM anon;"}	20260905000013_revoke_anon_operating_allocation.sql	007d6fcfa66acab85d5a3f573fee00bf03d22d0357db85318ba91217b0a9b9b4	2026-09-10 10:06:58.29101+00
20260905000015	{"\n-- ============================================================================\n-- 20260905000015_revoke_execute_public_functions.sql\n-- Hardening: revoke EXECUTE on ALL public-schema functions from PUBLIC and anon.\n--\n-- Context: 11 public functions (RPCs + helpers) were executable by the anon\n-- role and by PUBLIC by default, which violates least-privilege. The fix was\n-- applied manually to the production database; this migration records that same\n-- fix as a replayable, official migration.\n--\n-- Note: this is intentionally expressed as ALL FUNCTIONS (not a one-off\n-- per-function list) so the invariant stays true for any function added later\n-- to the public schema.\n-- ============================================================================\n\nREVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;\nREVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;"}	20260905000015_revoke_execute_public_functions.sql	5bcc06e8b9a71db89671218d6aa9778b59887b937c2897a7ad2ddc094ec0a4fa	2026-09-10 10:06:58.29101+00
20260905000016	{"\n-- ============================================================================\n-- 20260905000016_revoke_select_public_views.sql\n-- Hardening: revoke SELECT on ALL tables AND views in the public schema from\n-- PUBLIC and anon.\n--\n-- Context: every public view (v_treasury_balance, v_project_direct_costs,\n-- v_pending_liabilities, v_surplus_available) and every base table was readable\n-- by the anon role (and PUBLIC had the default grant). Views are treated as\n-- tables by PostgreSQL, so REVOKE SELECT ON ALL TABLES covers them too.\n--\n-- The application reads everything through the authenticated role; removing\n-- the anon/PUBLIC grants does not affect logged-in users (RLS + their explicit\n-- GRANTs stay intact).\n-- ============================================================================\n\nREVOKE SELECT ON ALL TABLES IN SCHEMA public FROM PUBLIC;\nREVOKE SELECT ON ALL TABLES IN SCHEMA public FROM anon;"}	20260905000016_revoke_select_public_views.sql	774c50cd2e6c531af37cdd0342026e620e504128b3a2e67afb29ebdb1eee5a14	2026-09-10 10:06:58.29101+00
20260905000017	{"-- applied manually via psql, see supabase/migrations/20260905000017_worker_liabilities_view.sql"}	20260905000017_worker_liabilities_view.sql	0498503cc03224ef56a577a52d5842d0c6f07297012aea191cc59ddcb97f587d	2026-09-10 10:06:58.29101+00
20260905000014	{"\n-- ============================================================================\n-- 20260905000014_cleanup_functions.sql\n-- Manual / External Scheduled Cleanup Functions\n-- (renumbered from 20260905000011 to resolve timestamp collision with\n--  20260905000011_workers_rls_owner_only.sql — the duplicate version caused\n--  this file to be silently skipped by the migration runner)\n-- ============================================================================\n\n-- 1. دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية\nCREATE OR REPLACE FUNCTION public.cleanup_expired_idempotency_keys()\nRETURNS INTEGER\nLANGUAGE plpgsql\nSECURITY DEFINER\nSET search_path = public\nAS $$\nDECLARE\n    deleted_count INTEGER;\nBEGIN\n    DELETE FROM public.idempotency_keys\n    WHERE expires_at < NOW();\n\n    GET DIAGNOSTICS deleted_count = ROW_COUNT;\n\n    RETURN deleted_count;\nEND;\n$$;\n\nCOMMENT ON FUNCTION public.cleanup_expired_idempotency_keys() IS 'دالة تنظيف مفاتيح عدم التكرار المنتهية الصلاحية، تُستدعى يدوياً أو بجدولة خارجية وتُعيد عدد الصفوف المحذوفة.';\n"}	20260905000014_cleanup_functions.sql	c556709878c63ce37ceabc8acbe08ddfb5af1ca663c39f2cb32fa12dfdf3511c	2026-09-10 10:06:58.29101+00
20260910000018	\N	20260910000018_idempotency_scope.sql	220e00b6b331bd2c0f11ff4726667697f1c290861ca005018045fad3c2d53aad	2026-09-10 10:09:01.7869+00
20260910000019	\N	20260910000019_no_hard_delete_policies.sql	6fd27d4618e7b7ae144946bc74febd966676a36c14950b925718b3548d8de2d4	2026-09-10 10:09:09.137068+00
20260910000020	\N	20260910000020_default_privileges.sql	ee239c07b2ba913b5a70d044e08514ec2887e73b8418ba44eab53dadfe1dca7a	2026-09-10 10:09:16.123977+00
20260910000021	\N	20260910000021_treasury_write_hardening.sql	4b53ebf91ae5aafdd6e533ffcbba655ae9ae7061d7aba321ddbddd198ce74265	2026-09-10 10:15:28.507048+00
20260910000022	\N	20260910000022_amount_upper_bounds.sql	78d39ac5c4497b216f4b78d6f47178df59e22b870f1c2450cb8f5d43bcfa4e09	2026-09-10 10:28:13.763078+00
20260910000023	\N	20260910000023_text_bounds.sql	8e75a3268c899091a3c8689ba837fc781e40c1341b896e6d92f925b9966c1850	2026-09-10 10:53:52.007157+00
20260910000024	\N	20260910000024_mandatory_reasons.sql	61c233676bb14ed7745d457c745ea633c010a6dc9150bb0ebb19fd7dfee50e3b	2026-09-10 11:03:45.708059+00
20260910000025	\N	20260910000025_rate_limits.sql	57201d7e9ed5483608fcf3152cb58c7bb0cbd216fdd9fd4dfa462f3f820b70df	2026-09-10 11:17:11.086689+00
20260910000026	\N	20260910000026_drop_old_remove_exclusion.sql	de197981b1164d4e8abc0352c94b11524c9e7dc05714235888edffc1992b826f	2026-09-10 11:36:36.816231+00
20260910000027	\N	20260910000027_audit_log.sql	05db0057f9836f110b6d97db57108023ab470b1ad33fad8fed5a1a892bf57581	2026-09-10 11:50:51.688499+00
20260910000028	\N	20260910000028_cleanup_gate_settings_attendance.sql	3602f67246c1b6bd4291279bcc5e091fd00e62b4c97c52cf24a251f65c79d5c9	2026-09-10 12:12:52.532424+00
20260910000029	\N	20260910000029_audit_actor_nullable_lookup.sql	0261cca196db7129fe91db6de6bbe8f4bb98222b2adb33b4d213fedc5a111cde	2026-09-10 12:23:06.763972+00
20260910000030	\N	20260910000030_attendance_unique_reverted.sql	7b95a34a34947c4d1cbe8eaf692ef0a73879f02757cba105a73a133282c6edde	2026-09-10 12:28:29.156333+00
20260910000031	\N	20260910000031_drop_old_close_overload.sql	cdd2a8649604b29f485fa57adb3d785dbb8dfc22c369ac4d00486c952f585d83	2026-09-10 12:31:46.105179+00
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: supabase_admin
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 21, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: supabase_admin
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: hooks_id_seq; Type: SEQUENCE SET; Schema: supabase_functions; Owner: supabase_functions_admin
--

SELECT pg_catalog.setval('supabase_functions.hooks_id_seq', 1, false);


--
-- Name: extensions extensions_pkey; Type: CONSTRAINT; Schema: _realtime; Owner: supabase_admin
--

ALTER TABLE ONLY _realtime.extensions
    ADD CONSTRAINT extensions_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: _realtime; Owner: supabase_admin
--

ALTER TABLE ONLY _realtime.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: _realtime; Owner: supabase_admin
--

ALTER TABLE ONLY _realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: _realtime; Owner: supabase_admin
--

ALTER TABLE ONLY _realtime.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: general_expenses general_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_pkey PRIMARY KEY (id);


--
-- Name: idempotency_keys idempotency_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_pkey PRIMARY KEY (key, user_id, action);


--
-- Name: operating_allocation_cycles operating_allocation_cycles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_cycles
    ADD CONSTRAINT operating_allocation_cycles_pkey PRIMARY KEY (id);


--
-- Name: operating_allocation_exclusions operating_allocation_exclusions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_exclusions
    ADD CONSTRAINT operating_allocation_exclusions_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: project_cost_adjustments project_cost_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_cost_adjustments
    ADD CONSTRAINT project_cost_adjustments_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: rate_limits rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rate_limits
    ADD CONSTRAINT rate_limits_pkey PRIMARY KEY (bucket, window_start);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: subcontract_orders subcontract_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcontract_orders
    ADD CONSTRAINT subcontract_orders_pkey PRIMARY KEY (id);


--
-- Name: subcontract_payments subcontract_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcontract_payments
    ADD CONSTRAINT subcontract_payments_pkey PRIMARY KEY (id);


--
-- Name: surplus_bank surplus_bank_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surplus_bank
    ADD CONSTRAINT surplus_bank_pkey PRIMARY KEY (id);


--
-- Name: treasury_transactions treasury_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treasury_transactions
    ADD CONSTRAINT treasury_transactions_pkey PRIMARY KEY (id);


--
-- Name: operating_allocation_exclusions uq_operating_exclusion_month_project; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_exclusions
    ADD CONSTRAINT uq_operating_exclusion_month_project UNIQUE (year_month, project_id);


--
-- Name: worker_advances worker_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_advances
    ADD CONSTRAINT worker_advances_pkey PRIMARY KEY (id);


--
-- Name: worker_logs worker_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_logs
    ADD CONSTRAINT worker_logs_pkey PRIMARY KEY (id);


--
-- Name: workers workers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_09_04 messages_2026_09_04_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2026_09_04
    ADD CONSTRAINT messages_2026_09_04_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_09_05 messages_2026_09_05_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2026_09_05
    ADD CONSTRAINT messages_2026_09_05_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_09_06 messages_2026_09_06_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2026_09_06
    ADD CONSTRAINT messages_2026_09_06_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_09_07 messages_2026_09_07_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2026_09_07
    ADD CONSTRAINT messages_2026_09_07_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_09_08 messages_2026_09_08_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.messages_2026_09_08
    ADD CONSTRAINT messages_2026_09_08_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: iceberg_namespaces iceberg_namespaces_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.iceberg_namespaces
    ADD CONSTRAINT iceberg_namespaces_pkey PRIMARY KEY (id);


--
-- Name: iceberg_tables iceberg_tables_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.iceberg_tables
    ADD CONSTRAINT iceberg_tables_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: hooks hooks_pkey; Type: CONSTRAINT; Schema: supabase_functions; Owner: supabase_functions_admin
--

ALTER TABLE ONLY supabase_functions.hooks
    ADD CONSTRAINT hooks_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: supabase_functions; Owner: supabase_functions_admin
--

ALTER TABLE ONLY supabase_functions.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (version);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: postgres
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: extensions_tenant_external_id_index; Type: INDEX; Schema: _realtime; Owner: supabase_admin
--

CREATE INDEX extensions_tenant_external_id_index ON _realtime.extensions USING btree (tenant_external_id);


--
-- Name: extensions_tenant_external_id_type_index; Type: INDEX; Schema: _realtime; Owner: supabase_admin
--

CREATE UNIQUE INDEX extensions_tenant_external_id_type_index ON _realtime.extensions USING btree (tenant_external_id, type);


--
-- Name: feature_flags_name_index; Type: INDEX; Schema: _realtime; Owner: supabase_admin
--

CREATE UNIQUE INDEX feature_flags_name_index ON _realtime.feature_flags USING btree (name);


--
-- Name: tenants_external_id_index; Type: INDEX; Schema: _realtime; Owner: supabase_admin
--

CREATE UNIQUE INDEX tenants_external_id_index ON _realtime.tenants USING btree (external_id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_actor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_actor ON public.audit_log USING btree (actor_id);


--
-- Name: idx_audit_log_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_entity ON public.audit_log USING btree (entity_table, entity_id);


--
-- Name: idx_audit_log_occurred; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_occurred ON public.audit_log USING btree (occurred_at DESC);


--
-- Name: idx_idempotency_keys_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_keys_expires_at ON public.idempotency_keys USING btree (expires_at);


--
-- Name: idx_project_cost_adjustments_cycle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_cost_adjustments_cycle ON public.project_cost_adjustments USING btree (operating_cycle_id);


--
-- Name: idx_project_cost_adjustments_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_cost_adjustments_project_id ON public.project_cost_adjustments USING btree (project_id);


--
-- Name: idx_project_cost_adjustments_voided; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_cost_adjustments_voided ON public.project_cost_adjustments USING btree (is_voided);


--
-- Name: idx_subcontract_orders_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subcontract_orders_project_id ON public.subcontract_orders USING btree (project_id);


--
-- Name: idx_subcontract_payments_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subcontract_payments_order_id ON public.subcontract_payments USING btree (subcontract_order_id);


--
-- Name: idx_surplus_bank_source_project; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_surplus_bank_source_project ON public.surplus_bank USING btree (source_project_id);


--
-- Name: idx_surplus_bank_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_surplus_bank_status ON public.surplus_bank USING btree (status);


--
-- Name: idx_treasury_transactions_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_treasury_transactions_category ON public.treasury_transactions USING btree (category);


--
-- Name: idx_treasury_transactions_is_voided; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_treasury_transactions_is_voided ON public.treasury_transactions USING btree (is_voided);


--
-- Name: idx_treasury_transactions_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_treasury_transactions_project_id ON public.treasury_transactions USING btree (project_id);


--
-- Name: idx_treasury_transactions_subcategory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_treasury_transactions_subcategory ON public.treasury_transactions USING btree (subcategory);


--
-- Name: idx_treasury_workshop_operating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_treasury_workshop_operating ON public.treasury_transactions USING btree (created_at) WHERE ((category = 'workshop_operating'::text) AND (NOT is_voided) AND (NOT is_direct_owner_payment));


--
-- Name: idx_worker_advances_is_settled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_worker_advances_is_settled ON public.worker_advances USING btree (is_settled);


--
-- Name: idx_worker_advances_worker_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_worker_advances_worker_id ON public.worker_advances USING btree (worker_id);


--
-- Name: idx_worker_logs_is_settled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_worker_logs_is_settled ON public.worker_logs USING btree (is_settled);


--
-- Name: idx_worker_logs_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_worker_logs_project_id ON public.worker_logs USING btree (project_id);


--
-- Name: idx_worker_logs_worker_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_worker_logs_worker_id ON public.worker_logs USING btree (worker_id);


--
-- Name: uq_operating_cycles_month_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_operating_cycles_month_active ON public.operating_allocation_cycles USING btree (year_month) WHERE (NOT is_voided);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_09_04_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2026_09_04_inserted_at_topic_idx ON realtime.messages_2026_09_04 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_09_05_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2026_09_05_inserted_at_topic_idx ON realtime.messages_2026_09_05 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_09_06_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2026_09_06_inserted_at_topic_idx ON realtime.messages_2026_09_06 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_09_07_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2026_09_07_inserted_at_topic_idx ON realtime.messages_2026_09_07 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_09_08_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX messages_2026_09_08_inserted_at_topic_idx ON realtime.messages_2026_09_08 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_selec ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter, COALESCE(selected_columns, '{}'::text[]));


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_iceberg_namespaces_bucket_id; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX idx_iceberg_namespaces_bucket_id ON storage.iceberg_namespaces USING btree (catalog_id, name);


--
-- Name: idx_iceberg_tables_location; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX idx_iceberg_tables_location ON storage.iceberg_tables USING btree (location);


--
-- Name: idx_iceberg_tables_namespace_id; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX idx_iceberg_tables_namespace_id ON storage.iceberg_tables USING btree (catalog_id, namespace_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: supabase_functions_hooks_h_table_id_h_name_idx; Type: INDEX; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE INDEX supabase_functions_hooks_h_table_id_h_name_idx ON supabase_functions.hooks USING btree (hook_table_id, hook_name);


--
-- Name: supabase_functions_hooks_request_id_idx; Type: INDEX; Schema: supabase_functions; Owner: supabase_functions_admin
--

CREATE INDEX supabase_functions_hooks_request_id_idx ON supabase_functions.hooks USING btree (request_id);


--
-- Name: messages_2026_09_04_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_09_04_inserted_at_topic_idx;


--
-- Name: messages_2026_09_04_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_09_04_pkey;


--
-- Name: messages_2026_09_05_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_09_05_inserted_at_topic_idx;


--
-- Name: messages_2026_09_05_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_09_05_pkey;


--
-- Name: messages_2026_09_06_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_09_06_inserted_at_topic_idx;


--
-- Name: messages_2026_09_06_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_09_06_pkey;


--
-- Name: messages_2026_09_07_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_09_07_inserted_at_topic_idx;


--
-- Name: messages_2026_09_07_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_09_07_pkey;


--
-- Name: messages_2026_09_08_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_09_08_inserted_at_topic_idx;


--
-- Name: messages_2026_09_08_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_09_08_pkey;


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: supabase_auth_admin
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


--
-- Name: audit_log set_timestamp_audit_log; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_audit_log BEFORE UPDATE ON public.audit_log FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: general_expenses set_timestamp_general_expenses; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_general_expenses BEFORE UPDATE ON public.general_expenses FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: operating_allocation_cycles set_timestamp_operating_allocation_cycles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_operating_allocation_cycles BEFORE UPDATE ON public.operating_allocation_cycles FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: profiles set_timestamp_profiles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: project_cost_adjustments set_timestamp_project_cost_adjustments; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_project_cost_adjustments BEFORE UPDATE ON public.project_cost_adjustments FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: projects set_timestamp_projects; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_projects BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: settings set_timestamp_settings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_settings BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: subcontract_orders set_timestamp_subcontract_orders; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_subcontract_orders BEFORE UPDATE ON public.subcontract_orders FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: subcontract_payments set_timestamp_subcontract_payments; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_subcontract_payments BEFORE UPDATE ON public.subcontract_payments FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: surplus_bank set_timestamp_surplus_bank; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_surplus_bank BEFORE UPDATE ON public.surplus_bank FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: treasury_transactions set_timestamp_treasury_transactions; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_treasury_transactions BEFORE UPDATE ON public.treasury_transactions FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: worker_advances set_timestamp_worker_advances; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_worker_advances BEFORE UPDATE ON public.worker_advances FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: worker_logs set_timestamp_worker_logs; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_worker_logs BEFORE UPDATE ON public.worker_logs FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: workers set_timestamp_workers; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_workers BEFORE UPDATE ON public.workers FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: operating_allocation_cycles trg_audit_alloc_cycle_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_alloc_cycle_insert AFTER INSERT ON public.operating_allocation_cycles FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_alloc_cycle_insert();


--
-- Name: operating_allocation_cycles trg_audit_alloc_cycle_void; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_alloc_cycle_void AFTER UPDATE ON public.operating_allocation_cycles FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_alloc_cycle_void();


--
-- Name: project_cost_adjustments trg_audit_cost_adj_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_cost_adj_insert AFTER INSERT ON public.project_cost_adjustments FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_cost_adj_insert();


--
-- Name: project_cost_adjustments trg_audit_cost_adj_void; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_cost_adj_void AFTER UPDATE ON public.project_cost_adjustments FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_cost_adj_void();


--
-- Name: audit_log trg_audit_log_immutable; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_log_immutable BEFORE DELETE OR UPDATE ON public.audit_log FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_log_mutation();


--
-- Name: subcontract_orders trg_audit_suborder_close; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_suborder_close AFTER UPDATE ON public.subcontract_orders FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_suborder_close();


--
-- Name: subcontract_payments trg_audit_subpay_void; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_subpay_void AFTER UPDATE ON public.subcontract_payments FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_subpay_void();


--
-- Name: treasury_transactions trg_audit_treasury_void; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_treasury_void AFTER UPDATE ON public.treasury_transactions FOR EACH ROW EXECUTE FUNCTION app_private.trg_log_treasury_void();


--
-- Name: treasury_transactions trg_treasury_no_tamper; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_treasury_no_tamper BEFORE UPDATE ON public.treasury_transactions FOR EACH ROW EXECUTE FUNCTION public.prevent_treasury_update_tampering();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: supabase_admin
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: extensions extensions_tenant_external_id_fkey; Type: FK CONSTRAINT; Schema: _realtime; Owner: supabase_admin
--

ALTER TABLE ONLY _realtime.extensions
    ADD CONSTRAINT extensions_tenant_external_id_fkey FOREIGN KEY (tenant_external_id) REFERENCES _realtime.tenants(external_id) ON DELETE CASCADE;


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: audit_log audit_log_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: general_expenses general_expenses_treasury_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_treasury_transaction_id_fkey FOREIGN KEY (treasury_transaction_id) REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT;


--
-- Name: idempotency_keys idempotency_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: operating_allocation_cycles operating_allocation_cycles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_cycles
    ADD CONSTRAINT operating_allocation_cycles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: operating_allocation_cycles operating_allocation_cycles_voided_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_cycles
    ADD CONSTRAINT operating_allocation_cycles_voided_by_fkey FOREIGN KEY (voided_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: operating_allocation_exclusions operating_allocation_exclusions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_exclusions
    ADD CONSTRAINT operating_allocation_exclusions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: operating_allocation_exclusions operating_allocation_exclusions_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operating_allocation_exclusions
    ADD CONSTRAINT operating_allocation_exclusions_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: project_cost_adjustments project_cost_adjustments_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_cost_adjustments
    ADD CONSTRAINT project_cost_adjustments_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: project_cost_adjustments project_cost_adjustments_surplus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_cost_adjustments
    ADD CONSTRAINT project_cost_adjustments_surplus_id_fkey FOREIGN KEY (surplus_id) REFERENCES public.surplus_bank(id) ON DELETE RESTRICT;


--
-- Name: project_cost_adjustments project_cost_adjustments_voided_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_cost_adjustments
    ADD CONSTRAINT project_cost_adjustments_voided_by_fkey FOREIGN KEY (voided_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: subcontract_orders subcontract_orders_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcontract_orders
    ADD CONSTRAINT subcontract_orders_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: subcontract_payments subcontract_payments_subcontract_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcontract_payments
    ADD CONSTRAINT subcontract_payments_subcontract_order_id_fkey FOREIGN KEY (subcontract_order_id) REFERENCES public.subcontract_orders(id) ON DELETE RESTRICT;


--
-- Name: subcontract_payments subcontract_payments_treasury_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcontract_payments
    ADD CONSTRAINT subcontract_payments_treasury_transaction_id_fkey FOREIGN KEY (treasury_transaction_id) REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT;


--
-- Name: surplus_bank surplus_bank_parent_surplus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surplus_bank
    ADD CONSTRAINT surplus_bank_parent_surplus_id_fkey FOREIGN KEY (parent_surplus_id) REFERENCES public.surplus_bank(id) ON DELETE RESTRICT;


--
-- Name: surplus_bank surplus_bank_source_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surplus_bank
    ADD CONSTRAINT surplus_bank_source_project_id_fkey FOREIGN KEY (source_project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: treasury_transactions treasury_transactions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treasury_transactions
    ADD CONSTRAINT treasury_transactions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: treasury_transactions treasury_transactions_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treasury_transactions
    ADD CONSTRAINT treasury_transactions_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: treasury_transactions treasury_transactions_voided_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treasury_transactions
    ADD CONSTRAINT treasury_transactions_voided_by_fkey FOREIGN KEY (voided_by) REFERENCES public.profiles(id) ON DELETE RESTRICT;


--
-- Name: worker_advances worker_advances_treasury_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_advances
    ADD CONSTRAINT worker_advances_treasury_transaction_id_fkey FOREIGN KEY (treasury_transaction_id) REFERENCES public.treasury_transactions(id) ON DELETE RESTRICT;


--
-- Name: worker_advances worker_advances_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_advances
    ADD CONSTRAINT worker_advances_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- Name: worker_logs worker_logs_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_logs
    ADD CONSTRAINT worker_logs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: worker_logs worker_logs_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.worker_logs
    ADD CONSTRAINT worker_logs_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- Name: iceberg_namespaces iceberg_namespaces_catalog_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.iceberg_namespaces
    ADD CONSTRAINT iceberg_namespaces_catalog_id_fkey FOREIGN KEY (catalog_id) REFERENCES storage.buckets_analytics(id) ON DELETE CASCADE;


--
-- Name: iceberg_tables iceberg_tables_catalog_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.iceberg_tables
    ADD CONSTRAINT iceberg_tables_catalog_id_fkey FOREIGN KEY (catalog_id) REFERENCES storage.buckets_analytics(id) ON DELETE CASCADE;


--
-- Name: iceberg_tables iceberg_tables_namespace_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.iceberg_tables
    ADD CONSTRAINT iceberg_tables_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES storage.iceberg_namespaces(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log audit_select_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_select_owner ON public.audit_log FOR SELECT TO authenticated USING (app_private.is_owner());


--
-- Name: project_cost_adjustments cost_adj_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY cost_adj_insert ON public.project_cost_adjustments FOR INSERT TO authenticated WITH CHECK ((app_private.is_staff() AND ((adjustment_type <> 'operating_allocation'::text) OR app_private.is_owner())));


--
-- Name: project_cost_adjustments cost_adj_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY cost_adj_select ON public.project_cost_adjustments FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: operating_allocation_cycles cycles_select_staff; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY cycles_select_staff ON public.operating_allocation_cycles FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: operating_allocation_exclusions exclusions_delete_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY exclusions_delete_owner ON public.operating_allocation_exclusions FOR DELETE TO authenticated USING (app_private.is_owner());


--
-- Name: operating_allocation_exclusions exclusions_insert_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY exclusions_insert_owner ON public.operating_allocation_exclusions FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: operating_allocation_exclusions exclusions_select_staff; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY exclusions_select_staff ON public.operating_allocation_exclusions FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: general_expenses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.general_expenses ENABLE ROW LEVEL SECURITY;

--
-- Name: general_expenses general_expenses_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY general_expenses_insert ON public.general_expenses FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());


--
-- Name: general_expenses general_expenses_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY general_expenses_select ON public.general_expenses FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: general_expenses general_expenses_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY general_expenses_update ON public.general_expenses FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: idempotency_keys; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.idempotency_keys ENABLE ROW LEVEL SECURITY;

--
-- Name: idempotency_keys idempotency_keys_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY idempotency_keys_insert ON public.idempotency_keys FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: idempotency_keys idempotency_keys_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY idempotency_keys_select ON public.idempotency_keys FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: idempotency_keys idempotency_keys_update_own_pending; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY idempotency_keys_update_own_pending ON public.idempotency_keys FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: operating_allocation_cycles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.operating_allocation_cycles ENABLE ROW LEVEL SECURITY;

--
-- Name: operating_allocation_exclusions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.operating_allocation_exclusions ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: profiles profiles_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_update ON public.profiles FOR UPDATE TO authenticated USING ((app_private.is_owner() OR (id = auth.uid()))) WITH CHECK ((app_private.is_owner() OR ((id = auth.uid()) AND (role = ( SELECT p.role
   FROM public.profiles p
  WHERE (p.id = auth.uid()))))));


--
-- Name: project_cost_adjustments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.project_cost_adjustments ENABLE ROW LEVEL SECURITY;

--
-- Name: projects; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

--
-- Name: projects projects_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY projects_insert ON public.projects FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());


--
-- Name: projects projects_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY projects_select ON public.projects FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: projects projects_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY projects_update ON public.projects FOR UPDATE TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());


--
-- Name: rate_limits; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

--
-- Name: settings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

--
-- Name: settings settings_insert_owner_only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY settings_insert_owner_only ON public.settings FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: settings settings_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY settings_select ON public.settings FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: settings settings_update_owner_only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY settings_update_owner_only ON public.settings FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: subcontract_orders; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.subcontract_orders ENABLE ROW LEVEL SECURITY;

--
-- Name: subcontract_orders subcontract_orders_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_orders_insert ON public.subcontract_orders FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: subcontract_orders subcontract_orders_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_orders_select ON public.subcontract_orders FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: subcontract_orders subcontract_orders_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_orders_update ON public.subcontract_orders FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: subcontract_payments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.subcontract_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: subcontract_payments subcontract_payments_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_payments_insert ON public.subcontract_payments FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: subcontract_payments subcontract_payments_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_payments_select ON public.subcontract_payments FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: subcontract_payments subcontract_payments_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subcontract_payments_update ON public.subcontract_payments FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: surplus_bank; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.surplus_bank ENABLE ROW LEVEL SECURITY;

--
-- Name: surplus_bank surplus_bank_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY surplus_bank_insert ON public.surplus_bank FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());


--
-- Name: surplus_bank surplus_bank_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY surplus_bank_select ON public.surplus_bank FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: surplus_bank surplus_bank_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY surplus_bank_update ON public.surplus_bank FOR UPDATE TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());


--
-- Name: treasury_transactions treasury_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY treasury_insert ON public.treasury_transactions FOR INSERT TO authenticated WITH CHECK ((app_private.is_staff() AND ((category <> ALL (ARRAY['owner_funding'::text, 'advance'::text, 'settlement'::text, 'subcontract_payment'::text, 'carried_forward_advance'::text])) OR app_private.is_owner())));


--
-- Name: treasury_transactions treasury_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY treasury_select ON public.treasury_transactions FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: treasury_transactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: treasury_transactions treasury_update_void_owner_only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY treasury_update_void_owner_only ON public.treasury_transactions FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: worker_advances; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.worker_advances ENABLE ROW LEVEL SECURITY;

--
-- Name: worker_advances worker_advances_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_advances_insert ON public.worker_advances FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: worker_advances worker_advances_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_advances_select ON public.worker_advances FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: worker_advances worker_advances_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_advances_update ON public.worker_advances FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: worker_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.worker_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: worker_logs worker_logs_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_logs_insert ON public.worker_logs FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());


--
-- Name: worker_logs worker_logs_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_logs_select ON public.worker_logs FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: worker_logs worker_logs_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_logs_update ON public.worker_logs FOR UPDATE TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());


--
-- Name: workers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;

--
-- Name: workers workers_insert_owner_only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY workers_insert_owner_only ON public.workers FOR INSERT TO authenticated WITH CHECK (app_private.is_owner());


--
-- Name: workers workers_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY workers_select ON public.workers FOR SELECT TO authenticated USING (app_private.is_staff());


--
-- Name: workers workers_update_owner_only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY workers_update_owner_only ON public.workers FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());


--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: iceberg_namespaces; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.iceberg_namespaces ENABLE ROW LEVEL SECURITY;

--
-- Name: iceberg_tables; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.iceberg_tables ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime OWNER TO postgres;

--
-- Name: SCHEMA app_private; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA app_private TO authenticated;


--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO dashboard_user;
GRANT USAGE ON SCHEMA auth TO postgres;


--
-- Name: SCHEMA extensions; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA extensions TO anon;
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO service_role;
GRANT ALL ON SCHEMA extensions TO dashboard_user;


--
-- Name: SCHEMA net; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA net TO supabase_functions_admin;
GRANT USAGE ON SCHEMA net TO postgres;
GRANT USAGE ON SCHEMA net TO anon;
GRANT USAGE ON SCHEMA net TO authenticated;
GRANT USAGE ON SCHEMA net TO service_role;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA realtime TO postgres;
GRANT USAGE ON SCHEMA realtime TO anon;
GRANT USAGE ON SCHEMA realtime TO authenticated;
GRANT USAGE ON SCHEMA realtime TO service_role;
GRANT ALL ON SCHEMA realtime TO supabase_realtime_admin;


--
-- Name: SCHEMA storage; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA storage TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin WITH GRANT OPTION;
GRANT ALL ON SCHEMA storage TO dashboard_user;


--
-- Name: SCHEMA supabase_functions; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA supabase_functions TO postgres;
GRANT USAGE ON SCHEMA supabase_functions TO anon;
GRANT USAGE ON SCHEMA supabase_functions TO authenticated;
GRANT USAGE ON SCHEMA supabase_functions TO service_role;
GRANT ALL ON SCHEMA supabase_functions TO supabase_functions_admin;


--
-- Name: SCHEMA vault; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA vault TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA vault TO service_role;


--
-- Name: FUNCTION append_audit_log(p_action text, p_entity_table text, p_entity_id uuid, p_reason text, p_details jsonb); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.append_audit_log(p_action text, p_entity_table text, p_entity_id uuid, p_reason text, p_details jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION app_private.append_audit_log(p_action text, p_entity_table text, p_entity_id uuid, p_reason text, p_details jsonb) TO authenticated;


--
-- Name: FUNCTION current_user_role(); Type: ACL; Schema: app_private; Owner: postgres
--

GRANT ALL ON FUNCTION app_private.current_user_role() TO authenticated;


--
-- Name: FUNCTION is_owner(); Type: ACL; Schema: app_private; Owner: postgres
--

GRANT ALL ON FUNCTION app_private.is_owner() TO authenticated;


--
-- Name: FUNCTION is_staff(); Type: ACL; Schema: app_private; Owner: postgres
--

GRANT ALL ON FUNCTION app_private.is_staff() TO authenticated;


--
-- Name: FUNCTION run_operating_allocation(p_year_month date); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.run_operating_allocation(p_year_month date) FROM PUBLIC;


--
-- Name: FUNCTION trg_log_alloc_cycle_insert(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_alloc_cycle_insert() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_alloc_cycle_void(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_alloc_cycle_void() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_cost_adj_insert(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_cost_adj_insert() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_cost_adj_void(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_cost_adj_void() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_suborder_close(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_suborder_close() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_subpay_void(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_subpay_void() FROM PUBLIC;


--
-- Name: FUNCTION trg_log_treasury_void(); Type: ACL; Schema: app_private; Owner: postgres
--

REVOKE ALL ON FUNCTION app_private.trg_log_treasury_void() FROM PUBLIC;


--
-- Name: FUNCTION email(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.email() TO dashboard_user;


--
-- Name: FUNCTION jwt(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.jwt() TO postgres;
GRANT ALL ON FUNCTION auth.jwt() TO dashboard_user;


--
-- Name: FUNCTION role(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.role() TO dashboard_user;


--
-- Name: FUNCTION uid(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.uid() TO dashboard_user;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.armor(bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.armor(bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.crypt(text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.crypt(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.dearmor(text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.dearmor(text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.digest(text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.digest(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_salt(text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.gen_salt(text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_cron_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.grant_pg_graphql_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_net_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_net_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg(OUT indexname text, OUT indexrelid oid, OUT indrelid oid, OUT innatts integer, OUT indisunique boolean, OUT indkey int2vector, OUT indcollation oidvector, OUT indclass oidvector, OUT indoption oidvector, OUT indexprs pg_node_tree, OUT indpred pg_node_tree, OUT amid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg(OUT indexname text, OUT indexrelid oid, OUT indrelid oid, OUT innatts integer, OUT indisunique boolean, OUT indkey int2vector, OUT indcollation oidvector, OUT indclass oidvector, OUT indoption oidvector, OUT indexprs pg_node_tree, OUT indpred pg_node_tree, OUT amid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_create_index(sql_order text, OUT indexrelid oid, OUT indexname text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_create_index(sql_order text, OUT indexrelid oid, OUT indexname text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_drop_index(indexid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_drop_index(indexid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_get_indexdef(indexid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_get_indexdef(indexid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_hidden_indexes(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_hidden_indexes() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_hide_index(indexid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_hide_index(indexid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_relation_size(indexid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_relation_size(indexid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_reset(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_reset() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_reset_index(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_reset_index() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_unhide_all_indexes(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_unhide_all_indexes() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hypopg_unhide_index(indexid oid); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hypopg_unhide_index(indexid oid) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION index_advisor(query text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.index_advisor(query text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgrst_ddl_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_ddl_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgrst_drop_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_drop_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.set_graphql_placeholder() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_nil() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_nil() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION graphql("operationName" text, query text, variables jsonb, extensions jsonb); Type: ACL; Schema: graphql_public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO postgres;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO anon;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO authenticated;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO service_role;


--
-- Name: FUNCTION pg_reload_conf(); Type: ACL; Schema: pg_catalog; Owner: supabase_admin
--

GRANT ALL ON FUNCTION pg_catalog.pg_reload_conf() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION get_auth(p_usename text); Type: ACL; Schema: pgbouncer; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION pgbouncer.get_auth(p_usename text) FROM PUBLIC;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO pgbouncer;


--
-- Name: FUNCTION cleanup_expired_idempotency_keys(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.cleanup_expired_idempotency_keys() FROM PUBLIC;
GRANT ALL ON FUNCTION public.cleanup_expired_idempotency_keys() TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer) TO authenticated;
GRANT ALL ON FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer) TO service_role;
GRANT ALL ON FUNCTION public.increment_rate_limit(p_bucket text, p_limit integer, p_window_seconds integer) TO anon;


--
-- Name: FUNCTION prevent_audit_log_mutation(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.prevent_audit_log_mutation() FROM PUBLIC;
GRANT ALL ON FUNCTION public.prevent_audit_log_mutation() TO authenticated;
GRANT ALL ON FUNCTION public.prevent_audit_log_mutation() TO service_role;


--
-- Name: FUNCTION prevent_treasury_update_tampering(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.prevent_treasury_update_tampering() FROM PUBLIC;
GRANT ALL ON FUNCTION public.prevent_treasury_update_tampering() TO authenticated;
GRANT ALL ON FUNCTION public.prevent_treasury_update_tampering() TO service_role;


--
-- Name: FUNCTION rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_add_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION rpc_close_subcontract_order(p_order_id uuid, p_status text, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_close_subcontract_order(p_order_id uuid, p_status text, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_close_subcontract_order(p_order_id uuid, p_status text, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_close_subcontract_order(p_order_id uuid, p_status text, p_reason text) TO service_role;


--
-- Name: FUNCTION rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_consume_surplus(p_surplus_id uuid, p_target_project_id uuid, p_consume_qty numeric, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_create_subcontract_order(p_project_id uuid, p_contractor_name text, p_description text, p_total_agreed_amount numeric) TO service_role;


--
-- Name: FUNCTION rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_pay_subcontract(p_order_id uuid, p_amount numeric, p_payment_date date, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_record_advance(p_worker_id uuid, p_amount numeric, p_advance_date date, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_record_attendance(p_worker_id uuid, p_project_id uuid, p_work_date date, p_fraction numeric) TO service_role;


--
-- Name: FUNCTION rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_remove_operating_exclusion(p_year_month date, p_project_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_return_surplus(p_project_id uuid, p_material_name text, p_unit text, p_quantity numeric, p_estimated_value numeric, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_run_operating_allocation(p_year_month date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_run_operating_allocation(p_year_month date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_run_operating_allocation(p_year_month date) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_run_operating_allocation(p_year_month date) TO service_role;


--
-- Name: FUNCTION rpc_scrap_surplus(p_surplus_id uuid, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_scrap_surplus(p_surplus_id uuid, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_scrap_surplus(p_surplus_id uuid, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_scrap_surplus(p_surplus_id uuid, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_settle_worker(p_worker_id uuid, p_notes text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_settle_worker(p_worker_id uuid, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_settle_worker(p_worker_id uuid, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_settle_worker(p_worker_id uuid, p_notes text) TO service_role;


--
-- Name: FUNCTION rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_void_allocation_cycle(p_cycle_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION rpc_void_allocation_line(p_adjustment_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_void_allocation_line(p_adjustment_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_void_allocation_line(p_adjustment_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_void_allocation_line(p_adjustment_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION rpc_void_subcontract_payment(p_payment_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.rpc_void_subcontract_payment(p_payment_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rpc_void_subcontract_payment(p_payment_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.rpc_void_subcontract_payment(p_payment_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION trigger_set_timestamp(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trigger_set_timestamp() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO service_role;


--
-- Name: FUNCTION apply_rls(wal jsonb, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;


--
-- Name: FUNCTION build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION "cast"(val text, type_ regtype); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_realtime_admin;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_realtime_admin;


--
-- Name: FUNCTION is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;


--
-- Name: FUNCTION quote_wal2json(entity regclass); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_realtime_admin;


--
-- Name: FUNCTION send(payload bytea, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.send(payload bytea, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload bytea, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION send(payload jsonb, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION subscription_check_filters(); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO service_role;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO supabase_realtime_admin;


--
-- Name: FUNCTION to_regrole(role_name text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO service_role;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO supabase_realtime_admin;


--
-- Name: FUNCTION topic(); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.topic() TO postgres;
GRANT ALL ON FUNCTION realtime.topic() TO dashboard_user;


--
-- Name: FUNCTION wal2json_escape_identifier(name text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.wal2json_escape_identifier(name text) TO postgres;
GRANT ALL ON FUNCTION realtime.wal2json_escape_identifier(name text) TO dashboard_user;


--
-- Name: FUNCTION http_request(); Type: ACL; Schema: supabase_functions; Owner: supabase_functions_admin
--

REVOKE ALL ON FUNCTION supabase_functions.http_request() FROM PUBLIC;
GRANT ALL ON FUNCTION supabase_functions.http_request() TO anon;
GRANT ALL ON FUNCTION supabase_functions.http_request() TO authenticated;
GRANT ALL ON FUNCTION supabase_functions.http_request() TO service_role;
GRANT ALL ON FUNCTION supabase_functions.http_request() TO postgres;


--
-- Name: FUNCTION _crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO service_role;


--
-- Name: FUNCTION create_secret(new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: FUNCTION update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: TABLE audit_log_entries; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.audit_log_entries TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.audit_log_entries TO postgres;
GRANT SELECT ON TABLE auth.audit_log_entries TO postgres WITH GRANT OPTION;


--
-- Name: TABLE custom_oauth_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.custom_oauth_providers TO postgres;
GRANT ALL ON TABLE auth.custom_oauth_providers TO dashboard_user;


--
-- Name: TABLE flow_state; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.flow_state TO postgres;
GRANT SELECT ON TABLE auth.flow_state TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.flow_state TO dashboard_user;


--
-- Name: TABLE identities; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.identities TO postgres;
GRANT SELECT ON TABLE auth.identities TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.identities TO dashboard_user;


--
-- Name: TABLE instances; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.instances TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.instances TO postgres;
GRANT SELECT ON TABLE auth.instances TO postgres WITH GRANT OPTION;


--
-- Name: TABLE mfa_amr_claims; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_amr_claims TO postgres;
GRANT SELECT ON TABLE auth.mfa_amr_claims TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_amr_claims TO dashboard_user;


--
-- Name: TABLE mfa_challenges; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_challenges TO postgres;
GRANT SELECT ON TABLE auth.mfa_challenges TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_challenges TO dashboard_user;


--
-- Name: TABLE mfa_factors; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.mfa_factors TO postgres;
GRANT SELECT ON TABLE auth.mfa_factors TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_factors TO dashboard_user;


--
-- Name: TABLE oauth_authorizations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_authorizations TO postgres;
GRANT ALL ON TABLE auth.oauth_authorizations TO dashboard_user;


--
-- Name: TABLE oauth_client_states; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_client_states TO postgres;
GRANT ALL ON TABLE auth.oauth_client_states TO dashboard_user;


--
-- Name: TABLE oauth_clients; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_clients TO postgres;
GRANT ALL ON TABLE auth.oauth_clients TO dashboard_user;


--
-- Name: TABLE oauth_consents; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.oauth_consents TO postgres;
GRANT ALL ON TABLE auth.oauth_consents TO dashboard_user;


--
-- Name: TABLE one_time_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.one_time_tokens TO postgres;
GRANT SELECT ON TABLE auth.one_time_tokens TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.one_time_tokens TO dashboard_user;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.refresh_tokens TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.refresh_tokens TO postgres;
GRANT SELECT ON TABLE auth.refresh_tokens TO postgres WITH GRANT OPTION;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO dashboard_user;
GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO postgres;


--
-- Name: TABLE saml_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.saml_providers TO postgres;
GRANT SELECT ON TABLE auth.saml_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_providers TO dashboard_user;


--
-- Name: TABLE saml_relay_states; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.saml_relay_states TO postgres;
GRANT SELECT ON TABLE auth.saml_relay_states TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_relay_states TO dashboard_user;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT ON TABLE auth.schema_migrations TO postgres WITH GRANT OPTION;


--
-- Name: TABLE sessions; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sessions TO postgres;
GRANT SELECT ON TABLE auth.sessions TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sessions TO dashboard_user;


--
-- Name: TABLE sso_domains; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sso_domains TO postgres;
GRANT SELECT ON TABLE auth.sso_domains TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_domains TO dashboard_user;


--
-- Name: TABLE sso_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.sso_providers TO postgres;
GRANT SELECT ON TABLE auth.sso_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_providers TO dashboard_user;


--
-- Name: TABLE users; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.users TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE auth.users TO postgres;
GRANT SELECT ON TABLE auth.users TO postgres WITH GRANT OPTION;


--
-- Name: TABLE webauthn_challenges; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.webauthn_challenges TO postgres;
GRANT ALL ON TABLE auth.webauthn_challenges TO dashboard_user;


--
-- Name: TABLE webauthn_credentials; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.webauthn_credentials TO postgres;
GRANT ALL ON TABLE auth.webauthn_credentials TO dashboard_user;


--
-- Name: TABLE hypopg_list_indexes; Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON TABLE extensions.hypopg_list_indexes TO postgres WITH GRANT OPTION;


--
-- Name: TABLE hypopg_hidden_indexes; Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON TABLE extensions.hypopg_hidden_indexes TO postgres WITH GRANT OPTION;


--
-- Name: TABLE pg_stat_statements; Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON TABLE extensions.pg_stat_statements TO postgres WITH GRANT OPTION;


--
-- Name: TABLE pg_stat_statements_info; Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON TABLE extensions.pg_stat_statements_info TO postgres WITH GRANT OPTION;


--
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.audit_log TO authenticated;
GRANT ALL ON TABLE public.audit_log TO service_role;


--
-- Name: TABLE general_expenses; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.general_expenses TO anon;
GRANT ALL ON TABLE public.general_expenses TO authenticated;
GRANT ALL ON TABLE public.general_expenses TO service_role;


--
-- Name: TABLE idempotency_keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.idempotency_keys TO anon;
GRANT ALL ON TABLE public.idempotency_keys TO authenticated;
GRANT ALL ON TABLE public.idempotency_keys TO service_role;


--
-- Name: TABLE operating_allocation_cycles; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.operating_allocation_cycles TO anon;
GRANT ALL ON TABLE public.operating_allocation_cycles TO authenticated;
GRANT ALL ON TABLE public.operating_allocation_cycles TO service_role;


--
-- Name: TABLE operating_allocation_exclusions; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.operating_allocation_exclusions TO anon;
GRANT ALL ON TABLE public.operating_allocation_exclusions TO authenticated;
GRANT ALL ON TABLE public.operating_allocation_exclusions TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE project_cost_adjustments; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.project_cost_adjustments TO anon;
GRANT ALL ON TABLE public.project_cost_adjustments TO authenticated;
GRANT ALL ON TABLE public.project_cost_adjustments TO service_role;


--
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.projects TO anon;
GRANT ALL ON TABLE public.projects TO authenticated;
GRANT ALL ON TABLE public.projects TO service_role;


--
-- Name: TABLE rate_limits; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.rate_limits TO authenticated;
GRANT ALL ON TABLE public.rate_limits TO service_role;


--
-- Name: TABLE settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.settings TO anon;
GRANT ALL ON TABLE public.settings TO authenticated;
GRANT ALL ON TABLE public.settings TO service_role;


--
-- Name: TABLE subcontract_orders; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.subcontract_orders TO anon;
GRANT ALL ON TABLE public.subcontract_orders TO authenticated;
GRANT ALL ON TABLE public.subcontract_orders TO service_role;


--
-- Name: TABLE subcontract_payments; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.subcontract_payments TO anon;
GRANT ALL ON TABLE public.subcontract_payments TO authenticated;
GRANT ALL ON TABLE public.subcontract_payments TO service_role;


--
-- Name: TABLE surplus_bank; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.surplus_bank TO anon;
GRANT ALL ON TABLE public.surplus_bank TO authenticated;
GRANT ALL ON TABLE public.surplus_bank TO service_role;


--
-- Name: TABLE treasury_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.treasury_transactions TO anon;
GRANT ALL ON TABLE public.treasury_transactions TO authenticated;
GRANT ALL ON TABLE public.treasury_transactions TO service_role;


--
-- Name: TABLE worker_advances; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.worker_advances TO anon;
GRANT ALL ON TABLE public.worker_advances TO authenticated;
GRANT ALL ON TABLE public.worker_advances TO service_role;


--
-- Name: TABLE worker_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.worker_logs TO anon;
GRANT ALL ON TABLE public.worker_logs TO authenticated;
GRANT ALL ON TABLE public.worker_logs TO service_role;


--
-- Name: TABLE workers; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.workers TO anon;
GRANT ALL ON TABLE public.workers TO authenticated;
GRANT ALL ON TABLE public.workers TO service_role;


--
-- Name: TABLE v_worker_liabilities; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.v_worker_liabilities TO anon;
GRANT ALL ON TABLE public.v_worker_liabilities TO authenticated;
GRANT ALL ON TABLE public.v_worker_liabilities TO service_role;


--
-- Name: TABLE v_pending_liabilities; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.v_pending_liabilities TO anon;
GRANT ALL ON TABLE public.v_pending_liabilities TO authenticated;
GRANT ALL ON TABLE public.v_pending_liabilities TO service_role;


--
-- Name: TABLE v_project_direct_costs; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.v_project_direct_costs TO anon;
GRANT ALL ON TABLE public.v_project_direct_costs TO authenticated;
GRANT ALL ON TABLE public.v_project_direct_costs TO service_role;


--
-- Name: TABLE v_surplus_available; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.v_surplus_available TO anon;
GRANT ALL ON TABLE public.v_surplus_available TO authenticated;
GRANT ALL ON TABLE public.v_surplus_available TO service_role;


--
-- Name: TABLE v_treasury_balance; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.v_treasury_balance TO anon;
GRANT ALL ON TABLE public.v_treasury_balance TO authenticated;
GRANT ALL ON TABLE public.v_treasury_balance TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON TABLE realtime.messages TO postgres;
GRANT ALL ON TABLE realtime.messages TO dashboard_user;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO anon;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO authenticated;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO service_role;


--
-- Name: TABLE messages_2026_09_04; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2026_09_04 TO postgres;
GRANT ALL ON TABLE realtime.messages_2026_09_04 TO dashboard_user;


--
-- Name: TABLE messages_2026_09_05; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2026_09_05 TO postgres;
GRANT ALL ON TABLE realtime.messages_2026_09_05 TO dashboard_user;


--
-- Name: TABLE messages_2026_09_06; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2026_09_06 TO postgres;
GRANT ALL ON TABLE realtime.messages_2026_09_06 TO dashboard_user;


--
-- Name: TABLE messages_2026_09_07; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2026_09_07 TO postgres;
GRANT ALL ON TABLE realtime.messages_2026_09_07 TO dashboard_user;


--
-- Name: TABLE messages_2026_09_08; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.messages_2026_09_08 TO postgres;
GRANT ALL ON TABLE realtime.messages_2026_09_08 TO dashboard_user;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.schema_migrations TO postgres;
GRANT ALL ON TABLE realtime.schema_migrations TO dashboard_user;
GRANT SELECT ON TABLE realtime.schema_migrations TO anon;
GRANT SELECT ON TABLE realtime.schema_migrations TO authenticated;
GRANT SELECT ON TABLE realtime.schema_migrations TO service_role;
GRANT ALL ON TABLE realtime.schema_migrations TO supabase_realtime_admin;


--
-- Name: TABLE subscription; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON TABLE realtime.subscription TO postgres;
GRANT ALL ON TABLE realtime.subscription TO dashboard_user;
GRANT SELECT ON TABLE realtime.subscription TO anon;
GRANT SELECT ON TABLE realtime.subscription TO authenticated;
GRANT SELECT ON TABLE realtime.subscription TO service_role;
GRANT ALL ON TABLE realtime.subscription TO supabase_realtime_admin;


--
-- Name: SEQUENCE subscription_id_seq; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO postgres;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO dashboard_user;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO anon;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO service_role;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO supabase_realtime_admin;


--
-- Name: TABLE buckets; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE storage.buckets TO service_role;
GRANT ALL ON TABLE storage.buckets TO authenticated;
GRANT ALL ON TABLE storage.buckets TO anon;


--
-- Name: TABLE buckets_analytics; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets_analytics TO service_role;
GRANT ALL ON TABLE storage.buckets_analytics TO authenticated;
GRANT ALL ON TABLE storage.buckets_analytics TO anon;


--
-- Name: TABLE buckets_vectors; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT ON TABLE storage.buckets_vectors TO service_role;
GRANT SELECT ON TABLE storage.buckets_vectors TO authenticated;
GRANT SELECT ON TABLE storage.buckets_vectors TO anon;


--
-- Name: TABLE iceberg_namespaces; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.iceberg_namespaces TO service_role;
GRANT SELECT ON TABLE storage.iceberg_namespaces TO authenticated;
GRANT SELECT ON TABLE storage.iceberg_namespaces TO anon;


--
-- Name: TABLE iceberg_tables; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.iceberg_tables TO service_role;
GRANT SELECT ON TABLE storage.iceberg_tables TO authenticated;
GRANT SELECT ON TABLE storage.iceberg_tables TO anon;


--
-- Name: TABLE objects; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.objects TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE storage.objects TO service_role;
GRANT ALL ON TABLE storage.objects TO authenticated;
GRANT ALL ON TABLE storage.objects TO anon;


--
-- Name: TABLE s3_multipart_uploads; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.s3_multipart_uploads TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO anon;


--
-- Name: TABLE s3_multipart_uploads_parts; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.s3_multipart_uploads_parts TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO anon;


--
-- Name: TABLE vector_indexes; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT ON TABLE storage.vector_indexes TO service_role;
GRANT SELECT ON TABLE storage.vector_indexes TO authenticated;
GRANT SELECT ON TABLE storage.vector_indexes TO anon;


--
-- Name: TABLE hooks; Type: ACL; Schema: supabase_functions; Owner: supabase_functions_admin
--

GRANT ALL ON TABLE supabase_functions.hooks TO anon;
GRANT ALL ON TABLE supabase_functions.hooks TO authenticated;
GRANT ALL ON TABLE supabase_functions.hooks TO service_role;


--
-- Name: SEQUENCE hooks_id_seq; Type: ACL; Schema: supabase_functions; Owner: supabase_functions_admin
--

GRANT ALL ON SEQUENCE supabase_functions.hooks_id_seq TO anon;
GRANT ALL ON SEQUENCE supabase_functions.hooks_id_seq TO authenticated;
GRANT ALL ON SEQUENCE supabase_functions.hooks_id_seq TO service_role;


--
-- Name: TABLE migrations; Type: ACL; Schema: supabase_functions; Owner: supabase_functions_admin
--

GRANT ALL ON TABLE supabase_functions.migrations TO anon;
GRANT ALL ON TABLE supabase_functions.migrations TO authenticated;
GRANT ALL ON TABLE supabase_functions.migrations TO service_role;


--
-- Name: TABLE secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.secrets TO service_role;


--
-- Name: TABLE decrypted_secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.decrypted_secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.decrypted_secrets TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON SEQUENCES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON FUNCTIONS TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON TABLES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: supabase_functions; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: supabase_functions; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: supabase_functions; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA supabase_functions GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE ALL ON FUNCTIONS FROM PUBLIC;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


ALTER EVENT TRIGGER issue_graphql_placeholder OWNER TO supabase_admin;

--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


ALTER EVENT TRIGGER issue_pg_cron_access OWNER TO supabase_admin;

--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


ALTER EVENT TRIGGER issue_pg_graphql_access OWNER TO supabase_admin;

--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


ALTER EVENT TRIGGER issue_pg_net_access OWNER TO supabase_admin;

--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


ALTER EVENT TRIGGER pgrst_ddl_watch OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


ALTER EVENT TRIGGER pgrst_drop_watch OWNER TO supabase_admin;

--
-- PostgreSQL database dump complete
--

\unrestrict nGCUiw1DmBshtb4gHNPApJfIIjo9O75qd7nuE17P5JOXuWcsMSDLifXMz7YKQxS

