-- =============================================================================
-- Migration: 20260918000051_restrict_cost_adj_insert.sql
-- Purpose  : P1-01 — حذف INSERT المباشر على project_cost_adjustments.
--
--   المشكلة: سياسة cost_adj_insert (migration 12) تسمح لـ is_staff() بإدراج
--   تعديلات تكلفة (surplus_return / surplus_consumption / surplus_scrap) مباشرة
--   دون المرور عبر RPCs التي تحسب القيمة وتربط الفائض وتسجل في audit_log.
--
--   الحل: حذف سياسة INSERT. الكتابة تتم فقط عبر:
--   - rpc_return_surplus   (SECURITY INVOKER — فحص is_staff داخلي)
--   - rpc_consume_surplus  (SECURITY DEFINER بعد migration 49b)
--   - rpc_scrap_surplus    (SECURITY DEFINER بعد migration 49b)
--   - rpc_run_operating_allocation وrpc_void_allocation_* (SECURITY DEFINER)
--
--   ملاحظة: رغم أن بعض RPCs هي SECURITY INVOKER (مثل rpc_return_surplus)،
--   فإنها تكتب في الجدول. بعد حذف INSERT policy:
--   - RPCs بـ SECURITY INVOKER تخضع لـ RLS بدور المستدعي → ستفشل INSERT.
--   - لذا: rpc_return_surplus تحتاج كذلك إلى SECURITY DEFINER.
--   سيتم معالجة ذلك في migration 20260918000051b.
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

DROP POLICY IF EXISTS "cost_adj_insert" ON public.project_cost_adjustments;

-- لا تُنشأ سياسة INSERT بديلة.
-- الكتابة تتم حصراً عبر RPCs الموثوقة (SECURITY DEFINER).
