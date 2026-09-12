'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff } from '@/lib/actions/guard'
import { z } from 'zod'
import { escapeIlike, pageSchema } from '@/lib/validations/list'
import {
  returnSurplusSchema,
  consumeSurplusSchema,
  scrapSurplusSchema,
  type ReturnSurplusInput,
  type ConsumeSurplusInput,
  type ScrapSurplusInput,
} from '@/lib/validations/surplus'

type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

// إرجاع فائض لبنك المواد
export async function returnSurplusToBank(
  input: ReturnSurplusInput
): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) {
      return { success: false, error: auth.error ?? 'غير مصرح لك (يرجى تسجيل الدخول)' }
    }
    const supabase = auth.supabase

    const parsed = returnSurplusSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { projectId, materialName, unit, quantity, estimatedValue, notes, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:return_surplus:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'return_surplus'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    const { data, error } = await supabase.rpc('rpc_return_surplus', {
      p_project_id: projectId,
      p_material_name: materialName,
      p_unit: unit,
      p_quantity: quantity,
      p_estimated_value: estimatedValue,
      p_notes: notes ?? undefined,
    })

    if (error) return { success: false, error: routeActionError('return_surplus', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'return_surplus', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('return_surplus', err) }
  }
}

// استهلاك فائض لمشروع آخر مع قفل الصفوف
export async function consumeSurplus(
  input: ConsumeSurplusInput
): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) {
      return { success: false, error: auth.error ?? 'غير مصرح لك (يرجى تسجيل الدخول)' }
    }
    const supabase = auth.supabase

    const parsed = consumeSurplusSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { surplusId, targetProjectId, consumeQuantity, notes, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:consume_surplus:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'consume_surplus'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    const { data, error } = await supabase.rpc('rpc_consume_surplus', {
      p_surplus_id: surplusId,
      p_target_project_id: targetProjectId,
      p_consume_qty: consumeQuantity,
      p_notes: notes ?? undefined,
    })

    if (error) return { success: false, error: routeActionError('consume_surplus', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'consume_surplus', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('consume_surplus', err) }
  }
}

// إتلاف / كهنة الفائض
export async function scrapSurplus(
  input: ScrapSurplusInput
): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) {
      return { success: false, error: auth.error ?? 'غير مصرح لك (يرجى تسجيل الدخول)' }
    }
    const supabase = auth.supabase

    const parsed = scrapSurplusSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { surplusId, reason, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:scrap_surplus:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'scrap_surplus'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    const { data, error } = await supabase.rpc('rpc_scrap_surplus', {
      p_surplus_id: surplusId,
      p_notes: reason,
    })

    if (error) return { success: false, error: routeActionError('scrap_surplus', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'scrap_surplus', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('scrap_surplus', err) }
  }
}

// جلب مخزون الفائض — ترقيم وبحث بالاسم في السيرفر
const surplusStatusSchema = z.enum(['available', 'consumed', 'scrapped'], { error: 'حالة المخزون غير صالحة' })

const surplusInventorySchema = pageSchema.extend({})

const SURPLUS_COLUMNS = `
        id,
        material_name,
        unit,
        quantity,
        initial_quantity,
        estimated_value,
        source_project_id,
        status,
        notes,
        created_at,
        source_project:projects(id, name)
      `

export async function getSurplusInventory(
  rawStatus: unknown = 'available',
  rawOpts: { page?: unknown; perPage?: unknown; q?: unknown } = {}
) {
  const statusParsed = surplusStatusSchema.safeParse(rawStatus)
  if (!statusParsed.success) throw new Error('حالة المخزون غير صالحة')
  const status = statusParsed.data

  const parsed = surplusInventorySchema.safeParse(rawOpts)
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const { page, perPage, q } = parsed.data
  const fromIdx = (page - 1) * perPage
  const toIdx = fromIdx + perPage - 1

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const applySurplusFilters = (query: any) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let filtered: any = query.eq('status', status)
      if (q) filtered = filtered.ilike('material_name', `%${escapeIlike(q)}%`)
      return filtered
    }

    const [rowsRes, totalRes] = await Promise.all([
      applySurplusFilters(supabase.from('surplus_bank').select(SURPLUS_COLUMNS))
        .order('created_at', { ascending: false })
        .range(fromIdx, toIdx),
      applySurplusFilters(
        supabase.from('surplus_bank').select('id', { count: 'exact', head: true })
      ),
    ])

    if (rowsRes.error) maskAndThrow('get_surplus_inventory', rowsRes.error)
    if (totalRes.error) maskAndThrow('get_surplus_inventory', totalRes.error)
    return {
      rows: rowsRes.data ?? [],
      total: totalRes.count ?? 0,
      page,
      perPage,
    }
  } catch (err) {
    maskAndThrow('get_surplus_inventory', err)
  }
}
