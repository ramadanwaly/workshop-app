import { z } from 'zod'

// ----------------------------------------------------------------------------
// ترقيم وبحث مشترك (P2-05): page/perPage بحد 200، ونص بحث بحد 100 حرف.
// ----------------------------------------------------------------------------

export const pageSchema = z.object({
  page: z.coerce.number().int('رقم الصفحة غير صالح').min(1, 'رقم الصفحة غير صالح').default(1),
  perPage: z.coerce.number().int('عدد الصفوف غير صالح').min(1, 'عدد الصفوف غير صالح').max(200, 'عدد الصفوف غير صالح').default(50),
  q: z.string().trim().max(100, 'نص البحث طويل جداً').optional(),
})

export type PageInput = z.infer<typeof pageSchema>

/** هروب محارف ilike الخاصة (% _ \) حتى يبحث النص حرفياً */
export function escapeIlike(s: string): string {
  return s.replace(/[\\%_]/g, (m) => `\\${m}`)
}

export type PagedResult<TRow> = {
  rows: TRow[]
  total: number
  page: number
  perPage: number
}
