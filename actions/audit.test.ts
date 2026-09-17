import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import type { PostgrestError } from '@supabase/supabase-js'
import type { SupabaseHarness } from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

import { createSupabaseHarness } from '@/test/helpers/supabase-harness'
import { getAuditLog } from './audit'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const postgrestError = (code: string, message: string): PostgrestError => ({
    name: 'PostgrestError',
    code,
    message,
    details: '',
    hint: '',
    toJSON: () => ({
        name: 'PostgrestError',
        code,
        message,
        details: '',
        hint: '',
    }),
})

describe('getAuditLog — سجل التدقيق الدائم', () => {
    beforeEach(() => {
        h.reset()
        h.state.user = { id: '11111111-1111-4111-8111-111111111111' }
        h.state.role = 'owner'
    })

    it('يقرأ الصفحة الأولى بترتيب تنازلي ويرجع العدد الإجمالي', async () => {
        const rows = [
            { id: 'a', action: 'remove_operating_exclusion' },
            { id: 'b', action: 'void_treasury' },
        ]
        h.when('audit_log', 'select', rows)
        h.whenCount('audit_log', 2)

        await expect(getAuditLog()).resolves.toEqual({
            rows,
            total: 2,
            page: 1,
            perPage: 50,
        })
        expect(h.callsOf('audit_log', 'order')[0].args).toEqual([
            'occurred_at',
            { ascending: false },
        ])
        expect(h.callsOf('audit_log', 'range')[0].args).toEqual([0, 49])
    })

    it('يحسب نطاق الصفحة الثانية بدقة', async () => {
        h.when('audit_log', 'select', [])
        h.whenCount('audit_log', 0)

        await expect(getAuditLog({ page: 2, perPage: 25 })).resolves.toEqual({
            rows: [],
            total: 0,
            page: 2,
            perPage: 25,
        })
        expect(h.callsOf('audit_log', 'range')[0].args).toEqual([25, 49])
    })

    it('يمرر البحث والإجراء بنفس الفلاتر للصفوف والعدد', async () => {
        h.when('audit_log', 'select', [])
        h.whenCount('audit_log', 0)

        await getAuditLog({ q: 'إزالة', action: 'remove_operating_exclusion' })

        const ilikes = h.callsOf('audit_log', 'ilike')
        expect(ilikes).toHaveLength(2)
        expect(ilikes[0].args).toEqual(['reason', '%إزالة%'])
        const eqs = h.callsOf('audit_log', 'eq')
        expect(eqs.filter((c) => c.args[0] === 'action')).toHaveLength(2)
    })

    it('يهرب محارف ilike الخاصة في البحث', async () => {
        h.when('audit_log', 'select', [])
        h.whenCount('audit_log', 0)

        await getAuditLog({ q: '100%_سبب' })

        expect(h.callsOf('audit_log', 'ilike')[0].args).toEqual([
            'reason',
            '%100\\%\\_سبب%',
        ])
    })

    it('يرفض الإجراء الغريب وعدد الصفوف المتجاوز', async () => {
        await expect(getAuditLog({ action: 'hacked' })).rejects.toThrow('الإجراء غير صالح')
        await expect(getAuditLog({ perPage: 999999 })).rejects.toThrow('عدد الصفوف غير صالح')
        expect(h.callsOf('audit_log', 'select')).toHaveLength(0)
    })

    it('يرفض المدير قبل أي استعلام (رسالة عامة كسائر القراءات)', async () => {
        h.state.role = 'manager'

        await expect(getAuditLog()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
        expect(h.callsOf('audit_log', 'select')).toHaveLength(0)
    })

    it('يرفض الزائر دون أي استعلام (رسالة عامة كسائر القراءات)', async () => {
        h.state.user = null

        await expect(getAuditLog()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
        expect(h.calls()).toHaveLength(0)
    })

    it('يرمي رسالة عامة فقط عند خطأ القراءة', async () => {
        h.fail('audit_log', 'select', postgrestError('PGRST116', 'query failed'))

        await expect(getAuditLog()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
    })
})
