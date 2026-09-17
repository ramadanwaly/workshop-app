import { describe, expect, it } from 'vitest'
import {
  createWorkerSchema,
  updateWorkerSchema,
  toggleWorkerStatusSchema,
} from './workers'

const WID = '11111111-1111-4111-8111-111111111111'

describe('createWorkerSchema', () => {
  const base = {
    name: 'محمد علي',
    dailyRate: 150,
    idempotencyKey: '11111111-1111-4111-8111-111111111117',
  }

  it('يقبل بيانات عامل صالحة', () => {
    const r = createWorkerSchema.safeParse(base)
    expect(r.success).toBe(true)
    if (r.success) {
      expect(r.data.name).toBe('محمد علي')
      expect(r.data.dailyRate).toBe(150)
    }
  })

  it('يقبل رقم هاتف صالح أو فارغ أو null', () => {
    const withPhone = createWorkerSchema.safeParse({ ...base, phone: '0501234567' })
    expect(withPhone.success).toBe(true)

    const withNull = createWorkerSchema.safeParse({ ...base, phone: null })
    expect(withNull.success).toBe(true)
  })

  it('يرفض اسماً فارغاً مع رسالة عربية', () => {
    const r = createWorkerSchema.safeParse({ ...base, name: '   ' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('اسم العامل مطلوب')
  })

  it('يرفض أجر يومي يساوي صفراً مع رسالة عربية', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: 0 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون أكبر من صفر')
  })

  it('يرفض أجر يومي سالباً', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: -50 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون أكبر من صفر')
  })

  it('يرفض أجراً غير منتهٍ عند باب النوع', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: Infinity })
    expect(r.success).toBe(false)
    // Zod v4 يرفض Infinity كرقم غير صالح أصلاً (قبل فحص finite)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون رقماً')
  })

  it('يرفض أجراً فوق سقف عمود الأجور', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: 1e10 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('القيمة تتجاوز الحد المسموح (تحقق من الأصفار)')
  })

  it('يرفض أجراً أدق من قرشين', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: 150.126 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('يُسمح بقرشين كحد أقصى بعد العلامة العشرية')
  })

  it('يرفض اسماً أطول من 200 حرف', () => {
    const r = createWorkerSchema.safeParse({ ...base, name: 'م'.repeat(201) })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('اسم العامل طويل جداً')
  })

  it('يرفض هاتفاً بصيغة غير صالحة', () => {
    const r = createWorkerSchema.safeParse({ ...base, phone: 'abc-def' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('رقم الهاتف غير صالح')
  })

  it('يقبل هاتفاً دولياً بمسافات وشرطات', () => {
    const r = createWorkerSchema.safeParse({ ...base, phone: '+20 100-123 4567' })
    expect(r.success).toBe(true)
  })

  it('يرفض أجراً غير رقمي', () => {
    const r = createWorkerSchema.safeParse({ ...base, dailyRate: 'كثير' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون رقماً')
  })

  it('يرفض مفتاح منع تكرار قصير', () => {
    const r = createWorkerSchema.safeParse({ ...base, idempotencyKey: 'x' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('updateWorkerSchema', () => {
  const base = {
    workerId: WID,
    name: 'أحمد محمود',
    dailyRate: 200,
    idempotencyKey: '11111111-1111-4111-8111-111111111118',
  }

  it('يقبل تعديلاً صالحاً', () => {
    const r = updateWorkerSchema.safeParse(base)
    expect(r.success).toBe(true)
    if (r.success) {
      expect(r.data.name).toBe('أحمد محمود')
    }
  })

  it('يرفض معرف عامل غير صالح', () => {
    const r = updateWorkerSchema.safeParse({ ...base, workerId: 'bad-uuid' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف العامل غير صالح')
  })

  it('يرفض اسماً فارغاً عند التعديل', () => {
    const r = updateWorkerSchema.safeParse({ ...base, name: '' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('اسم العامل مطلوب')
  })

  it('يرفض أجر يومي غير موجب عند التعديل', () => {
    const r = updateWorkerSchema.safeParse({ ...base, dailyRate: -5 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون أكبر من صفر')
  })

  it('يرفض أجر يومي غير رقمي عند التعديل', () => {
    const r = updateWorkerSchema.safeParse({ ...base, dailyRate: 'مائة' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('الأجر اليومي يجب أن يكون رقماً')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const r = updateWorkerSchema.safeParse({ ...base, idempotencyKey: 'short' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('toggleWorkerStatusSchema', () => {
  const base = {
    workerId: WID,
    isActive: true,
    idempotencyKey: '11111111-1111-4111-8111-111111111119',
  }

  it('يقبل تبديلاً صالحاً بحالة true', () => {
    const r = toggleWorkerStatusSchema.safeParse(base)
    expect(r.success).toBe(true)
  })

  it('يقبل تبديلاً صالحاً بحالة false', () => {
    const r = toggleWorkerStatusSchema.safeParse({ ...base, isActive: false })
    expect(r.success).toBe(true)
  })

  it('يرفض قيمة isActive غير منطقية', () => {
    const r = toggleWorkerStatusSchema.safeParse({ ...base, isActive: 'yes' })
    expect(r.success).toBe(false)
  })

  it('يرفض معرف عامل غير صالح', () => {
    const r = toggleWorkerStatusSchema.safeParse({ ...base, workerId: 'invalid-id' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف العامل غير صالح')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const r = toggleWorkerStatusSchema.safeParse({ ...base, idempotencyKey: 'short' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})
