import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import {
  createSupabaseHarness,
  postgrestError,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import {
  consumeSurplus,
  getSurplusInventory,
  returnSurplusToBank,
  scrapSurplus,
} from './surplus'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const SURPLUS_ID = '44444444-4444-4444-8444-444444444444'
const IDEM_KEY = '11111111-1111-4111-8111-111111111104'

describe('returnSurplusToBank', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يرجع فائضاً لبنك المواد (للمالك والمدير) مع تمرير صحيح لمعاملات RPC', async () => {
    const returned = { id: SURPLUS_ID, status: 'available' }
    h.rpcOk('rpc_return_surplus', returned)

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 50,
      estimatedValue: 1200,
      notes: 'فائض من مشروع',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: returned })
    expect(h.rpcOf('rpc_return_surplus')[0].args).toEqual({
      p_project_id: PROJECT_ID,
      p_material_name: 'خشب',
      p_unit: 'كجم',
      p_quantity: 50,
      p_estimated_value: 1200,
      p_notes: 'فائض من مشروع',
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      key: IDEM_KEY,
      user_id: USER_ID,
      action: 'return_surplus',
    })
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(1)
  })

  it('يسمح للمدير (موظف الورشة) أيضاً', async () => {
    h.state.role = 'manager'
    h.rpcOk('rpc_return_surplus', { id: SURPLUS_ID })

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res.success).toBe(true)
    expect(h.rpcOf('rpc_return_surplus')).toHaveLength(1)
  })

  it('يرفض شخصاً بلا صلاحية موظف قبل أي استدعاء RPC', async () => {
    h.state.role = 'viewer'

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط',
    })
    expect(h.rpcOf('rpc_return_surplus')).toHaveLength(0)
    expect(h.callsOf('idempotency_keys', 'insert')).toHaveLength(0)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يرفض القيمة التقديرية غير الموجبة عبر Zod قبل أي استدعاء', async () => {
    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 0,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'القيمة التقديرية يجب أن تكون أكبر من صفر' })
    expect(h.rpcOf('rpc_return_surplus')).toHaveLength(0)
  })

  it('يرسل رسالة رفض العمل (P0001) من RPC كما هي', async () => {
    h.rpcFail('rpc_return_surplus', postgrestError('P0001', 'الكمية المطلوب إرجاعها غير متوفرة'))

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'الكمية المطلوب إرجاعها غير متوفرة',
    })
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(0)
  })

  it('يقنّع أخطاء RPC غير العملية برسالة عامة', async () => {
    h.rpcFail('rpc_return_surplus', postgrestError('XX000', 'internal error'))

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: GENERIC_ERROR_MESSAGE })
  })

  it('يعيد النتيجة المخزنة دون استدعاء RPC عند اكتمال المفتاح', async () => {
    const cached = { id: SURPLUS_ID }
    h.idempotency.existing = { status: 'completed', response_payload: cached }

    const res = await returnSurplusToBank({
      projectId: PROJECT_ID,
      materialName: 'خشب',
      unit: 'كجم',
      quantity: 10,
      estimatedValue: 300,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: cached })
    expect(h.rpcOf('rpc_return_surplus')).toHaveLength(0)
  })
})

describe('consumeSurplus', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'manager'
  })

  it('يستهلك فائضاً لمشروع آخر مع تمرير صحيح لمعاملات RPC', async () => {
    const consumed = { id: SURPLUS_ID, status: 'consumed' }
    h.rpcOk('rpc_consume_surplus', consumed)

    const res = await consumeSurplus({
      surplusId: SURPLUS_ID,
      targetProjectId: PROJECT_ID,
      consumeQuantity: 8,
      notes: 'استهلاك',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: consumed })
    expect(h.rpcOf('rpc_consume_surplus')[0].args).toEqual({
      p_surplus_id: SURPLUS_ID,
      p_target_project_id: PROJECT_ID,
      p_consume_qty: 8,
      p_notes: 'استهلاك',
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'consume_surplus',
    })
  })

  it('يرفض الكمية غير الموجبة', async () => {
    const res = await consumeSurplus({
      surplusId: SURPLUS_ID,
      targetProjectId: PROJECT_ID,
      consumeQuantity: 0,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'الكمية المستهلكة يجب أن تكون أكبر من صفر' })
    expect(h.rpcOf('rpc_consume_surplus')).toHaveLength(0)
  })

  it('يرفض غير الموظف', async () => {
    h.state.role = 'viewer'

    const res = await consumeSurplus({
      surplusId: SURPLUS_ID,
      targetProjectId: PROJECT_ID,
      consumeQuantity: 8,
      idempotencyKey: IDEM_KEY,
    })

    expect(res.success).toBe(false)
    expect(h.rpcOf('rpc_consume_surplus')).toHaveLength(0)
  })

  it('يرسل رسالة رفض العمل (P0001) كما هي', async () => {
    h.rpcFail('rpc_consume_surplus', postgrestError('P0001', 'رصيد الفائض غير كافٍ'))

    const res = await consumeSurplus({
      surplusId: SURPLUS_ID,
      targetProjectId: PROJECT_ID,
      consumeQuantity: 8,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'رصيد الفائض غير كافٍ' })
  })
})

