import { z } from 'zod'
import { escapeIlike, pageSchema } from './list'

// ----------------------------------------------------------------------------
// P2-06 — قراءة سجل التدقيق الدائم (للمالك فقط).
// ----------------------------------------------------------------------------

export const AUDIT_ACTIONS = [
  'void_treasury',
  'void_subcontract_payment',
  'close_subcontract_order',
  'return_surplus',
  'consume_surplus',
  'scrap_surplus',
  'run_operating_allocation',
  'void_allocation_cycle',
  'void_allocation_line',
  'add_operating_exclusion',
  'remove_operating_exclusion',
  'correct_attendance',
] as const

export type AuditAction = (typeof AUDIT_ACTIONS)[number]

export const auditLogSchema = pageSchema.extend({
  action: z.enum(AUDIT_ACTIONS, { error: 'الإجراء غير صالح' }).optional(),
})

export type AuditLogInput = z.infer<typeof auditLogSchema>

export { escapeIlike }
