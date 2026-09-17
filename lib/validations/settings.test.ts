import { describe, expect, it } from 'vitest'
import { createManagerSchema, updateOverheadSchema } from './settings'

describe('updateOverheadSchema', () => {
  it('يقبل نسبة أوفر هيد صالحة', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 15.5,
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.overheadPercentage).toBe(15.5)
    }
  })

  it('يقبل 0% كنسبة أوفر هيد صالحة', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 0,
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.overheadPercentage).toBe(0)
    }
  })

  it('يقبل 100% كنسبة أوفر هيد صالحة', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 100,
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.overheadPercentage).toBe(100)
    }
  })

  it('يدعم معامل الشكل القديم overhead_percentage (رقم)', () => {
    const result = updateOverheadSchema.safeParse({
      overhead_percentage: 12,
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.overheadPercentage).toBe(12)
    }
  })

  it('يدعم معامل الشكل القديم overhead_percentage (سلسلة نصية رقمية)', () => {
    const result = updateOverheadSchema.safeParse({
      overhead_percentage: '22.5',
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.overheadPercentage).toBe(22.5)
    }
  })

  it('يرفض نسبة أوفر هيد بالسالب مع رسالة عربية', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: -5,
    })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('نسبة الأوفر هيد لا يمكن أن تكون بالسالب')
    }
  })

  it('يرفض نسبة أوفر هيد تتجاوز 100% مع رسالة عربية', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 105,
    })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('نسبة الأوفر هيد لا يمكن أن تتجاوز 100%')
    }
  })

  it('يرفض نسبة أوفر هيد غير رقمية مع رسالة عربية', () => {
    const res = updateOverheadSchema.safeParse({
      overheadPercentage: 'abc',
    })
    expect(res.success).toBe(false)
    if (!res.success) {
      expect(res.error.issues[0].message).toBe('نسبة الأوفر هيد يجب أن تكون رقماً')
    }
  })

  it('يقبل مفتاح عدم التكرار الصالح الاختياري', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 10,
      idempotencyKey: '11111111-1111-4111-8111-111111111125',
    })
    expect(result.success).toBe(true)
  })

  it('يرفض مفتاح عدم التكرار القصير إذا تم تزويده', () => {
    const result = updateOverheadSchema.safeParse({
      overheadPercentage: 10,
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
    }
  })
})

describe('createManagerSchema', () => {
  const valid = {
    email: 'manager@workshop.com',
    password: 'password123',
    fullName: 'أحمد محمود',
    idempotencyKey: '11111111-1111-4111-8111-111111111125',
  }

  it('يقبل مدخلات إنشاء مدير صالحة', () => {
    const res = createManagerSchema.safeParse(valid)
    expect(res.success).toBe(true)
  })

  it('يرفض بريد إلكتروني غير صالح', () => {
    const res = createManagerSchema.safeParse({ ...valid, email: 'invalid-email' })
    expect(res.success).toBe(false)
    if (!res.success) {
      expect(res.error.issues[0].message).toBe('يرجى إدخال بريد إلكتروني صحيح')
    }
  })

  it('يرفض كلمة مرور قصيرة', () => {
    const res = createManagerSchema.safeParse({ ...valid, password: '123' })
    expect(res.success).toBe(false)
    if (!res.success) {
      expect(res.error.issues[0].message).toBe('كلمة المرور يجب ألا تقل عن 6 أحرف')
    }
  })

  it('يرفض اسماً قصيراً', () => {
    const res = createManagerSchema.safeParse({ ...valid, fullName: 'أ' })
    expect(res.success).toBe(false)
    if (!res.success) {
      expect(res.error.issues[0].message).toBe('الاسم الكامل يجب أن يكون حرفين على الأقل')
    }
  })
})
