import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import {
  createSupabaseHarness,
  postgrestError,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'
import type { AttendanceInput } from '@/lib/validations/labor'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import {
  createWorker,
  getWorkerDayAttendance,
  getWorkerDetail,
  getWorkerLiabilities,
  getWorkers,
  recordWorkerAdvance,
  recordWorkerAttendance,
  settleWorker,
  toggleWorkerStatus,
  updateWorker,
} from './labor'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const WORKER_ID = '77777777-7777-4777-8777-777777777777'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const IDEM_KEY = '11111111-1111-4111-8111-111111111102'

describe('recordWorkerAttendance', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'manager'
  })

  it('يسجل حضور عامل مع تمرير صحيح لمعاملات RPC', async () => {
    const log = { id: 'l1', calculated_amount: 200 }
    h.rpcOk('rpc_record_attendance', log)

    const res = await recordWorkerAttendance({
      workerId: WORKER_ID,
      projectId: PROJECT_ID,
      workDate: '2026-09-01',
      fraction: 1,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: log })
    expect(h.rpcOf('rpc_record_attendance')[0].args).toEqual({
      p_worker_id: WORKER_ID,
      p_project_id: PROJECT_ID,
      p_work_date: '2026-09-01',
      p_fraction: 1,
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'record_attendance',
    })
  })

  it('يمرر null كمشروع عند العمل العام', async () => {
    const res = await recordWorkerAttendance({
      workerId: WORKER_ID,
      projectId: null,
      workDate: '2026-09-01',
      fraction: 0.5,
      idempotencyKey: IDEM_KEY,
    })

    expect(res.success).toBe(true)
    expect(h.rpcOf('rpc_record_attendance')[0].args).toMatchObject({
      p_project_id: null,
      p_fraction: 0.5,
    })
  })

  it('يرفض نسبة عمل غير صالحة', async () => {
    const res = await recordWorkerAttendance({
      workerId: WORKER_ID,
      projectId: PROJECT_ID,
      workDate: '2026-09-01',
      fraction: 0.75 as unknown as AttendanceInput['fraction'],
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'نسبة العمل يجب أن تكون 0.25 أو 0.50 أو 1.00',
    })
    expect(h.rpcOf('rpc_record_attendance')).toHaveLength(0)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await recordWorkerAttendance({
      workerId: WORKER_ID,
      projectId: PROJECT_ID,
      workDate: '2026-09-01',
      fraction: 1,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })
})

describe('getWorkerDayAttendance — فحص «مسجل اليوم بالفعل» قبل التسجيل', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'manager'
  })

  it('يعيد سجلات اليوم الموجودة للعامل', async () => {
    const rows = [
      { id: 'l1', fraction: 0.5, daily_rate: 200, project_id: null },
      { id: 'l2', fraction: 1, daily_rate: 200, project_id: PROJECT_ID },
    ]
    h.when('worker_logs', 'select', rows)

    const res = await getWorkerDayAttendance({
      workerId: WORKER_ID,
      workDate: '2026-09-01',
    })

    expect(res).toEqual({ success: true, data: rows })
    const calls = h.callsOf('worker_logs', 'eq')
    expect(calls.some((c) => c.args[0] === 'worker_id' && c.args[1] === WORKER_ID)).toBe(true)
    expect(calls.some((c) => c.args[0] === 'log_date' && c.args[1] === '2026-09-01')).toBe(true)
  })

  it('يرفض المدخلات غير الصالحة قبل أي استعلام', async () => {
    const res = await getWorkerDayAttendance({ workerId: 'ليس-uuid', workDate: '2026-09-01' })
    expect(res.success).toBe(false)
    expect(h.callsOf('worker_logs').length).toBe(0)
  })

  it('يعيد رسالة عامة فقط عند خطأ القراءة', async () => {
    h.fail('worker_logs', 'select', postgrestError('PGRST116', 'failed'))
    const res = await getWorkerDayAttendance({ workerId: WORKER_ID, workDate: '2026-09-01' })
    expect(res).toEqual({ success: false, error: GENERIC_ERROR_MESSAGE })
  })
})

describe('recordWorkerAdvance', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يصدر سلفة لعامل مع تمرير صحيح لمعاملات RPC', async () => {
    const advance = { id: 'a1', amount: 500 }
    h.rpcOk('rpc_record_advance', advance)

    const res = await recordWorkerAdvance({
      workerId: WORKER_ID,
      amount: 500,
      advanceDate: '2026-09-02',
      notes: 'سلفة أسبوعية',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: advance })
    expect(h.rpcOf('rpc_record_advance')[0].args).toEqual({
      p_worker_id: WORKER_ID,
      p_amount: 500,
      p_advance_date: '2026-09-02',
      p_notes: 'سلفة أسبوعية',
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'record_advance',
    })
  })

  it('يرفض المبلغ غير الموجب', async () => {
    const res = await recordWorkerAdvance({
      workerId: WORKER_ID,
      amount: 0,
      advanceDate: '2026-09-02',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'المبلغ يجب أن يكون أكبر من صفر' })
    expect(h.rpcOf('rpc_record_advance')).toHaveLength(0)
  })
})

