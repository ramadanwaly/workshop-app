-- =============================================================================
-- Migration: 20260918000049_restrict_surplus_bank_update.sql
-- Purpose  : P0-02 — تقييد UPDATE على surplus_bank للمالك فقط.
--
--   المشكلة: سياسة surplus_bank_update (migration 19) تمنح is_staff() صلاحية
--   UPDATE كاملة، مما يتيح للمدير تغيير quantity وestimated_value وstatus
--   مباشرة متجاوزاً RPCs (rpc_consume_surplus وrpc_scrap_surplus) وأقفال
--   FOR UPDATE وحسابات القيمة النسبية وسجل التدقيق.
--
--   الحل:
--   - حذف سياسة is_staff وإنشاء سياسة للمالك فقط.
--
--   تأثير على RPCs:
--   - rpc_scrap_surplus وrpc_consume_surplus: SECURITY INVOKER + is_staff() check
--     داخلي. بعد هذا الإصلاح، تخضع هذه RPCs لـ RLS بدور المستدعي:
--     * المالك: يملك is_owner() = true → تمر RLS → تعمل.
--     * المدير: is_staff() = true داخل RPC لكن is_owner() = false في RLS
--       → يُرفض UPDATE → تفشل.
--
--   لذا: يجب تحويل rpc_scrap_surplus وrpc_consume_surplus إلى SECURITY DEFINER
--   في migration منفصلة (20260918000049b) لكي يستطيع المدير تنفيذهما
--   عبر المسار الآمن المقصود فقط.
--
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. تقييد UPDATE على surplus_bank للمالك فقط
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "surplus_bank_update" ON public.surplus_bank;

CREATE POLICY "surplus_bank_update_owner_only"
ON public.surplus_bank
FOR UPDATE TO authenticated
USING (app_private.is_owner())
WITH CHECK (app_private.is_owner());
