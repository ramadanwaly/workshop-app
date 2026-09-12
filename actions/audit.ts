'use server'

import { maskAndThrow } from '@/lib/server-errors'
import { requireOwner } from '@/lib/actions/guard'
import { z } from 'zod'
import { escapeIlike, pageSchema } from '@/lib/validations/list'
import { AUDIT_ACTIONS } from '@/lib/validations/audit'

// ----------------------------------------------------------------------------
// P2-06 — قراءة سجل التدقيق الدائم (للمالك فقط).
// السجل كتابة فقط عبر القاعدة (triggers + RPCs)؛ هذا الأكشن قراءة مرقّمة.
// ----------------------------------------------------------------------------

const AUDIT_COLUMNS = `
    id,
    occurred_at,
    actor_id,
    action,
    entity_table,
    entity_id,
    reason,
    details,
    created_at
    `

const auditLogReadSchema = pageSchema.extend({
  action: z.enum(AUDIT_ACTIONS, { error: 'الإجراء غير صالح' }).optional(),
})

export async function getAuditLog(rawOpts: {
  page?: unknown
  perPage?: unknown
  q?: unknown
  action?: unknown
} = {}) {
  const parsed = auditLogReadSchema.safeParse(rawOpts)
  if (!parsed.success) throw new Error(parsed.error.issues[0].message)
  const { page, perPage, q, action } = parsed.data
  const fromIdx = (page - 1) * perPage
  const toIdx = fromIdx + perPage - 1
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const applyAuditFilters = (query: any) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let filtered: any = query
    if (q) filtered = filtered.ilike('reason', `%${escapeIlike(q)}%`)
    if (action) filtered = filtered.eq('action', action)
    return filtered
  }

  try {
    const auth = await requireOwner()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const [rowsRes, totalRes] = await Promise.all([
      applyAuditFilters(supabase.from('audit_log').select(AUDIT_COLUMNS))
        .order('occurred_at', { ascending: false })
        .range(fromIdx, toIdx),
      applyAuditFilters(
        supabase.from('audit_log').select('id', { count: 'exact', head: true })
      ),
    ])

    if (rowsRes.error) maskAndThrow('get_audit_log', rowsRes.error)
    if (totalRes.error) maskAndThrow('get_audit_log', totalRes.error)
    return {
      rows: rowsRes.data ?? [],
      total: totalRes.count ?? 0,
      page,
      perPage,
    }
  } catch (err) {
    maskAndThrow('get_audit_log', err)
  }
}
