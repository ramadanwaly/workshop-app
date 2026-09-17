import { cache } from 'react'
import { createClient } from '@/lib/supabase/server'

export type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

export type AuthResult = {
  supabase: Awaited<ReturnType<typeof createClient>>
  userId: string | null
  role: 'owner' | 'manager' | null
  error: string | null
}

/**
 * جلب هوية المستخدم ودوره مرة واحدة لكل طلب (Request memoization).
 * React's cache() يضمن: نفس الطلب + نفس الوسائط = تنفيذ فعلي واحد فقط،
 * وباقي الاستدعاءات تأخذ النتيجة من الذاكرة بدون أي استعلام جديد.
 * لا يغيّر أي منطق صلاحيات — فقط آلية الجلب.
 * ملاحظة: العميل (supabase client) يُنشأ طازجاً في كل استدعاء ولا يُخزَّن،
 * لأن setAll للكوكيز يجب أن يعمل في سياق الاستدعاء الحالي.
 */
type IdentityResult = {
  userId: string | null
  role: 'owner' | 'manager' | null
}

const fetchIdentity = async (): Promise<IdentityResult> => {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return { userId: null, role: null }
  }
  const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single()
  return { userId: user.id, role: (profile?.role as 'owner' | 'manager' | null) ?? null }
}

const getCachedIdentity = cache(fetchIdentity)

/**
 * في بيئة الاختبارات (vitest) لا يوجد سياق طلب (request scope) حقيقي،
 * وكل اختبار يمثّل طلباً مختلفاً بهوية مختلفة، لذلك نتجاوز الكاش هناك
 * للحفاظ على عزل الاختبارات. في الإنتاج/التطوير نستخدم الكاش لكل طلب.
 */
async function getIdentity(): Promise<IdentityResult> {
  if (process.env.VITEST) {
    return fetchIdentity()
  }
  return getCachedIdentity()
}

/**
 * التأكد من أن المستخدم مسجل دخول (أي رتبة)
 */
export async function requireUser(): Promise<AuthResult> {
  const supabase = await createClient()
  const { userId, role } = await getIdentity()
  if (!userId) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }
  return { supabase, userId, role, error: null }
}

/**
 * التأكد من أن المستخدم موظف في الورشة (مالك أو مدير)
 */
export async function requireStaff(): Promise<AuthResult> {
  const supabase = await createClient()
  const { userId, role } = await getIdentity()
  if (!userId) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }

  if (role !== 'owner' && role !== 'manager') {
    return {
      supabase,
      userId: null,
      role: null,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط',
    }
  }

  return { supabase, userId, role, error: null }
}

/**
 * التأكد من أن المستخدم هو المالك حصراً
 */
export async function requireOwner(): Promise<AuthResult> {
  const supabase = await createClient()
  const { userId, role } = await getIdentity()
  if (!userId) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }

  if (role !== 'owner') {
    return {
      supabase,
      userId: null,
      role: null,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    }
  }

  return { supabase, userId, role, error: null }
}
