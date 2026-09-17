import Link from 'next/link'

type PaginationProps = {
  basePath: string
  /** معاملات البحث الحالية للحفاظ عليها عند التنقل (بدون page) */
  params: Record<string, string | undefined>
  page: number
  perPage: number
  total: number
}

function href(basePath: string, params: Record<string, string | undefined>, page: number): string {
  const search = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== '') search.set(key, value)
  }
  search.set('page', String(page))
  return `${basePath}?${search.toString()}`
}

export function Pagination({ basePath, params, page, perPage, total }: PaginationProps) {
  const totalPages = Math.max(1, Math.ceil(total / perPage))
  if (totalPages <= 1) return null

  return (
    <nav aria-label="ترقيم الصفحات" className="mt-6 flex items-center justify-center gap-3">
      {page > 1 ? (
        <Link
          href={href(basePath, params, page - 1)}
          className="rounded-xl border border-secondary/30 bg-card px-4 py-2 text-sm font-bold text-primary transition hover:border-accent/60"
        >
          السابق
        </Link>
      ) : (
        <span className="cursor-not-allowed rounded-xl border border-secondary/20 bg-secondary/5 px-4 py-2 text-sm font-bold text-secondary/50">
          السابق
        </span>
      )}

      <span className="text-sm font-semibold text-secondary">
        صفحة <span className="font-bold tabular-nums text-ink">{page}</span> من{' '}
        <span className="font-bold tabular-nums text-ink">{totalPages}</span>
        <span className="text-secondary/70"> (الإجمالي {total})</span>
      </span>

      {page < totalPages ? (
        <Link
          href={href(basePath, params, page + 1)}
          className="rounded-xl border border-secondary/30 bg-card px-4 py-2 text-sm font-bold text-primary transition hover:border-accent/60"
        >
          التالي
        </Link>
      ) : (
        <span className="cursor-not-allowed rounded-xl border border-secondary/20 bg-secondary/5 px-4 py-2 text-sm font-bold text-secondary/50">
          التالي
        </span>
      )}
    </nav>
  )
}
