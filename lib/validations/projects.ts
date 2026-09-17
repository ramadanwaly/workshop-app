import { z } from 'zod'
import { idempotencyKeyField } from './text'

export const PROJECT_STATUSES = ['active', 'on_hold', 'completed', 'cancelled'] as const

export type ProjectStatus = (typeof PROJECT_STATUSES)[number]

export const createProjectSchema = z.object({
  name: z
    .string({ error: 'اسم المشروع مطلوب' })
    .trim()
    .min(1, 'اسم المشروع مطلوب')
    .max(200, 'اسم المشروع طويل جداً'),
  description: z
    .string()
    .trim()
    .max(1000, 'الوصف طويل جداً')
    .optional()
    .nullable(),
  idempotencyKey: idempotencyKeyField,
})

export const updateProjectSchema = z.object({
  projectId: z.string().uuid('معرف المشروع غير صالح'),
  name: z
    .string({ error: 'اسم المشروع مطلوب' })
    .trim()
    .min(1, 'اسم المشروع مطلوب')
    .max(200, 'اسم المشروع طويل جداً')
    .optional(),
  description: z
    .string()
    .trim()
    .max(1000, 'الوصف طويل جداً')
    .optional()
    .nullable(),
  idempotencyKey: idempotencyKeyField,
})

export const updateProjectStatusSchema = z.object({
  projectId: z.string().uuid('معرف المشروع غير صالح'),
  status: z.enum(PROJECT_STATUSES, { error: 'حالة المشروع غير صالحة' }),
  idempotencyKey: idempotencyKeyField,
})

export type CreateProjectInput = z.infer<typeof createProjectSchema>
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>
export type UpdateProjectStatusInput = z.infer<typeof updateProjectStatusSchema>
