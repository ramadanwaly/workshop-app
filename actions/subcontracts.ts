'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff, requireOwner } from '@/lib/actions/guard'
import { escapeIlike, pageSchema } from '@/lib/validations/list'
import {
  createOrderSchema,
  paySubcontractSchema,
  voidPaymentSchema,
  closeOrderSchema,
  type CreateOrderInput,
  type PaySubcontractInput,
  type VoidPaymentInput,
  type CloseOrderInput,
} from '@/lib/validations/subcontracts'

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
// 1. إنشاء اتفاقية مقاول باطن - للمالك فقط
//    Accrual basis: ترفع تكلفة المشروع والالتزام بالمبلغ المتفق عليه فوراً
//    (عبر views قاعدة البيانات)، بينما الخزينة لا تتأثر هنا.
//    ملاحظة ترخيص: فحص (is_owner) يتم داخل الـ RPC نفسه في قاعدة البيانات
//    (app_private.is_owner داخل rpc_create_subcontract_order) — لا يعتمد على
//    طبقة الأكشن. أي طلب من غير المالك يُرفض برسالة P0001 تصل للعميل حرفيًا.
// ----------------------------------------------------------------------------
export async function createSubcontractOrder(
  input: CreateOrderInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = createOrderSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { projectId, contractorName, description, totalAgreedAmount, idempotencyKey } =
      parsed.data

    const rl = await checkRateLimit(supabase, `w:create_subcontract_order:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'create_subcontract_order'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_create_subcontract_order', {
      p_project_id: projectId,
      p_contractor_name: contractorName,
      p_description: description,
      p_total_agreed_amount: totalAgreedAmount,
    })

    if (error) return { success: false, error: routeActionError('create_subcontract_order', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'create_subcontract_order', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('create_subcontract_order', err) }
  }
}

// ----------------------------------------------------------------------------
// 2. سداد دفعة لمقاول باطن - للمالك فقط (حركة نقدية: خزينة OUT + تخفيض الالتزام)
//    ضد التكرار عبر قفل الصف (SELECT ... FOR UPDATE) داخل قاعدة البيانات.
//    ملاحظة ترخيص: فحص (is_owner) داخل rpc_pay_subcontract في قاعدة البيانات.
// ----------------------------------------------------------------------------
export async function paySubcontract(
  input: PaySubcontractInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = paySubcontractSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { orderId, amount, paymentDate, notes, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:pay_subcontract:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'pay_subcontract'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_pay_subcontract', {
      p_order_id: orderId,
      p_amount: amount,
      p_payment_date: paymentDate,
      p_notes: notes,
    })

    if (error) return { success: false, error: routeActionError('pay_subcontract', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'pay_subcontract', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('pay_subcontract', err) }
  }
}

// ----------------------------------------------------------------------------
// 3. إلغاء دفعة مقاول باطن - للمالك فقط (لا حذف، بل is_voided = true + إلغاء حركة الخزينة)
//    ملاحظة ترخيص: فحص (is_owner) داخل rpc_void_subcontract_payment في قاعدة البيانات.
// ----------------------------------------------------------------------------
export async function voidSubcontractPayment(
  input: VoidPaymentInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = voidPaymentSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { paymentId, reason, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:void_subcontract_payment:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'void_subcontract_payment'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_void_subcontract_payment', {
      p_payment_id: paymentId,
      p_reason: reason,
    })

    if (error) return { success: false, error: routeActionError('void_subcontract_payment', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'void_subcontract_payment', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('void_subcontract_payment', err) }
  }
}

// ----------------------------------------------------------------------------
// 4. إغلاق اتفاقية مقاول باطن - للمالك فقط (completed: يجب أن تكون مدفوعة بالكامل)
//    ملاحظة ترخيص: فحص (is_owner) داخل rpc_close_subcontract_order في قاعدة البيانات.
// ----------------------------------------------------------------------------
export async function closeSubcontractOrder(
  input: CloseOrderInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = closeOrderSchema.safeParse(input)
    if (!parsed.success) return { success: false, error: parsed.error.issues[0].message }

    const { orderId, status, reason, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:close_subcontract_order:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'close_subcontract_order'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: sanitizeDto(idempotency.cachedData) }
    }

    const { data, error } = await supabase.rpc('rpc_close_subcontract_order', {
      p_order_id: orderId,
      p_status: status,
      p_reason: reason,
    })

    if (error) return { success: false, error: routeActionError('close_subcontract_order', error) }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'close_subcontract_order', data)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: sanitizeDto(data), error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: sanitizeDto(data) }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('close_subcontract_order', err) }
  }
}

// ----------------------------------------------------------------------------
// 5. قراءة (بالصلاحية للعرض فقط دون تعامل مالي)
//    v_pending_liabilities  -> أرصدة مقاولي الباطن
//    subcontract_orders     -> قائمة الاتفاقيات (تعرض للمدير والمالك)
// ----------------------------------------------------------------------------
export async function getSubcontractOrders(rawOpts: {
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
    const applyOrderFilters = (query: any) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let filtered: any = query
      if (q) filtered = filtered.ilike('contractor_name', `%${escapeIlike(q)}%`)
      return filtered
    }

    const [rowsRes, totalRes] = await Promise.all([
      applyOrderFilters(
        supabase
          .from('subcontract_orders')
          .select('id, project_id, contractor_name, description, total_agreed_amount, status, created_at')
      )
        .order('created_at', { ascending: false })
        .range(fromIdx, toIdx),
      applyOrderFilters(
        supabase.from('subcontract_orders').select('id', { count: 'exact', head: true })
      ),
    ])

    if (rowsRes.error) maskAndThrow('get_subcontract_orders', rowsRes.error)
    if (totalRes.error) maskAndThrow('get_subcontract_orders', totalRes.error)
    return {
      rows: rowsRes.data ?? [],
      total: totalRes.count ?? 0,
      page,
      perPage,
    }
  } catch (err) {
    maskAndThrow('get_subcontract_orders', err)
  }
}

export async function getSubcontractLiabilities() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase
    
    const { data, error } = await supabase
      .from('v_pending_liabilities')
      .select('total_worker_liabilities, total_subcontract_liabilities, total_pending_liabilities')
      .maybeSingle()

    if (error) maskAndThrow('get_subcontract_liabilities', error)
    return data
  } catch (err) {
    maskAndThrow('get_subcontract_liabilities', err)
  }
}
