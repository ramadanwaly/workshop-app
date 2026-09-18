import { z } from 'zod'
import { MAX_10_2, positiveAmount } from './money'
import { pastDateSchema } from './dates'
import { idempotencyKeyField, optionalText } from './text'

export const attendanceSchema = z.object({
    workerId: z.string().uuid('معرف العامل غير صالح'),
    projectId: z.string().uuid('معرف المشروع غير صالح').optional().nullable(),
    workDate: pastDateSchema('تاريخ العمل مطلوب'),
    fraction: z.union(
        [z.literal(0.25), z.literal(0.5), z.literal(1)],
        { error: 'نسبة العمل يجب أن تكون 0.25 أو 0.50 أو 1.00' }
    ),
    idempotencyKey: idempotencyKeyField,
})

export const advanceSchema = z.object({
    workerId: z.string().uuid('معرف العامل غير صالح'),
    amount: positiveAmount({
        notNumber: 'المبلغ يجب أن يكون رقماً',
        notFinite: 'المبلغ غير صالح',
        tooSmall: 'المبلغ يجب أن يكون أكبر من صفر',
        max: MAX_10_2,
    }),
    advanceDate: pastDateSchema('تاريخ السلفة مطلوب'),
    notes: optionalText(1000, 'الملاحظات طويلة جداً'),
    idempotencyKey: idempotencyKeyField,
})

export const settlementSchema = z.object({
    workerId: z.string().uuid('معرف العامل غير صالح'),
    notes: optionalText(1000, 'الملاحظات طويلة جداً'),
    idempotencyKey: idempotencyKeyField,
})

export const correctAttendanceSchema = z.object({
    logId: z.string().uuid('معرف السجل غير صالح'),
    newFraction: z.union(
        [z.literal(0.25), z.literal(0.5), z.literal(1)],
        { error: 'نسبة العمل يجب أن تكون 0.25 أو 0.50 أو 1.00' }
    ),
    newProjectId: z.string().uuid('معرف المشروع غير صالح').optional().nullable(),
    correctionReason: z.string().min(3, 'يجب كتابة سبب التصحيح (3 أحرف على الأقل)').max(1000, 'السبب طويل جداً'),
    idempotencyKey: idempotencyKeyField,
})

export type AttendanceInput = z.infer<typeof attendanceSchema>
export type AdvanceInput = z.infer<typeof advanceSchema>
export type SettlementInput = z.infer<typeof settlementSchema>
export type CorrectAttendanceInput = z.infer<typeof correctAttendanceSchema>
