import { describe, expect, it } from 'vitest'
import { attendanceSchema, advanceSchema, settlementSchema } from './labor'

const WID = '11111111-1111-4111-8111-111111111111'
const PID = '22222222-2222-4222-8222-222222222222'

describe('attendanceSchema', () => {
  const base = {
    workerId: WID,
    workDate: '2026-09-05',
    fraction: 1,
    idempotencyKey: '11111111-1111-4111-8111-111111111110',
  }

  it('يقبل حضوراً صالحاً على مشروع', () => {
    const r = attendanceSchema.safeParse({ ...base, projectId: PID })
    expect(r.success).toBe(true)
  })

  it('يقبل حضوراً عاماً بدون مشروع', () => {
    const r = attendanceSchema.safeParse({ ...base, projectId: null })
    expect(r.success).toBe(true)
  })

  it('يقبل النسب الصالحة 0.25 و 0.50 و 1.00', () => {
    for (const f of [0.25, 0.5, 1]) {
      expect(attendanceSchema.safeParse({ ...base, fraction: f }).success).toBe(true)
    }
  })

  it('يرفض نسبة غير صالحة', () => {
    const r = attendanceSchema.safeParse({ ...base, fraction: 0.75 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe(
      'نسبة العمل يجب أن تكون 0.25 أو 0.50 أو 1.00'
    )
  })

  it('يرفض معرف عامل غير صالح', () => {
    const r = attendanceSchema.safeParse({ ...base, workerId: 'nope' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف العامل غير صالح')
  })

  it('يرفض مفتاح منع تكرار قصير', () => {
    const r = attendanceSchema.safeParse({ ...base, idempotencyKey: 's' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })

  it('يرفض تاريخ عمل فارغاً', () => {
    const r = attendanceSchema.safeParse({ ...base, workDate: '' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('تاريخ العمل مطلوب')
  })

  it('يرفض تاريخ عمل بصيغة غير صالحة', () => {
    for (const bad of ['foo', '2026-9-1', '01/09/2026', '9999-99-99']) {
      const r = attendanceSchema.safeParse({ ...base, workDate: bad })
      expect(r.success).toBe(false)
    }
  })

  it('يرفض تاريخ عمل مستحيل التقويم', () => {
    const r = attendanceSchema.safeParse({ ...base, workDate: '2026-02-30' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('التاريخ غير موجود في التقويم')
  })

  it('يرفض تاريخ عمل في المستقبل', () => {
    const r = attendanceSchema.safeParse({ ...base, workDate: '2999-01-01' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('التاريخ لا يمكن أن يكون في المستقبل')
  })

  it('يرفض تاريخ عمل قديماً جداً', () => {
    const r = attendanceSchema.safeParse({ ...base, workDate: '1999-12-31' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('التاريخ قديم جداً — تحقق من السنة')
  })
})

describe('advanceSchema', () => {
  const base = {
    workerId: WID,
    amount: 250,
    advanceDate: '2026-09-05',
    idempotencyKey: '11111111-1111-4111-8111-111111111111',
  }

  it('يقبل سلفة صالحة', () => {
    const r = advanceSchema.safeParse(base)
    expect(r.success).toBe(true)
  })

  it('يرفض مبلغاً غير موجب', () => {
    const r = advanceSchema.safeParse({ ...base, amount: 0 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('المبلغ يجب أن يكون أكبر من صفر')
  })

  it('يرفض مبلغاً غير رقمي', () => {
    const r = advanceSchema.safeParse({ ...base, amount: 'كثير' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('المبلغ يجب أن يكون رقماً')
  })

  it('يرفض مبلغ سلفة غير منتهٍ أو فلكياً أو أدق من قرشين', () => {
    for (const bad of [Infinity, 1e18, 10.126]) {
      const r = advanceSchema.safeParse({ ...base, amount: bad })
      expect(r.success).toBe(false)
    }
    const huge = advanceSchema.safeParse({ ...base, amount: 1e18 })
    expect(huge.error?.issues[0].message).toBe('القيمة تتجاوز الحد المسموح (تحقق من الأصفار)')
  })

  it('يرفض معرف عامل غير صالح', () => {
    const r = advanceSchema.safeParse({ ...base, workerId: 'x' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف العامل غير صالح')
  })

  it('يرفض تاريخ سلفة فارغاً', () => {
    const r = advanceSchema.safeParse({ ...base, advanceDate: '' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('تاريخ السلفة مطلوب')
  })

  it('يرفض تاريخ سلفة بصيغة غير صالحة أو مستقبلياً', () => {
    for (const bad of ['foo', '2026-13-01', '2999-06-01']) {
      const r = advanceSchema.safeParse({ ...base, advanceDate: bad })
      expect(r.success).toBe(false)
    }
  })

  it('يرفض ملاحظات أطول من 1000 حرف', () => {
    const r = advanceSchema.safeParse({ ...base, notes: 'x'.repeat(1001) })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الملاحظات طويلة جداً')
  })
})

describe('settlementSchema', () => {
  it('يقبل تسوية صالحة', () => {
    const r = settlementSchema.safeParse({
      workerId: WID,
      idempotencyKey: '11111111-1111-4111-8111-111111111112',
    })
    expect(r.success).toBe(true)
  })

  it('يرفض معرف عامل غير صالح', () => {
    const r = settlementSchema.safeParse({
      workerId: 'bad',
      idempotencyKey: '11111111-1111-4111-8111-111111111112',
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف العامل غير صالح')
  })

  it('يرفض مفتاح منع تكرار قصير', () => {
    const r = settlementSchema.safeParse({
      workerId: WID,
      idempotencyKey: 'x',
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})
