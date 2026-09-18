'use server'

import { maskAndLogError, routeActionError } from '@/lib/server-errors'
import { requireStaff } from '@/lib/actions/guard'

type ActionResult<T = unknown> = {
    success: boolean
    data?: T
    error?: string
}

export type PaginationParams = {
    limit?: number
    offset?: number
}

// ----------------------------------------------------------------------------
// 1. إحصائيات الخزنة الشهرية (الإيرادات والمصروفات)
// ----------------------------------------------------------------------------
export async function getMonthlyTreasuryStats(params: PaginationParams = {}): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const limit = Math.min(Math.max(1, params.limit ?? 24), 100)
        const offset = Math.max(0, params.offset ?? 0)

        const { data, error } = await supabase
            .from('v_monthly_treasury_stats')
            .select('*')
            .order('month', { ascending: false })
            .range(offset, offset + limit - 1)

        if (error) {
            return { success: false, error: routeActionError('getMonthlyTreasuryStats', error) }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getMonthlyTreasuryStats', err) }
    }
}

// ----------------------------------------------------------------------------
// 2. ربحية المشاريع
// ----------------------------------------------------------------------------
export async function getProjectProfitability(params: PaginationParams = {}): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const limit = Math.min(Math.max(1, params.limit ?? 50), 200)
        const offset = Math.max(0, params.offset ?? 0)

        const { data, error } = await supabase
            .from('v_project_profitability')
            .select('*')
            .order('project_name', { ascending: true })
            .range(offset, offset + limit - 1)

        if (error) {
            return { success: false, error: routeActionError('getProjectProfitability', error) }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getProjectProfitability', err) }
    }
}

// ----------------------------------------------------------------------------
// 3. أداء العمال الشهري (أيام العمل، الأجور، السلف)
// ----------------------------------------------------------------------------
export async function getWorkerPerformanceStats(params: PaginationParams = {}): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const limit = Math.min(Math.max(1, params.limit ?? 50), 200)
        const offset = Math.max(0, params.offset ?? 0)

        const { data, error } = await supabase
            .from('v_worker_performance_stats')
            .select('*')
            .order('month', { ascending: false })
            .order('worker_name', { ascending: true })
            .range(offset, offset + limit - 1)

        if (error) {
            return { success: false, error: routeActionError('getWorkerPerformanceStats', error) }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getWorkerPerformanceStats', err) }
    }
}
