'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireOwner, requireStaff } from '@/lib/actions/guard'
import {
  createManagerSchema,
  updateOverheadSchema,
  type CreateManagerInput,
  type UpdateOverheadInput,
} from '@/lib/validations/settings'
import { createAdminClient } from '@/lib/supabase/admin'

type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

// ----------------------------------------------------------------------------
// 1. جلب إعدادات النظام (getSettings)
// ----------------------------------------------------------------------------
export async function getSettings() {
  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
      .from('settings')
      .select('id, overhead_percentage')
      .limit(1)
      .maybeSingle()

    if (error) {
      maskAndThrow('get_settings', error)
    }

    return data ?? { id: '', overhead_percentage: 10.0 }
  } catch (err) {
    maskAndThrow('get_settings', err)
  }
}

// ----------------------------------------------------------------------------
// 2. تحديث نسبة الأوفر هيد (updateOverhead) — للمالك فقط
// ----------------------------------------------------------------------------
export async function updateOverhead(
  input: UpdateOverheadInput
): Promise<ActionResult> {
  try {
    // أ. التحقق من الهوية والصلاحية (للمالك فقط)
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    // ب. التحقق من المدخلات بـ Zod
    const parsed = updateOverheadSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { overheadPercentage, idempotencyKey } = parsed.data

    // ج. فحص منع التكرار (Idempotency) إن وجد
    const rl = await checkRateLimit(supabase, `w:update_overhead:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'update_overhead'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // د. تحديث صف الإعدادات الموجود أو إدراجه إن لم يوجد
    const { data: existingSettings } = await supabase
      .from('settings')
      .select('id')
      .limit(1)
      .maybeSingle()

    let resultData = null
    if (existingSettings?.id) {
      const { data: updated, error: updateError } = await supabase
        .from('settings')
        .update({ overhead_percentage: overheadPercentage })
        .eq('id', existingSettings.id)
        .select()
        .single()

      if (updateError) {
        return { success: false, error: routeActionError('update_overhead', updateError) }
      }
      resultData = updated
    } else {
      const { data: inserted, error: insertError } = await supabase
        .from('settings')
        .insert({ overhead_percentage: overheadPercentage })
        .select()
        .single()

      if (insertError) {
        return { success: false, error: routeActionError('update_overhead', insertError) }
      }
      resultData = inserted
    }

    revalidatePath('/', 'layout')
    // هـ. تأكيد اكتمال مفتاح منع التكرار
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'update_overhead', resultData)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: resultData, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }

    return { success: true, data: resultData }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('update_overhead', err) }
  }
}

// ----------------------------------------------------------------------------
// 3. جلب قائمة المستخدمين (getProfiles)
// ----------------------------------------------------------------------------
export async function getProfiles() {
  try {
    const auth = await requireOwner()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, role, created_at, updated_at')
      .order('created_at', { ascending: true })

    if (error) {
      maskAndThrow('get_profiles', error)
    }

    return data ?? []
  } catch (err) {
    maskAndThrow('get_profiles', err)
  }
}

// ----------------------------------------------------------------------------
// 4. إنشاء مدير جديد (createManager) — للمالك فقط
// ----------------------------------------------------------------------------
export async function createManager(
  input: CreateManagerInput
): Promise<ActionResult> {
  try {
    const auth = await requireOwner()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = createManagerSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { email, password, fullName, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:create_manager:${auth.userId}`, 10)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }

    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'create_manager'
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    const adminSupabase = createAdminClient()
    const { data: newUser, error: createError } = await adminSupabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName, role: 'manager' },
    })

    if (createError) {
      return { success: false, error: routeActionError('create_manager', createError) }
    }

    if (newUser.user) {
      await adminSupabase
        .from('profiles')
        .upsert({ id: newUser.user.id, role: 'manager', full_name: fullName })
    }

    const resultData = { id: newUser.user?.id, email: newUser.user?.email, fullName }

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'create_manager', resultData)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: resultData, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }

    return { success: true, data: resultData }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('create_manager', err) }
  }
}