describe('settleWorker', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
  })

  it('يسوي العامل مع تمرير صحيح لمعاملات RPC', async () => {
    const result = { worker_id: WORKER_ID, settled: true }
    h.rpcOk('rpc_settle_worker', result)

    const res = await settleWorker({
      workerId: WORKER_ID,
      notes: 'تسوية نهائية',
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: result })
    expect(h.rpcOf('rpc_settle_worker')[0].args).toEqual({
      p_worker_id: WORKER_ID,
      p_notes: 'تسوية نهائية',
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'settle_worker',
    })
  })

  it('يرسل رسالة رفض العمل (P0001) كما هي', async () => {
    h.rpcFail('rpc_settle_worker', postgrestError('P0001', 'لا يمكن التسوية وسلف جديدة معلقة بالخصم'))

    const res = await settleWorker({
      workerId: WORKER_ID,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'لا يمكن التسوية وسلف جديدة معلقة بالخصم',
    })
  })
})

describe('createWorker', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('ينشئ عاملاً للمالك مع تعيين رقم الهاتف null عند غيابه', async () => {
    const worker = { id: WORKER_ID, name: 'محمد', daily_rate: 200 }
    h.when('workers', 'insert', worker)

    const res = await createWorker({
      name: 'محمد',
      dailyRate: 200,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: worker })
    expect(h.callsOf('workers', 'insert')[0].args[0]).toEqual({
      name: 'محمد',
      phone: null,
      daily_rate: 200,
    })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'create_worker',
    })
  })

  it('يرفض غير المالك قبل أي كتابة', async () => {
    h.state.role = 'manager'

    const res = await createWorker({
      name: 'محمد',
      dailyRate: 200,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(h.callsOf('workers', 'insert')).toHaveLength(0)
    expect(h.callsOf('idempotency_keys', 'insert')).toHaveLength(0)
  })

  it('يرفض الزائر', async () => {
    h.state.user = null

    const res = await createWorker({
      name: 'محمد',
      dailyRate: 200,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })
})

describe('updateWorker', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يحذّث بيانات عامل للمالك مع تصفية بالمعرف', async () => {
    const updated = { id: WORKER_ID, name: 'مصطفى', phone: '01000000000', daily_rate: 250 }
    h.when('workers', 'update', updated)

    const res = await updateWorker({
      workerId: WORKER_ID,
      name: 'مصطفى',
      phone: '01000000000',
      dailyRate: 250,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: updated })
    expect(h.callsOf('workers', 'update')[0].args[0]).toEqual({
      name: 'مصطفى',
      phone: '01000000000',
      daily_rate: 250,
    })
    expect(h.callsOf('workers', 'eq')[0].args).toEqual(['id', WORKER_ID])
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'update_worker',
    })
  })

  it('يرفض غير المالك', async () => {
    h.state.role = 'viewer'

    const res = await updateWorker({
      workerId: WORKER_ID,
      name: 'مصطفى',
      dailyRate: 250,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(h.callsOf('workers', 'update')).toHaveLength(0)
  })
})

describe('toggleWorkerStatus', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يوقف عاملًا بكتابة is_active فقط', async () => {
    const toggled = { id: WORKER_ID, is_active: false }
    h.when('workers', 'update', toggled)

    const res = await toggleWorkerStatus({
      workerId: WORKER_ID,
      isActive: false,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({ success: true, data: toggled })
    expect(h.callsOf('workers', 'update')[0].args[0]).toEqual({ is_active: false })
    expect(h.callsOf('idempotency_keys', 'insert')[0].args[0]).toMatchObject({
      action: 'toggle_worker_status',
    })
  })

  it('يرفض غير المالك', async () => {
    h.state.role = 'manager'

    const res = await toggleWorkerStatus({
      workerId: WORKER_ID,
      isActive: true,
      idempotencyKey: IDEM_KEY,
    })

    expect(res).toEqual({
      success: false,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    })
    expect(h.callsOf('workers', 'update')).toHaveLength(0)
  })
})

