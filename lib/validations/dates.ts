import { z } from 'zod'

// ----------------------------------------------------------------------------
// تحقق مشترك من تواريخ التشغيل (حضور / سلفة / دفعة) — P1-08.
// القاعدة: صيغة YYYY-MM-DD + تاريخ تقويمي حقيقي + ليس في المستقبل.
// الحد الأدنى 2000-01-01 مجرد حارس إملائي (سنة ناقصة رقماً)، وليس قرار عمل.
// ----------------------------------------------------------------------------

/** تاريخ تقويمي حقيقي (يرفض 2026-02-30 و 2026-13-01 رغم مطابقة الصيغة) */
function isRealCalendarDate(s: string): boolean {
  const [y, m, d] = s.split('-').map(Number)
  if (!y || m < 1 || m > 12 || d < 1 || d > 31) return false
  const dt = new Date(Date.UTC(y, m - 1, d))
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d
}

/**
 * تاريخ ماضٍ (أو اليوم): للحضور والسلف والدفعات — لا مستقبل ولا هراء.
 * @param requiredMessage رسالة الحقل الفارغ (تختلف per حقل)
 */
export function pastDateSchema(requiredMessage: string) {
  return z
    .string({ error: requiredMessage })
    .trim()
    .min(1, requiredMessage)
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'صيغة التاريخ غير صالحة (مثال: 2026-09-01)')
    .refine(isRealCalendarDate, 'التاريخ غير موجود في التقويم')
    .refine((s) => s >= '2000-01-01', 'التاريخ قديم جداً — تحقق من السنة')
    .refine(
      (s) => s <= new Date().toISOString().slice(0, 10),
      'التاريخ لا يمكن أن يكون في المستقبل'
    )
}
