-- =============================================================================
-- Migration: 20260918000050_revoke_audit_log_direct_grant.sql
-- Purpose  : P0-03 — سحب EXECUTE على append_audit_log من authenticated.
--
--   المشكلة: migration 20260910000027 منحت authenticated صلاحية EXECUTE على
--   app_private.append_audit_log(). رغم أن الدالة تستخدم SECURITY DEFINER
--   وأن الجدول audit_log لا يحتوي على INSERT policy للمستخدمين المباشرين،
--   إلا أن وجود GRANT مباشر على الدالة يُتيح للمدير إنشاء سجلات تدقيق
--   مضللة إذا تمكن من استدعاء الدالة عبر Supabase API.
--
--   الحل: سحب GRANT من authenticated. الاستدعاء يبقى صالحاً فقط من:
--   - Triggers تعمل بـ SECURITY DEFINER (trg_log_treasury_void, إلخ).
--   - RPCs التي تستدعي append_audit_log صراحةً وتعمل بـ SECURITY DEFINER.
--
--   التأكد: جميع استدعاءات append_audit_log في الكود تأتي من:
--   - Triggers: SECURITY DEFINER (migrations 27).
--   - rpc_add_operating_exclusion / rpc_remove_operating_exclusion: SECURITY DEFINER.
--   لا توجد استدعاءات مباشرة من Server Actions عبر supabase.rpc().
-- Note     : Migrations are append-only. Never edit an applied file.
-- =============================================================================

REVOKE EXECUTE ON FUNCTION app_private.append_audit_log(TEXT, TEXT, UUID, TEXT, JSONB)
FROM authenticated;

-- ملاحظة: GRANT على anon كان غائباً أصلاً (migration 27 منحت authenticated فقط).
-- سحبنا هنا authenticated فقط للتطابق مع ما مُنح.
