import { Suspense } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import StatCard from '@/components/dashboard/stat-card'
import { formatCurrency } from '@/lib/format'
import { getSurplusInventory } from '@/actions/surplus'
import { SurplusTable, type SurplusRecord } from '@/components/surplus/surplus-table'
import { Pagination } from '@/components/ui/pagination'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

type SurplusPageProps = {
  searchParams: Promise<{ status?: string; q?: string; page?: string }>
}

export default async function SurplusPage(props: SurplusPageProps) {
  const searchParams = await props.searchParams
  const rawStatus = searchParams?.status
  const currentStatus: 'available' | 'consumed' | 'scrapped' =
    rawStatus === 'consumed' || rawStatus === 'scrapped' ? rawStatus : 'available'
  const query = searchParams?.q || undefined
  const pageNum = searchParams?.page || undefined

  return (
    <main className="min-h-screen pb-20 lg:pb-8">
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6">
          <h1 className="text-xl font-bold text-ink sm:text-2xl">بنك الفائض (Surplus Bank)</h1>
          <p className="mt-1 text-sm text-secondary">
            سجل ومخزون مواد الفائض المسترجعة من المشاريع لإعادة الاستخدام أو التصفية
          </p>
        </header>

        <form
          method="get"
          action="/surplus"
          className="mb-6 flex flex-col gap-3 rounded-md border border-border bg-card p-4 sm:flex-row"
        >
          <input type="hidden" name="status" value={currentStatus} />
          <Input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم المادة..."
            maxLength={100}
            className="flex-1"
          />
          <div className="flex gap-2">
            <Button type="submit">
              بحث
            </Button>
            <Link
              href={`/surplus?status=${currentStatus}`}
              className="inline-flex h-10 items-center justify-center whitespace-nowrap rounded-md border border-input bg-background px-4 py-2 font-bold transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            >
              مسح
            </Link>
          </div>
        </form>

        <Suspense key={`${currentStatus}-${query ?? ''}-${pageNum ?? '1'}`} fallback={<SurplusSkeleton />}>
          <SurplusContent currentStatus={currentStatus} query={query} pageNum={pageNum} />
        </Suspense>
      </div>
    </main>
  )
}

function SurplusSkeleton() {
  return (
    <div className="animate-pulse space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3 sm:gap-6">
        {[1, 2, 3].map(i => <div key={i} className="h-24 rounded-md border border-border bg-card/50" />)}
      </div>
      <div className="h-12 w-full rounded-md border-b border-border" />
      <div className="h-64 w-full rounded-md border border-border bg-card/50" />
    </div>
  )
}

async function SurplusContent({ currentStatus, query, pageNum }: { currentStatus: 'available' | 'consumed' | 'scrapped'; query?: string; pageNum?: string }) {
  const supabase = await createClient()

  let items: SurplusRecord[] = []
  let total = 0
  let page = 1
  const perPage = 50
  let projects: { id: string; name: string }[] = []
  const stats = {
    availableCount: 0,
    availableValue: 0,
    consumedCount: 0,
    consumedValue: 0,
    scrappedCount: 0,
    scrappedValue: 0,
  }

  try {
    const [surplusData, projectsRes, statsRes] = await Promise.all([
      getSurplusInventory(currentStatus, { q: query, page: pageNum, perPage }),
      supabase.from('projects').select('id, name').order('name', { ascending: true }),
      // الإحصائيات تُحسب داخل قاعدة البيانات (GROUP BY status) بدل سحب كل الصفوف
      supabase
        .from('v_surplus_status_stats')
        .select('status, item_count, total_estimated_value'),
    ])

    items = ((surplusData?.rows ?? []) as SurplusRecord[])
    total = surplusData?.total ?? 0
    page = surplusData?.page ?? 1
    projects = projectsRes.data ?? []

    if (statsRes.error) {
      console.error('[surplus] فشل تحميل إحصائيات الفائض:', statsRes.error.message)
    } else {
      const statsByStatus = new Map(
        (statsRes.data ?? []).map((row) => [row.status, row])
      )
      stats.availableCount = statsByStatus.get('available')?.item_count ?? 0
      stats.availableValue = Number(
        statsByStatus.get('available')?.total_estimated_value ?? 0
      )
      stats.consumedCount = statsByStatus.get('consumed')?.item_count ?? 0
      stats.consumedValue = Number(
        statsByStatus.get('consumed')?.total_estimated_value ?? 0
      )
      stats.scrappedCount = statsByStatus.get('scrapped')?.item_count ?? 0
      stats.scrappedValue = Number(
        statsByStatus.get('scrapped')?.total_estimated_value ?? 0
      )
    }
  } catch (err) {
    console.error('[surplus] فشل تحميل بنك الفائض:', err)
    return (
      <div>
        <h2 className="mb-4 text-xl font-bold text-danger">تعذّر تحميل بنك الفائض</h2>
        <p className="text-secondary">
          حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.
        </p>
      </div>
    )
  }

  const TABS = [
    { key: 'available', label: 'متاح للاستخدام', count: stats.availableCount, href: '/surplus?status=available' },
    { key: 'consumed', label: 'مستهلك بالمشاريع', count: stats.consumedCount, href: '/surplus?status=consumed' },
    { key: 'scrapped', label: 'متلف / هالك', count: stats.scrappedCount, href: '/surplus?status=scrapped' },
  ]

  return (
    <>
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3 sm:gap-6">
        <StatCard
          title="إجمالي الفائض المتاح"
          value={formatCurrency(stats.availableValue)}
          subtitle={`${stats.availableCount} صنف متاح`}
          accent="accent"
        />
        <StatCard
          title="إجمالي المواد المستهلكة"
          value={formatCurrency(stats.consumedValue)}
          subtitle={`${stats.consumedCount} صنف مستهلك`}
          accent="success"
        />
        <StatCard
          title="إجمالي الهالك والإنقاذ"
          value={formatCurrency(stats.scrappedValue)}
          subtitle={`${stats.scrappedCount} صنف متلف`}
          accent="danger"
        />
      </div>

      <div className="mb-6 border-b border-border">
        <nav className="flex gap-2" aria-label="حالة الفائض">
          {TABS.map((tab) => {
            const isActive = currentStatus === tab.key
            return (
              <Link
                key={tab.key}
                href={tab.href}
                className={`inline-flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-bold transition ${
                  isActive
                    ? 'border-accent text-accent'
                    : 'border-transparent text-muted-foreground hover:border-border hover:text-foreground'
                }`}
              >
                <span>{tab.label}</span>
                <span
                  className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                    isActive ? 'bg-accent/15 text-accent' : 'bg-muted text-muted-foreground'
                  }`}
                >
                  {tab.count}
                </span>
              </Link>
            )
          })}
        </nav>
      </div>

      <SurplusTable
        items={items}
        projects={projects}
        currentStatus={currentStatus}
      />

      <Pagination
        basePath="/surplus"
        params={{ status: currentStatus, q: query }}
        page={page}
        perPage={perPage}
        total={total}
      />
    </>
  )
}
