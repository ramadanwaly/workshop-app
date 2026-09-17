import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

// المرحلة 1 — اتساق database.types.ts مع migration المعرض (بدون قاعدة بيانات).
// يتأكد أن الأنواع المولدة تعكس الجدولين والـView العام، وأن صف الـView
// لا يحمل project_id ولا أي حقل مالي.
const TYPES = readFileSync(new URL('../types/database.types.ts', import.meta.url), 'utf8')

// مقطع صف الـView العام فقط (من اسمه حتى Relationships التالية له)
const viewStart = TYPES.indexOf('v_portfolio_gallery_public')
const viewRowEnd = TYPES.indexOf('Relationships', viewStart)
const viewBlock = viewStart >= 0 && viewRowEnd > viewStart ? TYPES.slice(viewStart, viewRowEnd) : ''

describe('اتساق أنواع المعرض مع قاعدة البيانات', () => {
  it('الجدولان والـView موجودة في الأنواع', () => {
    expect(TYPES).toContain('portfolio_entries')
    expect(TYPES).toContain('portfolio_photos')
    expect(TYPES).toContain('v_portfolio_gallery_public')
  })

  it('صف الـView يحمل الأعمدة العامة السبع فقط بلا project_id ولا مالية', () => {
    expect(viewStart).toBeGreaterThanOrEqual(0)
    for (const col of [
      'entry_id',
      'display_title',
      'public_description',
      'storage_path',
      'alt_text',
      'sort_order',
      'completed_at',
    ]) {
      expect(viewBlock, `العمود ${col} موجود في النوع`).toContain(col)
    }
    expect(viewBlock).not.toContain('project_id')
    for (const money of ['amount', 'cost', 'profit', 'revenue', 'balance']) {
      expect(viewBlock, `ممنوع حقل مالي (${money}) في نوع الـView`).not.toContain(money)
    }
  })

  it('علاقة project_id الداخلية موثقة في نوع portfolio_entries فقط', () => {
    expect(TYPES).toContain('portfolio_entries_project_id_fkey')
  })
})

