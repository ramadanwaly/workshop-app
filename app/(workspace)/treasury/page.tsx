import { Suspense } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { formatCurrency } from '@/lib/format'
import { getTreasuryBalance, getTreasuryLedger } from '@/actions/treasury'
import { getOperatingAllocationCycles, getOperatingAllocationExclusions } from '@/actions/operating'
import { LedgerTable } from '@/components/treasury/ledger-table'
import { OperatingAllocationPanel } from '@/components/treasury/operating-allocation-panel'
import { Pagination } from '@/components/ui/pagination'
import { TreasuryFilters } from '@/components/treasury/treasury-filters'

type TreasuryPageProps = {
  searchParams: Promise<{ q?: string; category?: string; type?: string; from?: string; to?: string; page?: string }>
}

const CATEGORY_OPTIONS = [
  { value: '', label: 'كل التصنيفات' },
  { value: 'owner_funding', label: 'تمويل المالك' },
  { value: 'material', label: 'مواد' },
  { value: 'freight', label: 'شحن' },
  { value: 'workshop_operating', label: 'مصاريف تشغيل' },
  { value: 'advance', label: 'سلفة' },
  { value: 'settlement', label: 'تسوية' },
  { value: 'subcontract_payment', label: 'دفع مقاول' },
  { value: 'general_expense', label: 'مصروف عام' },
  { value: 'carried_forward_advance', label: 'سلفة مُحولة' },
  { value: 'other', label: 'أخرى' },
]

export default async function TreasuryPage(props: TreasuryPageProps) {
  const searchParams = await props.searchParams
  const filters = {
    q: searchParams?.q || undefined,
    category: searchParams?.category || undefined,
    type: searchParams?.type || undefined,
    from: searchParams?.from || undefined,
    to: searchParams?.to || undefined,
    page: searchParams?.page || undefined,
  }

  const hasActiveFilters = Boolean(filters.q || filters.category || filters.type || filters.from || filters.to)

  return (
    <main className="min-h-screen pb-16">
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        
        {/* Page Header */}
        <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-ink sm:text-3xl">الخزينة</h1>
            <p className="mt-1 text-sm text-secondary">الرصيد الكلي ودفتر الحركات المالية للورشة</p>
          </div>
        </div>

        <Suspense fallback={<TreasurySkeleton />}>
          <TreasuryContent filters={filters} hasActiveFilters={hasActiveFilters} />
        </Suspense>
      </div>
    </main>
  )
}

function TreasurySkeleton() {
  return (
    <div className="animate-pulse space-y-8">
      <div className="h-48 w-full rounded-md border border-border bg-card/50" />
      <div className="h-24 w-full rounded-md border border-border bg-card/50" />
      <div className="h-96 w-full rounded-md border border-border bg-card/50" />
    </div>
  )
}

