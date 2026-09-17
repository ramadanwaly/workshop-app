import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import {
  createSupabaseHarness,
  postgrestError,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'
import type { CloseOrderInput } from '@/lib/validations/subcontracts'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import {
  closeSubcontractOrder,
  createSubcontractOrder,
  getSubcontractLiabilities,
  getSubcontractOrders,
  paySubcontract,
  voidSubcontractPayment,
} from './subcontracts'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const ORDER_ID = '55555555-5555-4555-8555-555555555555'
const PAYMENT_ID = '66666666-6666-4666-8666-666666666666'
const IDEM_KEY = '11111111-1111-4111-8111-111111111103'

describe('createSubcontractOrder', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('ينشئ اتفاقية مقاول باطن مع تمرير صحيح لمعاملات RPC', async () => {
    const order = { id: ORDER_ID, contractor_name: 'مقاول' }
    h.rpcOk('rpc_create_subcontract_order', order)

    const res = await createSubcontractOrder({
      projectId: PROJECT_ID,
      contractorName: 'مقاول الخشب',
      description: 'أعمال فك وتركيب',
      totalAgreedAmount: 15000,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: order })
    expect(h.rpcOf('rpc_create_subcontract_order')[0].args).toEqual({
      p_project_id: PROJECT_ID,
      p_contractor_name: 'مقاول الخشب',
      p_description: 'أعمال فك وتركيب',
      p_total_agreed_amount: 15000,
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'create_subcontract_order',
    })
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(1)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await createSubcontractOrder({
      projectId: PROJECT_ID,
      contractorName: 'مقاول',
      description: 'وصف',
      totalAgreedAmount: 5000,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يرفض وصفاً فارغاً عبر Zod', async () => {
    const res = await createSubcontractOrder({
      projectId: PROJECT_ID,
      contractorName: 'مقاول',
      description: '   ',
      totalAgreedAmount: 5000,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'وصف الاتفاقية مطلوب' })
    expect(h.rpcOf('rpc_create_subcontract_order')).toHaveLength(0)
  })

  it('يرسل رسالة رفض العمل (P0001) من RPC كما هي', async () => {
    h.rpcFail('rpc_create_subcontract_order', postgrestError('P0001', 'المشروع غير نشط'))

    const res = await createSubcontractOrder({
      projectId: PROJECT_ID,
      contractorName: 'مقاول',
      description: 'وصف',
      totalAgreedAmount: 5000,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'المشروع غير نشط' })
  })

  it('يعيد النتيجة المخزنة دون استدعاء RPC عند اكتمال المفتاح', async () => {
    const cached = { id: ORDER_ID }
    h.idempotency.existing = { status: 'completed', response_payload: cached }

    const res = await createSubcontractOrder({
      projectId: PROJECT_ID,
      contractorName: 'مقاول',
      description: 'وصف',
      totalAgreedAmount: 5000,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: cached })
    expect(h.rpcOf('rpc_create_subcontract_order')).toHaveLength(0)
  })
})

describe('paySubcontract', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يسدد دفعة لمقاول باطن مع تمرير صحيح لمعاملات RPC', async () => {
    const payment = { id: PAYMENT_ID, amount: 4000 }
    h.rpcOk('rpc_pay_subcontract', payment)

    const res = await paySubcontract({
      orderId: ORDER_ID,
      amount: 4000,
      paymentDate: '2026-09-01',
      notes: 'دفعة أولى',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: payment })
    expect(h.rpcOf('rpc_pay_subcontract')[0].args).toEqual({
      p_order_id: ORDER_ID,
      p_amount: 4000,
      p_payment_date: '2026-09-01',
      p_notes: 'دفعة أولى',
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'pay_subcontract',
    })
  })

  it('يرفض المبلغ غير الموجب', async () => {
    const res = await paySubcontract({
      orderId: ORDER_ID,
      amount: -5,
      paymentDate: '2026-09-01',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'المبلغ يجب أن يكون أكبر من صفر' })
    expect(h.rpcOf('rpc_pay_subcontract')).toHaveLength(0)
  })

  it('يرفض تاريخ دفعة فارغاً', async () => {
    const res = await paySubcontract({
      orderId: ORDER_ID,
      amount: 1000,
      paymentDate: '',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'تاريخ الدفعة مطلوب' })
  })
})

