import { describe, expect, it } from 'vitest'
import {
  createOrderSchema,
  paySubcontractSchema,
  voidPaymentSchema,
  closeOrderSchema,
} from './subcontracts'

const PID = '22222222-2222-4222-8222-222222222222'
const OID = '33333333-3333-4333-8333-333333333333'
const PAYID = '44444444-4444-4444-8444-444444444444'

describe('createOrderSchema', () => {
  const base = {
    projectId: PID,
    contractorName: 'مقاول النجارة',
    description: 'تشطيب كامل',
    totalAgreedAmount: 10000,
    idempotencyKey: '11111111-1111-4111-8111-111111111113',
  }

  it('يقبل اتفاقية صالحة', () => {
    expect(createOrderSchema.safeParse(base).success).toBe(true)
  })

  it('يرفض مبلغاً غير موجب', () => {
    const r = createOrderSchema.safeParse({ ...base, totalAgreedAmount: 0 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('المبلغ المتفق عليه يجب أن يكون أكبر من صفر')
  })

  it('يرفض مبلغاً غير رقمي', () => {
    const r = createOrderSchema.safeParse({ ...base, totalAgreedAmount: 'كثير' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('المبلغ المتفق عليه يجب أن يكون رقماً')
  })

  it('يرفض معرف مشروع غير صالح', () => {
    const r = createOrderSchema.safeParse({ ...base, projectId: 'x' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يرفض اسم مقاول فارغ', () => {
    const r = createOrderSchema.safeParse({ ...base, contractorName: '  ' })
    expect(r.success).toBe(false)
  })

  it('يرفض مفتاح منع تكرار قصير', () => {
    const r = createOrderSchema.safeParse({ ...base, idempotencyKey: 's' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('paySubcontractSchema', () => {
  const base = {
    orderId: OID,
    amount: 5000,
    paymentDate: '2026-09-05',
    idempotencyKey: '11111111-1111-4111-8111-111111111114',
  }

  it('يقبل دفعة صالحة', () => {
    expect(paySubcontractSchema.safeParse(base).success).toBe(true)
  })

  it('يرفض مبلغاً غير موجب', () => {
    const r = paySubcontractSchema.safeParse({ ...base, amount: 0 })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('المبلغ يجب أن يكون أكبر من صفر')
  })

  it('يرفض مبلغ دفعة غير منتهٍ أو فلكياً أو أدق من قرشين', () => {
    for (const bad of [Infinity, 1e18, 10.126]) {
      const r = paySubcontractSchema.safeParse({ ...base, amount: bad })
      expect(r.success).toBe(false)
    }
  })

  it('يرفض اسم مقاول أطول من 200 حرف', () => {
    const r = createOrderSchema.safeParse({
      projectId: PID,
      contractorName: 'م'.repeat(201),
      description: 'تشطيب كامل',
      totalAgreedAmount: 10000,
      idempotencyKey: '11111111-1111-4111-8111-111111111113',
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('اسم المقاول طويل جداً')
  })

  it('يرفض معرف اتفاقية غير صالح', () => {
    const r = paySubcontractSchema.safeParse({ ...base, orderId: 'bad' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف الاتفاقية غير صالح')
  })

  it('يرفض تاريخ دفعة فارغاً', () => {
    const r = paySubcontractSchema.safeParse({ ...base, paymentDate: '' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('تاريخ الدفعة مطلوب')
  })

  it('يرفض تاريخ دفعة بصيغة غير صالحة', () => {
    for (const bad of ['foo', '2026-02-30', '9999-99-99']) {
      const r = paySubcontractSchema.safeParse({ ...base, paymentDate: bad })
      expect(r.success).toBe(false)
    }
  })

  it('يرفض تاريخ دفعة في المستقبل', () => {
    const r = paySubcontractSchema.safeParse({ ...base, paymentDate: '2999-01-01' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('التاريخ لا يمكن أن يكون في المستقبل')
  })
})

describe('voidPaymentSchema', () => {
  it('يقبل إلغاء صالح', () => {
    expect(
      voidPaymentSchema.safeParse({ paymentId: PAYID, reason: 'دفعة مكررة بالخطأ', idempotencyKey: '11111111-1111-4111-8111-111111111115' }).success
    ).toBe(true)
  })

  it('يرفض معرف دفعة غير صالح', () => {
    const r = voidPaymentSchema.safeParse({ paymentId: 'bad', reason: 'دفعة مكررة', idempotencyKey: '11111111-1111-4111-8111-111111111115' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('معرف الدفعة غير صالح')
  })

  it('يرفض إلغاء بدون سبب', () => {
    const r = voidPaymentSchema.safeParse({ paymentId: PAYID, idempotencyKey: '11111111-1111-4111-8111-111111111115' })
    expect(r.success).toBe(false)
  })
})

describe('closeOrderSchema', () => {
  const closeBase = {
    orderId: OID,
    reason: 'انتهت الأعمال وتم الاستلام',
    idempotencyKey: '11111111-1111-4111-8111-111111111116',
  }

  it('يقبل الإغلاق كـ completed', () => {
    expect(
      closeOrderSchema.safeParse({ ...closeBase, status: 'completed' }).success
    ).toBe(true)
  })

  it('يقبل الإغلاق كـ cancelled', () => {
    expect(
      closeOrderSchema.safeParse({ ...closeBase, status: 'cancelled' }).success
    ).toBe(true)
  })

  it('يرفض حالة غير صالحة', () => {
    const r = closeOrderSchema.safeParse({ ...closeBase, status: 'closed' })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('حالة الإغلاق يجب أن تكون completed أو cancelled')
  })

  it('يرفض إغلاقاً بدون سبب', () => {
    const r = closeOrderSchema.safeParse({
      orderId: OID,
      status: 'completed',
      idempotencyKey: '11111111-1111-4111-8111-111111111116',
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('يجب كتابة سبب الإغلاق (3 أحرف على الأقل)')
  })
})
