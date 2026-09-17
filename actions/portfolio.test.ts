import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  createSupabaseHarness,
  postgrestError,
  type SupabaseHarness,
} from '@/test/helpers/supabase-harness'

const hState = vi.hoisted(() => ({ harness: null as SupabaseHarness | null }))

vi.mock('@/lib/supabase/server', () => ({
  createClient: () => hState.harness!.createClient(),
}))

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}))

import { deletePortfolioPhoto, getProjectGalleryPhotos, uploadPortfolioPhoto } from './portfolio'

const h: SupabaseHarness = createSupabaseHarness()
hState.harness = h

const USER_ID = '11111111-1111-4111-8111-111111111111'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const ENTRY_ID = '55555555-5555-4555-8555-555555555555'
const PHOTO_ID = '44444444-4444-4444-8444-444444444444'
const IDEM_KEY = '11111111-1111-4111-8111-111111111105'
const PATH = `completed/${PROJECT_ID}/photo-1.jpg`

const uploadInput = {
  projectId: PROJECT_ID,
  displayTitle: 'غرفة نوم كلاسيك',
  publicDescription: 'تشطيب كامل',
  storagePath: PATH,
  sortOrder: 0,
  altText: 'صورة الغرفة',
  idempotencyKey: IDEM_KEY,
}

describe('uploadPortfolioPhoto — إدارة المعرض الداخلية', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يسجل صورة لمشروع مكتمل وينشئ صف العرض عند الحاجة', async () => {
    h.when('projects', 'select', { id: PROJECT_ID, status: 'completed' })
    h.when('portfolio_entries', 'select', null)
    h.when('portfolio_entries', 'insert', { id: ENTRY_ID })
    h.when('portfolio_photos', 'insert', {
      id: PHOTO_ID,
      entry_id: ENTRY_ID,
      storage_path: PATH,
      sort_order: 0,
      alt_text: 'صورة الغرفة',
      created_by: USER_ID,
    })

    const result = await uploadPortfolioPhoto(uploadInput)

    expect(result.success).toBe(true)
    expect(h.callsOf('portfolio_photos', 'insert')[0].args[0]).toMatchObject({
      entry_id: ENTRY_ID,
      storage_path: PATH,
    })
    expect(result.data).toMatchObject({ id: PHOTO_ID, storage_path: PATH })
    expect(result.data).not.toHaveProperty('created_by')
  })

  it('يستخدم صف العرض الموجود ولا ينشئ صفاً جديداً', async () => {
    h.when('projects', 'select', { id: PROJECT_ID, status: 'completed' })
    h.when('portfolio_entries', 'select', { id: ENTRY_ID })
    h.when('portfolio_photos', 'insert', {
      id: PHOTO_ID,
      entry_id: ENTRY_ID,
      storage_path: PATH,
      sort_order: 1,
      alt_text: null,
    })

    const result = await uploadPortfolioPhoto({ ...uploadInput, sortOrder: 1 })

    expect(result.success).toBe(true)
    expect(h.callsOf('portfolio_entries', 'insert')).toHaveLength(0)
  })

  it('يرفض التسجيل لمشروع غير مكتمل قبل أي كتابة', async () => {
    h.when('projects', 'select', { id: PROJECT_ID, status: 'active' })

    const result = await uploadPortfolioPhoto(uploadInput)

    expect(result).toEqual({
      success: false,
      error: 'لا يمكن عرض مشروع غير مكتمل في معرض الأعمال',
    })
    expect(h.callsOf('portfolio_entries', 'insert')).toHaveLength(0)
    expect(h.callsOf('portfolio_photos', 'insert')).toHaveLength(0)
  })

  it('يسمح للمدير ويرفض الزائر قبل أي كتابة', async () => {
    h.state.role = 'manager'
    h.when('projects', 'select', { id: PROJECT_ID, status: 'completed' })
    h.when('portfolio_entries', 'select', { id: ENTRY_ID })
    h.when('portfolio_photos', 'insert', {
      id: PHOTO_ID,
      entry_id: ENTRY_ID,
      storage_path: PATH,
      sort_order: 0,
      alt_text: null,
    })

    const managerResult = await uploadPortfolioPhoto(uploadInput)
    expect(managerResult.success).toBe(true)

    h.reset()
    h.state.user = null
    const guestResult = await uploadPortfolioPhoto(uploadInput)
    expect(guestResult).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يرفض المسار الفاسد عبر Zod قبل أي كتابة', async () => {
    const result = await uploadPortfolioPhoto({ ...uploadInput, storagePath: 'other/x.jpg' })

    expect(result.success).toBe(false)
    expect(result.error).toBe('مسار الصورة غير صالح (يجب completed/<معرف المشروع>/<ملف>)')
    expect(h.callsOf('projects', 'select')).toHaveLength(0)
  })

  it('يعيد النتيجة المخزنة عند تكرار المفتاح', async () => {
    const cached = { id: PHOTO_ID }
    h.idempotency.existing = { status: 'completed', response_payload: cached }

    const result = await uploadPortfolioPhoto(uploadInput)

    expect(result).toEqual({ success: true, data: cached })
    expect(h.callsOf('projects', 'select')).toHaveLength(0)
  })

  it('يمرر خطأ حد الصور من القاعدة بالعربية', async () => {
    h.when('projects', 'select', { id: PROJECT_ID, status: 'completed' })
    h.when('portfolio_entries', 'select', { id: ENTRY_ID })
    h.fail('portfolio_photos', 'insert', postgrestError('P0001', 'الحد الأقصى 10 صور للمشروع الواحد'))

    const result = await uploadPortfolioPhoto(uploadInput)

    expect(result).toEqual({ success: false, error: 'الحد الأقصى 10 صور للمشروع الواحد' })
  })
})

