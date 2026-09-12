'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff, requireOwner } from '@/lib/actions/guard'
import { z } from 'zod'
import type { Database } from '@/types/database.types'
import {
  createProjectSchema,
  updateProjectSchema,
  updateProjectStatusSchema,
  type CreateProjectInput,
  type UpdateProjectInput,
  type UpdateProjectStatusInput,
} from '@/lib/validations/projects'

type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

// ----------------------------------------------------------------------------
// قراءة جميع المشاريع (تتبع سياسات RLS)
// ----------------------------------------------------------------------------
export async function getProjects() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    
    const { data, error } = await auth.supabase
      .from('projects')
      .select('id, name')
      .order('name', { ascending: true })

    if (error) maskAndThrow('get_projects', error)
    return data
  } catch (err) {
    maskAndThrow('get_projects', err)
  }
}

// ----------------------------------------------------------------------------
// 1. إنشاء مشروع جديد (Create Project) — للمالك والمدير
// ----------------------------------------------------------------------------
export async function createProject(
  input: CreateProjectInput
): Promise<ActionResult> {
  try {
    // أ. التحقق من الهوية (للمالك والمدير)
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    // ب. التحقق من المدخلات بـ Zod
    const parsed = createProjectSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { name, description, idempotencyKey } = parsed.data

    // ج. فحص منع التكرار (Idempotency)

    const rl = await checkRateLimit(supabase, `w:create_project:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'create_project'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // د. إدراج المشروع
    const { data: project, error: insertError } = await supabase
      .from('projects')
      .insert({
        name,
        description: description || null,
      })
      .select()
      .single()

    if (insertError) {
      return { success: false, error: routeActionError('create_project', insertError) }
    }

    revalidatePath('/', 'layout')
    // هـ. تأكيد اكتمال مفتاح منع التكرار
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'create_project', project)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: project, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: project }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('create_project', err) }
  }
}

// ----------------------------------------------------------------------------
// 2. تعديل مشروع (Update Project) — للمالك والمدير
// ----------------------------------------------------------------------------
export async function updateProject(
  input: UpdateProjectInput
): Promise<ActionResult> {
  try {
    // أ. التحقق من الهوية (للمالك والمدير)
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    // ب. التحقق من المدخلات بـ Zod
    const parsed = updateProjectSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { projectId, name, description, idempotencyKey } = parsed.data

    // ج. فحص منع التكرار

    const rl = await checkRateLimit(supabase, `w:update_project:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'update_project'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // د. بناء كائن التحديث (لا تحديث القيم غير المحددة)
    const updatePayload: Database['public']['Tables']['projects']['Update'] = {}
    if (name !== undefined) updatePayload.name = name
    if (description !== undefined) updatePayload.description = description || null

    if (Object.keys(updatePayload).length === 0) {
      return { success: false, error: 'لم يتم تحديد أي حقول للتعديل' }
    }

    // هـ. تحديث المشروع
    const { data: project, error: updateError } = await supabase
      .from('projects')
      .update(updatePayload)
      .eq('id', projectId)
      .select()
      .single()

    if (updateError) {
      return { success: false, error: routeActionError('update_project', updateError) }
    }

    revalidatePath('/', 'layout')
    // و. تأكيد اكتمال مفتاح منع التكرار
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'update_project', project)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: project, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: project }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('update_project', err) }
  }
}

// ----------------------------------------------------------------------------
// 3. تغيير حالة مشروع (Update Project Status) — للمالك فقط
// ----------------------------------------------------------------------------
export async function updateProjectStatus(
  input: UpdateProjectStatusInput
): Promise<ActionResult> {
  try {
    // أ. التحقق من الهوية والصلاحية (للمالك فقط)
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    // ب. التحقق من المدخلات بـ Zod
    const parsed = updateProjectStatusSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { projectId, status, idempotencyKey } = parsed.data

    // ج. فحص منع التكرار

    const rl = await checkRateLimit(supabase, `w:update_project_status:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'update_project_status'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // د. تحديث الحالة
    const { data: project, error: updateError } = await supabase
      .from('projects')
      .update({ status })
      .eq('id', projectId)
      .select()
      .single()

    if (updateError) {
      return { success: false, error: routeActionError('update_project_status', updateError) }
    }

    revalidatePath('/', 'layout')
    // هـ. تأكيد اكتمال مفتاح منع التكرار
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'update_project_status', project)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: project, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: project }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('update_project_status', err) }
  }
}

// ----------------------------------------------------------------------------
// 4. جلب الحركات التفصيلية للمشروع (Project Transactions Ledger)
// ----------------------------------------------------------------------------
const projectIdSchema = z.object({ projectId: z.string().uuid('معرف المشروع غير صالح') })

const transactionsLimitSchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(100),
})

export async function getProjectTransactions(
  rawProjectId: string,
  rawOpts: { limit?: unknown } = {}
) {
  const parsed = projectIdSchema.safeParse({ projectId: rawProjectId })
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const projectId = parsed.data.projectId

  const limitParsed = transactionsLimitSchema.safeParse(rawOpts)
  if (!limitParsed.success) throw new Error('حد القراءة غير صالح')
  const limit = limitParsed.data.limit

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

  const [treasuryRes, workerLogsRes, subcontractsRes, adjustmentsRes] = await Promise.all([
    supabase
      .from('treasury_transactions')
      .select('id, transaction_type, category, subcategory, amount, description, is_direct_owner_payment, is_voided, created_at')
      .eq('project_id', projectId)
      .order('created_at', { ascending: false })
      .limit(limit),
    supabase
      .from('worker_logs')
      .select('id, log_date, fraction, daily_rate, calculated_amount, is_settled, notes, workers(name)')
      .eq('project_id', projectId)
      .order('log_date', { ascending: false })
      .limit(limit),
    supabase
      .from('subcontract_orders')
      .select('id, contractor_name, description, total_agreed_amount, status, created_at')
      .eq('project_id', projectId)
      .order('created_at', { ascending: false })
      .limit(limit),
    supabase
      .from('project_cost_adjustments')
      .select('id, adjustment_type, amount, notes, created_at, surplus_bank(material_name, unit)')
      .eq('project_id', projectId)
      .order('created_at', { ascending: false })
      .limit(limit),
  ])

  if (treasuryRes.error) maskAndThrow('get_project_transactions', treasuryRes.error)
  if (workerLogsRes.error) maskAndThrow('get_project_transactions', workerLogsRes.error)
  if (subcontractsRes.error) maskAndThrow('get_project_transactions', subcontractsRes.error)
  if (adjustmentsRes.error) maskAndThrow('get_project_transactions', adjustmentsRes.error)

  return {
    treasuryTransactions: treasuryRes.data,
    workerLogs: workerLogsRes.data,
    subcontractOrders: subcontractsRes.data,
    costAdjustments: adjustmentsRes.data,
  }
  } catch (err) {
    maskAndThrow('get_project_transactions', err)
  }
}

// ----------------------------------------------------------------------------
// 5. جلب تفاصيل مشروع (Project Detail) — للقراءة
// ----------------------------------------------------------------------------
export async function getProjectDetail(rawProjectId: string) {
  const parsed = projectIdSchema.safeParse({ projectId: rawProjectId })
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const projectId = parsed.data.projectId

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
      .from('projects')
      .select('id, name, description, status')
      .eq('id', projectId)
      .maybeSingle()

    if (error) maskAndThrow('get_project_detail', error)
    return data
  } catch (err) {
    maskAndThrow('get_project_detail', err)
  }
}

