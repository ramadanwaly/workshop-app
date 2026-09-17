'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff, requireOwner } from '@/lib/actions/guard'
import {
    runOperatingAllocationSchema,
    voidAllocationCycleSchema,
    voidAllocationLineSchema,
    addOperatingExclusionSchema,
    removeOperatingExclusionSchema,
    type RunOperatingAllocationInput,
    type VoidAllocationCycleInput,
    type VoidAllocationLineInput,
    type AddOperatingExclusionInput,
    type RemoveOperatingExclusionInput,
} from '@/lib/validations/operating'

type ActionResult<T = unknown> = {
    success: boolean
    data?: T
    error?: string
}

// ----------------------------------------------------------------------------
// 1. قراءة دورات توزيع مصاريف التشغيل (للموظفين: المالك والمدير)
// ----------------------------------------------------------------------------
export async function getOperatingAllocationCycles() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
    .from('operating_allocation_cycles')
    .select(`
        id,
        year_month,
        status,
        total_amount,
        eligible_project_ids,
        notes,
        is_voided,
        void_reason,
        created_at
    `)
    .order('year_month', { ascending: false })

    if (error) maskAndThrow('get_operating_allocation_cycles', error)
        return data
  } catch (err) {
    maskAndThrow('get_operating_allocation_cycles', err)
  }
}

// ----------------------------------------------------------------------------
// 2. قراءة استبعادات التوزيع (للموظفين)
// ----------------------------------------------------------------------------
export async function getOperatingAllocationExclusions() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
    .from('operating_allocation_exclusions')
    .select(`
        id,
        year_month,
        project_id,
        reason,
        created_at,
        project:projects(id, name)
    `)
    .order('year_month', { ascending: false })

    if (error) maskAndThrow('get_operating_allocation_exclusions', error)
        return data
  } catch (err) {
    maskAndThrow('get_operating_allocation_exclusions', err)
  }
}

// ----------------------------------------------------------------------------
// 3. تشغيل التوزيع يدوياً لشهر محدد — للمالك فقط
// ----------------------------------------------------------------------------
export async function runOperatingAllocation(
    input: RunOperatingAllocationInput
): Promise<ActionResult> {
    try {
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const parsed = runOperatingAllocationSchema.safeParse(input)
        if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

        const { yearMonth, idempotencyKey } = parsed.data

        const rl = await checkRateLimit(supabase, `w:run_operating_allocation:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
        const idempotency = await checkAndLockIdempotency(supabase, idempotencyKey, auth.userId, 'run_operating_allocation')
        if (idempotency.alreadyCompleted) return { success: true, data: idempotency.cachedData }

        const { data: rpcResult, error: rpcError } = await supabase
        .rpc('rpc_run_operating_allocation', { p_year_month: `${yearMonth}-01` })

        if (rpcError) return { success: false, error: routeActionError('run_operating_allocation', rpcError) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'run_operating_allocation', rpcResult)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: rpcResult, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: rpcResult }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('run_operating_allocation', err) }
    }
}

// ----------------------------------------------------------------------------
// 4. إلغاء دورة توزيع بالكامل — للمالك فقط
// ----------------------------------------------------------------------------
export async function voidOperatingAllocationCycle(
    input: VoidAllocationCycleInput
): Promise<ActionResult> {
    try {
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const parsed = voidAllocationCycleSchema.safeParse(input)
        if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

        const { cycleId, reason, idempotencyKey } = parsed.data

        const rl = await checkRateLimit(supabase, `w:void_operating_allocation_cycle:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
        const idempotency = await checkAndLockIdempotency(supabase, idempotencyKey, auth.userId, 'void_operating_allocation_cycle')
        if (idempotency.alreadyCompleted) return { success: true, data: idempotency.cachedData }

        const { data: rpcResult, error: rpcError } = await supabase
        .rpc('rpc_void_allocation_cycle', { p_cycle_id: cycleId, p_reason: reason })

        if (rpcError) return { success: false, error: routeActionError('void_operating_allocation_cycle', rpcError) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'void_operating_allocation_cycle', rpcResult)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: rpcResult, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: rpcResult }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('void_operating_allocation_cycle', err) }
    }
}

// ----------------------------------------------------------------------------
// 5. إلغاء سطر توزيع مفرد — للمالك فقط
// ----------------------------------------------------------------------------
export async function voidOperatingAllocationLine(
    input: VoidAllocationLineInput
): Promise<ActionResult> {
    try {
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const parsed = voidAllocationLineSchema.safeParse(input)
        if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

        const { adjustmentId, reason, idempotencyKey } = parsed.data

        const rl = await checkRateLimit(supabase, `w:void_operating_allocation_line:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
        const idempotency = await checkAndLockIdempotency(supabase, idempotencyKey, auth.userId, 'void_operating_allocation_line')
        if (idempotency.alreadyCompleted) return { success: true, data: idempotency.cachedData }

        const { data: rpcResult, error: rpcError } = await supabase
        .rpc('rpc_void_allocation_line', { p_adjustment_id: adjustmentId, p_reason: reason })

        if (rpcError) return { success: false, error: routeActionError('void_operating_allocation_line', rpcError) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'void_operating_allocation_line', rpcResult)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: rpcResult, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: rpcResult }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('void_operating_allocation_line', err) }
    }
}

// ----------------------------------------------------------------------------
// 6. إضافة استبعاد مشروع من توزيع شهر محدد — للمالك فقط
// ----------------------------------------------------------------------------
export async function addOperatingAllocationExclusion(
    input: AddOperatingExclusionInput
): Promise<ActionResult> {
    try {
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const parsed = addOperatingExclusionSchema.safeParse(input)
        if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

        const { yearMonth, projectId, reason, idempotencyKey } = parsed.data

        const rl = await checkRateLimit(supabase, `w:add_operating_exclusion:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
        const idempotency = await checkAndLockIdempotency(supabase, idempotencyKey, auth.userId, 'add_operating_exclusion')
        if (idempotency.alreadyCompleted) return { success: true, data: idempotency.cachedData }

        const { data: rpcResult, error: rpcError } = await supabase
        .rpc('rpc_add_operating_exclusion', { p_year_month: `${yearMonth}-01`, p_project_id: projectId, p_reason: reason })

        if (rpcError) return { success: false, error: routeActionError('add_operating_exclusion', rpcError) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'add_operating_exclusion', rpcResult)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: rpcResult, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: rpcResult }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('add_operating_exclusion', err) }
    }
}

// ----------------------------------------------------------------------------
// 7. إزالة استبعاد مشروع من توزيع شهر محدد — للمالك فقط
// ----------------------------------------------------------------------------
export async function removeOperatingAllocationExclusion(
    input: RemoveOperatingExclusionInput
): Promise<ActionResult> {
    try {
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const parsed = removeOperatingExclusionSchema.safeParse(input)
        if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

        const { yearMonth, projectId, reason, idempotencyKey } = parsed.data

        const rl = await checkRateLimit(supabase, `w:remove_operating_exclusion:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
        const idempotency = await checkAndLockIdempotency(supabase, idempotencyKey, auth.userId, 'remove_operating_exclusion')
        if (idempotency.alreadyCompleted) return { success: true, data: idempotency.cachedData }

        const { data: rpcResult, error: rpcError } = await supabase
        .rpc('rpc_remove_operating_exclusion', { p_year_month: `${yearMonth}-01`, p_project_id: projectId, p_reason: reason })

        if (rpcError) return { success: false, error: routeActionError('remove_operating_exclusion', rpcError) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'remove_operating_exclusion', rpcResult)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: rpcResult, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: rpcResult }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('remove_operating_exclusion', err) }
    }
}