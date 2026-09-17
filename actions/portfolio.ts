'use server'

import { revalidatePath } from 'next/cache'

import { checkAndLockIdempotency, markIdempotencyCompleted } from '@/lib/supabase/idempotency'
import { maskAndLogError, maskAndThrow, routeActionError } from '@/lib/server-errors'
import { checkRateLimit, rateLimitMessage } from '@/lib/rate-limit'
import { requireStaff } from '@/lib/actions/guard'
import {
  deletePortfolioPhotoSchema,
  uploadPortfolioPhotoSchema,
  type DeletePortfolioPhotoInput,
  type UploadPortfolioPhotoInput,
} from '@/lib/validations/portfolio'

type ActionResult<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}

// ----------------------------------------------------------------------------
// إدارة معرض الأعمال الداخلية (المرحلة 2) — للموظفين (مالك ومدير) فقط.
// حذف الصور هنا مسموح لأنه غير مالي (لا سجل محاسبي). الصفحة العامة تقرأ
// الـView العام فقط ولا تستورد هذا الملف أبداً.
// ----------------------------------------------------------------------------

// نوع الصورة المعادة للواجهة — بدون created_by (تعقيم DTO حسب المعايير)
export type PortfolioPhotoDto = {
  id: string
  entry_id: string
  storage_path: string
  sort_order: number
  alt_text: string | null
}

function sanitizePhoto(row: Record<string, unknown>): PortfolioPhotoDto {
  return {
    id: String(row.id),
    entry_id: String(row.entry_id),
    storage_path: String(row.storage_path),
    sort_order: Number(row.sort_order ?? 0),
    alt_text: (row.alt_text as string | null) ?? null,
  }
}

// ----------------------------------------------------------------------------
// 1. قراءة صور مشروع داخلية (لشاشة الإدارة) — للموظفين فقط
// ----------------------------------------------------------------------------
export async function getProjectGalleryPhotos(rawProjectId: string) {
  const uuidPattern = /^[0-9a-fA-F-]{36}$/
  if (!uuidPattern.test(rawProjectId)) throw new Error('معرف المشروع غير صالح')

  try {
    const auth = await requireStaff()
    if (!auth.userId) throw new Error(auth.error ?? 'غير مصرح لك')
    const supabase = auth.supabase

    const { data: entry, error: entryError } = await supabase
      .from('portfolio_entries')
      .select('id, display_title, public_description, completed_at')
      .eq('project_id', rawProjectId)
      .maybeSingle()

    if (entryError) maskAndThrow('get_project_gallery_photos', entryError)
    if (!entry) return { entry: null, photos: [] as PortfolioPhotoDto[] }

    const entryId = (entry as { id: string }).id
    const { data: photos, error: photosError } = await supabase
      .from('portfolio_photos')
      .select('id, entry_id, storage_path, sort_order, alt_text')
      .eq('entry_id', entryId)
      .order('sort_order', { ascending: true })

    if (photosError) maskAndThrow('get_project_gallery_photos', photosError)
    const rows = (photos ?? []) as Array<Record<string, unknown>>
    return { entry, photos: rows.map(sanitizePhoto) }
  } catch (err) {
    maskAndThrow('get_project_gallery_photos', err)
  }
}


