import { describe, expect, it } from 'vitest'
import {
  consumeSurplusSchema,
  returnSurplusSchema,
  scrapSurplusSchema,
} from './surplus'

const uuid = '11111111-1111-4111-8111-111111111111'
const idempotencyKey = '11111111-1111-4111-8111-111111111127'

describe('returnSurplusSchema', () => {
  it('يقبل إرجاع فائض صالحاً', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب سويد',
      unit: 'kg',
      quantity: 120,
      estimatedValue: 1500,
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض معرف مشروع غير صالح', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: 'x',
      materialName: 'خشب',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يتطلب اسم المادة حرفين على الأقل', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خ',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'اسم المادة يجب أن يكون حرفين على الأقل'
    )
  })

  it('يتطلب وحدة القياس', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب',
      unit: ' ',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'وحدة القياس مطلوبة (مثل: كجم، متر، طن)'
    )
  })

  it('يرفض الكمية غير الموجبة', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      quantity: 0,
      estimatedValue: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('الكمية يجب أن تكون أكبر من صفر')
  })

  it('يرفض القيمة التقديرية غير الموجبة', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 0,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'القيمة التقديرية يجب أن تكون أكبر من صفر'
    )
  })

  it('يرفض اسم مادة أطول من 200 حرف ووحدة أطول من 30', () => {
    const base = {
      projectId: uuid,
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey,
    }
    const longName = returnSurplusSchema.safeParse({ ...base, materialName: 'م'.repeat(201) })
    expect(longName.success).toBe(false)
    expect(longName.error?.issues[0].message).toBe('اسم المادة طويل جداً')
    const longUnit = returnSurplusSchema.safeParse({ ...base, materialName: 'خشب', unit: 'u'.repeat(31) })
    expect(longUnit.success).toBe(false)
    expect(longUnit.error?.issues[0].message).toBe('وحدة القياس طويلة جداً')
  })

  it('يرفض كمية غير منتهية أو أدق من قرشين', () => {
    const base = {
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      estimatedValue: 1,
      idempotencyKey,
    }
    for (const bad of [Infinity, 10.126]) {
      expect(returnSurplusSchema.safeParse({ ...base, quantity: bad }).success).toBe(false)
    }
    const inf = returnSurplusSchema.safeParse({ ...base, quantity: Infinity })
    // Zod v4 يرفض Infinity كرقم غير صالح أصلاً (قبل فحص finite)
    expect(inf.error?.issues[0].message).toBe('الكمية يجب أن تكون رقماً')
  })

  it('الملاحظات اختيارية', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      notes: 'أحجار متبقية',
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = returnSurplusSchema.safeParse({
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('consumeSurplusSchema', () => {
  it('يقبل استهلاكاً صالحاً', () => {
    const result = consumeSurplusSchema.safeParse({
      surplusId: uuid,
      targetProjectId: uuid,
      consumeQuantity: 40,
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض معرف فائض غير صالح', () => {
    const result = consumeSurplusSchema.safeParse({
      surplusId: 'x',
      targetProjectId: uuid,
      consumeQuantity: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف الفائض غير صالح')
  })

  it('يرفض الكمية غير الموجبة', () => {
    const result = consumeSurplusSchema.safeParse({
      surplusId: uuid,
      targetProjectId: uuid,
      consumeQuantity: -1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'الكمية المستهلكة يجب أن تكون أكبر من صفر'
    )
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = consumeSurplusSchema.safeParse({
      surplusId: uuid,
      targetProjectId: uuid,
      consumeQuantity: 40,
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('scrapSurplusSchema', () => {
  it('يقبل إتلافاً صالحاً', () => {
    const result = scrapSurplusSchema.safeParse({
      surplusId: uuid,
      reason: 'تلف تخزين',
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض إتلافاً بدون سبب', () => {
    const result = scrapSurplusSchema.safeParse({
      surplusId: uuid,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('يجب كتابة سبب الإتلاف (3 أحرف على الأقل)')
  })

  it('يرفض معرف فائض غير صالح', () => {
    const result = scrapSurplusSchema.safeParse({
      surplusId: 'x',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف الفائض غير صالح')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = scrapSurplusSchema.safeParse({
      surplusId: uuid,
      reason: 'تلف تخزين',
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})