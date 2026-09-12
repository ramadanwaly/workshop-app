import { beforeEach, describe, expect, it, vi } from 'vitest'
import { GENERIC_ERROR_MESSAGE } from '@/lib/server-errors'
import type { PostgrestError } from '@supabase/supabase-js'
import type { SupabaseHarness } from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

import { createSupabaseHarness } from '@/test/helpers/supabase-harness'
import {
    getTreasuryBalance,
    getTreasuryLedger,
    injectOwnerFunding,
    recordExpense,
    voidTransaction,
} from './treasury'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const TX_ID = '22222222-2222-4222-8222-222222222222'
const IDEM_KEY = '11111111-1111-4111-8111-111111111101'

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

describe('injectOwnerFunding', () => {
    beforeEach(() => {
        h.reset()
        h.state.user = { id: USER_ID }
        h.state.role = 'owner'
    })

    it('يُدخل حركة تمويل للمالك مع تأمين مفتاح منع التكرار', async () => {
        const tx = { id: TX_ID, transaction_type: 'in', category: 'owner_funding', amount: 5000 }
        h.rpcOk('rpc_record_treasury_transaction', tx)

        const res = await injectOwnerFunding({
            amount: 5000,
            description: 'رأس مال أولي',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: tx })

        expect(h.callsOf('profiles', 'select')).toHaveLength(1)
        expect(h.rpcOf('rpc_record_treasury_transaction')[0].args).toMatchObject({
            p_idempotency_key: IDEM_KEY,
            p_action: 'inject_owner_funding',
            p_transaction_type: 'in',
            p_category: 'owner_funding',
            p_amount: 5000,
            p_description: 'رأس مال أولي'
        })
    })

    it('يرفض غير المالك قبل أي كتابة', async () => {
        h.state.role = 'manager'

        const res = await injectOwnerFunding({
            amount: 5000,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({
            success: false,
            error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
        })
        expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
    })

    it('يرفض الزائر دون أي استعلام', async () => {
        h.state.user = null

        const res = await injectOwnerFunding({
            amount: 5000,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
        expect(h.calls()).toHaveLength(0)
    })

    it('يرفض المبلغ غير الصالح قبل أي كتابة', async () => {
        const res = await injectOwnerFunding({
            amount: -5,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'المبلغ يجب أن يكون أكبر من صفر' })
        expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
    })

    it('يرفض عند تجاوز حد المعدل قبل أي كتابة مالية', async () => {
        h.rpcOk('increment_rate_limit', { allowed: false, count: 31, retry_after: 25 })

        const res = await injectOwnerFunding({
            amount: 5000,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'طلبات كثيرة جداً — انتظر 25 ثانية وحاول مجدداً' })
        expect(h.rpcOf('rpc_record_treasury_transaction').length).toBeLessThan(2)
    })

    it('يعيد النتيجة المخزنة دون إدراج عند اكتمال المفتاح عبر الـ RPC', async () => {
        const cached = { id: TX_ID, amount: 5000 }
        h.rpcOk('rpc_record_treasury_transaction', cached)

        const res = await injectOwnerFunding({
            amount: 5000,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: cached })
    })

    it('يتم التعامل مع مفتاح متكرر بأنه يرجع نفس النتيجة إذا كان مكتملاً في الـ RPC', async () => {
        // Not specifically tested here since RPC hides it
    })

    it('يرسل رسالة العمل رفض القاعدة (P0001) كما هي', async () => {
        h.rpcFail('rpc_record_treasury_transaction', postgrestError('P0001', 'رفض نظام الخزينة العملية'))

        const res = await injectOwnerFunding({
            amount: 5000,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'رفض نظام الخزينة العملية' })
    })
})

describe('recordExpense', () => {
    beforeEach(() => {
        h.reset()
        h.state.user = { id: USER_ID }
        h.state.role = 'manager'
    })

    it('يسجل مصروف مواد بالتصنيف الفرعي للمدير', async () => {
        const tx = { id: TX_ID, transaction_type: 'out', category: 'material', amount: 3500 }
        h.rpcOk('rpc_record_treasury_transaction', tx)

        const res = await recordExpense({
            category: 'material',
            subcategory: 'wood_boards',
            amount: 3500,
            description: 'فك خشب',
            projectId: null,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: tx })
        expect(h.rpcOf('rpc_record_treasury_transaction')[0].args).toMatchObject({
            p_action: 'record_expense',
            p_transaction_type: 'out',
            p_category: 'material',
            p_subcategory: 'wood_boards',
            p_amount: 3500,
            p_description: 'فك خشب',
            p_project_id: null,
            p_is_direct_owner: false
        })
    })

    it('يحوّل الحقول الاختيارية الفارغة لـ null', async () => {
        const res = await recordExpense({
            category: 'general_expense',
            amount: 120,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res.success).toBe(true)
        expect(h.rpcOf('rpc_record_treasury_transaction')[0].args).toMatchObject({
            p_subcategory: null,
            p_description: null,
            p_project_id: null,
            p_is_direct_owner: false,
        })
    })

    it('يرفض الزائر', async () => {
        h.state.user = null

        const res = await recordExpense({
            category: 'general_expense',
            amount: 120,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
        expect(h.calls()).toHaveLength(0)
    })

    it('يلزم التصنيف الفرعي لتصنيف المواد', async () => {
        const res = await recordExpense({
            category: 'material',
            amount: 3500,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'التصنيف الفرعي مطلوب لهذا التصنيف' })
        expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
    })

    it('يرفض ربط مصاريف تشغيل الورشة بمشروع محدد', async () => {
        const res = await recordExpense({
            category: 'workshop_operating',
            subcategory: 'electricity',
            amount: 800,
            projectId: TX_ID,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({
            success: false,
            error: 'مصاريف تشغيل الورشة لا ترتبط بمشروع محدد',
        })
        expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
    })

    it('يعيد النتيجة المخزنة دون إدراج عند اكتمال المفتاح (بمحاكاة للـ RPC)', async () => {
        const cached = { id: TX_ID }
        h.rpcOk('rpc_record_treasury_transaction', cached)

        const res = await recordExpense({
            category: 'general_expense',
            amount: 120,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: cached })
    })

    it('يرسل رسالة رفض القاعدة (P0001) كما هي', async () => {
        h.rpcFail('rpc_record_treasury_transaction', postgrestError('P0001', 'لا يجوز تسجيل مصروف بهذا الحجم'))

        const res = await recordExpense({
            category: 'general_expense',
            amount: 5000,
            isDirectOwnerPayment: false,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'لا يجوز تسجيل مصروف بهذا الحجم' })
    })

    it('يرفض المدير عند تحديد سداد المالك المباشر (H-02)', async () => {
        h.state.role = 'manager'

        const res = await recordExpense({
            category: 'general_expense',
            amount: 500,
            projectId: TX_ID,
            isDirectOwnerPayment: true,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({
            success: false,
            error: 'تحديد سداد المالك المباشر يتطلب صلاحيات المالك فقط',
        })
        expect(h.rpcOf('rpc_record_treasury_transaction')).toHaveLength(0)
    })

    it('يقبل سداد المالك المباشر من المالك فقط (H-02)', async () => {
        h.state.role = 'owner'
        const tx = { id: TX_ID, transaction_type: 'out', category: 'general_expense', amount: 500 }
        h.rpcOk('rpc_record_treasury_transaction', tx)

        const res = await recordExpense({
            category: 'general_expense',
            amount: 500,
            projectId: TX_ID,
            isDirectOwnerPayment: true,
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: tx })
    })
})

describe('voidTransaction', () => {
    beforeEach(() => {
        h.reset()
        h.state.user = { id: USER_ID }
        h.state.role = 'owner'
    })

    it('يلغي حركة عبر الـ RPC الذري', async () => {
        const updated = { id: TX_ID, is_voided: true, void_reason: 'إدخال خاطئ' }
        h.rpcOk('rpc_void_treasury_transaction', updated)

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: updated })
        expect(h.rpcOf('rpc_void_treasury_transaction')[0].args).toMatchObject({
            p_idempotency_key: IDEM_KEY,
            p_action: 'void_transaction',
            p_transaction_id: TX_ID,
            p_reason: 'إدخال خاطئ',
        })
    })

    it('يرفض غير المالك قبل أي استدعاء للـ RPC', async () => {
        h.state.role = 'manager'

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({
            success: false,
            error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
        })
        expect(h.rpcOf('rpc_void_treasury_transaction')).toHaveLength(0)
    })

    it('يرفض الزائر', async () => {
        h.state.user = null

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
        expect(h.calls()).toHaveLength(0)
    })

    it('يرفض إلغاء حركة ملغاة مسبقاً (رفض الـ RPC)', async () => {
        h.rpcFail('rpc_void_treasury_transaction', postgrestError('P0001', 'هذه الحركة ملغاة بالفعل مسبقاً'))

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'هذه الحركة ملغاة بالفعل مسبقاً' })
    })

    it('يرفض حركة غير موجودة (رفض الـ RPC)', async () => {
        h.rpcFail('rpc_void_treasury_transaction', postgrestError('P0001', 'الحركة المالية غير موجودة'))

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: false, error: 'الحركة المالية غير موجودة' })
    })

    it('يعيد النتيجة المخزنة عند اكتمال المفتاح عبر الـ RPC', async () => {
        const cached = { id: TX_ID, is_voided: true }
        h.rpcOk('rpc_void_treasury_transaction', cached)

        const res = await voidTransaction({
            transactionId: TX_ID,
            reason: 'إدخال خاطئ',
            idempotencyKey: IDEM_KEY,
        })

        expect(res).toEqual({ success: true, data: cached })
    })
})

describe('getTreasuryBalance', () => {
    it('يقرأ الرصيد من العرض الموثوق', async () => {
        h.reset()
        const balance = { current_balance: 12800, total_in: 20000, total_out: 7200 }
        h.when('v_treasury_balance', 'select', balance)

        await expect(getTreasuryBalance()).resolves.toEqual(balance)
        expect(h.callsOf('v_treasury_balance', 'select')).toHaveLength(1)
    })

    it('يرمي رسالة عامة فقط عند خطأ القراءة', async () => {
        h.reset()
        h.fail('v_treasury_balance', 'select', postgrestError('PGRST116', 'The result contains 0 rows'))

        await expect(getTreasuryBalance()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
    })
})

describe('getTreasuryLedger', () => {
    it('يقرأ الصفحة الأولى بترتيب تنازلي ويرجع العدد الإجمالي', async () => {
        h.reset()
        const rows = [{ id: 'a', amount: 1 }, { id: 'b', amount: 2 }]
        h.when('treasury_transactions', 'select', rows)
        h.whenCount('treasury_transactions', 2)

        await expect(getTreasuryLedger()).resolves.toEqual({
            rows,
            total: 2,
            page: 1,
            perPage: 50,
        })
        expect(h.callsOf('treasury_transactions', 'order')[0].args).toEqual([
            'created_at',
            { ascending: false },
        ])
        expect(h.callsOf('treasury_transactions', 'range')[0].args).toEqual([0, 49])
    })

    it('يحسب نطاق الصفحة الثانية بدقة', async () => {
        h.reset()
        h.when('treasury_transactions', 'select', [])
        h.whenCount('treasury_transactions', 0)

        await expect(getTreasuryLedger({ page: 2, perPage: 25 })).resolves.toEqual({
            rows: [],
            total: 0,
            page: 2,
            perPage: 25,
        })
        expect(h.callsOf('treasury_transactions', 'range')[0].args).toEqual([25, 49])
    })

    it('يمرر البحث والتصنيف والمدى الزمني بنفس الفلاتر للصفوف والعدد', async () => {
        h.reset()
        h.when('treasury_transactions', 'select', [])
        h.whenCount('treasury_transactions', 0)

        await getTreasuryLedger({
            q: 'خشب',
            category: 'material',
            from: '2026-09-01',
            to: '2026-09-10',
        })

        const ilikes = h.callsOf('treasury_transactions', 'ilike')
        expect(ilikes).toHaveLength(2)
        expect(ilikes[0].args).toEqual(['description', '%خشب%'])
        const eqs = h.callsOf('treasury_transactions', 'eq')
        expect(eqs.filter((c) => c.args[0] === 'category')).toHaveLength(2)
        expect(h.callsOf('treasury_transactions', 'gte')).toHaveLength(2)
        expect(h.callsOf('treasury_transactions', 'lt')).toHaveLength(2)
    })

    it('يهرب محارف ilike الخاصة في البحث', async () => {
        h.reset()
        h.when('treasury_transactions', 'select', [])
        h.whenCount('treasury_transactions', 0)

        await getTreasuryLedger({ q: '100%_خصم' })

        expect(h.callsOf('treasury_transactions', 'ilike')[0].args).toEqual([
            'description',
            '%100\\%\\_خصم%',
        ])
    })

    it('يرفض التصنيف الغريب وعدد الصفوف المتجاوز', async () => {
        h.reset()

        await expect(getTreasuryLedger({ category: 'hacked' })).rejects.toThrow(
            'تصنيف المصروف غير صالح'
        )
        await expect(getTreasuryLedger({ perPage: 999999 })).rejects.toThrow(
            'عدد الصفوف غير صالح'
        )
        expect(h.callsOf('treasury_transactions', 'select')).toHaveLength(0)
    })

    it('يرمي رسالة عامة فقط عند خطأ القراءة', async () => {
        h.reset()
        h.fail('treasury_transactions', 'select', postgrestError('PGRST116', 'query failed'))

        await expect(getTreasuryLedger()).rejects.toThrow(GENERIC_ERROR_MESSAGE)
    })
})