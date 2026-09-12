import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import {
  createSupabaseHarness,
  postgrestError,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'
import type { UpdateProjectStatusInput } from '@/lib/validations/projects'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import {
  createProject,
  getProjectDetail,
  getProjectTransactions,
  getProjects,
  updateProject,
  updateProjectStatus,
} from './projects'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const IDEM_KEY = '11111111-1111-4111-8111-111111111105'

describe('updateProjectStatus — الفحص بالصلاحية', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يسمح لمالك الورشة بتغيير الحالة ويُحدِّث قاعدة البيانات', async () => {
    const projectRecord = { id: PROJECT_ID, name: 'مشروع', status: 'completed' }
    h.when('projects', 'update', projectRecord)

    const result = await updateProjectStatus({
      projectId: PROJECT_ID,
      status: 'completed',
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({ success: true, data: projectRecord })
    expect(h.callsOf('projects', 'update')[0].args[0]).toEqual({ status: 'completed' })
    expect(h.callsOf('projects', 'eq')[0].args).toEqual(['id', PROJECT_ID])
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'update_project_status',
    })
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(1)
  })

  it('يرفض المدير تغيير الحالة قبل أي كتابة في قاعدة البيانات', async () => {
    h.state.role = 'manager'

    const result = await updateProjectStatus({
      projectId: PROJECT_ID,
      status: 'completed',
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(h.callsOf('projects', 'update')).toHaveLength(0)
    expect(h.callsOf('idempotency_keys', 'insert')).toHaveLength(0)
  })

  it('يرفض الزائر من غير جلسة قبل أي كتابة في قاعدة البيانات', async () => {
    h.state.user = null

    const result = await updateProjectStatus({
      projectId: PROJECT_ID,
      status: 'completed',
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يرفض حالة غير صالحة عبر Zod', async () => {
    const result = await updateProjectStatus({
      projectId: PROJECT_ID,
      status: 'broken' as unknown as UpdateProjectStatusInput['status'],
      idempotencyKey: IDEM_KEY,
    })

    expect(result).toEqual({ success: false, error: 'حالة المشروع غير صالحة' })
    expect(h.callsOf('projects', 'update')).toHaveLength(0)
  })
})

describe('createProject', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('ينشئ مشروعاً جديداً مع تعيين الوصف null عند غيابه', async () => {
    const project = { id: PROJECT_ID, name: 'مشروع جديد' }
    h.when('projects', 'insert', project)

    const res = await createProject({
      name: 'مشروع جديد',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: project })
    expect(h.callsOf('projects', 'insert')[0].args[0]).toEqual({
      name: 'مشروع جديد',
      description: null,
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'create_project',
    })
  })

  it('يعين الوصف المقدم', async () => {
    h.when('projects', 'insert', { id: PROJECT_ID })

    const res = await createProject({
      name: 'مشروع جديد',
      description: 'وصف المشروع',
      idempotencyKey: IDEM_KEY,
    })

    expect(res.success).toBe(true)
    expect(h.callsOf('projects', 'insert')[0].args[0]).toEqual({
      name: 'مشروع جديد',
      description: 'وصف المشروع',
    })
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await createProject({
      name: 'مشروع جديد',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يعيد النتيجة المخزنة دون إدراج عند اكتمال المفتاح', async () => {
    const cached = { id: PROJECT_ID }
    h.idempotency.existing = { status: 'completed', response_payload: cached }

    const res = await createProject({
      name: 'مشروع جديد',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: cached })
    expect(h.callsOf('projects', 'insert')).toHaveLength(0)
  })
})

describe('updateProject', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
  })

  it('يحدّث المشروع بالحقول المحددة فقط', async () => {
    const project = { id: PROJECT_ID, name: 'اسم محدث', description: null }
    h.when('projects', 'update', project)

    const res = await updateProject({
      projectId: PROJECT_ID,
      name: 'اسم محدث',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: project })
    expect(h.callsOf('projects', 'update')[0].args[0]).toEqual({ name: 'اسم محدث' })
    expect(h.callsOf('projects', 'eq')[0].args).toEqual(['id', PROJECT_ID])
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'update_project',
    })
  })

  it('يرفض تعديلاً بلا أي حقول محددة', async () => {
    const res = await updateProject({
      projectId: PROJECT_ID,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'لم يتم تحديد أي حقول للتعديل' })
    expect(h.callsOf('projects', 'update')).toHaveLength(0)
    expect(h.callsOf('idempotency_keys', 'update')).toHaveLength(0)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await updateProject({
      projectId: PROJECT_ID,
      name: 'اسم محدث',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })
})

