import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import StatCard from '@/components/dashboard/stat-card'
import { formatCurrency } from '@/lib/format'
import { getSurplusInventory } from '@/actions/surplus'
import { SurplusTable, type SurplusRecord } from '@/components/surplus/surplus-table'
import { Pagination } from '@/components/ui/pagination'

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
    const [surplusData, projectsRes, allSurplusRes] = await Promise.all([
      getSurplusInventory(currentStatus, { q: query, page: pageNum, perPage }),
      supabase.from('projects').select('id, name').order('name', { ascending: true }),
      supabase.from('surplus_bank').select('status, estimated_value'),
    ])

    items = ((surplusData?.rows ?? []) as SurplusRecord[])
    total = surplusData?.total ?? 0
    page = surplusData?.page ?? 1
    projects = projectsRes.data ?? []

    if (allSurplusRes.data) {
      for (const row of allSurplusRes.data) {
        const val = Number(row.estimated_value || 0)
        if (row.status === 'available') {
          stats.availableCount++
          stats.availableValue += val
        } else if (row.status === 'consumed') {
          stats.consumedCount++
          stats.consumedValue += val
        } else if (row.status === 'scrapped') {
          stats.scrappedCount++
          stats.scrappedValue += val
        }
      }
    }
  } catch (err) {
    console.error('[surplus] فشل تحميل بنك الفائض:', err)
    return (
      <main className="min-h-screen">
        <WorkspaceHeader />
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل بنك الفائض</h1>
          <p className="text-secondary">
            حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.
          </p>
        </div>
      </main>
    )
  }

  const TABS = [
    { key: 'available', label: 'متاح للاستخدام', count: stats.availableCount, href: '/surplus?status=available' },
    { key: 'consumed', label: 'مستهلك بالمشاريع', count: stats.consumedCount, href: '/surplus?status=consumed' },
    { key: 'scrapped', label: 'متلف / هالك', count: stats.scrappedCount, href: '/surplus?status=scrapped' },
  ]

  return (
    <main className="min-h-screen pb-20 lg:pb-8">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6">
          <h1 className="text-xl font-bold text-ink sm:text-2xl">بنك الفائض (Surplus Bank)</h1>
          <p className="mt-1 text-sm text-secondary">
            سجل ومخزون مواد الفائض المسترجعة من المشاريع لإعادة الاستخدام أو التصفية
          </p>
        </header>

        {/* كروت الإحصائيات */}
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

        {/* التبويبات (Tabs) */}
        <div className="mb-6 border-b border-secondary/20">
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
                      : 'border-transparent text-secondary hover:border-secondary/30 hover:text-ink'
                  }`}
                >
                  <span>{tab.label}</span>
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                      isActive ? 'bg-accent/15 text-accent' : 'bg-secondary/15 text-secondary'
                    }`}
                  >
                    {tab.count}
                  </span>
                </Link>
              )
            })}
          </nav>
        </div>

        {/* بحث */}
        <form
          method="get"
          action="/surplus"
          className="mb-6 flex flex-col gap-3 rounded-2xl border border-secondary/30 bg-white p-4 sm:flex-row"
        >
          <input type="hidden" name="status" value={currentStatus} />
          <input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم المادة..."
            maxLength={100}
            className="flex-1 rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-background transition hover:bg-primary/90"
            >
              بحث
            </button>
            <Link
              href={`/surplus?status=${currentStatus}`}
              className="rounded-xl border border-secondary/30 px-4 py-2 text-sm font-bold text-secondary transition hover:border-secondary/60"
            >
              مسح
            </Link>
          </div>
        </form>

        {/* الجدول الرئيسي */}
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
      </div>
    </main>
  )
}
