import { describe, expect, it } from 'vitest'
import {
  createProjectSchema,
  updateProjectSchema,
  updateProjectStatusSchema,
} from './projects'

describe('createProjectSchema', () => {
  const valid = {
    name: 'غرفة نوم',
    idempotencyKey: '11111111-1111-4111-8111-111111111124',
  }

  it('يقبل مشروعاً صالحاً', () => {
    const result = createProjectSchema.safeParse(valid)
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.name).toBe('غرفة نوم')
    }
  })

  it('يقبل وصفاً اختيارياً', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      description: 'تشطيب كامل',
    })
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.description).toBe('تشطيب كامل')
    }
  })

  it('يقبل وصفاً بقيمة null', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      description: null,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض اسم المشروع الفارغ مع رسالة عربية', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      name: '   ',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم المشروع مطلوب')
  })

  it('يرفض اسم المشروع الذي يتجاوز 200 حرف', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      name: 'أ'.repeat(201),
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم المشروع طويل جداً')
  })

  it('يرفض وصف المشروع الذي يتجاوز 1000 حرف', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      description: 'و'.repeat(1001),
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('الوصف طويل جداً')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = createProjectSchema.safeParse({
      ...valid,
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('updateProjectSchema', () => {
  const id = '11111111-1111-4111-8111-111111111111'
  const idempotencyKey = '11111111-1111-4111-8111-111111111124'

  it('يقبل تحديثاً صالحاً', () => {
    const result = updateProjectSchema.safeParse({
      projectId: id,
      name: 'اسم جديد',
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض معرف مشروع غير صالح', () => {
    const result = updateProjectSchema.safeParse({
      projectId: 'x',
      name: 'اسم جديد',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يرفض اسم المشروع الفارغ عند التحديث', () => {
    const result = updateProjectSchema.safeParse({
      projectId: id,
      name: '',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم المشروع مطلوب')
  })

  it('يرفض اسم المشروع الطويل عند التحديث', () => {
    const result = updateProjectSchema.safeParse({
      projectId: id,
      name: 'س'.repeat(201),
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('اسم المشروع طويل جداً')
  })

  it('يقبل وصفاً فارغاً nullable', () => {
    const result = updateProjectSchema.safeParse({
      projectId: id,
      name: 'اسم',
      description: null,
      idempotencyKey,
    })
    expect(result.success).toBe(true)
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = updateProjectSchema.safeParse({
      projectId: id,
      idempotencyKey: 'abc',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})

describe('updateProjectStatusSchema', () => {
  const id = '11111111-1111-4111-8111-111111111111'
  const idempotencyKey = '11111111-1111-4111-8111-111111111124'

  it('يقبل الحالات الصالحة المختلفة', () => {
    const statuses = ['active', 'on_hold', 'completed', 'cancelled'] as const
    for (const status of statuses) {
      const result = updateProjectStatusSchema.safeParse({
        projectId: id,
        status,
        idempotencyKey,
      })
      expect(result.success).toBe(true)
    }
  })

  it('يرفض حالة غير صالحة مع رسالة عربية', () => {
    const result = updateProjectStatusSchema.safeParse({
      projectId: id,
      status: 'bogus',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('حالة المشروع غير صالحة')
  })

  it('يرفض معرف مشروع غير صالح', () => {
    const result = updateProjectStatusSchema.safeParse({
      projectId: 'x',
      status: 'active',
      idempotencyKey,
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('معرف المشروع غير صالح')
  })

  it('يرفض مفتاح عدم التكرار القصير', () => {
    const result = updateProjectStatusSchema.safeParse({
      projectId: id,
      status: 'active',
      idempotencyKey: 'short',
    })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].message).toBe('مفتاح عدم التكرار غير صالح')
  })
})
