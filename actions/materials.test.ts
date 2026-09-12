import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  createSupabaseHarness,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
  createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import { purchaseMaterial } from './materials'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const IDEM_KEY = '11111111-1111-4111-8111-111111111106'

describe('purchaseMaterial', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
  })

  it('يسجل شراء مواد عبر recordExpense بتصنيف material', async () => {
    const tx = { id: 't1', category: 'material', amount: 850 }
    h.rpcOk('rpc_record_treasury_transaction', tx)

    const res = await purchaseMaterial({
      subcategory: 'wood_boards',
      amount: 850,
      description: 'شراء فك خشب',
      projectId: PROJECT_ID,
      isDirectOwnerPayment: false,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: tx })
    expect(h.rpcOf('rpc_record_treasury_transaction')[0].args).toMatchObject({
      p_action: 'record_expense',
      p_transaction_type: 'out',
      p_category: 'material',
      p_subcategory: 'wood_boards',
      p_amount: 850,
      p_description: 'شراء فك خشب',
      p_project_id: PROJECT_ID,
      p_is_direct_owner: false,
    })
  })

  it('يلزم التصنيف الفرعي للمواد عبر Zod', async () => {
    const res = await purchaseMaterial({
      amount: 850,
      isDirectOwnerPayment: false,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'التصنيف الفرعي مطلوب لهذا التصنيف' })
    expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await purchaseMaterial({
      subcategory: 'wood_boards',
      amount: 850,
      isDirectOwnerPayment: false,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يعيد النتيجة المخزنة دون إدراج عند اكتمال المفتاح', async () => {
    const cached = { id: 't1', category: 'material' }
    h.rpcOk('rpc_record_treasury_transaction', cached)

    const res = await purchaseMaterial({
      subcategory: 'wood_boards',
      amount: 850,
      isDirectOwnerPayment: false,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: cached })
  })
})