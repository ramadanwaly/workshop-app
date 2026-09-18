'use server'
import { revalidatePath } from 'next/cache'

import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff, requireOwner } from '@/lib/actions/guard'
import { z } from 'zod'
import { escapeIlike, pageSchema } from '@/lib/validations/list'
import {
    injectFundingSchema,
    recordExpenseSchema,
    voidTransactionSchema,
    type InjectFundingInput,
    type RecordExpenseInput,
    type VoidTransactionInput,
} from '@/lib/validations/treasury'

type ActionResult<T = unknown> = {
    success: boolean
    data?: T
    error?: string
}

// ----------------------------------------------------------------------------
// 1. حقن أموال المالك (Owner Funding Injection) - للمالك فقط
// ----------------------------------------------------------------------------
export async function injectOwnerFunding(
    input: InjectFundingInput
): Promise<ActionResult> {
    try {

        // أ. التحقق من الهوية والصلاحية
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        // ب. التحقق من المدخلات بـ Zod
        const parsed = injectFundingSchema.safeParse(input)
        if (!parsed.success) {
            return { success: false, error: parsed.error.issues[0].message }
        }

        const { amount, description, idempotencyKey } = parsed.data

        // ج. فحص منع التكرار والإدراج عبر RPC الذري
        const rl = await checkRateLimit(supabase, `w:inject_owner_funding:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }

        const { data: transaction, error: rpcError } = await supabase.rpc('rpc_record_treasury_transaction', {
            p_idempotency_key: idempotencyKey,
            p_action: 'inject_owner_funding',
            p_transaction_type: 'in',
            p_category: 'owner_funding',
            p_subcategory: null,
            p_amount: amount,
            p_project_id: null,
            p_is_direct_owner: false,
            p_description: description || 'تمويل نقدي من المالك'
        })

        if (rpcError) {
            return { success: false, error: routeActionError('inject_owner_funding', rpcError) }
        }

        if (transaction && typeof transaction === 'object') {
            const tx = transaction as Record<string, unknown>
            delete tx.created_by
            delete tx.voided_by
        }

        revalidatePath('/', 'layout')
        return { success: true, data: transaction }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('inject_owner_funding', err) }
    }
}

// ----------------------------------------------------------------------------
// 2. تسجيل مصروف (Record Expense) - للمدير والمالك
// ----------------------------------------------------------------------------
export async function recordExpense(
    input: RecordExpenseInput
): Promise<ActionResult> {
    try {

        // أ. التحقق من الهوية
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        // ب. التحقق بـ Zod
        const parsed = recordExpenseSchema.safeParse(input)
        if (!parsed.success) {
            return { success: false, error: parsed.error.issues[0].message }
        }

        const {
            category,
            subcategory,
            amount,
            description,
            projectId,
            isDirectOwnerPayment,
            idempotencyKey,
        } = parsed.data

        // ج-١. التحقق من صلاحية سداد المالك المباشر
        if (isDirectOwnerPayment) {
            const ownerAuth = await requireOwner()
            if (!ownerAuth.userId) {
                return { success: false, error: 'تحديد سداد المالك المباشر يتطلب صلاحيات المالك فقط' }
            }
        }

        // ج-٢. فحص منع التكرار والإدراج عبر RPC الذري
        const rl = await checkRateLimit(supabase, `w:record_expense:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }

        const { data: transaction, error: rpcError } = await supabase.rpc('rpc_record_treasury_transaction', {
            p_idempotency_key: idempotencyKey,
            p_action: 'record_expense',
            p_transaction_type: 'out',
            p_category: category,
            p_subcategory: subcategory || null,
            p_amount: amount,
            p_project_id: projectId || null,
            p_is_direct_owner: isDirectOwnerPayment,
            p_description: description || null
        })

        if (rpcError) {
            return { success: false, error: routeActionError('record_expense', rpcError) }
        }

        if (transaction && typeof transaction === 'object') {
            const tx = transaction as Record<string, unknown>
            delete tx.created_by
            delete tx.voided_by
        }

        revalidatePath('/', 'layout')
        return { success: true, data: transaction }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('record_expense', err) }
    }
}

