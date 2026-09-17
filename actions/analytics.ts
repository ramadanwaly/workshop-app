'use server'

import { maskAndLogError } from '@/lib/server-errors'
import { requireStaff } from '@/lib/actions/guard'

type ActionResult<T = unknown> = {
    success: boolean
    data?: T
    error?: string
}

// ----------------------------------------------------------------------------
// 1. إحصائيات الخزنة الشهرية (الإيرادات والمصروفات)
// ----------------------------------------------------------------------------
export async function getMonthlyTreasuryStats(): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const { data, error } = await supabase
            .from('v_monthly_treasury_stats')
            .select('*')
            .order('month', { ascending: false })

        if (error) {
            return { success: false, error: error.message }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getMonthlyTreasuryStats', err) }
    }
}

// ----------------------------------------------------------------------------
// 2. ربحية المشاريع
// ----------------------------------------------------------------------------
export async function getProjectProfitability(): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const { data, error } = await supabase
            .from('v_project_profitability')
            .select('*')
            .order('project_name', { ascending: true })

        if (error) {
            return { success: false, error: error.message }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getProjectProfitability', err) }
    }
}

// ----------------------------------------------------------------------------
// 3. أداء العمال الشهري (أيام العمل، الأجور، السلف)
// ----------------------------------------------------------------------------
export async function getWorkerPerformanceStats(): Promise<ActionResult> {
    try {
        const auth = await requireStaff()
        if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
        const supabase = auth.supabase

        const { data, error } = await supabase
            .from('v_worker_performance_stats')
            .select('*')
            .order('month', { ascending: false })
            .order('worker_name', { ascending: true })

        if (error) {
            return { success: false, error: error.message }
        }

        return { success: true, data }
    } catch (err: unknown) {
        return { success: false, error: maskAndLogError('getWorkerPerformanceStats', err) }
    }
}
