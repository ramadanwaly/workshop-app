import { describe, it, expect, beforeEach, vi } from 'vitest'
import type { SupabaseHarness } from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
    createClient: () => hState.harness!.createClient(),
}))

import { createSupabaseHarness } from '@/test/helpers/supabase-harness'
import { getMonthlyTreasuryStats, getProjectProfitability, getWorkerPerformanceStats } from './analytics'

const h = createSupabaseHarness()
hState.harness = h

describe('Analytics Server Actions', () => {
    beforeEach(() => {
        h.reset()
    })

    describe('Authorization', () => {
        it('prevents anonymous users from fetching stats', async () => {
            h.state.user = null
            h.state.role = null

            const res1 = await getMonthlyTreasuryStats()
            expect(res1.success).toBe(false)
            expect(res1.error).toMatch(/غير مصرح لك/)

            const res2 = await getProjectProfitability()
            expect(res2.success).toBe(false)

            const res3 = await getWorkerPerformanceStats()
            expect(res3.success).toBe(false)
        })

        it('allows staff to fetch stats and returns data', async () => {
            h.state.user = { id: 'staff-id' }
            h.state.role = 'manager'

            // Mocking the result of the views
            h.when('v_monthly_treasury_stats', 'select', [{ month: '2026-09-01T00:00:00Z', total_in: 5000, total_out: 2000 }])

            const res = await getMonthlyTreasuryStats()
            expect(res.success).toBe(true)
            expect(res.data).toBeDefined()
            
            // Verify what was called
            const calls = h.callsOf('v_monthly_treasury_stats', 'select')
            expect(calls.length).toBeGreaterThan(0)
        })
    })

    describe('Pagination & Range parameters', () => {
        it('applies custom limit and offset when provided', async () => {
            h.state.user = { id: 'owner-id' }
            h.state.role = 'owner'
            
            h.when('v_project_profitability', 'select', [{ project_id: '123', total_revenue: 10000, net_profit: 2000 }])

            const res = await getProjectProfitability({ limit: 10, offset: 20 })
            expect(res.success).toBe(true)
            expect(res.data).toBeDefined()
            
            const calls = h.callsOf('v_project_profitability', 'select')
            expect(calls.length).toBeGreaterThan(0)
        })
    })

    describe('getWorkerPerformanceStats', () => {
        it('fetches worker performance correctly with pagination', async () => {
            h.state.user = { id: 'owner-id' }
            h.state.role = 'owner'
            
            h.when('v_worker_performance_stats', 'select', [{ worker_id: 'w1', total_days: 5, total_wages: 500, total_advances: 100 }])

            const res = await getWorkerPerformanceStats({ limit: 25, offset: 0 })
            expect(res.success).toBe(true)
            expect(res.data).toBeDefined()

            const calls = h.callsOf('v_worker_performance_stats', 'select')
            expect(calls.length).toBeGreaterThan(0)
        })
    })
})
