import { describe, expect, it } from 'vitest'
import {
  deletePortfolioPhotoSchema,
  uploadPortfolioPhotoSchema,
} from './portfolio'

const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const PHOTO_ID = '44444444-4444-4444-8444-444444444444'
const IDEM_KEY = '11111111-1111-4111-8111-111111111105'
const PATH = `completed/${PROJECT_ID}/photo-1.jpg`

const validUpload = {
  projectId: PROJECT_ID,
  displayTitle: 'غرفة نوم كلاسيك',
  publicDescription: 'تشطيب كامل بخشب الزان',
  storagePath: PATH,
  sortOrder: 0,
  altText: 'صورة غرفة النوم',
  idempotencyKey: IDEM_KEY,
}

describe('uploadPortfolioPhotoSchema', () => {
  it('يقبل بيانات رفع صالحة', () => {
    const result = uploadPortfolioPhotoSchema.safeParse(validUpload)
    expect(result.success).toBe(true)
  })

  it('يقبل وصفاً ونصاً بديلاً فارغين', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({
      ...validUpload,
      publicDescription: null,
      altText: null,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض اسم العرض القصير جداً', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, displayTitle: 'أ' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم العرض قصير جداً')
  })

  it('يرفض اسم العرض الذي يتجاوز 200 حرف', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, displayTitle: 'أ'.repeat(201) })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم العرض طويل جداً')
  })

  it('يرفض الوصف العام الذي يتجاوز 1000 حرف', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, publicDescription: 'و'.repeat(1001) })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('الوصف العام طويل جداً')
  })

  it('يرفض مساراً خارج مجلد completed', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, storagePath: 'other/photo.jpg' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مسار الصورة غير صالح (يجب completed/<معرف المشروع>/<ملف>)')
  })

  it('يرفض امتداداً غير مسموح', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({
      ...validUpload,
      storagePath: `completed/${PROJECT_ID}/photo.gif`,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مسار الصورة غير صالح (يجب completed/<معرف المشروع>/<ملف>)')
  })

  it('يرفض مساراً يحاول الخروج من المجلد', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({
      ...validUpload,
      storagePath: `completed/${PROJECT_ID}/../secret.jpg`,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مسار الصورة غير صالح (يجب completed/<معرف المشروع>/<ملف>)')
  })

  it('يرفض مساراً يخص مشروعاً آخر', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({
      ...validUpload,
      storagePath: 'completed/55555555-5555-4555-8555-555555555555/photo-1.jpg',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مسار الصورة لا يطابق المشروع المحدد')
  })

  it('يرفض ترتيباً يتجاوز الحد الأقصى 10 صور', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, sortOrder: 10 })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('الحد الأقصى 10 صور للمشروع الواحد')
  })

  it('يرفض النص البديل الطويل', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, altText: 'ب'.repeat(201) })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('النص البديل طويل جداً')
  })

  it('يرفض معرف مشروع غير صالح', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, projectId: 'x' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = uploadPortfolioPhotoSchema.safeParse({ ...validUpload, idempotencyKey: 'short' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('deletePortfolioPhotoSchema', () => {
  it('يقبل حذفاً صالحاً', () => {
    const result = deletePortfolioPhotoSchema.safeParse({ photoId: PHOTO_ID, idempotencyKey: IDEM_KEY })
    expect(result.success).toBe(true)
  })

  it('يرفض معرف صورة غير صالح', () => {
    const result = deletePortfolioPhotoSchema.safeParse({ photoId: 'x', idempotencyKey: IDEM_KEY })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف الصورة غير صالح')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = deletePortfolioPhotoSchema.safeParse({ photoId: PHOTO_ID, idempotencyKey: 'abc' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})
