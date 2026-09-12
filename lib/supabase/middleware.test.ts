import { describe, expect, it, beforeEach, vi } from 'vitest'
import { NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

// ----------------------------------------------------------------------------
// اختبارات حماية المسارات عبر الـ Proxy (إغلاق فجوة الدخول):
//  - زائر غير مسجل يُوجَّه لصفحة الدخول عند محاولة فتح مسارات محمية
//  - صفحة الدخول ومسار callback يبقيان متاحين للزوار
//  - مستخدم مسجل يُوجَّه للوحة التحكم عند فتح صفحة الدخول
// ----------------------------------------------------------------------------

const h = vi.hoisted(() => {
  const state = { user: null as { id: string } | null }
  const getUser = vi.fn()
  // محاكاة دالة increment_rate_limit في القاعدة: عداد لكل بصمة
  const buckets = new Map<string, number>()
  const rpc = vi.fn(async (_fn: string, args: Record<string, unknown>) => {
    const bucket = String(args.p_bucket)
    const limit = Number(args.p_limit)
    const count = (buckets.get(bucket) ?? 0) + 1
    buckets.set(bucket, count)
    return {
      data: { allowed: count <= limit, count, retry_after: 42 },
      error: null,
    }
  })
  return { state, getUser, buckets, rpc }
})

vi.mock('@supabase/ssr', () => ({
  createServerClient: () => ({
    auth: {
      getUser: h.getUser,
    },
    rpc: h.rpc,
  }),
}))

function makeRequest(pathname: string, method = 'GET', ip = '127.0.0.1'): NextRequest {
  const req = new NextRequest(`http://localhost:3000${pathname}`, { method })
  req.headers.set('x-forwarded-for', ip)
  return req
}

beforeEach(() => {
  h.state.user = null
  h.getUser.mockImplementation(async () => ({ data: { user: h.state.user } }))
  h.buckets.clear()
})

describe('الزائر غير المسجل (لا توجد جلسة)', () => {
  it('يُعاد توجيهه من لوحة التحكم إلى صفحة الدخول', async () => {
    const response = await updateSession(makeRequest('/dashboard'))
    expect(response.status).toBe(307)
    expect(response.headers.get('location')).toContain('/login')
  })

  it('يُعاد توجيهه من الصفحة الرئيسية إلى صفحة الدخول', async () => {
    const response = await updateSession(makeRequest('/'))
    expect(response.status).toBe(307)
    expect(response.headers.get('location')).toContain('/login')
  })

  it('يُعاد توجيهه من صفحة المشروع إلى صفحة الدخول', async () => {
    const response = await updateSession(makeRequest('/projects/some-id'))
    expect(response.status).toBe(307)
    expect(response.headers.get('location')).toContain('/login')
  })

  it('يحتفظ بالمسار الأصلي ضمن معامل next ليعود إليه بعد الدخول', async () => {
    const response = await updateSession(makeRequest('/dashboard'))
    const location = decodeURIComponent(response.headers.get('location') ?? '')
    expect(location).toContain('next=/dashboard')
  })

  it('يبقى قادراً على فتح صفحة الدخول (لا حلقة إعادة توجيه)', async () => {
    const response = await updateSession(makeRequest('/login'))
    expect(response.status).toBe(200)
    expect(response.headers.get('location')).toBeNull()
  })

  it('يبقى مسار استقبال الرابط السحري مفتوحاً للزوار', async () => {
    const response = await updateSession(makeRequest('/auth/callback?code=xyz'))
    expect(response.status).toBe(200)
    expect(response.headers.get('location')).toBeNull()
  })
})

describe('المستخدم المسجل (جلسة موجودة)', () => {
  beforeEach(() => {
    h.state.user = { id: '11111111-1111-4111-8111-111111111111' }
  })

  it('يُعاد توجيهه من صفحة الدخول إلى لوحة التحكم', async () => {
    const response = await updateSession(makeRequest('/login'))
    expect(response.status).toBe(307)
    expect(response.headers.get('location')).toContain('/dashboard')
  })

  it('يبقى قادراً على فتح لوحة التحكم دون إعادة توجيه', async () => {
    const response = await updateSession(makeRequest('/dashboard'))
    expect(response.status).toBe(200)
    expect(response.headers.get('location')).toBeNull()
  })
})

describe('حماية Rate Limiting لصفحة الدخول POST /login', () => {
  it('يسمح بـ 5 محاولات دخول متتالية من نفس الـ IP ويمنع المحاولة السادسة بـ 429 وبودي JSON عربي', async () => {
    const testIp = '10.0.0.42'
    for (let i = 1; i <= 5; i++) {
      const res = await updateSession(makeRequest('/login', 'POST', testIp))
      expect(res.status).not.toBe(429)
    }

    const blockedRes = await updateSession(makeRequest('/login', 'POST', testIp))
    expect(blockedRes.status).toBe(429)

    const json = await blockedRes.json()
    expect(json.error).toBe('تم تجاوز عدد محاولات الدخول المسموح بها. يرجى الانتظار دقيقة قبل المحاولة مرة أخرى.')
  })

  it('يرفق ترويسة Retry-After عند الحظر', async () => {
    const testIp = '10.0.0.43'
    for (let i = 1; i <= 6; i++) {
      await updateSession(makeRequest('/login', 'POST', testIp))
    }
    const blockedRes = await updateSession(makeRequest('/login', 'POST', testIp))
    expect(blockedRes.status).toBe(429)
    expect(blockedRes.headers.get('Retry-After')).toBe('42')
  })

  it('يعزل العدادات بين عناوين IP مختلفة', async () => {
    for (let i = 1; i <= 5; i++) {
      await updateSession(makeRequest('/login', 'POST', '10.0.0.50'))
    }
    const other = await updateSession(makeRequest('/login', 'POST', '10.0.0.51'))
    expect(other.status).not.toBe(429)
  })
})