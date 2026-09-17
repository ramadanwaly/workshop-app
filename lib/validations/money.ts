import { z } from 'zod'

// ----------------------------------------------------------------------------
// مصنع تحقق المبالغ (P2-01): كل مبلغ/أجر/كمية/قيمة في النظام يمر من هنا.
// القاعدة: رقم منتهٍ + موجب (أو غير سالب) + سقف عمود القاعدة + دقة قرشين.
// السقفان يعكسان عرض العمود الفعلي حتى لا ينجح التحقق ثم تفشل القاعدة:
//   MAX_12_2 → NUMERIC(12,2) أي 9999999999.99 (الخزينة، الباطن، الفائض)
//   MAX_10_2 → NUMERIC(10,2) أي 99999999.99 (الأجور والسلف)
// ----------------------------------------------------------------------------

export const MAX_12_2 = 9999999999.99
export const MAX_10_2 = 99999999.99

type AmountMessages = {
  /** ليس رقماً (يحافظ على رسالة كل حقل الأصلية) */
  notNumber: string
  /** غير منتهٍ (Infinity/NaN) */
  notFinite: string
  /** رسالة positive/nonnegative الأصلية */
  tooSmall: string
  /** سقف العمود */
  max: number
}

function baseAmount(m: AmountMessages) {
  return z
    .number({ error: m.notNumber })
    .finite(m.notFinite)
    .max(m.max, 'القيمة تتجاوز الحد المسموح (تحقق من الأصفار)')
    .multipleOf(0.01, 'يُسمح بقرشين كحد أقصى بعد العلامة العشرية')
}

/** مبلغ يجب أن يكون أكبر من صفر (معظم الحقول) */
export function positiveAmount(m: AmountMessages) {
  return baseAmount(m).positive(m.tooSmall)
}

/** قيمة يجوز أن تكون صفراً (القيمة التقديرية للفائض) */
export function nonNegativeAmount(m: AmountMessages) {
  return baseAmount(m).nonnegative(m.tooSmall)
}
