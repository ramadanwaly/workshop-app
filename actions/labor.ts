'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff, requireOwner } from '@/lib/actions/guard'
import { z } from 'zod'
import { escapeIlike, pageSchema } from '@/lib/validations/list'
import { pastDateSchema } from '@/lib/validations/dates'
import {
  attendanceSchema,
  advanceSchema,
  settlementSchema,
  correctAttendanceSchema,
  type AttendanceInput,
  type AdvanceInput,
  type SettlementInput,
  type CorrectAttendanceInput,
} from '@/lib/validations/labor'
import {
  createWorkerSchema,
  updateWorkerSchema,
  toggleWorkerStatusSchema,
  type CreateWorkerInput,
  type UpdateWorkerInput,
  type ToggleWorkerStatusInput,
} from '@/lib/validations/workers'

function sanitizeDto<T>(obj: T): T {
  if (obj && typeof obj === 'object') {
    const copy = { ...obj } as Record<string, unknown>
    delete copy.created_by
    delete copy.voided_by
    delete copy.updated_by
    return copy as T
  }
  return obj
}

type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

// ----------------------------------------------------------------------------
// 1. فحص قبل تسجيل الحضور: هل للعامل سجل(s) في هذا اليوم؟ (قراءة سريعة)
//    يستخدمه حوار التسجيل لعرض تأكيد «مسجل اليوم بالفعل» قبل الإضافة.
//    قرار المنتج (المالك): السماح باليوم المقسم مع تأكيد صريح، لا منع.
// ----------------------------------------------------------------------------
const workerDayAttendanceSchema = z.object({
  workerId: z.string().uuid('معرف العامل غير صالح'),
  workDate: pastDateSchema('تاريخ العمل مطلوب'),
})

export async function getWorkerDayAttendance(
  input: { workerId?: unknown; workDate?: unknown }
): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = workerDayAttendanceSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }
    const { workerId, workDate } = parsed.data

    const { data, error } = await supabase
      .from('worker_logs')
      .select('id, fraction, daily_rate, project_id')
      .eq('worker_id', workerId)
      .eq('log_date', workDate)
      .order('created_at', { ascending: true })
      .limit(10)

    if (error) return { success: false, error: routeActionError('get_worker_day_attendance', error) }
    return { success: true, data: data ?? [] }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('get_worker_day_attendance', err) }
  }
}

// ----------------------------------------------------------------------------
// 1b. تسجيل حضور عامل (مشروع أو عمل عام) - للمدير والمالك
//     labor cost = daily_rate x fraction (تحسب في قاعدة البيانات، ليست من العميل)
// ----------------------------------------------------------------------------
export async function recordWorkerAttendance(
  input: AttendanceInput
): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = attendanceSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { workerId, projectId, workDate, fraction, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:record_attendance:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'record_attendance'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_record_attendance', {
      p_worker_id: workerId,
      p_project_id: projectId || null,
      p_work_date: workDate,
      p_fraction: fraction,
    })

    if (error) return { success: false, error: routeActionError('record_attendance', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'record_attendance', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('record_attendance', err) }
  }
}

// ----------------------------------------------------------------------------
// تصحيح حضور عامل - للمالك فقط (تحديث النسبة أو المشروع مع سبب مسجل)
// ----------------------------------------------------------------------------
export async function correctWorkerAttendance(
  input: CorrectAttendanceInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = correctAttendanceSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { logId, newFraction, newProjectId, correctionReason, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:correct_attendance:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'correct_attendance'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_correct_attendance', {
      p_log_id: logId,
      p_new_fraction: newFraction,
      p_new_project_id: newProjectId || null,
      p_correction_reason: correctionReason,
    })

    if (error) return { success: false, error: routeActionError('correct_attendance', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'correct_attendance', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('correct_attendance', err) }
  }
}