describe('voidSubcontractPayment', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يلغي دفعة مع تمرير صحيح لمعاملات RPC', async () => {
    const result = { id: PAYMENT_ID, is_voided: true }
    h.rpcOk('rpc_void_subcontract_payment', result)

    const res = await voidSubcontractPayment({
      paymentId: PAYMENT_ID,
      reason: 'دفعة خاطئة',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: result })
    expect(h.rpcOf('rpc_void_subcontract_payment')[0].args).toEqual({
      p_payment_id: PAYMENT_ID,
      p_reason: 'دفعة خاطئة',
    })
  })

  it('يرفض معرف دفعة غير صالح', async () => {
    const res = await voidSubcontractPayment({
      paymentId: 'bad-id',
      reason: 'دفعة خاطئة',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'معرف الدفعة غير صالح' })
    expect(h.rpcOf('rpc_void_subcontract_payment')).toHaveLength(0)
  })
})

describe('closeSubcontractOrder', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يغلق اتفاقية بالحالة الممررة', async () => {
    const order = { id: ORDER_ID, status: 'completed' }
    h.rpcOk('rpc_close_subcontract_order', order)

    const res = await closeSubcontractOrder({
      orderId: ORDER_ID,
      status: 'completed',
      reason: 'انتهت الأعمال وتم الاستلام',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: order })
    expect(h.rpcOf('rpc_close_subcontract_order')[0].args).toEqual({
      p_order_id: ORDER_ID,
      p_status: 'completed',
      p_reason: 'انتهت الأعمال وتم الاستلام',
    })
  })

  it('يرفض حالة إغلاق غير صالحة', async () => {
    const res = await closeSubcontractOrder({
      orderId: ORDER_ID,
      status: 'archived' as unknown as CloseOrderInput['status'],
      reason: 'سبب تجريبي',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'حالة الإغلاق يجب أن تكون completed أو cancelled',
    })
    expect(h.rpcOf('rpc_close_subcontract_order')).toHaveLength(0)
  })

  it('يرسل رسالة رفض العمل (P0001) كما هي', async () => {
    h.rpcFail('rpc_close_subcontract_order', postgrestError('P0001', 'لا يُغلق إلا بعد سداد الالتزام كاملاً'))

    const res = await closeSubcontractOrder({
      orderId: ORDER_ID,
      status: 'completed',
      reason: 'انتهت الأعمال وتم الاستلام',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'لا يُغلق إلا بعد سداد الالتزام كاملاً',
    })
  })

  it('يرفض إغلاقاً بسبب قصير قبل أي RPC', async () => {
    const res = await closeSubcontractOrder({
      orderId: ORDER_ID,
      status: 'completed',
      reason: 'ab',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'يجب كتابة سبب الإغلاق (3 أحرف على الأقل)',
    })
    expect(h.rpcOf('rpc_close_subcontract_order')).toHaveLength(0)
  })
})

describe('قراءة بيانات المقاولين الباطن', () => {
  beforeEach(() => h.reset())

  it('يقرأ قائمة الاتفاقيات مرتبة مع العدد', async () => {
    const orders = [{ id: ORDER_ID }]
    h.when('subcontract_orders', 'select', orders)
    h.whenCount('subcontract_orders', 1)

    await expect(getSubcontractOrders()).resolves.toEqual({
      rows: orders,
      total: 1,
      page: 1,
      perPage: 50,
    })
    expect(h.callsOf('subcontract_orders', 'order')[0].args).toEqual([
      'created_at',
      { ascending: false },
    ])
    expect(h.callsOf('subcontract_orders', 'range')[0].args).toEqual([0, 49])
  })

  it('يبحث باسم المقاول في السيرفر', async () => {
    h.when('subcontract_orders', 'select', [])
    h.whenCount('subcontract_orders', 0)

    await getSubcontractOrders({ q: 'النجار' })

    const ilikes = h.callsOf('subcontract_orders', 'ilike')
    expect(ilikes).toHaveLength(2)
    expect(ilikes[0].args).toEqual(['contractor_name', '%النجار%'])
  })

  it('يرمي رسالة عامة فقط عند خطأ قراءة الاتفاقيات', async () => {
    h.fail('subcontract_orders', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getSubcontractOrders()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يقرأ الالتزامات المعلقة', async () => {
    const liab = { total_liabilities: 11000 }
    h.when('v_pending_liabilities', 'select', liab)

    await expect(getSubcontractLiabilities()).resolves.toEqual(liab)
    expect(h.callsOf('v_pending_liabilities', 'maybeSingle')).toHaveLength(1)
  })

  it('يرمي رسالة عامة فقط عند خطأ قراءة الالتزامات', async () => {
    h.fail('v_pending_liabilities', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getSubcontractLiabilities()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })
})