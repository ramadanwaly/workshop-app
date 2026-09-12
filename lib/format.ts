export function formatCurrency(value: number | null | undefined): string {
  return `${Number(value ?? 0).toLocaleString('ar-EG')} ج.م`
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return '—'
  return new Date(value).toLocaleDateString('ar-EG', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}