async function TreasuryContent({ filters, hasActiveFilters }: { filters: { q?: string; category?: string; type?: string; from?: string; to?: string; page?: string }; hasActiveFilters: boolean }) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return (
      <div>
        <h1 className="mb-4 text-2xl font-bold text-danger">غير مصرح</h1>
        <p className="text-secondary">يرجى تسجيل الدخول للوصول إلى الخزينة.</p>
      </div>
    )
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const userRole = profile?.role ?? 'staff'
  const canRecordExpense = userRole === 'owner' || userRole === 'manager'
  const canInjectFunding = userRole === 'owner'

  let balance = null
  let ledger: Awaited<ReturnType<typeof getTreasuryLedger>> | null = null
  let cycles: Awaited<ReturnType<typeof getOperatingAllocationCycles>> = []
  let exclusions: Awaited<ReturnType<typeof getOperatingAllocationExclusions>> = []
  let projectsList = []

  try {
    const [balanceResult, ledgerResult, cyclesResult, exclusionsResult, projectsResult] = await Promise.all([
      getTreasuryBalance(),
      getTreasuryLedger({ ...filters, perPage: 50 }),
      getOperatingAllocationCycles(),
      getOperatingAllocationExclusions(),
      // قائمة المشاريع مستقلة عن الأربعة أعلاه، فتُنفَّذ معها بدل التتابع بعدها
      supabase.from('projects').select('id, name').order('name'),
    ])
    balance = balanceResult
    ledger = ledgerResult ?? null
    cycles = cyclesResult ?? []
    exclusions = exclusionsResult ?? []
    projectsList = projectsResult.data ?? []
  } catch (err) {
    console.error('[treasury] فشل تحميل بيانات الخزينة:', err)
    return (
      <section className="max-w-xl rounded-md border border-danger/20 bg-danger/5 p-5 sm:p-6" aria-labelledby="treasury-error-title">
        <p className="text-sm font-semibold text-danger">تعذّر تحميل البيانات المالية</p>
        <h1 id="treasury-error-title" className="mt-1 text-xl font-bold text-ink">لم تكتمل صفحة الخزينة</h1>
        <p className="mt-2 text-sm leading-6 text-secondary">لم نتمكن من جلب بيانات الخزينة الآن. أعد المحاولة، وإذا استمرت المشكلة فتحدث مع مالك الورشة.</p>
        <Link href="/treasury" className="mt-5 inline-flex h-10 items-center justify-center rounded-md bg-danger px-4 text-sm font-bold text-background transition hover:bg-danger/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-danger/50">إعادة المحاولة</Link>
      </section>
    )
  }

  const isOverdrawn = Number(balance?.current_balance) < 0

  return (
    <>
      {/* Financial Summary */}
      <section className="mb-8" aria-labelledby="treasury-summary-title">
        <div className={`rounded-md border p-6 sm:p-8 ${isOverdrawn ? 'border-danger/40 bg-danger/5' : 'border-border bg-card'}`}>
          <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <h2 id="treasury-summary-title" className="text-sm font-bold text-secondary">الرصيد الحالي في الخزينة</h2>
              <div className="mt-2 flex items-baseline gap-3">
                <p className={`text-4xl font-bold tabular-nums tracking-tight sm:text-5xl ${isOverdrawn ? 'text-danger' : 'text-ink'}`}>
                  {formatCurrency(balance?.current_balance)}
                </p>
              </div>
              {isOverdrawn ? (
                <p className="mt-4 max-w-md text-sm leading-6 text-danger" role="alert">
                  <strong className="font-bold">تنبيه: الرصيد مكشوف.</strong> راجع الحركات أو أضف تمويلًا من المالك.
                </p>
              ) : (
                <p className="mt-3 max-w-md text-sm text-muted-foreground">
                  يُحسب من الحركات الصحيحة، ويستبعد المدفوعات المباشرة للمالك.
                </p>
              )}
            </div>
            <dl className="flex gap-8 border-t border-border pt-6 lg:border-t-0 lg:pt-0">
              <div>
                <dt className="text-xs font-bold text-secondary">إجمالي الوارد</dt>
                <dd className="mt-1.5 text-lg font-bold tabular-nums text-success">{formatCurrency(balance?.total_in)}</dd>
              </div>
              <div>
                <dt className="text-xs font-bold text-secondary">إجمالي الصادر</dt>
                <dd className="mt-1.5 text-lg font-bold tabular-nums text-danger">{formatCurrency(balance?.total_out)}</dd>
              </div>
            </dl>
          </div>
        </div>
      </section>

      {/* Ledger Filters */}
      <section aria-labelledby="ledger-filters-title" className="mb-6">
        <div className="mb-3 flex items-center justify-between">
          <h2 id="ledger-filters-title" className="text-lg font-bold text-ink">دفتر الحركات</h2>
          {hasActiveFilters && (
            <span className="inline-flex items-center rounded-md bg-accent/10 px-2 py-1 text-xs font-bold text-accent">
              تصفية نشطة
            </span>
          )}
        </div>
        <TreasuryFilters
          filters={filters}
          categoryOptions={CATEGORY_OPTIONS}
          hasActiveFilters={hasActiveFilters}
        />
      </section>

      {/* Ledger Table */}
      <div className="mt-5">
        <LedgerTable 
          transactions={ledger?.rows ?? []} 
          userRole={userRole} 
          projects={projectsList} 
          canRecordExpense={canRecordExpense} 
          canInjectFunding={canInjectFunding} 
          hasActiveFilters={hasActiveFilters} 
        />
      </div>

      <div className="mt-4">
        <Pagination
          basePath="/treasury"
          params={{ q: filters.q, category: filters.category, type: filters.type, from: filters.from, to: filters.to }}
          page={ledger?.page ?? 1}
          perPage={ledger?.perPage ?? 50}
          total={ledger?.total ?? 0}
        />
      </div>

      {/* Operating Allocation */}
      <div className="mt-12">
        <OperatingAllocationPanel
          cycles={cycles ?? []}
          exclusions={exclusions ?? []}
          projects={projectsList ?? []}
          userRole={userRole}
        />
      </div>
    </>
  )
}