describe('deletePortfolioPhoto — حذف غير مالي', () => {
  beforeEach(() => {
    h.reset()
    h.state.user = { id: USER_ID }
    h.state.role = 'owner'
  })

  it('يحذف الصف ثم ملف التخزين وينجح', async () => {
    h.when('portfolio_photos', 'select', { id: PHOTO_ID, storage_path: PATH })
    h.when('portfolio_photos', 'delete', [])

    const result = await deletePortfolioPhoto({ photoId: PHOTO_ID, idempotencyKey: IDEM_KEY })

    expect(result).toEqual({ success: true, data: { id: PHOTO_ID } })
    expect(h.callsOf('portfolio_photos', 'delete')).toHaveLength(1)
    expect(h.storageRemovals).toEqual([{ bucket: 'portfolio', paths: [PATH] }])
  })

  it('ينجح مع تحذير عند فشل ملف التخزين', async () => {
    h.when('portfolio_photos', 'select', { id: PHOTO_ID, storage_path: PATH })
    h.when('portfolio_photos', 'delete', [])
    h.storageRemoveError = postgrestError('500', 'تعذر حذف الملف')

    const result = await deletePortfolioPhoto({ photoId: PHOTO_ID, idempotencyKey: IDEM_KEY })

    expect(result.success).toBe(true)
    expect(result.error).toBe('تم حذف الصورة من المعرض، لكن ملف التخزين يحتاج تنظيفاً يدوياً')
  })

  it('يرفض الصورة غير الموجودة قبل أي حذف', async () => {
    h.when('portfolio_photos', 'select', null)

    const result = await deletePortfolioPhoto({ photoId: PHOTO_ID, idempotencyKey: IDEM_KEY })

    expect(result).toEqual({ success: false, error: 'الصورة غير موجودة' })
    expect(h.callsOf('portfolio_photos', 'delete')).toHaveLength(0)
    expect(h.storageRemovals).toHaveLength(0)
  })

  it('يرفض الزائر قبل أي كتابة', async () => {
    h.state.user = null

    const result = await deletePortfolioPhoto({ photoId: PHOTO_ID, idempotencyKey: IDEM_KEY })

    expect(result).toEqual({ success: false, error: 'غير مصرح لك (يرجى تسجيل الدخول)' })
    expect(h.calls()).toHaveLength(0)
  })

  it('يرفض معرف الصورة الفاسد عبر Zod', async () => {
    const result = await deletePortfolioPhoto({ photoId: 'x', idempotencyKey: IDEM_KEY })

    expect(result).toEqual({ success: false, error: 'معرف الصورة غير صالح' })
    expect(h.callsOf('portfolio_photos', 'select')).toHaveLength(0)
  })
})

describe('getProjectGalleryPhotos — قراءة داخلية', () => {
  beforeEach(() => h.reset())

  it('يعيد الصف والصور بدون created_by', async () => {
    const entry = { id: ENTRY_ID, display_title: 'غرفة', public_description: null, completed_at: 'x' }
    const photos = [
      { id: PHOTO_ID, entry_id: ENTRY_ID, storage_path: PATH, sort_order: 0, alt_text: null, created_by: USER_ID },
    ]
    h.when('portfolio_entries', 'select', entry)
    h.when('portfolio_photos', 'select', photos)

    const res = await getProjectGalleryPhotos(PROJECT_ID)

    expect(res.entry).toEqual(entry)
    expect(res.photos).toEqual([
      { id: PHOTO_ID, entry_id: ENTRY_ID, storage_path: PATH, sort_order: 0, alt_text: null },
    ])
  })

  it('يعيد قائمة فارغة عند غياب صف العرض', async () => {
    h.when('portfolio_entries', 'select', null)

    const res = await getProjectGalleryPhotos(PROJECT_ID)

    expect(res).toEqual({ entry: null, photos: [] })
    expect(h.callsOf('portfolio_photos', 'select')).toHaveLength(0)
  })

  it('يرفض معرف المشروع الفاسد', async () => {
    await expect(getProjectGalleryPhotos('not-a-uuid')).rejects.toThrow('معرف المشروع غير صالح')
    expect(h.callsOf('portfolio_entries', 'select')).toHaveLength(0)
  })
})

