import { describe, expect, it } from 'vitest'
import {
  attendanceSchema,
  advanceSchema,
  settlementSchema,
} from './labor'
import {
  createOrderSchema,
  paySubcontractSchema,
  voidPaymentSchema,
  closeOrderSchema,
} from './subcontracts'
import {
  returnSurplusSchema,
  consumeSurplusSchema,
  scrapSurplusSchema,
} from './surplus'
import {
  injectFundingSchema,
  recordExpenseSchema,
  voidTransactionSchema,
} from './treasury'

// Phase 10 financial audit — code-level input validation only (no DB).
// Every value below mirrors supabase/verify_financial_audit.sql exactly,
// proving the app layer accepts the same inputs the DB narrative asserts.
const PROJECT_A = 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa'
const PROJECT_B = 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb'
const WORKER = 'cccccccc-3333-4333-8333-cccccccccccc'
const ORDER = 'dddddddd-4444-4444-8444-dddddddddddd'
const PAYMENT = 'eeeeeeee-5555-4555-8555-eeeeeeeeeeee'
const SURPLUS = 'ffffffff-6666-4666-8666-ffffffffffff'
const TX = '11111111-1111-4111-8111-111111111111'
// مفاتيح عدم تكرار صالحة (UUID) — مولد حتمي برقم
const ukey = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`

describe('audit treasury inputs', () => {
  it('يقبل تمويل المالك 100000', () => {
    const r = injectFundingSchema.safeParse({
      amount: 100000,
      description: 'audit funding',
      idempotencyKey: ukey(1),
    })
    expect(r.success).toBe(true)
  })

  it('يقبل مصروفاً نقدياً عاماً 1500', () => {
    const r = recordExpenseSchema.safeParse({
      category: 'general_expense',
      amount: 1500,
      description: 'audit general expense',
      idempotencyKey: ukey(2),
    })
    expect(r.success).toBe(true)
    if (r.success) expect(r.data.isDirectOwnerPayment).toBe(false)
  })

  it('يقبل مصروف مالك مباشر 5000 لمشروع', () => {
    const r = recordExpenseSchema.safeParse({
      category: 'material',
      subcategory: 'wood_boards',
      amount: 5000,
      projectId: PROJECT_A,
      isDirectOwnerPayment: true,
      idempotencyKey: ukey(3),
    })
    expect(r.success).toBe(true)
  })

  it('يقبل إلغاء حركة بسبب واضح', () => {
    const r = voidTransactionSchema.safeParse({
      transactionId: TX,
      reason: 'audit void',
      idempotencyKey: ukey(4),
    })
    expect(r.success).toBe(true)
  })

  it('يرفض التمويل الصفري والسالب', () => {
    for (const amount of [0, -100]) {
      const r = injectFundingSchema.safeParse({
        amount,
        idempotencyKey: ukey(5),
      })
      expect(r.success).toBe(false)
    }
  })
})

describe('audit surplus inputs', () => {
  it('يقبل إرجاع الفائض (10 قطع / 800)', () => {
    const r = returnSurplusSchema.safeParse({
      projectId: PROJECT_A,
      materialName: 'Audit Beech Wood',
      unit: 'piece',
      quantity: 10,
      estimatedValue: 800,
      idempotencyKey: ukey(6),
    })
    expect(r.success).toBe(true)
  })

  it('يقبل الاستهلاك الجزئي 4 والكلي 6', () => {
    for (const qty of [4, 6]) {
      const r = consumeSurplusSchema.safeParse({
        surplusId: SURPLUS,
        targetProjectId: PROJECT_B,
        consumeQuantity: qty,
        idempotencyKey: ukey(qty),
      })
      expect(r.success).toBe(true)
    }
  })

  it('يقبل الإتلاف بملاحظة', () => {
    const r = scrapSurplusSchema.safeParse({
      surplusId: SURPLUS,
      reason: 'audit scrap',
      idempotencyKey: ukey(7),
    })
    expect(r.success).toBe(true)
  })

  it('يرفض الكمية الصفرية والقيمة السالبة', () => {
    const zero = returnSurplusSchema.safeParse({
      projectId: PROJECT_A,
      materialName: 'Xy',
      unit: 'piece',
      quantity: 0,
      estimatedValue: 10,
      idempotencyKey: ukey(8),
    })
    expect(zero.success).toBe(false)
    const neg = returnSurplusSchema.safeParse({
      projectId: PROJECT_A,
      materialName: 'Xy',
      unit: 'piece',
      quantity: 1,
      estimatedValue: -5,
      idempotencyKey: ukey(9),
    })
    expect(neg.success).toBe(false)
  })
})

describe('audit labor inputs', () => {
  it('يقبل حضور المشروع 1.00 والعام 0.50', () => {
    const a = attendanceSchema.safeParse({
      workerId: WORKER,
      projectId: PROJECT_A,
      workDate: '2026-09-05',
      fraction: 1,
      idempotencyKey: ukey(11),
    })
    expect(a.success).toBe(true)
    const g = attendanceSchema.safeParse({
      workerId: WORKER,
      projectId: null,
      workDate: '2026-09-05',
      fraction: 0.5,
      idempotencyKey: ukey(12),
    })
    expect(g.success).toBe(true)
  })

  it('يقبل السلف 250 و 200 والتسوية', () => {
    for (const [amount, key] of [[250, ukey(21)], [200, ukey(22)]] as Array<[number, string]>) {
      const r = advanceSchema.safeParse({
        workerId: WORKER,
        amount,
        advanceDate: '2026-09-05',
        idempotencyKey: key,
      })
      expect(r.success).toBe(true)
    }
    const s = settlementSchema.safeParse({
      workerId: WORKER,
      notes: 'audit settle',
      idempotencyKey: ukey(14),
    })
    expect(s.success).toBe(true)
  })

  it('يرفض نسبة عمل 0.75', () => {
    const r = attendanceSchema.safeParse({
      workerId: WORKER,
      projectId: PROJECT_A,
      workDate: '2026-09-05',
      fraction: 0.75,
      idempotencyKey: ukey(13),
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('نسبة العمل يجب أن تكون 0.25 أو 0.50 أو 1.00')
  })
})

describe('audit subcontract inputs', () => {
  it('يقبل اتفاقيات 15000 و 30000 و 5000', () => {
    for (const [amount, key] of [[15000, '1'], [30000, '2'], [5000, '3']] as const) {
      const r = createOrderSchema.safeParse({
        projectId: PROJECT_A,
        contractorName: `Audit Contractor ${key}`,
        description: 'audit job',
        totalAgreedAmount: amount,
        idempotencyKey: ukey(Number(key)),
      })
      expect(r.success).toBe(true)
    }
  })

  it('يقبل الدفعات 6000 و 15000 و 16000 و 14000 و 2000', () => {
    for (const [amount, key] of [[6000, '1'], [15000, '2'], [16000, '3'], [14000, '4'], [2000, '5']] as const) {
      const r = paySubcontractSchema.safeParse({
        orderId: ORDER,
        amount,
        paymentDate: '2026-09-05',
        idempotencyKey: ukey(Number(key) + 10),
      })
      expect(r.success).toBe(true)
    }
  })

  it('يقبل إلغاء دفعة وإغلاق completed و cancelled', () => {
    const v = voidPaymentSchema.safeParse({
      paymentId: PAYMENT,
      reason: 'audit reversal',
      idempotencyKey: ukey(15),
    })
    expect(v.success).toBe(true)
    for (const [status, key] of [['completed', '1'], ['cancelled', '2']] as const) {
      const r = closeOrderSchema.safeParse({
        orderId: ORDER,
        status,
        reason: 'audit close',
        idempotencyKey: ukey(Number(key) + 20),
      })
      expect(r.success).toBe(true)
    }
  })

  it('يرفض حالة إغلاق غير صالحة', () => {
    const r = closeOrderSchema.safeParse({
      orderId: ORDER,
      status: 'active',
      idempotencyKey: ukey(16),
    })
    expect(r.success).toBe(false)
    expect(r.error?.issues[0].message).toBe('حالة الإغلاق يجب أن تكون completed أو cancelled')
  })
})
