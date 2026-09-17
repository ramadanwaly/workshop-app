import { z } from 'zod'
import { pastDateSchema } from './dates'
import { MAX_12_2, positiveAmount } from './money'
import { idempotencyKeyField, optionalText, reasonField, requiredName } from './text'

export const createOrderSchema = z.object({
    projectId: z.string().uuid('معرف المشروع غير صالح'),
    contractorName: requiredName('اسم المقاول'),
    description: z.string().trim().min(1, 'وصف الاتفاقية مطلوب').max(1000, 'وصف الاتفاقية طويل جداً'),
    totalAgreedAmount: positiveAmount({
        notNumber: 'المبلغ المتفق عليه يجب أن يكون رقماً',
        notFinite: 'المبلغ غير صالح',
        tooSmall: 'المبلغ المتفق عليه يجب أن يكون أكبر من صفر',
        max: MAX_12_2,
    }),
    idempotencyKey: idempotencyKeyField,
})

export const paySubcontractSchema = z.object({
    orderId: z.string().uuid('معرف الاتفاقية غير صالح'),
    amount: positiveAmount({
        notNumber: 'المبلغ يجب أن يكون رقماً',
        notFinite: 'المبلغ غير صالح',
        tooSmall: 'المبلغ يجب أن يكون أكبر من صفر',
        max: MAX_12_2,
    }),
    paymentDate: pastDateSchema('تاريخ الدفعة مطلوب'),
    notes: optionalText(1000, 'الملاحظات طويلة جداً'),
    idempotencyKey: idempotencyKeyField,
})

export const voidPaymentSchema = z.object({
    paymentId: z.string().uuid('معرف الدفعة غير صالح'),
    reason: reasonField(),
    idempotencyKey: idempotencyKeyField,
})

export const closeOrderSchema = z.object({
    orderId: z.string().uuid('معرف الاتفاقية غير صالح'),
    status: z.enum(['completed', 'cancelled'], {
        error: 'حالة الإغلاق يجب أن تكون completed أو cancelled',
    }),
    reason: reasonField('يجب كتابة سبب الإغلاق (3 أحرف على الأقل)'),
    idempotencyKey: idempotencyKeyField,
})

export type CreateOrderInput = z.infer<typeof createOrderSchema>
export type PaySubcontractInput = z.infer<typeof paySubcontractSchema>
export type VoidPaymentInput = z.infer<typeof voidPaymentSchema>
export type CloseOrderInput = z.infer<typeof closeOrderSchema>
