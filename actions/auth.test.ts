import { describe, expect, it, beforeEach, vi } from 'vitest'

// ----------------------------------------------------------------------------
// اختبارات Server Actions الخاصة بالدخول:
//  - التحقق من المدخلات قبل أي اتصال بـ Supabase
//  - تمرير البيانات الصحيحة لـ supabase.auth
//  - تحويل أخطاء Supabase الخام إلى رسائل عربية مضبوطة (لا تسريب تفاصيل)
// ----------------------------------------------------------------------------

const h = vi.hoisted(() => {
  const signInWithPassword = vi.fn()
  const signInWithOtp = vi.fn()
  const resetPasswordForEmail = vi.fn()
  const getUser = vi.fn()
  const updateUser = vi.fn()
  const signOut = vi.fn()
  return {
    signInWithPassword,
    signInWithOtp,
    resetPasswordForEmail,
    getUser,
    updateUser,
    signOut,
  }
})

vi.mock('@/lib/supabase/server', () => ({
  createClient: () => ({
    auth: {
      signInWithPassword: h.signInWithPassword,
      signInWithOtp: h.signInWithOtp,
      resetPasswordForEmail: h.resetPasswordForEmail,
      getUser: h.getUser,
      updateUser: h.updateUser,
      signOut: h.signOut,
    },
  }),
}))

vi.mock('next/headers', () => ({
  headers: async () => ({
    get: (name: string) =>
      name === 'origin' ? 'http://localhost:3000' : null,
  }),
}))

vi.mock('@/lib/rate-limit', async (importOriginal) => {
  const mod = await importOriginal<typeof import('@/lib/rate-limit')>()
  return {
    ...mod,
    checkRateLimit: vi.fn().mockResolvedValue({ allowed: true, retryAfter: 0 }),
  }
})

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}))

import { requestPasswordReset, signInWithOtp, signInWithPassword, updatePassword } from './auth'

beforeEach(() => {
  h.signInWithPassword.mockReset()
  h.signInWithOtp.mockReset()
  h.resetPasswordForEmail.mockReset()
  h.getUser.mockReset()
  h.updateUser.mockReset()
  h.signOut.mockReset()
})

describe('تسجيل الدخول بكلمة المرور', () => {
  it('يرفض بريداً إلكترونياً غير صالح قبل الاتصال بـ Supabase', async () => {
    const result = await signInWithPassword({ email: 'not-an-email', password: '123456' })
    expect(result.success).toBe(false)
    expect(result.error).toBe('يرجى إدخال بريد إلكتروني صحيح')
    expect(h.signInWithPassword).not.toHaveBeenCalled()
  })

  it('يرفض كلمة مرور قصيرة دون الاتصال بـ Supabase', async () => {
    const result = await signInWithPassword({ email: 'owner@example.com', password: '123' })
    expect(result.success).toBe(false)
    expect(result.error).toBe('كلمة المرور يجب ألا تقل عن 6 أحرف')
    expect(h.signInWithPassword).not.toHaveBeenCalled()
  })

  it('يمرر بيانات الدخول الصحيحة إلى supabase.auth ويُعلن النجاح', async () => {
    h.signInWithPassword.mockResolvedValue({ error: null })
    const result = await signInWithPassword({
      email: 'owner@example.com',
      password: 'strong-pass',
    })
    expect(h.signInWithPassword).toHaveBeenCalledWith({
      email: 'owner@example.com',
      password: 'strong-pass',
    })
    expect(result.success).toBe(true)
  })

  it('يحوّل خطأ Supabase الخام إلى رسالة عربية مضبوطة (لا يسرب التفاصيل)', async () => {
    h.signInWithPassword.mockResolvedValue({
      error: { message: 'Invalid login credentials (code 42) from auth server' },
    })
    const result = await signInWithPassword({
      email: 'owner@example.com',
      password: 'wrong-pass',
    })
    expect(result.success).toBe(false)
    expect(result.error).toBe('بيانات الدخول غير صحيحة، يرجى المحاولة مرة أخرى')
    expect(result.error).not.toContain('Invalid login credentials')
  })
})

