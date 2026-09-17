import { z } from 'zod'
import { idempotencyKeyField } from './text'

// ----------------------------------------------------------------------------
// تحقق معرض الأعمال الداخلي (المرحلة 2): إدارة صور المشاريع المكتملة فقط.
// لا مالية هنا — الاسم والوصف المبسط والصور فقط. الحدود تطابق migration 46:
// display_title حتى 200، public_description حتى 1000، alt_text حتى 200،
// sort_order من 0 إلى 9 (حتى 10 صور)، والمسار completed/<uuid>/<file>.
// ----------------------------------------------------------------------------

/** مسار ملزم داخل bucket portfolio: completed/<project_uuid>/<file> */
export const portfolioStoragePathField = z
  .string({ error: 'مسار الصورة مطلوب' })
  .trim()
  .min(1, 'مسار الصورة مطلوب')
  .max(500, 'مسار الصورة طويل جداً')
  .regex(
    /^completed\/[0-9a-fA-F-]{36}\/[A-Za-z0-9][A-Za-z0-9._-]*\.(jpg|jpeg|png|webp)$/,
    'مسار الصورة غير صالح (يجب completed/<معرف المشروع>/<ملف>)',
  )

export const uploadPortfolioPhotoSchema = z
  .object({
    projectId: z.string().uuid('معرف المشروع غير صالح'),
    displayTitle: z
      .string({ error: 'اسم العرض مطلوب' })
      .trim()
      .min(2, 'اسم العرض قصير جداً')
      .max(200, 'اسم العرض طويل جداً'),
    publicDescription: z
      .string()
      .trim()
      .max(1000, 'الوصف العام طويل جداً')
      .optional()
      .nullable(),
    storagePath: portfolioStoragePathField,
    sortOrder: z.coerce
      .number()
      .int('ترتيب الصورة غير صالح')
      .min(0, 'ترتيب الصورة غير صالح')
      .max(9, 'الحد الأقصى 10 صور للمشروع الواحد'),
    altText: z.string().trim().max(200, 'النص البديل طويل جداً').optional().nullable(),
    idempotencyKey: idempotencyKeyField,
  })
  .superRefine((value, ctx) => {
    // دفاع إضافي: الـuuid داخل المسار يجب أن يطابق المشروع المحدد
    const match = value.storagePath.match(/^completed\/([^/]+)\//)
    if (match && match[1].toLowerCase() !== value.projectId.toLowerCase()) {
      ctx.addIssue({ code: 'custom', message: 'مسار الصورة لا يطابق المشروع المحدد' })
    }
  })

export const deletePortfolioPhotoSchema = z.object({
  photoId: z.string().uuid('معرف الصورة غير صالح'),
  idempotencyKey: idempotencyKeyField,
})

export type UploadPortfolioPhotoInput = z.infer<typeof uploadPortfolioPhotoSchema>
export type DeletePortfolioPhotoInput = z.infer<typeof deletePortfolioPhotoSchema>
