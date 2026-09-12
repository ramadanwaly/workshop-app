import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import StatCard from '@/components/dashboard/stat-card'
import { formatCurrency } from '@/lib/format'
import { getTreasuryBalance, getTreasuryLedger } from '@/actions/treasury'
import { getOperatingAllocationCycles, getOperatingAllocationExclusions } from '@/actions/operating'
import { LedgerTable } from '@/components/treasury/ledger-table'
import { OperatingAllocationPanel } from '@/components/treasury/operating-allocation-panel'
import { Pagination } from '@/components/ui/pagination'

type TreasuryPageProps = {
  searchParams: Promise<{ q?: string; category?: string; from?: string; to?: string; page?: string }>
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
    from: searchParams?.from || undefined,
    to: searchParams?.to || undefined,
    page: searchParams?.page || undefined,
  }
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return (
      <main className="min-h-screen p-8">
        <h1 className="mb-4 text-2xl font-bold text-danger">غير مصرح</h1>
        <p className="text-secondary">يرجى تسجيل الدخول للوصول إلى الخزينة.</p>
      </main>
    )
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const userRole = profile?.role ?? 'staff'

  let balance = null
  let ledger: Awaited<ReturnType<typeof getTreasuryLedger>> | null = null
  let cycles: Awaited<ReturnType<typeof getOperatingAllocationCycles>> = []
  let exclusions: Awaited<ReturnType<typeof getOperatingAllocationExclusions>> = []
  let projectsList = []

  try {
    const [balanceResult, ledgerResult, cyclesResult, exclusionsResult] = await Promise.all([
      getTreasuryBalance(),
      getTreasuryLedger({ ...filters, perPage: 50 }),
      getOperatingAllocationCycles(),
      getOperatingAllocationExclusions(),
    ])
    const projectsResult = await supabase.from('projects').select('id, name').order('name')
    balance = balanceResult
    ledger = ledgerResult ?? null
    cycles = cyclesResult ?? []
    exclusions = exclusionsResult ?? []
    projectsList = projectsResult.data ?? []
  } catch (err) {
    console.error('[treasury] فشل تحميل بيانات الخزينة:', err)
    return (
      <main className="min-h-screen p-8">
        <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل الخزينة</h1>
        <p className="text-secondary">
          حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.
        </p>
      </main>
    )
  }

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-6">
          <h1 className="text-xl font-bold text-ink sm:text-2xl">الخزينة</h1>
          <p className="mt-1 text-sm text-secondary">
            حركات الخزينة والأرصدة
          </p>
        </div>

        {Number(balance?.current_balance) < 0 && (
          <div className="mb-6 rounded-xl border border-danger bg-danger/10 p-4 text-danger">
            ⚠️ تنبيه: رصيد الخزينة مكشوف (بالسالب). يرجى مراجعة الحركات المالية.
          </div>
        )}

        <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3 sm:gap-6">
          <StatCard
            title="إجمالي الوارد"
            value={formatCurrency(balance?.total_in)}
            accent="success"
          />
          <StatCard
            title="إجمالي الصادر"
            value={formatCurrency(balance?.total_out)}
            accent="danger"
          />
          <StatCard
            title="الرصيد الحالي"
            value={formatCurrency(balance?.current_balance)}
            accent={Number(balance?.current_balance) < 0 ? 'danger' : 'accent'}
          />
        </div>

        <form
          method="get"
          action="/treasury"
          className="mb-6 grid grid-cols-1 gap-3 rounded-2xl border border-secondary/30 bg-white p-4 sm:grid-cols-2 lg:grid-cols-5"
        >
          <input
            type="search"
            name="q"
            defaultValue={filters.q ?? ''}
            placeholder="بحث في الوصف..."
            maxLength={100}
            className="rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          />
          <select
            name="category"
            defaultValue={filters.category ?? ''}
            className="rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          >
            {CATEGORY_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <input
            type="date"
            name="from"
            defaultValue={filters.from ?? ''}
            aria-label="من تاريخ"
            className="rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          />
          <input
            type="date"
            name="to"
            defaultValue={filters.to ?? ''}
            aria-label="إلى تاريخ"
            className="rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              className="flex-1 rounded-xl bg-primary px-4 py-2 text-sm font-bold text-background transition hover:bg-primary/90"
            >
              بحث
            </button>
            <Link
              href="/treasury"
              className="rounded-xl border border-secondary/30 px-4 py-2 text-sm font-bold text-secondary transition hover:border-secondary/60"
            >
              مسح
            </Link>
          </div>
        </form>

        <LedgerTable transactions={ledger?.rows ?? []} userRole={userRole} />

        <Pagination
          basePath="/treasury"
          params={{ q: filters.q, category: filters.category, from: filters.from, to: filters.to }}
          page={ledger?.page ?? 1}
          perPage={ledger?.perPage ?? 50}
          total={ledger?.total ?? 0}
        />

        <OperatingAllocationPanel
          cycles={cycles ?? []}
          exclusions={exclusions ?? []}
          projects={projectsList ?? []}
          userRole={userRole}
        />
      </div>
    </main>
  )
}