describe('تسجيل الدخول بالرابط السحري', () => {
  it('يرفض بريداً إلكترونياً غير صالح قبل الاتصال بـ Supabase', async () => {
    const result = await signInWithOtp({ email: 'bad' })
    expect(result.success).toBe(false)
    expect(h.signInWithOtp).not.toHaveBeenCalled()
  })

  it('يرسل OTP مع رابط العودة المبني من الـ origin', async () => {
    h.signInWithOtp.mockResolvedValue({ error: null })
    const result = await signInWithOtp({ email: 'owner@example.com' })
    expect(h.signInWithOtp).toHaveBeenCalledWith({
      email: 'owner@example.com',
      options: {
        emailRedirectTo: 'http://localhost:3000/auth/callback',
      },
    })
    expect(result.success).toBe(true)
    expect(result.message).toContain('رابط الدخول')
  })

  it('يحوّل فشل إرسال الرابط إلى رسالة عربية مضبوطة', async () => {
    h.signInWithOtp.mockResolvedValue({
      error: { message: 'Email provider is not configured' },
    })
    const result = await signInWithOtp({ email: 'owner@example.com' })
    expect(result.success).toBe(false)
    expect(result.error).toBe('تعذّر إرسال رابط الدخول، يرجى التحقق من البريد الإلكتروني')
    expect(result.error).not.toContain('Email provider')
  })
})

describe('طلب إعادة تعيين كلمة المرور', () => {
  it('يرفض بريداً إلكترونياً غير صالح قبل الاتصال بـ Supabase', async () => {
    const result = await requestPasswordReset({ email: 'not-an-email' })
    expect(result.success).toBe(false)
    expect(h.resetPasswordForEmail).not.toHaveBeenCalled()
  })

  it('يرسل رابط إعادة التعيين إلى صفحة تحديث كلمة المرور', async () => {
    h.resetPasswordForEmail.mockResolvedValue({ error: null })
    const result = await requestPasswordReset({ email: 'owner@example.com' })
    expect(h.resetPasswordForEmail).toHaveBeenCalledWith('owner@example.com', {
      redirectTo: 'http://localhost:3000/auth/callback?next=/auth/update-password',
    })
    expect(result.success).toBe(true)
    expect(result.message).toContain('إعادة تعيين')
  })

  it('يحوّل فشل إرسال البريد إلى رسالة عربية مضبوطة', async () => {
    h.resetPasswordForEmail.mockResolvedValue({
      error: { message: 'Email provider is not configured' },
    })
    const result = await requestPasswordReset({ email: 'owner@example.com' })
    expect(result.success).toBe(false)
    expect(result.error).toBe('تعذّر إرسال رابط إعادة التعيين، يرجى التحقق من البريد الإلكتروني')
    expect(result.error).not.toContain('Email provider')
  })
})

describe('تحديث كلمة المرور', () => {
  it('يرفض كلمة مرور قصيرة دون الاتصال بـ Supabase', async () => {
    const result = await updatePassword({ password: '123' })
    expect(result.success).toBe(false)
    expect(h.updateUser).not.toHaveBeenCalled()
  })

  it('يرفض التحديث دون جلسة صالحة (لا يوجد مستخدم)', async () => {
    h.getUser.mockResolvedValue({ data: { user: null } })
    const result = await updatePassword({ password: 'new-strong-pass' })
    expect(result.success).toBe(false)
    expect(h.updateUser).not.toHaveBeenCalled()
  })

  it('يحدّث كلمة المرور بجلسة صالحة ثم يسجّل الخروج', async () => {
    h.getUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    h.updateUser.mockResolvedValue({ error: null })
    h.signOut.mockResolvedValue({ error: null })
    const result = await updatePassword({ password: 'new-strong-pass' })
    expect(h.updateUser).toHaveBeenCalledWith({ password: 'new-strong-pass' })
    expect(h.signOut).toHaveBeenCalled()
    expect(result.success).toBe(true)
  })

  it('يحوّل خطأ Supabase الخام إلى رسالة عربية مضبوطة', async () => {
    h.getUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    h.updateUser.mockResolvedValue({ error: { message: 'Password update failed (500)' } })
    const result = await updatePassword({ password: 'new-strong-pass' })
    expect(result.success).toBe(false)
    expect(result.error).toBe('تعذّر تحديث كلمة المرور، يرجى المحاولة مرة أخرى')
    expect(result.error).not.toContain('500')
  })
})