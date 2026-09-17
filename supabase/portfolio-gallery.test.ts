import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

// اختبار سلبي ثابت للمرحلة 1 (بدون قاعدة بيانات — يعمل في CI):
// يقرأ ملف الـmigration الوحيد للمعرض ويتأكد أن anon مرفوض من قراءة
// projects والجداول المالية مباشرة، وأن المنفذ العام الوحيد هو الـView.
const MIGRATION = readFileSync(
  new URL('./migrations/20260916000046_portfolio_gallery.sql', import.meta.url),
  'utf8',
)

const stripComments = (sql: string) =>
  sql
    .split('\n')
    .map((line) => line.replace(/--.*$/, ''))
    .join('\n')

const body = stripComments(MIGRATION)

describe('عزل معرض الأعمال العام عن البيانات المالية (اختبار سلبي)', () => {
  it('لا يوجد أي GRANT لقراءة projects أو الجداول المالية من anon', () => {
    const financialObjects = [
      'projects',
      'treasury_transactions',
      'worker_advances',
      'worker_logs',
      'subcontract_orders',
      'subcontract_payments',
      'general_expenses',
      'surplus_bank',
      'portfolio_entries',
      'portfolio_photos',
    ]
    for (const table of financialObjects) {
      const grantToAnon = new RegExp(
        `GRANT[^;]*ON\\s+(public\\.)?${table}\\s+TO[^;]*\\banon\\b`,
        'i',
      )
      expect(
        body,
        `ممنوع منح anon أي صلاحية على ${table} مباشرة`,
      ).not.toMatch(grantToAnon)
    }
  })

  it('لا توجد أي سياسة TO anon على الجدولين أو storage.objects', () => {
    const anonPolicy = /CREATE POLICY[^;]*TO\s+anon/i
    expect(body, 'ممنوعة أي سياسة TO anon — القراءة العامة عبر الـView فقط').not.toMatch(
      anonPolicy,
    )
  })

  it('الـView العام الوحيد يسرد 7 أعمدة بالاسم فقط بلا مالية وبلا project_id', () => {
    expect(body).toMatch(/CREATE OR REPLACE VIEW public\.v_portfolio_gallery_public/i)
    expect(body).not.toMatch(/SELECT\s+\*/)

    const viewMatch = body.match(
      /CREATE OR REPLACE VIEW public\.v_portfolio_gallery_public AS([\s\S]*?);/,
    )
    expect(viewMatch, 'تعريف الـView العام موجود').not.toBeNull()
    const viewDef = viewMatch?.[1] ?? ''

    for (const col of [
      'entry_id',
      'display_title',
      'public_description',
      'storage_path',
      'alt_text',
      'sort_order',
      'completed_at',
    ]) {
      expect(viewDef).toMatch(new RegExp(`\\b${col}\\b`))
    }

    const selectList = viewDef.slice(
      0,
      viewDef.toLowerCase().indexOf('from public.portfolio_entries'),
    )
    expect(selectList, 'قائمة SELECT موجودة').not.toBe('')
    expect(selectList.toLowerCase()).not.toContain('project_id')
    for (const money of ['amount', 'cost', 'profit', 'revenue', 'balance', 'liabilit']) {
      expect(selectList.toLowerCase(), `ممنوع عمود مالي (${money}) في الـView`).not.toContain(
        money,
      )
    }
    expect(viewDef).toMatch(/status\s*=\s*'completed'/)
  })

  it('المنح العام الوحيد المسموح هو SELECT على الـView العام', () => {
    const grantsToAnon = body.match(/GRANT[^;]*TO[^;]*\banon\b/gi) ?? []
    expect(grantsToAnon.length).toBeGreaterThan(0)
    for (const grant of grantsToAnon) {
      expect(
        grant,
        `أي GRANT TO anon آخر مرفوض: ${grant}`,
      ).toMatch(/v_portfolio_gallery_public/i)
    }
  })

  it('كتابة المعرض للموظفين فقط عبر is_staff ولا توجد سياسة FOR ALL', () => {
    expect(body).toMatch(/app_private\.is_staff\(\)/)
    expect(body).not.toMatch(/FOR ALL/)
  })

  it('حراس الاكتمال وحد الصور موجودة بأخطاء عربية', () => {
    expect(body).toMatch(/لا يمكن عرض مشروع غير مكتمل في معرض الأعمال/)
    expect(body).toMatch(/لا يمكن إضافة صورة لمشروع غير مكتمل في معرض الأعمال/)
    expect(body).toMatch(/الحد الأقصى 10 صور للمشروع الواحد/)
  })
})
