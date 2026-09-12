import { describe, expect, it } from 'vitest'
import {
  injectFundingSchema,
  recordExpenseSchema,
  voidTransactionSchema,
} from './treasury'

describe('injectFundingSchema', () => {
  it('يقبل حقن تمويل صالح', () => {
    const result = injectFundingSchema.safeParse({
      amount: 5000,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
      description: 'رأس مال إضافي',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.amount).toBe(5000)
      expect(result.data.description).toBe('رأس مال إضافي')
    }
  })

  it('يفشل عندما لا يكون المبلغ رقماً مع رسالة عربية واضحة', () => {
    const result = injectFundingSchema.safeParse({
      amount: '5000',
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('المبلغ يجب أن يكون رقماً')
  })

  it('يمنع المبلغ غير الموجب', () => {
    const result = injectFundingSchema.safeParse({
      amount: 0,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('المبلغ يجب أن يكون أكبر من صفر')
  })

  it('يرفض المبلغ غير المنتهي (Infinity) عند باب النوع', () => {
    const result = injectFundingSchema.safeParse({
      amount: Infinity,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    // Zod v4 يرفض Infinity كرقم غير صالح أصلاً (قبل فحص finite)
    expect(result.error?.issues[0].message).toBe('المبلغ يجب أن يكون رقماً')
  })

  it('يرفض المبلغ الفلكي فوق سقف العمود', () => {
    const result = injectFundingSchema.safeParse({
      amount: 1e18,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('القيمة تتجاوز الحد المسموح (تحقق من الأصفار)')
  })

  it('يرفض كسوراً أدق من قرشين', () => {
    const result = injectFundingSchema.safeParse({
      amount: 10.126,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('يُسمح بقرشين كحد أقصى بعد العلامة العشرية')
  })

  it('يقبل سقف العمود 9999999999.99', () => {
    const result = injectFundingSchema.safeParse({
      amount: 9999999999.99,
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(true)
  })

  it('يرفض مفتاح منع التكرار القصير', () => {
    const result = injectFundingSchema.safeParse({
      amount: 100,
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })

  it('يرفض مفتاح منع تكرار غير UUID (حتى لو طويل)', () => {
    const result = injectFundingSchema.safeParse({
      amount: 100,
      idempotencyKey: 'not-a-uuid-but-long-enough-key',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })

  it('يرفض مفتاح فراغات', () => {
    const result = injectFundingSchema.safeParse({
      amount: 100,
      idempotencyKey: '          ',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })

  it('يرفض وصفاً ضخماً (1MB)', () => {
    const result = injectFundingSchema.safeParse({
      amount: 100,
      description: 'x'.repeat(1024 * 1024),
      idempotencyKey: '11111111-1111-4111-8111-111111111120',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('الوصف طويل جداً')
  })

  it('يعيد أول خطأ حسب ترتيب الحقول عند وجود عدة أخطاء', () => {
    const result = injectFundingSchema.safeParse({
      amount: 'ليس رقماً',
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('المبلغ يجب أن يكون رقماً')
  })
})

describe('recordExpenseSchema', () => {
  const valid = {
    category: 'material',
    subcategory: 'wood_boards',
    amount: 250,
    idempotencyKey: '11111111-1111-4111-8111-111111111121',
  }

  it('يقبل مصروفاً صالحاً ويعطي قيماً افتراضية', () => {
    const result = recordExpenseSchema.safeParse(valid)
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.isDirectOwnerPayment).toBe(false)
      expect(result.data.projectId).toBeUndefined()
    }
  })

  it('يرفض تصنيفاً غير صالح مع رسالة عربية', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      category: 'bogus',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('تصنيف المصروف غير صالح')
  })

  it('يفشل عندما لا يكون المبلغ رقماً', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      amount: 'كثير',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('المبلغ يجب أن يكون رقماً')
  })

  it('يقبل projectId فارغاً', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      projectId: null,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض projectId غير صالح', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      projectId: 'not-a-uuid',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يرفض سداد المالك المباشر بدون مشروع (C-01)', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      isDirectOwnerPayment: true,
      projectId: null,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'المدفوعات المباشرة من المالك يجب أن ترتبط بمشروع محدد لزيادة تكلفته'
    )
  })

  it('يقبل سداد المالك المباشر مع مشروع صالح', () => {
    const result = recordExpenseSchema.safeParse({
      ...valid,
      isDirectOwnerPayment: true,
      projectId: '11111111-1111-4111-8111-111111111111',
    })
    expect(result.success).toBe(true)
  })
})

describe('voidTransactionSchema', () => {
  const id = '11111111-1111-4111-8111-111111111111'
  const idempotencyKey = '11111111-1111-4111-8111-111111111122'

  it('يقبل إلغاءً صالحاً', () => {
    const result = voidTransactionSchema.safeParse({
      transactionId: id,
      reason: 'إدخال خاطئ',
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض معرف حركة غير صالح', () => {
    const result = voidTransactionSchema.safeParse({
      transactionId: 'x',
      reason: 'إدخال خاطئ',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف الحركة غير صالح')
  })

  it('يرفض سبب الإلغاء القصير', () => {
    const result = voidTransactionSchema.safeParse({
      transactionId: id,
      reason: 'لا',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe(
      'يجب كتابة سبب الإلغاء (3 أحرف على الأقل)'
    )
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = voidTransactionSchema.safeParse({
      transactionId: id,
      reason: 'إدخال خاطئ',
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('recordExpense subcategory pairing', () => {
  const recordBase = {
    category: 'material' as const,
    amount: 500,
    idempotencyKey: '11111111-1111-4111-8111-111111111123',
  }

  it('accepts material with a valid subcategory', () => {
    expect(recordExpenseSchema.safeParse({ ...recordBase, subcategory: 'wood_boards' }).success).toBe(true)
  })
  it('rejects material without a subcategory', () => {
    expect(recordExpenseSchema.safeParse({ ...recordBase }).success).toBe(false)
  })
  it('rejects a subcategory that does not belong to the category', () => {
    expect(recordExpenseSchema.safeParse({ ...recordBase, subcategory: 'rent' }).success).toBe(false)
  })
  it('accepts workshop_operating only with its own subcategories and no project', () => {
    const opBase = { ...recordBase, category: 'workshop_operating' as const }
    expect(recordExpenseSchema.safeParse({ ...opBase, subcategory: 'electricity' }).success).toBe(true)
    expect(recordExpenseSchema.safeParse({ ...opBase, subcategory: 'wood_boards' }).success).toBe(false)
    expect(recordExpenseSchema.safeParse({ ...opBase, subcategory: 'electricity', projectId: crypto.randomUUID() }).success).toBe(false)
  })
  it('accepts general_expense without a subcategory', () => {
    const g = { ...recordBase, category: 'general_expense' as const }
    expect(recordExpenseSchema.safeParse(g).success).toBe(true)
  })
})