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
 * التأكد من أن المستخدم مسجل دخول (أي رتبة)
 */
export async function requireUser(): Promise<AuthResult> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }
  const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single()
  return { supabase, userId: user.id, role: profile?.role as 'owner' | 'manager' | null, error: null }
}

/**
 * التأكد من أن المستخدم موظف في الورشة (مالك أو مدير)
 */
export async function requireStaff(): Promise<AuthResult> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'owner' && profile?.role !== 'manager') {
    return {
      supabase,
      userId: null,
      role: null,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لموظفي الورشة فقط',
    }
  }

  return { supabase, userId: user.id, role: profile.role as 'owner' | 'manager', error: null }
}

/**
 * التأكد من أن المستخدم هو المالك حصراً
 */
export async function requireOwner(): Promise<AuthResult> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return { supabase, userId: null, role: null, error: 'غير مصرح لك (يرجى تسجيل الدخول)' }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'owner') {
    return {
      supabase,
      userId: null,
      role: null,
      error: 'صلاحية مرفوضة: هذا الإجراء مخصص لمالك الورشة فقط',
    }
  }

  return { supabase, userId: user.id, role: profile.role as 'owner' | 'manager', error: null }
}