describe('scrapSurplus', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يتلف فائضاً مع تمرير صحيح لمعاملات RPC', async () => {
    const scrapped = { id: SURPLUS_ID, status: 'scrapped' }
    h.rpcOk('rpc_scrap_surplus', scrapped)

    const res = await scrapSurplus({
      surplusId: SURPLUS_ID,
      reason: 'تلف تخزين',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: scrapped })
    expect(h.rpcOf('rpc_scrap_surplus')[0].args).toEqual({
      p_surplus_id: SURPLUS_ID,
      p_notes: 'تلف تخزين',
    })
  })

  it('يرفض معرف فائض غير صالح', async () => {
    const res = await scrapSurplus({
      surplusId: 'not-a-uuid',
      reason: 'تلف تخزين',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'معرف الفائض غير صالح' })
    expect(h.rpcOf('rpc_scrap_surplus')).toHaveLength(0)
  })

  it('يعيد النتيجة المخزنة دون استدعاء RPC عند اكتمال المفتاح', async () => {
    const cached = { id: SURPLUS_ID }
    h.idempotency.existing = { status: 'completed', response_payload: cached }

    const res = await scrapSurplus({
      surplusId: SURPLUS_ID,
      reason: 'تلف تخزين',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: cached })
    expect(h.rpcOf('rpc_scrap_surplus')).toHaveLength(0)
  })

  it('يرفض إتلافاً بدون سبب قبل أي RPC', async () => {
    const res = await scrapSurplus({
      surplusId: SURPLUS_ID,
      reason: 'x',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'يجب كتابة سبب الإتلاف (3 أحرف على الأقل)',
    })
    expect(h.rpcOf('rpc_scrap_surplus')).toHaveLength(0)
  })
})

describe('getSurplusInventory', () => {
  beforeEach(() => { h.reset(); h.state.user = { id: USER_ID }; h.state.role = 'manager'; })

  it('يقرأ المخزون المتاح بفلتر الحالة والترتيب التنازلي مع العدد', async () => {
    const rows = [{ id: SURPLUS_ID, status: 'available' }]
    h.when('surplus_bank', 'select', rows)
    h.whenCount('surplus_bank', 1)

    await expect(getSurplusInventory()).resolves.toEqual({
      rows,
      total: 1,
      page: 1,
      perPage: 50,
    })
    expect(h.callsOf('surplus_bank', 'eq')[0].args).toEqual(['status', 'available'])
    expect(h.callsOf('surplus_bank', 'order')[0].args).toEqual([
      'created_at',
      { ascending: false },
    ])
    expect(h.callsOf('surplus_bank', 'range')[0].args).toEqual([0, 49])
  })

  it('يقرأ المخزون حسب الحالة الممررة', async () => {
    h.when('surplus_bank', 'select', [])
    h.whenCount('surplus_bank', 0)

    await expect(getSurplusInventory('scrapped')).resolves.toEqual({
      rows: [],
      total: 0,
      page: 1,
      perPage: 50,
    })
    expect(h.callsOf('surplus_bank', 'eq')[0].args).toEqual(['status', 'scrapped'])
  })

  it('يبحث بالاسم مع هروب المحارف الخاصة', async () => {
    h.when('surplus_bank', 'select', [])
    h.whenCount('surplus_bank', 0)

    await getSurplusInventory('available', { q: 'خشب%_' })

    const ilikes = h.callsOf('surplus_bank', 'ilike')
    expect(ilikes).toHaveLength(2)
    expect(ilikes[0].args).toEqual(['material_name', '%خشب\\%\\_%'])
  })

  it('يرمي رسالة عامة فقط عند خطأ القراءة', async () => {
    h.fail('surplus_bank', 'select', postgrestError('PGRST116', 'The result contains 0 rows'))

    await expect(getSurplusInventory()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يرفض حالة المخزون الفاسدة بخطأ تحقق عربي', async () => {
    await expect(getSurplusInventory('hacked' as never)).rejects.toThrow('حالة المخزون غير صالحة')
    expect(h.callsOf('surplus_bank', 'select')).toHaveLength(0)
  })
})