import { describe, expect, it } from 'vitest'
import { escapeIlike, pageSchema } from './list'

describe('pageSchema', () => {
  it('يقبل فراغاً بحدود افتراضية', () => {
    const r = pageSchema.safeParse({})
    expect(r.success).toBe(true)
    if (r.success) {
      expect(r.data).toEqual({ page: 1, perPage: 50 })
    }
  })

  it('يقبل صفحة ورقماً صالحين ونص بحث', () => {
    const r = pageSchema.safeParse({ page: '2', perPage: 25, q: 'خشب' })
    expect(r.success).toBe(true)
    if (r.success) {
      expect(r.data).toEqual({ page: 2, perPage: 25, q: 'خشب' })
    }
  })

  it('يرفض صفحة صفرية وعدداً متجاوزاً ونصاً ضخماً', () => {
    expect(pageSchema.safeParse({ page: 0 }).success).toBe(false)
    expect(pageSchema.safeParse({ perPage: 201 }).success).toBe(false)
    expect(pageSchema.safeParse({ q: 'x'.repeat(101) }).success).toBe(false)
  })
})

describe('escapeIlike', () => {
  it('يهرب % و _ و \\ حرفياً', () => {
    expect(escapeIlike('100%_خصم\\')).toBe('100\\%\\_خصم\\\\')
  })

  it('يترك النص العادي كما هو', () => {
    expect(escapeIlike('خشب سويد')).toBe('خشب سويد')
  })
})
