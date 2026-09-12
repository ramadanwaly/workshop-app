import type { Json } from '@/types/database.types'
import type { createClient } from './server'

type SupabaseClient = Awaited<ReturnType<typeof createClient>>

export class IdempotencyError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'IdempotencyError'
    }
}

// ----------------------------------------------------------------------------
// Idempotency guard against double-submit / concurrent duplicates.
// The key is a PRIMARY KEY in the database, so concurrent inserts of the same
// key fail with 23505 and are rejected. Completed keys return the cached result.
//
// SECURITY: we scope every query by (key + user_id + action) so that:
//   • User B cannot read the cached result of User A's key.
//   • An attacker cannot pre-reserve another user's key to block them.
//   • A different action with the same UUID is treated as a distinct key.
// ----------------------------------------------------------------------------
export async function checkAndLockIdempotency(
    supabase: SupabaseClient,
    key: string,
    userId: string,
    action: string
): Promise<{ alreadyCompleted: boolean; cachedData?: unknown }> {
    const { data: existing } = await supabase
        .from('idempotency_keys')
        .select('status, response_payload, created_at')
        .eq('key', key)
        .eq('user_id', userId)
        .eq('action', action)
        .single()

    if (existing) {
        if (existing.status === 'completed') {
            return { alreadyCompleted: true, cachedData: existing.response_payload }
        }
        if (existing.status === 'pending') {
            const ageMs = Date.now() - new Date(existing.created_at).getTime()
            if (ageMs > 5 * 60 * 1000) {
                // Stuck for > 5 minutes. Mark as failed and let the new insert happen or just delete it.
                // Since the client can't DELETE, we UPDATE it to failed, and then we need to insert?
                // Actually, the key is PRIMARY KEY (key, user_id, action). We can't insert a new one!
                // So we just update the existing one back to pending!
                const { error: updateErr } = await supabase
                    .from('idempotency_keys')
                    .update({ status: 'pending', created_at: new Date().toISOString() })
                    .eq('key', key)
                    .eq('user_id', userId)
                    .eq('action', action)
                    .eq('status', 'pending')

                if (updateErr) {
                    throw new Error('فشل تأمين المعاملة ضد التكرار: ' + updateErr.message)
                }
                return { alreadyCompleted: false }
            }
            throw new IdempotencyError('العملية قيد التنفيذ بالفعل، يرجى الانتظار')
        }
    }

    const { error } = await supabase.from('idempotency_keys').insert({
        key,
        user_id: userId,
        action,
        status: 'pending',
    })

    if (error) {
        if (error.code === '23505') {
            throw new IdempotencyError('تم استقبال هذا الطلب مسبقاً، يرجى عدم تكرار الضغط')
        }
        throw new Error('فشل تأمين المعاملة ضد التكرار: ' + error.message)
    }

    return { alreadyCompleted: false }
}

export async function markIdempotencyCompleted(
    supabase: SupabaseClient,
    key: string,
    userId: string,
    action: string,
    payload: unknown
) {
    await supabase
        .from('idempotency_keys')
        .update({
            status: 'completed',
            response_payload: payload as Json,
        })
        .eq('key', key)
        .eq('user_id', userId)
        .eq('action', action)
}
