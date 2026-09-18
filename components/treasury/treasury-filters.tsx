'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter, usePathname, useSearchParams } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Label } from '@/components/ui/label'
import Link from 'next/link'
import { useDebounce } from '@/lib/hooks/use-debounce'

type TreasuryFiltersProps = {
  filters: {
    q?: string
    category?: string
    type?: string
    from?: string
    to?: string
  }
  categoryOptions: { value: string; label: string }[]
  hasActiveFilters: boolean
}

export function TreasuryFilters({ filters, categoryOptions, hasActiveFilters }: TreasuryFiltersProps) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()
  
  const isInitialMount = useRef(true)

  const [q, setQ] = useState(filters.q ?? '')
  const [category, setCategory] = useState(filters.category ?? '')
  const [type, setType] = useState(filters.type ?? '')
  const [from, setFrom] = useState(filters.from ?? '')
  const [to, setTo] = useState(filters.to ?? '')

  const debouncedQ = useDebounce(q, 300)

  // Update URL when any of the states change
  useEffect(() => {
    if (isInitialMount.current) {
      isInitialMount.current = false
      return
    }

    const params = new URLSearchParams()
    
    if (debouncedQ) params.set('q', debouncedQ)
    if (category) params.set('category', category)
    if (type) params.set('type', type)
    if (from) params.set('from', from)
    if (to) params.set('to', to)

    // Compare with current search params to avoid redundant pushes
    // We only care about the keys we manage
    const currentQ = searchParams.get('q') ?? ''
    const currentCategory = searchParams.get('category') ?? ''
    const currentType = searchParams.get('type') ?? ''
    const currentFrom = searchParams.get('from') ?? ''
    const currentTo = searchParams.get('to') ?? ''

    if (
      debouncedQ === currentQ &&
      category === currentCategory &&
      type === currentType &&
      from === currentFrom &&
      to === currentTo
    ) {
      return
    }

    router.replace(`${pathname}?${params.toString()}`, { scroll: false })
  }, [debouncedQ, category, type, from, to, pathname, router, searchParams])

  return (
    <div className="rounded-md border border-border bg-card p-4 transition-opacity">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-[2fr_1fr_1fr_1fr_1fr_auto] lg:items-end">
        <div className="relative">
          <Label htmlFor="ledger-search" className="mb-2 block text-xs font-bold text-secondary">البحث في الوصف أو المشروع</Label>
          <Input
            id="ledger-search"
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="مثال: شراء خشب..."
            maxLength={100}
          />
        </div>
        <div>
          <Label htmlFor="ledger-type" className="mb-2 block text-xs font-bold text-secondary">نوع الحركة</Label>
          <Select id="ledger-type" value={type} onChange={(e) => setType(e.target.value)}>
            <option value="">الكل</option>
            <option value="in">وارد فقط</option>
            <option value="out">صادر فقط</option>
          </Select>
        </div>
        <div>
          <Label htmlFor="ledger-category" className="mb-2 block text-xs font-bold text-secondary">التصنيف (اختياري)</Label>
          <Select id="ledger-category" value={category} onChange={(e) => setCategory(e.target.value)}>
            {categoryOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </Select>
        </div>
        <div>
          <Label htmlFor="ledger-from" className="mb-2 block text-xs font-bold text-secondary">من تاريخ</Label>
          <Input id="ledger-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        </div>
        <div>
          <Label htmlFor="ledger-to" className="mb-2 block text-xs font-bold text-secondary">إلى تاريخ</Label>
          <Input id="ledger-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} />
        </div>
        <div className="flex gap-2 pt-2 sm:col-span-2 lg:col-span-1 lg:pt-0">
          {hasActiveFilters && (
            <Link
              href="/treasury"
              onClick={() => {
                setQ('')
                setCategory('')
                setType('')
                setFrom('')
                setTo('')
              }}
              className="inline-flex h-10 w-full items-center justify-center rounded-md border border-input bg-background px-3 text-sm font-bold text-ink transition hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            >
              مسح
            </Link>
          )}
        </div>
      </div>
    </div>
  )
}
