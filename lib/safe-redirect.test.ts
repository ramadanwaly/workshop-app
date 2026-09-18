import { describe, expect, it } from 'vitest'
import { safeNextPath } from './safe-redirect'

describe('تنقية مسار العودة بعد الدخول (P2-08 & Security Hardening)', () => {
  it('يقبل المسار الداخلي السليم بأشكاله المختلفة', () => {
    expect(safeNextPath('/dashboard')).toBe('/dashboard')
    expect(safeNextPath('/auth/update-password')).toBe('/auth/update-password')
    expect(safeNextPath('/projects/123-abc')).toBe('/projects/123-abc')
    expect(safeNextPath('/reports?year=2026&month=9')).toBe('/reports?year=2026&month=9')
  })

  it('يرفض الروابط الخارجية ويسقط على لوحة التحكم', () => {
    expect(safeNextPath('https://evil.example/x')).toBe('/dashboard')
    expect(safeNextPath('http://evil.example/x')).toBe('/dashboard')
    expect(safeNextPath('//evil.example/x')).toBe('/dashboard')
    expect(safeNextPath('///evil.example')).toBe('/dashboard')
  })

  it('يرفض محاولات التجاوز بشرطة عكسية (Backslash bypass)', () => {
    expect(safeNextPath('/\\evil.example')).toBe('/dashboard')
    expect(safeNextPath('\\evil.example')).toBe('/dashboard')
    expect(safeNextPath('/dashboard\\evil')).toBe('/dashboard')
  })

  it('يرفض محاولات التجاوز بالبروتوكولات الأخرى (javascript:, data:, vbscript:)', () => {
    expect(safeNextPath('javascript:alert(1)')).toBe('/dashboard')
    expect(safeNextPath('data:text/html,<script>alert(1)</script>')).toBe('/dashboard')
    expect(safeNextPath('vbscript:msgbox(1)')).toBe('/dashboard')
  })

  it('يرفض القيم الفارغة وغير النصية والمسافات الضائعة', () => {
    expect(safeNextPath('')).toBe('/dashboard')
    expect(safeNextPath('   ')).toBe('/dashboard')
    expect(safeNextPath(null)).toBe('/dashboard')
    expect(safeNextPath(undefined)).toBe('/dashboard')
    expect(safeNextPath(42)).toBe('/dashboard')
    expect(safeNextPath({})).toBe('/dashboard')
    expect(safeNextPath([])).toBe('/dashboard')
  })
})
