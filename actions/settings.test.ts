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

const mockAdminCreateUser = vi.fn()
const mockAdminUpdateProfile = vi.fn()

vi.mock('@/lib/supabase/admin', () => ({
  createAdminClient: () => ({
    auth: {
      admin: {
        createUser: mockAdminCreateUser,
      },
    },
    from: () => ({
      update: () => ({
        eq: mockAdminUpdateProfile,
      }),
      upsert: mockAdminUpdateProfile,
    }),
  }),
}))

import { createManager, updateOverhead } from './settings'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const IDEM_KEY = '11111111-1111-4111-8111-111111111107'

describe('updateOverhead — الفحص بالصلاحية', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يسمح لمالك الورشة بتحديث الأوفر هيد', async () => {
    const updated = { id: 's1', overhead_percentage: 15.0 }
    h.when('settings', 'select', { id: 's1', overhead_percentage: 10.0 })
    h.when('settings', 'update', updated)

    const result = await updateOverhead({
      overheadPercentage: 15.0,
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({ success: true, data: updated })
    expect(h.callsOf('settings', 'update')).toHaveLength(1)
    expect(h.callsOf('idempotency_keys', 'insert')).toHaveLength(1)
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(1)
  })

  it('يرفض المدير تعديل الأوفر هيد', async () => {
    h.state.role = 'manager'

    const result = await updateOverhead({
      overheadPercentage: 15.0,
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(h.callsOf('settings', 'update')).toHaveLength(0)
    expect(h.callsOf('idempotency_keys', 'insert')).toHaveLength(0)
  })

  it('يرفض الزائر من غير جلسة', async () => {
    h.state.user = null
    h.state.role = null

    const result = await updateOverhead({
      overheadPercentage: 15.0,
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({
      success: false,
      error: 'غير مصرح لك (يرجى تسجيل الدخول)',
    })
    expect(h.callsOf('settings', 'update')).toHaveLength(0)
  })
})

describe('createManager — إنشاء حساب مدير', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
    mockAdminCreateUser.mockReset()
    mockAdminUpdateProfile.mockReset()
  })

  it('ينشئ حساب مدير جديد عند استدعائه من قبل المالك', async () => {
    mockAdminCreateUser.mockResolvedValue({
      data: { user: { id: 'm1', email: 'manager@workshop.com' } },
      error: null,
    })
    mockAdminUpdateProfile.mockResolvedValue({ error: null })

    const res = await createManager({
      email: 'manager@workshop.com',
      password: 'password123',
      fullName: 'أحمد محمود',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: true,
      data: { id: 'm1', email: 'manager@workshop.com', fullName: 'أحمد محمود' },
    })
    expect(mockAdminCreateUser).toHaveBeenCalledWith({
      email: 'manager@workshop.com',
      password: 'password123',
      email_confirm: true,
      user_metadata: { full_name: 'أحمد محمود', role: 'manager' },
    })
  })

  it('يرفض المدير عند محاولة إنشاء حساب مدير آخر', async () => {
    h.state.role = 'manager'

    const res = await createManager({
      email: 'manager2@workshop.com',
      password: 'password123',
      fullName: 'علي حسن',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(mockAdminCreateUser).not.toHaveBeenCalled()
  })
})