// ----------------------------------------------------------------------------
// 2. إصدار سلفة لعامل - للمالك فقط (حركة مالية: خزينة OUT + التزام على العامل)
//    ملاحظة ترخيص: فحص (is_owner) داخل rpc_record_advance في قاعدة البيانات.
// ----------------------------------------------------------------------------
export async function recordWorkerAdvance(
  input: AdvanceInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = advanceSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { workerId, amount, advanceDate, notes, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:record_advance:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'record_advance'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_record_advance', {
      p_worker_id: workerId,
      p_amount: amount,
      p_advance_date: advanceDate,
      p_notes: notes,
    })

    if (error) return { success: false, error: routeActionError('record_advance', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'record_advance', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('record_advance', err) }
  }
}

// ----------------------------------------------------------------------------
// 3. تسوية العامل - للمالك فقط (قفل الصفوف + تسوية داخل قاعدة البيانات)
//    لا يثق في حسابات العميل إطلاقاً
//    ملاحظة ترخيص: فحص (is_owner) داخل rpc_settle_worker في قاعدة البيانات.
// ----------------------------------------------------------------------------
export async function settleWorker(
  input: SettlementInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = settlementSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { workerId, notes, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:settle_worker:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'settle_worker'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_settle_worker', {
      p_worker_id: workerId,
      p_notes: notes,
    })

    if (error) return { success: false, error: routeActionError('settle_worker', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'settle_worker', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('settle_worker', err) }
  }
}

// ----------------------------------------------------------------------------
// 4. قراءة بيانات العامل والتزاماته (من قاعدة البيانات الموثوقة فقط)
// ----------------------------------------------------------------------------
export async function getWorkerLiabilities() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase
    
    const { data, error } = await supabase
      .from('v_pending_liabilities')
      .select('total_worker_liabilities, total_subcontract_liabilities, total_pending_liabilities')
      .maybeSingle()

    if (error) maskAndThrow('get_worker_liabilities', error)
    return data
  } catch (err) {
    maskAndThrow('get_worker_liabilities', err)
  }
}

export async function getWorkers(rawOpts: {
  page?: unknown
  perPage?: unknown
  q?: unknown
} = {}) {
  const parsed = pageSchema.safeParse(rawOpts)
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const { page, perPage, q } = parsed.data
  const fromIdx = (page - 1) * perPage
  const toIdx = fromIdx + perPage - 1

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const applyWorkerFilters = (query: any) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let filtered: any = query
      if (q) filtered = filtered.ilike('name', `%${escapeIlike(q)}%`)
      return filtered
    }

    const [rowsRes, totalRes] = await Promise.all([
      applyWorkerFilters(
        supabase.from('workers').select('id, name, phone, daily_rate, is_active')
      )
        .order('is_active', { ascending: false })
        .order('name', { ascending: true })
        .range(fromIdx, toIdx),
      applyWorkerFilters(
        supabase.from('workers').select('id', { count: 'exact', head: true })
      ),
    ])

    if (rowsRes.error) maskAndThrow('get_workers', rowsRes.error)
    if (totalRes.error) maskAndThrow('get_workers', totalRes.error)
    return {
      rows: rowsRes.data ?? [],
      total: totalRes.count ?? 0,
      page,
      perPage,
    }
  } catch (err) {
    maskAndThrow('get_workers', err)
  }
}

