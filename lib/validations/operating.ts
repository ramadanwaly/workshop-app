import { z } from 'zod'
import { idempotencyKeyField, optionalText, reasonField } from './text'

const monthPattern = /^\d{4}-(0[1-9]|1[0-2])$/

export const runOperatingAllocationSchema = z.object({
    yearMonth: z.string().regex(monthPattern, 'صيغة الشهر غير صالحة (مثال: 2026-08)'),
    idempotencyKey: idempotencyKeyField,
})

export const voidAllocationCycleSchema = z.object({
    cycleId: z.string().uuid('معرف الدورة غير صالح'),
    reason: reasonField(),
    idempotencyKey: idempotencyKeyField,
})

export const voidAllocationLineSchema = z.object({
    adjustmentId: z.string().uuid('معرف السطر غير صالح'),
    reason: reasonField(),
    idempotencyKey: idempotencyKeyField,
})

export const addOperatingExclusionSchema = z.object({
    yearMonth: z.string().regex(monthPattern, 'صيغة الشهر غير صالحة (مثال: 2026-08)'),
    projectId: z.string().uuid('معرف المشروع غير صالح'),
    reason: optionalText(1000, 'السبب طويل جداً (بحد أقصى 1000 حرف)'),
    idempotencyKey: idempotencyKeyField,
})

export const removeOperatingExclusionSchema = z.object({
    yearMonth: z.string().regex(monthPattern, 'صيغة الشهر غير صالحة (مثال: 2026-08)'),
    projectId: z.string().uuid('معرف المشروع غير صالح'),
    reason: reasonField('يجب كتابة سبب الإزالة (3 أحرف على الأقل)'),
    idempotencyKey: idempotencyKeyField,
})

export type RunOperatingAllocationInput = z.infer<typeof runOperatingAllocationSchema>
export type VoidAllocationCycleInput = z.infer<typeof voidAllocationCycleSchema>
export type VoidAllocationLineInput = z.infer<typeof voidAllocationLineSchema>
export type AddOperatingExclusionInput = z.infer<typeof addOperatingExclusionSchema>
export type RemoveOperatingExclusionInput = z.infer<typeof removeOperatingExclusionSchema>
