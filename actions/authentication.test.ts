import { describe, expect, it, beforeEach, vi } from 'vitest'

// ----------------------------------------------------------------------------
// سيناريو "زائر من غير تسجيل دخول خالص" (لا توجد جلسة إطلاقاً):
// كل أزرار شريط الموبايل تستدعي Server Actions. يجب أن يرفضها السيرفر فور
// التحقق من الهوية، ويكون الرفض قبل أي كتابة في قاعدة البيانات.
// ----------------------------------------------------------------------------

const h = vi.hoisted(() => {
  const state = {
    user: null as { id: string } | null,
    role: null as string | null,
  }

  const insert = vi.fn()
  const update = vi.fn()
  const rpc = vi.fn()

  return { state, insert, update, rpc }
})

vi.mock('@/lib/supabase/server', () => ({
  createClient: () => ({
    auth: {
      getUser: async () => ({ data: { user: h.state.user } }),
    },
    from: (table: string) => {
      if (table === 'profiles') {
        return {
          select: () => ({
            eq: () => ({
              single: async () => ({ data: { role: h.state.role } }),
            }),
          }),
        }
      }
      return { insert: h.insert, update: h.update }
    },
    rpc: h.rpc,
  }),
}))

import { injectOwnerFunding, recordExpense, voidTransaction } from './treasury'
import { recordWorkerAttendance } from './labor'
import {
  returnSurplusToBank,
  consumeSurplus,
  scrapSurplus,
} from './surplus'

const uuid = '11111111-1111-4111-8111-111111111111'
const idempotencyKey = '11111111-1111-4111-8111-111111111108'
const AUTH_ERROR = 'غير مصرح لك (يرجى تسجيل الدخول)'

beforeEach(() => {
  h.state.user = null
  h.state.role = null
  h.insert.mockClear()
  h.update.mockClear()
  h.rpc.mockClear()
})

describe('زائر من غير تسجيل دخول (لا توجد جلسة إطلاقاً)', () => {
  it('يرفض تسجيل المصروف من شريط الموبايل دون تعديل قاعدة البيانات', async () => {
    const result = await recordExpense({
      category: 'material',
      amount: 250,
      projectId: null,
      isDirectOwnerPayment: false,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error).toBe(AUTH_ERROR)
    expect(h.insert).not.toHaveBeenCalled()
    expect(h.update).not.toHaveBeenCalled()
    expect(h.rpc).not.toHaveBeenCalled()
  })

  it('يرفض تسجيل اليومية من شريط الموبايل دون تعديل قاعدة البيانات', async () => {
    const result = await recordWorkerAttendance({
      workerId: uuid,
      projectId: null,
      workDate: '2026-09-05',
      fraction: 1,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error).toBe(AUTH_ERROR)
    expect(h.rpc).not.toHaveBeenCalled()
  })

  it('يرفض إرجاع الفائض من شريط الموبايل دون تعديل قاعدة البيانات', async () => {
    const result = await returnSurplusToBank({
      projectId: uuid,
      materialName: 'خشب سويد',
      unit: 'kg',
      quantity: 10,
      estimatedValue: 500,
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error).toBe(AUTH_ERROR)
    expect(h.rpc).not.toHaveBeenCalled()
  })

  it('يرفض باقي عمليات الفائض (استهلاك/إتلاف) دون تعديل قاعدة البيانات', async () => {
    const consume = await consumeSurplus({
      surplusId: uuid,
      targetProjectId: uuid,
      consumeQuantity: 5,
      idempotencyKey,
    })
    expect(consume.success).toBe(false)
    expect(consume.error).toBe(AUTH_ERROR)

    const scrap = await scrapSurplus({
      surplusId: uuid,
      reason: 'تلف تخزين',
      idempotencyKey,
    })
    expect(scrap.success).toBe(false)
    expect(scrap.error).toBe(AUTH_ERROR)

    expect(h.rpc).not.toHaveBeenCalled()
  })

  it('يرفض عمليات الخزينة المالية للمالك (حقن/إلغاء) دون تعديل قاعدة البيانات', async () => {
    const inject = await injectOwnerFunding({
      amount: 5000,
      idempotencyKey,
    })
    expect(inject.success).toBe(false)
    expect(inject.error).toBe(AUTH_ERROR)

    const voidTx = await voidTransaction({
      transactionId: uuid,
      reason: 'إدخال خاطئ',
      idempotencyKey,
    })
    expect(voidTx.success).toBe(false)
    expect(voidTx.error).toBe(AUTH_ERROR)

    expect(h.insert).not.toHaveBeenCalled()
    expect(h.update).not.toHaveBeenCalled()
  })
})

describe('مستخدم مسجل بدور غير صالح (ليس مالكاً ولا مديراً)', () => {
  it('يرفض عمليات الفائض الثلاثة - صلاحية مرفوضة', async () => {
    h.state.user = { id: uuid }
    h.state.role = 'viewer'

    const returnResult = await returnSurplusToBank({
      projectId: uuid,
      materialName: 'خشب',
      unit: 'kg',
      quantity: 1,
      estimatedValue: 1,
      idempotencyKey,
    })
    expect(returnResult.success).toBe(false)
    expect(returnResult.error).toBe(
      'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط'
    )

    const consume = await consumeSurplus({
      surplusId: uuid,
      targetProjectId: uuid,
      consumeQuantity: 1,
      idempotencyKey,
    })
    expect(consume.success).toBe(false)
    expect(consume.error).toBe(
      'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط'
    )

    const scrap = await scrapSurplus({
      surplusId: uuid,
      reason: 'تلف تخزين',
      idempotencyKey,
    })
    expect(scrap.success).toBe(false)
    expect(scrap.error).toBe(
      'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط'
    )

    expect(h.rpc).not.toHaveBeenCalled()
    expect(h.insert).not.toHaveBeenCalled()
    expect(h.update).not.toHaveBeenCalled()
  })
})