describe('getProjects', () => {
  beforeEach(() => h.reset())

  it('يقرأ قائمة المشاريع مرتبة بالاسم', async () => {
    const rows = [{ id: PROJECT_ID, name: 'أ' }, { id: 'b', name: 'ب' }]
    h.when('projects', 'select', rows)

    await expect(getProjects()).resolves.toEqual(rows)
    expect(h.callsOf('projects', 'order')[0].args).toEqual(['name', { ascending: true }])
  })

  it('يقنّع خطأ القراءة برسالة عامة', async () => {
    h.fail('projects', 'select', postgrestError('PGRST116', 'فشل جلب المشاريع'))

    await expect(getProjects()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })
})

describe('getProjectDetail', () => {
  beforeEach(() => h.reset())

  it('يقرأ تفاصيل مشروع واحد عبر eq/maybeSingle', async () => {
    const project = { id: PROJECT_ID, name: 'مشروع', description: null, status: 'active' }
    h.when('projects', 'select', project)

    await expect(getProjectDetail(PROJECT_ID)).resolves.toEqual(project)
    expect(h.callsOf('projects', 'eq')[0].args).toEqual(['id', PROJECT_ID])
    expect(h.callsOf('projects', 'maybeSingle')).toHaveLength(1)
  })

  it('يقنّع خطأ القراءة برسالة عامة', async () => {
    h.fail('projects', 'select', postgrestError('PGRST116', 'فشل جلب تفاصيل المشروع'))

    await expect(getProjectDetail(PROJECT_ID)).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يرفض معرف المشروع الفاسد بخطأ تحقق عربي', async () => {
    await expect(getProjectDetail('not-a-uuid')).rejects.toThrow('معرف المشروع غير صالح')
    expect(h.callsOf('projects', 'select')).toHaveLength(0)
  })
})

describe('getProjectTransactions', () => {
  beforeEach(() => h.reset())

  it('يجمع حركات المشروع من المصادر الأربعة', async () => {
    const treasury = [{ id: 't1', project_id: PROJECT_ID }]
    const logs = [{ id: 'l1', project_id: PROJECT_ID }]
    const subcontracts = [{ id: 's1', project_id: PROJECT_ID }]
    const adjustments = [{ id: 'aj1', project_id: PROJECT_ID }]
    h.when('treasury_transactions', 'select', treasury)
    h.when('worker_logs', 'select', logs)
    h.when('subcontract_orders', 'select', subcontracts)
    h.when('project_cost_adjustments', 'select', adjustments)

    const res = await getProjectTransactions(PROJECT_ID)

    expect(res).toEqual({
      treasuryTransactions: treasury,
      workerLogs: logs,
      subcontractOrders: subcontracts,
      costAdjustments: adjustments,
    })
    expect(
      h.callsOf('treasury_transactions', 'eq')[0].args
    ).toEqual(['project_id', PROJECT_ID])
    expect(h.callsOf('project_cost_adjustments', 'eq')[0].args).toEqual([
      'project_id',
      PROJECT_ID,
    ])
  })

  it('يقنّع خطأ أي مصدر فاشل برسالة عامة', async () => {
    h.when('treasury_transactions', 'select', [])
    h.fail('worker_logs', 'select', postgrestError('PGRST116', 'فشل جلب السجلات'))

    await expect(getProjectTransactions(PROJECT_ID)).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يحد كل مصدر بمائة صف افتراضياً وبحد مخصص عند الطلب', async () => {
    h.when('treasury_transactions', 'select', [])
    h.when('worker_logs', 'select', [])
    h.when('subcontract_orders', 'select', [])
    h.when('project_cost_adjustments', 'select', [])

    await getProjectTransactions(PROJECT_ID)
    for (const table of [
      'treasury_transactions',
      'worker_logs',
      'subcontract_orders',
      'project_cost_adjustments',
    ]) {
      expect(h.callsOf(table, 'limit')[0].args).toEqual([100])
    }

    h.reset()
    h.when('treasury_transactions', 'select', [])
    h.when('worker_logs', 'select', [])
    h.when('subcontract_orders', 'select', [])
    h.when('project_cost_adjustments', 'select', [])

    await getProjectTransactions(PROJECT_ID, { limit: 20 })
    expect(h.callsOf('treasury_transactions', 'limit')[0].args).toEqual([20])

    await expect(getProjectTransactions(PROJECT_ID, { limit: 999999 })).rejects.toThrow(
      'حد القراءة غير صالح'
    )
  })

  it('يرفض معرف المشروع الفاسد في الحركات بخطأ تحقق عربي', async () => {
    await expect(getProjectTransactions('not-a-uuid')).rejects.toThrow('معرف المشروع غير صالح')
    expect(h.callsOf('treasury_transactions', 'select')).toHaveLength(0)
  })
})