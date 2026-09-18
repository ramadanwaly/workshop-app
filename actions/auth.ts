'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { headers } from 'next/headers'
import { z } from 'zod'
import { checkRateLimit, hashId, rateLimitMessage } from '@/lib/rate-limit'
import { logError } from '@/lib/logger'

import { env } from '@/lib/validations/env'

// ---------------------------------------------------------------------------
// رابط الموقع الثابت — يُقرأ من متغير البيئة فقط وليس من ترويسة الطلب.
// هذا يمنع ثغرة تسميم Host حيث يمكن للمهاجم توجيه رمز الدخول لموقعه.
// ---------------------------------------------------------------------------
function getSiteUrl(): string {
  const url = env.NEXT_PUBLIC_SITE_URL.replace(/\/$/, '')
  if (!url) throw new Error('متغير NEXT_PUBLIC_SITE_URL غير مضبوط في بيئة الخادم')
  return url
}

// عنوان العميل للبصمات (يُجزّأ دائماً قبل التخزين — انظر lib/rate-limit.ts).
// ملاحظة: تسجيل الدخول بكلمة المرور مغطى في طبقة middleware (POST /login)،
// لذلك لا يُفحص هنا مرة ثانية حتى لا يُخصم من الحصة مرتين.
async function clientIpBucket(prefix: string, extra: string): Promise<string> {
  let ip = 'unknown'
  try {
    const h = await headers()
    ip = h.get('x-forwarded-for')?.split(',').pop()?.trim() || 'unknown'
  } catch {
    ip = 'unknown'
  }
  return `${prefix}:${hashId(ip)}:${hashId(extra)}`
}

type AuthResult = {
  success: boolean
  error?: string
  message?: string
}

const emailSchema = z.object({
  email: z.string().trim().email('يرجى إدخال بريد إلكتروني صحيح'),
})

const passwordSchema = emailSchema.extend({
  password: z.string().min(6, 'كلمة المرور يجب ألا تقل عن 6 أحرف'),
})

// ----------------------------------------------------------------------------
// تسجيل الدخول بالبريد وكلمة المرور
// الجلسة تُنشأ على الخادم عبر cookies() وتُربط ببقية الـ Server Actions.
// ----------------------------------------------------------------------------
export async function signInWithPassword(input: {
  email: string
  password: string
}): Promise<AuthResult> {
  const parsed = passwordSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message }
  }

  const supabase = await createClient()

  const rl = await checkRateLimit(
    supabase,
    await clientIpBucket('login', parsed.data.email),
    10,
    60,
    true
  )
  if (!rl.allowed) {
    return { success: false, error: rateLimitMessage(rl.retryAfter) }
  }

  const { error } = await supabase.auth.signInWithPassword({
    email: parsed.data.email,
    password: parsed.data.password,
  })

  if (error) {
    logError('auth_sign_in_password', error)
    return {
      success: false,
      error: 'بيانات الدخول غير صحيحة، يرجى المحاولة مرة أخرى',
    }
  }

  revalidatePath('/dashboard')
  return { success: true, message: 'تم تسجيل الدخول بنجاح' }
}

// ----------------------------------------------------------------------------
// تسجيل الدخول بالرابط السحري (بريد إلكتروني) — لا حاجة لكلمة مرور
// يرسل Supabase رسالة تحتوي رابطاً يعيد المستخدم إلى /auth/callback
// ----------------------------------------------------------------------------
export async function signInWithOtp(input: { email: string }): Promise<AuthResult> {
  const parsed = emailSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message }
  }

  const supabase = await createClient()

  const rl = await checkRateLimit(
    supabase,
    await clientIpBucket('otp', parsed.data.email),
    5,
    60,
    true
  )
  if (!rl.allowed) {
    return { success: false, error: rateLimitMessage(rl.retryAfter) }
  }

  const redirectTo = `${getSiteUrl()}/auth/callback`

  const { error } = await supabase.auth.signInWithOtp({
    email: parsed.data.email,
    options: { emailRedirectTo: redirectTo },
  })

  if (error) {
    logError('auth_sign_in_otp', error)
    return {
      success: false,
      error: 'تعذّر إرسال رابط الدخول، يرجى التحقق من البريد الإلكتروني',
    }
  }

  return { success: true, message: 'تم إرسال رابط الدخول إلى بريدك الإلكتروني' }
}

// ----------------------------------------------------------------------------
// طلب إعادة تعيين كلمة المرور — يُرسل بريداً يحتوي رابطاً يعيد المستخدم إلى
// /auth/callback?next=/auth/update-password (مع نوع recovery)
// ----------------------------------------------------------------------------
export async function requestPasswordReset(input: { email: string }): Promise<AuthResult> {
  const parsed = emailSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message }
  }

  const redirectTo = `${getSiteUrl()}/auth/callback?next=/auth/update-password`

  const supabase = await createClient()

  const rl = await checkRateLimit(
    supabase,
    await clientIpBucket('pwdreset', parsed.data.email),
    5,
    60,
    true
  )
  if (!rl.allowed) {
    return { success: false, error: rateLimitMessage(rl.retryAfter) }
  }

  const { error } = await supabase.auth.resetPasswordForEmail(parsed.data.email, {
    redirectTo,
  })

  if (error) {
    logError('auth_request_password_reset', error)
    return {
      success: false,
      error: 'تعذّر إرسال رابط إعادة التعيين، يرجى التحقق من البريد الإلكتروني',
    }
  }

  return {
    success: true,
    message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
  }
}

// ----------------------------------------------------------------------------
// تحديث كلمة المرور — يُستدعى من صفحة /auth/update-password التي يصل إليها
// المستخدم عبر رابط إعادة التعيين (جلسة recovery نشطة). لا يُسمح بالتحديث
// إلا بجلسة صالحة، وبعد النجاح يُسجَّل الخروج للدخول من جديد.
// ----------------------------------------------------------------------------
const newPasswordSchema = z.object({
  password: z
    .string()
    .min(6, 'كلمة المرور يجب ألا تقل عن 6 أحرف')
    .max(72, 'كلمة المرور يجب ألا تزيد عن 72 حرفاً'),
})

export async function updatePassword(input: { password: string }): Promise<AuthResult> {
  const parsed = newPasswordSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: parsed.error.issues[0].message }
  }

  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return {
      success: false,
      error: 'رابط إعادة التعيين غير صالح أو انتهت صلاحيته، أعد طلب رابط جديد',
    }
  }

  const rl = await checkRateLimit(supabase, `pwdupdate:${user.id}`, 10, 60, true)
  if (!rl.allowed) {
    return { success: false, error: rateLimitMessage(rl.retryAfter) }
  }

  const { error } = await supabase.auth.updateUser({ password: parsed.data.password })

  if (error) {
    logError('auth_update_password', error)
    return {
      success: false,
      error: 'تعذّر تحديث كلمة المرور، يرجى المحاولة مرة أخرى',
    }
  }

  await supabase.auth.signOut()
  revalidatePath('/login')
  return { success: true, message: 'تم تحديث كلمة المرور بنجاح، سجّل الدخول من جديد' }
}

// ----------------------------------------------------------------------------
// تسجيل الخروج — إبطال الجلسة ثم العودة لصفحة الدخول
// ----------------------------------------------------------------------------
export async function signOut(): Promise<AuthResult> {
  const supabase = await createClient()
  await supabase.auth.signOut()
  revalidatePath('/dashboard')
  redirect('/login')
}