// ----------------------------------------------------------------------------
// 3. إلغاء حركة مالية (Void Transaction) - للمالك فقط (No Hard Delete)
// ----------------------------------------------------------------------------
export async function voidTransaction(
    input: VoidTransactionInput
): Promise<ActionResult> {
    try {

        // أ. التحقق من الهوية والصلاحية
        const auth = await requireOwner()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        // ب. التحقق بـ Zod
        const parsed = voidTransactionSchema.safeParse(input)
        if (!parsed.success) {
            return { success: false, error: parsed.error.issues[0].message }
        }

        const { transactionId, reason, idempotencyKey } = parsed.data

        // ج. فحص حد المعدل واستدعاء الـ RPC الذري
        const rl = await checkRateLimit(supabase, `w:void_transaction:${auth.userId}`, 30)
        if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }

        const { data: updatedTx, error: rpcError } = await supabase.rpc('rpc_void_treasury_transaction', {
            p_idempotency_key: idempotencyKey,
            p_action: 'void_transaction',
            p_transaction_id: transactionId,
            p_reason: reason,
        })

        if (rpcError) {
            return { success: false, error: routeActionError('void_transaction', rpcError) }
        }

        if (updatedTx && typeof updatedTx === 'object') {
            const tx = updatedTx as Record<string, unknown>
            delete tx.created_by
            delete tx.voided_by
        }

        revalidatePath('/', 'layout')
        return { success: true, data: updatedTx }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('void_transaction', err) }
    }
}

// ----------------------------------------------------------------------------
// 4. قراءة رصيد الخزينة الموثوق (Authoritative View)
// ----------------------------------------------------------------------------
export async function getTreasuryBalance() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
    .from('v_treasury_balance')
    .select('current_balance, total_in, total_out')
    .single()

    if (error) maskAndThrow('get_treasury_balance', error)
        return data
  } catch (err) {
    maskAndThrow('get_treasury_balance', err)
  }
}

// ----------------------------------------------------------------------------
// 5. قراءة دفتر الخزينة (Treasury Ledger) — ترقيم وبحث وفلترة في السيرفر
// ----------------------------------------------------------------------------
const LEDGER_CATEGORIES = [
  'owner_funding',
  'material',
  'freight',
  'advance',
  'settlement',
  'subcontract_payment',
  'general_expense',
  'carried_forward_advance',
  'other',
  'workshop_operating',
] as const

const LEDGER_COLUMNS = `
    id,
    transaction_type,
    category,
    subcategory,
    amount,
    description,
    is_direct_owner_payment,
    is_voided,
    voided_at,
    void_reason,
    created_at,
    project:projects(id, name)
    `

const treasuryLedgerSchema = pageSchema.extend({
  category: z.enum(LEDGER_CATEGORIES, { error: 'تصنيف المصروف غير صالح' }).optional(),
  from: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'صيغة التاريخ غير صالحة (YYYY-MM-DD)')
    .optional(),
  to: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'صيغة التاريخ غير صالحة (YYYY-MM-DD)')
    .optional(),
  type: z.enum(['in', 'out'], { error: 'نوع الحركة غير صالح' }).optional(),
})

export async function getTreasuryLedger(rawOpts: {
  page?: unknown
  perPage?: unknown
  q?: unknown
  category?: unknown
  from?: unknown
  to?: unknown
  type?: unknown
} = {}) {
  const parsed = treasuryLedgerSchema.safeParse(rawOpts)
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const { page, perPage, q, category, from, to, type } = parsed.data
  const fromIdx = (page - 1) * perPage
  const toIdx = fromIdx + perPage - 1
  // تصفية مشتركة لاستعلام الصفوف واستعلام العدد (any لتجاوز تضييق أنواع الباني)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const applyLedgerFilters = (query: any) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let filtered: any = query
    if (q) filtered = filtered.ilike('description', `%${escapeIlike(q)}%`)
    if (category) filtered = filtered.eq('category', category)
    if (type) filtered = filtered.eq('transaction_type', type)
    if (from) filtered = filtered.gte('created_at', from)
    if (to) filtered = filtered.lt('created_at', `${to}T23:59:59.999Z`)
    return filtered
  }

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const [rowsRes, totalRes] = await Promise.all([
      applyLedgerFilters(supabase.from('treasury_transactions').select(LEDGER_COLUMNS))
        .order('created_at', { ascending: false })
        .range(fromIdx, toIdx),
      applyLedgerFilters(
        supabase.from('treasury_transactions').select('id', { count: 'exact', head: true })
      ),
    ])

    if (rowsRes.error) maskAndThrow('get_treasury_ledger', rowsRes.error)
    if (totalRes.error) maskAndThrow('get_treasury_ledger', totalRes.error)
    return {
      rows: rowsRes.data ?? [],
      total: totalRes.count ?? 0,
      page,
      perPage,
    }
  } catch (err) {
    maskAndThrow('get_treasury_ledger', err)
  }
}
