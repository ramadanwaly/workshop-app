import { z } from 'zod'
import { MAX_10_2, positiveAmount } from './money'
import { idempotencyKeyField, phoneField, requiredName } from './text'

const dailyRateSchema = () =>
  positiveAmount({
    notNumber: 'الأجر اليومي يجب أن يكون رقماً',
    notFinite: 'الأجر اليومي غير صالح',
    tooSmall: 'الأجر اليومي يجب أن يكون أكبر من صفر',
    max: MAX_10_2,
  })

export const createWorkerSchema = z.object({
  name: requiredName('اسم العامل'),
  phone: phoneField,
  dailyRate: dailyRateSchema(),
  idempotencyKey: idempotencyKeyField,
})

export const updateWorkerSchema = z.object({
  workerId: z.string().uuid('معرف العامل غير صالح'),
  name: requiredName('اسم العامل'),
  phone: phoneField,
  dailyRate: dailyRateSchema(),
  idempotencyKey: idempotencyKeyField,
})

export const toggleWorkerStatusSchema = z.object({
  workerId: z.string().uuid('معرف العامل غير صالح'),
  isActive: z.boolean(),
  idempotencyKey: idempotencyKeyField,
})

export type CreateWorkerInput = z.infer<typeof createWorkerSchema>
export type UpdateWorkerInput = z.infer<typeof updateWorkerSchema>
export type ToggleWorkerStatusInput = z.infer<typeof toggleWorkerStatusSchema>
