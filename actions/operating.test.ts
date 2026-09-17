import { describe, it, expect, beforeEach, vi } from 'vitest'
import {
    runOperatingAllocation,
    voidOperatingAllocationLine,
    addOperatingAllocationExclusion,
} from './operating'

const h = vi.hoisted(() => {
    const state = {
        user: null as { id: string } | null,
        role: null as string | null,
        rpcResult: { status: 'applied' },
        rpcError: null as { message: string } | null,
    }
    const rpcCalls: Array<{ fn: string; args: Record<string, unknown> }> = []
    const idempotency: Array<{ key: string; action: string }> = []
    return { state, rpcCalls, idempotency }
})

vi.mock('next/cache', () => ({
    revalidatePath: vi.fn(),
}))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => ({
        auth: { getUser: async () => ({ data: { user: h.state.user } }) },
        from: (table: string) => {
            if (table === 'profiles') {
                return { select: () => ({ eq: () => ({ single: async () => ({ data: { role: h.state.role } }) }) }) }
            }
            return { select: () => ({ single: async () => ({ data: null }) }) }
        },
        rpc: (fn: string, args: Record<string, unknown>) => {
            // فحص المعدل المشترك: سماح دائماً ولا يُسجل (ليس RPC عمل)
            if (fn === 'increment_rate_limit') {
                return Promise.resolve({ data: { allowed: true, count: 1, retry_after: 0 }, error: null })
            }
            h.rpcCalls.push({ fn, args })
            return Promise.resolve({ data: h.state.rpcResult, error: h.state.rpcError })
        },
    }),
}))

vi.mock('@/lib/supabase/idempotency', () => ({
    checkAndLockIdempotency: async (_s: unknown, key: string, _u: string, action: string) => {
        h.idempotency.push({ key, action })
        return { alreadyCompleted: false, cachedData: null }
    },
    markIdempotencyCompleted: async () => {},
    IdempotencyError: class IdempotencyError extends Error {},
}))

const KEY = '11111111-1111-4111-8111-111111111109'

beforeEach(() => {
    h.state.user = { id: crypto.randomUUID() }
    h.state.role = 'owner'
    h.state.rpcError = null
    h.rpcCalls.length = 0
    h.idempotency.length = 0
})

describe('operating allocation server actions', () => {
    it('runOperatingAllocation calls the owner wrapper with month-first-of-month', async () => {
        const res = await runOperatingAllocation({ yearMonth: '2026-08', idempotencyKey: KEY })
        expect(res.success).toBe(true)
        expect(h.rpcCalls[0].fn).toBe('rpc_run_operating_allocation')
        expect(h.rpcCalls[0].args.p_year_month).toBe('2026-08-01')
    })
    it('rejects a visitor without calling the rpc', async () => {
        h.state.user = null
        const res = await runOperatingAllocation({ yearMonth: '2026-08', idempotencyKey: KEY })
        expect(res.success).toBe(false)
        expect(h.rpcCalls.length).toBe(0)
    })
    it('voidOperatingAllocationLine maps the adjustment id + reason', async () => {
        const res = await voidOperatingAllocationLine({ adjustmentId: crypto.randomUUID(), reason: 'سطر خاطئ', idempotencyKey: KEY })
        expect(res.success).toBe(true)
        expect(h.rpcCalls[0].fn).toBe('rpc_void_allocation_line')
        expect(typeof h.rpcCalls[0].args.p_reason).toBe('string')
    })
    it('addOperatingAllocationExclusion maps month/project/reason', async () => {
        await addOperatingAllocationExclusion({ yearMonth: '2026-08', projectId: crypto.randomUUID(), reason: 'مشروع مجمد', idempotencyKey: KEY })
        expect(h.rpcCalls[0].fn).toBe('rpc_add_operating_exclusion')
        expect(h.rpcCalls[0].args.p_year_month).toBe('2026-08-01')
    })
    it('surfaces rpc errors through routeActionError', async () => {
        h.state.rpcError = { message: 'boom' }
        const res = await runOperatingAllocation({ yearMonth: '2026-08', idempotencyKey: KEY })
        expect(res.success).toBe(false)
    })
})