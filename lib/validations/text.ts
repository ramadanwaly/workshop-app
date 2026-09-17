import { z } from 'zod'

// ----------------------------------------------------------------------------
// حقول نصية مشتركة (P2-02): حدود الطول + صيغة الهاتف + مفتاح عدم التكرار.
// الحدود (200 للأسماء، 1000 للأوصاف والملاحظات والأسباب، 30 للهاتف/الوحدة)
// تمنع التضخم وإغراق السجلات؛ والرسائل تحافظ على نصوص الحقول الأصلية.
// ----------------------------------------------------------------------------

/**
 * مفتاح عدم التكرار: UUID حصرياً — يولده `generateIdempotencyKey()`
 * (crypto.randomUUID) في كل نافذة إدخال. النص الحر (حتى الطويل ≥10) مرفوض.
 */
export const idempotencyKeyField = z
  .string()
  .trim()
  .uuid('مفتاح عدم التكرار غير صالح')
  .max(100, 'مفتاح عدم التكرار غير صالح')

/** اسم مطلوب بحد 200 حرف (مشروع/عامل/مقاول) */
export function requiredName(label: string, tooLong?: string) {
  return z
    .string({ error: `${label} مطلوب` })
    .trim()
    .min(1, `${label} مطلوب`)
    .max(200, tooLong ?? `${label} طويل جداً`)
}

/** نص اختياري بحد أقصى (وصف/ملاحظات) */
export function optionalText(max: number, tooLong: string) {
  return z.string().trim().max(max, tooLong).optional()
}

/** هاتف اختياري: فارغ أو رقم يبدأ بـ + أو رقم (يسمح بمسافات وشرطات) */
export const phoneField = z
  .string()
  .trim()
  .max(30, 'رقم الهاتف طويل جداً')
  .regex(/^([+\d][\d\s-]*)?$/, 'رقم الهاتف غير صالح')
  .optional()
  .nullable()

/** سبب إلغاء: 3 أحرف على الأقل وبحد 1000 (الحقل المفقود عربي أيضاً) */
export function reasonField(
  tooShort = 'يجب كتابة سبب الإلغاء (3 أحرف على الأقل)'
) {
  return z
    .string({ error: tooShort })
    .trim()
    .min(3, tooShort)
    .max(1000, 'السبب طويل جداً (بحد أقصى 1000 حرف)')
}
