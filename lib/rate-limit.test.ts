import { describe, expect, it, vi } from 'vitest'
import { checkRateLimit, hashId, rateLimitMessage } from './rate-limit'
import type { createClient } from '@/lib/supabase/server'

type TestClient = Awaited<ReturnType<typeof createClient>>

function caller(data: unknown, error: { message?: string } | null = null) {
  return {
    rpc: vi.fn(async () => ({ data, error })),
  } as unknown as TestClient
}

describe('hashId', () => {
  it('بصمة حتمية من 8 خانات ولا تكشف الأصل', () => {
    expect(hashId('a@b.c')).toBe(hashId('a@b.c'))
    expect(hashId('a@b.c')).toMatch(/^[0-9a-f]{8}$/)
    expect(hashId('a@b.c')).not.toContain('a@b.c')
  })
})

describe('checkRateLimit', () => {
  it('يسمح عند سماح القاعدة ويمرر المهلة', async () => {
    const r = await checkRateLimit(
      caller({ allowed: true, count: 2, retry_after: 0 }),
      'login:abc',
      5
    )
    expect(r).toEqual({ allowed: true, retryAfter: 0 })
  })

  it('يمنع عند تجاوز الحد مع مهلة القاعدة', async () => {
    const c = caller({ allowed: false, count: 9, retry_after: 37 })
    const r = await checkRateLimit(c, 'login:abc', 5)
    expect(r).toEqual({ allowed: false, retryAfter: 37 })
    expect(c.rpc).toHaveBeenCalledWith('increment_rate_limit', {
      p_bucket: 'login:abc',
      p_limit: 5,
      p_window_seconds: 60,
    })
  })

  it('يسمح عند عطل القاعدة (لا نعطل الورشة لعطل جانبي)', async () => {
    const r = await checkRateLimit(
      caller(null, { message: 'boom' }),
      'login:abc',
      5
    )
    expect(r).toEqual({ allowed: true, retryAfter: 0 })
  })

  it('يسمح عند رد فارغ أو ناقص', async () => {
    expect(await checkRateLimit(caller(null), 'x', 5)).toEqual({
      allowed: true,
      retryAfter: 0,
    })
    expect(await checkRateLimit(caller({}), 'x', 5)).toEqual({
      allowed: true,
      retryAfter: 0,
    })
  })
})

describe('rateLimitMessage', () => {
  it('رسالة عربية تتضمن الثواني', () => {
    expect(rateLimitMessage(37)).toContain('37')
  })
})