// ----------------------------------------------------------------------------
// 2. تسجيل صورة مرفوعة في المعرض — للموظفين فقط
//    التدفق: الواجهة ترفع الملف للتخزين أولاً (بجلسة الموظف)، ثم تستدعي هذا
//    الإجراء لتسجيل المسار. يتحقق أن المشروع مكتمل وينشئ صف العرض عند الحاجة.
// ----------------------------------------------------------------------------
export async function uploadPortfolioPhoto(input: UploadPortfolioPhotoInput): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = uploadPortfolioPhotoSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { projectId, displayTitle, publicDescription, storagePath, sortOrder, altText, idempotencyKey } =
      parsed.data

    const rl = await checkRateLimit(supabase, `w:upload_portfolio_photo:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'upload_portfolio_photo',
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // أ. المشروع يجب أن يكون مكتملاً (شرط العرض التلقائي)
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('id, status')
      .eq('id', projectId)
      .maybeSingle()

    if (projectError) {
      return { success: false, error: routeActionError('upload_portfolio_photo', projectError) }
    }
    const status = (project as { status?: string } | null)?.status
    if (!project || status !== 'completed') {
      return { success: false, error: 'لا يمكن عرض مشروع غير مكتمل في معرض الأعمال' }
    }

    // ب. صف العرض: موجود أو يُنشأ لأول صورة
    const { data: existingEntry, error: entrySelectError } = await supabase
      .from('portfolio_entries')
      .select('id')
      .eq('project_id', projectId)
      .maybeSingle()

    if (entrySelectError) {
      return { success: false, error: routeActionError('upload_portfolio_photo', entrySelectError) }
    }

    let entryId = (existingEntry as { id?: string } | null)?.id ?? null
    if (!entryId) {
      const { data: newEntry, error: entryInsertError } = await supabase
        .from('portfolio_entries')
        .insert({
          project_id: projectId,
          display_title: displayTitle,
          public_description: publicDescription || null,
        })
        .select('id')
        .single()

      if (entryInsertError) {
        return { success: false, error: routeActionError('upload_portfolio_photo', entryInsertError) }
      }
      entryId = (newEntry as { id: string }).id
    }

    // ج. تسجيل الصورة (حد 10 صور وشرط الاكتمال يفرضهما حارسا القاعدة أيضاً)
    const { data: photo, error: photoError } = await supabase
      .from('portfolio_photos')
      .insert({
        entry_id: entryId,
        storage_path: storagePath,
        sort_order: sortOrder,
        alt_text: altText || null,
      })
      .select('id, entry_id, storage_path, sort_order, alt_text')
      .single()

    if (photoError) {
      return { success: false, error: routeActionError('upload_portfolio_photo', photoError) }
    }

    const dto = sanitizePhoto(photo as Record<string, unknown>)

    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'upload_portfolio_photo', dto)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: dto, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    return { success: true, data: dto }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('upload_portfolio_photo', err) }
  }
}

// ----------------------------------------------------------------------------
// 3. حذف صورة من المعرض — للموظفين فقط (حذف حقيقي مسموح: غير مالي).
//    يحذف صف القاعدة أولاً ثم ملف التخزين (الـView العام يقرأ من الجدول،
//    ففشل التخزين لا يعيد الصورة للمعرض — فقط تحذير تنظيف).
// ----------------------------------------------------------------------------
export async function deletePortfolioPhoto(input: DeletePortfolioPhotoInput): Promise<ActionResult> {
  try {
    const auth = await requireStaff()
    if (!auth.userId) return { success: false, error: auth.error ?? 'غير مصرح لك' }
    const supabase = auth.supabase

    const parsed = deletePortfolioPhotoSchema.safeParse(input)
    if (!parsed.success) {
      return { success: false, error: parsed.error.issues[0].message }
    }

    const { photoId, idempotencyKey } = parsed.data

    const rl = await checkRateLimit(supabase, `w:delete_portfolio_photo:${auth.userId}`, 30)
    if (!rl.allowed) return { success: false, error: rateLimitMessage(rl.retryAfter) }
    const idempotency = await checkAndLockIdempotency(
      supabase,
      idempotencyKey,
      auth.userId,
      'delete_portfolio_photo',
    )
    if (idempotency.alreadyCompleted) {
      return { success: true, data: idempotency.cachedData }
    }

    // أ. جلب مسار الصورة أولاً (لازم لحذف ملف التخزين بعدها)
    const { data: photo, error: photoError } = await supabase
      .from('portfolio_photos')
      .select('id, storage_path')
      .eq('id', photoId)
      .maybeSingle()

    if (photoError) {
      return { success: false, error: routeActionError('delete_portfolio_photo', photoError) }
    }
    if (!photo) {
      return { success: false, error: 'الصورة غير موجودة' }
    }
    const storagePath = (photo as { storage_path: string }).storage_path

    // ب. حذف الصف من القاعدة أولاً (الـView العام يقرأ من هنا)
    const { error: deleteError } = await supabase.from('portfolio_photos').delete().eq('id', photoId)

    if (deleteError) {
      return { success: false, error: routeActionError('delete_portfolio_photo', deleteError) }
    }

    // ج. حذف ملف التخزين — فشله لا يفشل العملية، فقط تحذير تنظيف
    let storageWarning: string | undefined
    const relativePath = storagePath.startsWith('portfolio/')
      ? storagePath.slice('portfolio/'.length)
      : storagePath
    const { error: storageError } = await supabase.storage.from('portfolio').remove([relativePath])
    if (storageError) {
      const { logError } = await import('@/lib/logger')
      logError('portfolio_storage_remove_failed', {
        photoId,
        storagePath,
        message: storageError.message,
      })
      storageWarning = 'تم حذف الصورة من المعرض، لكن ملف التخزين يحتاج تنظيفاً يدوياً'
    }

    const resultData = { id: photoId }
    revalidatePath('/', 'layout')
    try {
      await markIdempotencyCompleted(supabase, idempotencyKey, auth.userId, 'delete_portfolio_photo', resultData)
    } catch (err: unknown) {
      const { logError } = await import('@/lib/logger')
      logError('idempotency_mark_failed', err)
      return { success: true, data: resultData, error: 'تمت العملية بنجاح (مع تحذير في مفتاح التكرار)' }
    }
    if (storageWarning) {
      return { success: true, data: resultData, error: storageWarning }
    }
    return { success: true, data: resultData }
  } catch (err: unknown) {
    return { success: false, error: maskAndLogError('delete_portfolio_photo', err) }
  }
}

