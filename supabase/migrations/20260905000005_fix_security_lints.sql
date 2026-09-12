-- ============================================================================
-- Resolve All Lint 0029 Warnings
-- 1. Switch RPCs to SECURITY INVOKER
-- 2. Move RLS helpers to private schema (app_private)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- الخطوة 1: إنشاء المخطط الداخلي الخاص app_private
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS app_private;

-- منح المستخدمين المسجلين صلاحية استخدام المخطط الداخلي لقراءة السياسات
GRANT USAGE ON SCHEMA app_private TO authenticated;

-- نقل دوال فحص الصلاحيات إلى المخطط الداخلي
CREATE OR REPLACE FUNCTION app_private.current_user_role()
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION app_private.is_owner()
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT (app_private.current_user_role() = 'owner');
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION app_private.is_staff()
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT (app_private.current_user_role() IN ('owner', 'manager'));
$$ LANGUAGE sql STABLE;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_private TO authenticated;

-- ----------------------------------------------------------------------------
-- الخطوة 2: تحديث سياسات الـ RLS لاستخدام الدوال الخاصة من app_private
-- ----------------------------------------------------------------------------
-- settings
DROP POLICY IF EXISTS "settings_select" ON public.settings;
DROP POLICY IF EXISTS "settings_modify_owner_only" ON public.settings;
CREATE POLICY "settings_select" ON public.settings FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "settings_modify_owner_only" ON public.settings FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());

-- profiles
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE TO authenticated USING (app_private.is_owner() OR id = auth.uid()) WITH CHECK (app_private.is_owner() OR (id = auth.uid() AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())));

-- projects
DROP POLICY IF EXISTS "projects_select" ON public.projects;
DROP POLICY IF EXISTS "projects_insert" ON public.projects;
DROP POLICY IF EXISTS "projects_update" ON public.projects;
CREATE POLICY "projects_select" ON public.projects FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "projects_insert" ON public.projects FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());
CREATE POLICY "projects_update" ON public.projects FOR UPDATE TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());

-- treasury_transactions
DROP POLICY IF EXISTS "treasury_select" ON public.treasury_transactions;
DROP POLICY IF EXISTS "treasury_insert" ON public.treasury_transactions;
DROP POLICY IF EXISTS "treasury_update_void_owner_only" ON public.treasury_transactions;
CREATE POLICY "treasury_select" ON public.treasury_transactions FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "treasury_insert" ON public.treasury_transactions FOR INSERT TO authenticated WITH CHECK (app_private.is_staff() AND ((category NOT IN ('owner_funding', 'advance', 'settlement')) OR app_private.is_owner()));
CREATE POLICY "treasury_update_void_owner_only" ON public.treasury_transactions FOR UPDATE TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());

-- surplus_bank & adjustments
DROP POLICY IF EXISTS "surplus_bank_select" ON public.surplus_bank;
DROP POLICY IF EXISTS "surplus_bank_insert_update" ON public.surplus_bank;
DROP POLICY IF EXISTS "cost_adj_select" ON public.project_cost_adjustments;
DROP POLICY IF EXISTS "cost_adj_insert" ON public.project_cost_adjustments;
CREATE POLICY "surplus_bank_select" ON public.surplus_bank FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "surplus_bank_insert_update" ON public.surplus_bank FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());
CREATE POLICY "cost_adj_select" ON public.project_cost_adjustments FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "cost_adj_insert" ON public.project_cost_adjustments FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());

-- workers & logs
DROP POLICY IF EXISTS "workers_select" ON public.workers;
DROP POLICY IF EXISTS "workers_insert_update" ON public.workers;
DROP POLICY IF EXISTS "worker_logs_select" ON public.worker_logs;
DROP POLICY IF EXISTS "worker_logs_insert_update" ON public.worker_logs;
CREATE POLICY "workers_select" ON public.workers FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "workers_insert_update" ON public.workers FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());
CREATE POLICY "worker_logs_select" ON public.worker_logs FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "worker_logs_insert_update" ON public.worker_logs FOR ALL TO authenticated USING (app_private.is_staff()) WITH CHECK (app_private.is_staff());

-- worker_advances
DROP POLICY IF EXISTS "worker_advances_select" ON public.worker_advances;
DROP POLICY IF EXISTS "worker_advances_insert_update" ON public.worker_advances;
CREATE POLICY "worker_advances_select" ON public.worker_advances FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "worker_advances_insert_update" ON public.worker_advances FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());

-- subcontracts
DROP POLICY IF EXISTS "subcontract_orders_select" ON public.subcontract_orders;
DROP POLICY IF EXISTS "subcontract_orders_modify" ON public.subcontract_orders;
DROP POLICY IF EXISTS "subcontract_payments_select" ON public.subcontract_payments;
DROP POLICY IF EXISTS "subcontract_payments_modify" ON public.subcontract_payments;
CREATE POLICY "subcontract_orders_select" ON public.subcontract_orders FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "subcontract_orders_modify" ON public.subcontract_orders FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());
CREATE POLICY "subcontract_payments_select" ON public.subcontract_payments FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "subcontract_payments_modify" ON public.subcontract_payments FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());

-- general_expenses
DROP POLICY IF EXISTS "general_expenses_select" ON public.general_expenses;
DROP POLICY IF EXISTS "general_expenses_insert" ON public.general_expenses;
DROP POLICY IF EXISTS "general_expenses_modify" ON public.general_expenses;
CREATE POLICY "general_expenses_select" ON public.general_expenses FOR SELECT TO authenticated USING (app_private.is_staff());
CREATE POLICY "general_expenses_insert" ON public.general_expenses FOR INSERT TO authenticated WITH CHECK (app_private.is_staff());
CREATE POLICY "general_expenses_modify" ON public.general_expenses FOR ALL TO authenticated USING (app_private.is_owner()) WITH CHECK (app_private.is_owner());

-- حذف الدوال القديمة من public حتى لا تظهر في الـ API نهائياً
DROP FUNCTION IF EXISTS public.current_user_role();
DROP FUNCTION IF EXISTS public.is_owner();
DROP FUNCTION IF EXISTS public.is_staff();

-- ----------------------------------------------------------------------------
-- الخطوة 3: إعادة بناء دوال الفائض كـ SECURITY INVOKER (تنفذ بصلاحيات المستخدم RLS)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_return_surplus(
    p_project_id UUID,
    p_material_name TEXT,
    p_unit TEXT,
    p_quantity NUMERIC,
    p_estimated_value NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY INVOKER
SET search_path = public
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_consume_surplus(
    p_surplus_id UUID,
    p_target_project_id UUID,
    p_consume_qty NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY INVOKER
SET search_path = public
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.rpc_scrap_surplus(
    p_surplus_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_surplus RECORD;
    v_scrap_value NUMERIC(12,2);
    v_adjustment_id UUID;
BEGIN
    IF NOT app_private.is_staff() THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول كمدير أو مالك';
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
$$ LANGUAGE plpgsql;