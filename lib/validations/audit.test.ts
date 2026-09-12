import { describe, expect, it } from 'vitest'
import { auditLogSchema } from './audit'

describe('auditLogSchema — سجل التدقيق الدائم', () => {
  it('يقبل قراءة افتراضية بلا فلاتر', () => {
    expect(auditLogSchema.safeParse({}).success).toBe(true)
  })

  it('يقبل إجراءً صالحاً من القائمة', () => {
    const parsed = auditLogSchema.safeParse({ action: 'remove_operating_exclusion' })
    expect(parsed.success).toBe(true)
  })

  it('يرفض الإجراء الغريب', () => {
    const parsed = auditLogSchema.safeParse({ action: 'hacked' })
    expect(parsed.success).toBe(false)
    if (!parsed.success) {
      expect(parsed.error.issues[0].message).toBe('الإجراء غير صالح')
    }
  })

  it('يرفض رقم صفحة غير صالح وعدد صفوف متجاوز', () => {
    expect(auditLogSchema.safeParse({ page: 0 }).success).toBe(false)
    expect(auditLogSchema.safeParse({ perPage: 999999 }).success).toBe(false)
  })

  it('يرفض نص بحث أطول من 100 حرف', () => {
    expect(auditLogSchema.safeParse({ q: 'س'.repeat(101) }).success).toBe(false)
  })
})
