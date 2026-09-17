import { describe, expect, it } from 'vitest'
import { safeNextPath } from './safe-redirect'

describe('تنقية مسار العودة بعد الدخول', () => {
  it('يقبل المسار الداخلي السليم', () => {
    expect(safeNextPath('/dashboard')).toBe('/dashboard')
    expect(safeNextPath('/auth/update-password')).toBe('/auth/update-password')
  })

  it('يرفض الروابط الخارجية ويسقط على لوحة التحكم', () => {
    expect(safeNextPath('https://evil.example/x')).toBe('/dashboard')
    expect(safeNextPath('//evil.example/x')).toBe('/dashboard')
  })

  it('يرفض القيم الفارغة وغير النصية', () => {
    expect(safeNextPath('')).toBe('/dashboard')
    expect(safeNextPath(null)).toBe('/dashboard')
    expect(safeNextPath(undefined)).toBe('/dashboard')
    expect(safeNextPath(42)).toBe('/dashboard')
  })
})
