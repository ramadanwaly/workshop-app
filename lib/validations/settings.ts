import { z } from 'zod'
import { idempotencyKeyField } from './text'

export const updateOverheadSchema = z.preprocess(
  (val) => {
    if (typeof val === 'object' && val !== null) {
      const obj = val as Record<string, unknown>
      if ('overhead_percentage' in obj && !('overheadPercentage' in obj)) {
        return {
          ...obj,
          overheadPercentage:
            typeof obj.overhead_percentage === 'string'
              ? Number(obj.overhead_percentage)
              : obj.overhead_percentage,
        }
      }
    }
    return val
  },
  z.object({
    overheadPercentage: z
      .number({ error: 'نسبة الأوفر هيد يجب أن تكون رقماً' })
      .min(0, 'نسبة الأوفر هيد لا يمكن أن تكون بالسالب')
      .max(100, 'نسبة الأوفر هيد لا يمكن أن تتجاوز 100%'),
    idempotencyKey: idempotencyKeyField,
  })
)

export type UpdateOverheadInput = z.infer<typeof updateOverheadSchema>

export const createManagerSchema = z.object({
  email: z.string().trim().email('يرجى إدخال بريد إلكتروني صحيح'),
  password: z.string().min(6, 'كلمة المرور يجب ألا تقل عن 6 أحرف'),
  fullName: z.string().trim().min(2, 'الاسم الكامل يجب أن يكون حرفين على الأقل').max(100, 'الاسم طويل جداً'),
  idempotencyKey: idempotencyKeyField,
})

export type CreateManagerInput = z.infer<typeof createManagerSchema>