// ----------------------------------------------------------------------------
// 5. إنشاء عامل جديد - للمالك فقط
// ----------------------------------------------------------------------------
export async function createWorker(
  input: CreateWorkerInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = createWorkerSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { name, phone, dailyRate, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:create_worker:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'create_worker'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase
      .from('workers')
      .insert({ name, phone: phone || null, daily_rate: dailyRate })
      .select()
      .single()

    if (error) return { success: false, error: routeActionError('create_worker', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'create_worker', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('create_worker', err) }
  }
}

// ----------------------------------------------------------------------------
// 6. تعديل بيانات عامل - للمالك فقط
// ----------------------------------------------------------------------------
export async function updateWorker(
  input: UpdateWorkerInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = updateWorkerSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { workerId, name, phone, dailyRate, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:update_worker:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'update_worker'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase
      .from('workers')
      .update({ name, phone: phone || null, daily_rate: dailyRate })
      .eq('id', workerId)
      .select()
      .single()

    if (error) return { success: false, error: routeActionError('update_worker', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'update_worker', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('update_worker', err) }
  }
}

// ----------------------------------------------------------------------------
// 7. تبديل حالة العامل (نشط/موقوف) - للمالك فقط
// ----------------------------------------------------------------------------
export async function toggleWorkerStatus(
  input: ToggleWorkerStatusInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = toggleWorkerStatusSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { workerId, isActive, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:toggle_worker_status:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'toggle_worker_status'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase
      .from('workers')
      .update({ is_active: isActive })
      .eq('id', workerId)
      .select()
      .single()

    if (error) return { success: false, error: routeActionError('toggle_worker_status', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'toggle_worker_status', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('toggle_worker_status', err) }
  }
}

// ----------------------------------------------------------------------------
// 8. تفاصيل عامل: بيانات + حضور + سلف + التزامات (من قاعدة البيانات فقط)
// ----------------------------------------------------------------------------
const workerIdSchema = z.object({ workerId: z.string().uuid('معرف العامل غير صالح') })

export async function getWorkerDetail(rawWorkerId: string) {
  const parsed = workerIdSchema.safeParse({ workerId: rawWorkerId })
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const workerId = parsed.data.workerId

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

  const { data: worker, error: workerErr } = await supabase
    .from('workers')
    .select('id, name, phone, daily_rate, is_active')
    .eq('id', workerId)
    .maybeSingle()

  if (workerErr) maskAndThrow('get_worker_detail', workerErr)

  if (!worker) {
    return {
      worker: null,
      logs: [],
      advances: [],
      liabilities: {
        pending_wages: 0,
        pending_advances: 0,
        net_payable: 0,
        carried_forward_credit: 0,
      },
    }
  }

  // آخر 30 سجل حضور + السلف غير المسددة + الالتزامات: الثلاثة مستقلة عن
  // بعضها (تحتاج worker_id فقط من المدخلات)، فتُنفَّذ معًا بدل التتابع.
  // لا تغيير في المنطق ولا في ترتيب فحص الأخطاء.
  const [logsRes, advancesRes, liabRes] = await Promise.all([
    // آخر 30 سجل حضور مع اسم المشروع
    supabase
      .from('worker_logs')
      .select('id, log_date, fraction, daily_rate, calculated_amount, is_settled, notes, projects(name)')
      .eq('worker_id', workerId)
      .order('log_date', { ascending: false })
      .limit(30),
    // السلف غير المسددة
    supabase
      .from('worker_advances')
      .select('id, amount, advance_date, notes')
      .eq('worker_id', workerId)
      .eq('is_settled', false)
      .order('advance_date', { ascending: false }),
    // التزامات العامل غير المسددة محسوبة في قاعدة البيانات (v_worker_liabilities)
    // — لا يُحسب أي رقم مالي في TypeScript (SYSTEM_PROMPT القاعدة 3)
    supabase
      .from('v_worker_liabilities')
      .select('unsettled_wages, unsettled_advances, net_payable, carried_forward_credit')
      .eq('worker_id', workerId)
      .maybeSingle(),
  ])

  const { data: logs, error: logsErr } = logsRes
  if (logsErr) maskAndThrow('get_worker_detail', logsErr)

  const { data: advances, error: advancesErr } = advancesRes
  if (advancesErr) maskAndThrow('get_worker_detail', advancesErr)

  const { data: liab, error: liabErr } = liabRes
  if (liabErr) maskAndThrow('get_worker_detail', liabErr)

  return {
    worker,
    logs: logs ?? [],
    advances: advances ?? [],
    liabilities: {
      pending_wages: liab?.unsettled_wages ?? 0,
      pending_advances: liab?.unsettled_advances ?? 0,
      net_payable: liab?.net_payable ?? 0,
      carried_forward_credit: liab?.carried_forward_credit ?? 0,
    },
  }
  } catch (err) {
    maskAndThrow('get_worker_detail', err)
  }
}