describe('قراءة بيانات العمال', () => {
  beforeEach(() => h.reset())

  it('يقرأ الالتزامات المعلقة', async () => {
    const liab = { total_wages: 4500, total_advances: 1200 }
    h.when('v_pending_liabilities', 'select', liab)

    await expect(getWorkerLiabilities()).resolves.toEqual(liab)
    expect(h.callsOf('v_pending_liabilities', 'maybeSingle')).toHaveLength(1)
  })

  it('يرمي رسالة عامة فقط عند خطأ قراءة الالتزامات', async () => {
    h.fail('v_pending_liabilities', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getWorkerLiabilities()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يقرأ قائمة العمال مرتبة بالاسم مع العدد', async () => {
    const workers = [{ id: WORKER_ID, name: 'محمد' }]
    h.when('workers', 'select', workers)
    h.whenCount('workers', 1)

    await expect(getWorkers()).resolves.toEqual({
      rows: workers,
      total: 1,
      page: 1,
      perPage: 50,
    })
    expect(h.callsOf('workers', 'order')[0].args).toEqual([
      'is_active',
      { ascending: false },
    ])
    expect(h.callsOf('workers', 'order')[1].args).toEqual(['name', { ascending: true }])
  })

  it('يبحث بالاسم في السيرفر', async () => {
    h.when('workers', 'select', [])
    h.whenCount('workers', 0)

    await getWorkers({ q: 'محمد' })

    const ilikes = h.callsOf('workers', 'ilike')
    expect(ilikes).toHaveLength(2)
    expect(ilikes[0].args).toEqual(['name', '%محمد%'])
  })

  it('يرمي رسالة عامة فقط عند خطأ قراءة العمال', async () => {
    h.fail('workers', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getWorkers()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يجمع تفاصيل العامل والتزاماته من قاعدة البيانات (بلا حساب في TS)', async () => {
    const worker = { id: WORKER_ID, name: 'محمد', daily_rate: 200 }
    const logs = [
      { id: 'l1', worker_id: WORKER_ID, log_date: '2026-09-01', calculated_amount: 200, is_settled: false },
      { id: 'l2', worker_id: WORKER_ID, log_date: '2026-09-02', calculated_amount: 100, is_settled: false },
      { id: 'l3', worker_id: WORKER_ID, log_date: '2026-09-03', calculated_amount: 300, is_settled: true },
    ]
    const advances = [
      { id: 'a1', worker_id: WORKER_ID, advance_date: '2026-09-02', amount: 150, is_settled: false },
      { id: 'a2', worker_id: WORKER_ID, advance_date: '2026-09-03', amount: 50, is_settled: true },
    ]
    const liabilitiesRow = {
      worker_id: WORKER_ID,
      unsettled_wages: 400,
      unsettled_advances: 150,
      net_payable: 250,
      carried_forward_credit: 0,
    }
    h.when('workers', 'select', worker)
    h.when('worker_logs', 'select', logs)
    h.when('worker_advances', 'select', advances)
    h.when('v_worker_liabilities', 'select', liabilitiesRow)

    const res = await getWorkerDetail(WORKER_ID)

    expect(res.worker).toEqual(worker)
    expect(res.logs).toEqual(logs)
    expect(res.advances).toEqual(advances)
    expect(res.liabilities).toEqual({
      pending_wages: 400,
      pending_advances: 150,
      net_payable: 250,
      carried_forward_credit: 0,
    })
    expect(h.callsOf('worker_logs', 'limit')[0].args).toEqual([30])
    expect(h.callsOf('worker_advances', 'order')[0].args).toEqual([
      'advance_date',
      { ascending: false },
    ])
    expect(h.callsOf('v_worker_liabilities', 'eq')[0].args).toEqual(['worker_id', WORKER_ID])
    expect(h.callsOf('v_worker_liabilities', 'maybeSingle')).toHaveLength(1)
  })

  it('يرجع أصفاراً للالتزامات عندما لا يوجد صف في v_worker_liabilities', async () => {
    h.when('workers', 'select', { id: WORKER_ID, name: 'محمد' })
    h.when('worker_logs', 'select', [])
    h.when('worker_advances', 'select', [])
    h.when('v_worker_liabilities', 'select', null)

    const res = await getWorkerDetail(WORKER_ID)

    expect(res.liabilities).toEqual({
      pending_wages: 0,
      pending_advances: 0,
      net_payable: 0,
      carried_forward_credit: 0,
    })
  })

  it('يرجع worker = null ولا يجلب الالتزامات عند عدم وجود العامل', async () => {
    h.when('workers', 'select', null)

    const res = await getWorkerDetail(WORKER_ID)

    expect(res.worker).toBeNull()
    expect(res.logs).toEqual([])
    expect(res.advances).toEqual([])
    expect(h.callsOf('v_worker_liabilities', 'select')).toHaveLength(0)
  })

  it('يرمي رسالة عامة فقط عند خطأ جلب العامل', async () => {
    h.fail('workers', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getWorkerDetail(WORKER_ID)).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })

  it('يرفض معرف العامل الفاسد بخطأ تحقق عربي', async () => {
    await expect(getWorkerDetail('not-a-uuid')).rejects.toThrow('معرف العامل غير صالح')
    expect(h.callsOf('workers', 'select')).toHaveLength(0)
  })

  it('يرمي رسالة عامة فقط عند خطأ قراءة v_worker_liabilities', async () => {
    h.when('workers', 'select', { id: WORKER_ID, name: 'محمد' })
    h.when('worker_logs', 'select', [])
    h.when('worker_advances', 'select', [])
    h.fail('v_worker_liabilities', 'select', postgrestError('PGRST116', 'failed'))

    await expect(getWorkerDetail(WORKER_ID)).rejects.toThrow(GENERIC_ERROR_MESSAGE)
  })
})