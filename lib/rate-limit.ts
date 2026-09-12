import { logWarn } from '@/lib/logger'
import type { createClient } from '@/lib/supabase/server'

// ----------------------------------------------------------------------------
// تحديد المعدل المشترك (P2-04): عدّاد ذري في القاعدة عبر
// increment_rate_limit (هجرة 25) — مشترك بين النسخ ويبقى بعد إعادة التشغيل.
// البصمات (IP/بريد) تُجزّأ قبل التخزين فلا تُحفظ بيانات تعريفية خام.
// عند تعطل الفحص نفسه: سماح + تحذير (لا نعطل الورشة لعطل جانبي).
// ----------------------------------------------------------------------------

export type RateLimitResult = { allowed: boolean; retryAfter: number }

type SupabaseClient = Awaited<ReturnType<typeof createClient>>

/** بصمة FNV-1a قصيرة — تعمل في Edge وNode دون اعتماديات */
export function hashId(value: string): string {
  let h = 0x811c9dc5
  for (let i = 0; i < value.length; i++) {
    h ^= value.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return (h >>> 0).toString(16).padStart(8, '0')
}

export async function checkRateLimit(
  supabase: SupabaseClient,
  bucket: string,
  limit: number,
  windowSec = 60
): Promise<RateLimitResult> {
  try {
    const { data, error } = await supabase.rpc('increment_rate_limit', {
      p_bucket: bucket,
      p_limit: limit,
      p_window_seconds: windowSec,
    })
    if (error || !data || typeof data !== 'object') {
      return { allowed: true, retryAfter: 0 }
    }
    const d = data as { allowed?: unknown; retry_after?: unknown }
    if (typeof d.allowed !== 'boolean') {
      return { allowed: true, retryAfter: 0 }
    }
    return {
      allowed: d.allowed,
      retryAfter: typeof d.retry_after === 'number' ? d.retry_after : windowSec,
    }
  } catch (err) {
    logWarn('rate_limit', { bucket, err: err instanceof Error ? err.message : err })
    return { allowed: true, retryAfter: 0 }
  }
}

export function rateLimitMessage(retryAfter: number): string {
  const s = Math.max(1, retryAfter)
  return `طلبات كثيرة جداً — انتظر ${s} ثانية وحاول مجدداً`
}
