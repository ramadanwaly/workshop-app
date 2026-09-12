import { z } from 'zod'
import { MAX_12_2, positiveAmount } from './money'
import { idempotencyKeyField, optionalText, reasonField } from './text'

export const returnSurplusSchema = z.object({
  projectId: z.string().uuid('معرف المشروع غير صالح'),
  materialName: z.string().trim().min(2, 'اسم المادة يجب أن يكون حرفين على الأقل').max(200, 'اسم المادة طويل جداً'),
  unit: z.string().trim().min(1, 'وحدة القياس مطلوبة (مثل: كجم، متر، طن)').max(30, 'وحدة القياس طويلة جداً'),
  quantity: positiveAmount({
    notNumber: 'الكمية يجب أن تكون رقماً',
    notFinite: 'الكمية غير صالحة',
    tooSmall: 'الكمية يجب أن تكون أكبر من صفر',
    max: MAX_12_2,
  }),
  estimatedValue: positiveAmount({
    notNumber: 'القيمة التقديرية يجب أن تكون رقماً',
    notFinite: 'القيمة التقديرية غير صالحة',
    tooSmall: 'القيمة التقديرية يجب أن تكون أكبر من صفر',
    max: MAX_12_2,
  }),
  notes: optionalText(1000, 'الملاحظات طويلة جداً'),
  idempotencyKey: idempotencyKeyField,
})

export const consumeSurplusSchema = z.object({
  surplusId: z.string().uuid('معرف الفائض غير صالح'),
  targetProjectId: z.string().uuid('معرف المشروع المستهدف غير صالح'),
  consumeQuantity: positiveAmount({
    notNumber: 'الكمية المستهلكة يجب أن تكون رقماً',
    notFinite: 'الكمية المستهلكة غير صالحة',
    tooSmall: 'الكمية المستهلكة يجب أن تكون أكبر من صفر',
    max: MAX_12_2,
  }),
  notes: optionalText(1000, 'الملاحظات طويلة جداً'),
  idempotencyKey: idempotencyKeyField,
})

export const scrapSurplusSchema = z.object({
  surplusId: z.string().uuid('معرف الفائض غير صالح'),
  reason: reasonField('يجب كتابة سبب الإتلاف (3 أحرف على الأقل)'),
  idempotencyKey: idempotencyKeyField,
})

export type ReturnSurplusInput = z.infer<typeof returnSurplusSchema>
export type ConsumeSurplusInput = z.infer<typeof consumeSurplusSchema>
export type ScrapSurplusInput = z.infer<typeof scrapSurplusSchema>
