import { Suspense } from 'react'
import {
  getMonthlyTreasuryStats,
  getProjectProfitability,
  getWorkerPerformanceStats,
  getOverheadVariance
} from '@/actions/analytics'
import {
  TreasuryChart,
  ProjectProfitabilityChart,
  WorkerPerformanceChart
} from '@/components/analytics/charts'
import { formatCurrency } from '@/lib/format'

export const metadata = {
  title: 'التحليلات والتقارير | إدارة الورشة',
  description: 'نظرة تحليلية شاملة لأداء الورشة المالي والتشغيلي',
}

async function AnalyticsContent() {
  const [treasuryRes, projectsRes, workersRes, varianceRes] = await Promise.all([
    getMonthlyTreasuryStats(),
    getProjectProfitability(),
    getWorkerPerformanceStats(),
    getOverheadVariance()
  ])

  if (!treasuryRes.success || !projectsRes.success || !workersRes.success || !varianceRes.success) {
    return (
      <div className="rounded-md border border-danger/30 bg-danger/5 p-6">
        <h2 className="mb-2 text-lg font-bold text-danger">تعذّر تحميل البيانات</h2>
        <p className="text-sm text-danger/80">
          {treasuryRes.error || projectsRes.error || workersRes.error || varianceRes.error}
        </p>
      </div>
    )
  }

  const treasuryData = Array.isArray(treasuryRes.data) ? treasuryRes.data : []
  const projectsData = Array.isArray(projectsRes.data) ? projectsRes.data : []
  const workersData = Array.isArray(workersRes.data) ? workersRes.data : []
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const overheadVariance = Number((varianceRes.data as any)?.overhead_variance) || 0

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const totalProjectsCost = projectsData.reduce((acc: number, p: any) => acc + (Number(p.estimated_total_cost) || 0), 0)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const totalProjectsRevenue = projectsData.reduce((acc: number, p: any) => acc + (Number(p.total_revenue) || 0), 0)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const totalWorkerWages = workersData.reduce((acc: number, w: any) => acc + (Number(w.total_wages) || 0), 0)

  return (
    <div className="flex flex-col gap-8">
      {/* KPI Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div className="flex flex-col justify-center rounded-xl border border-border bg-card p-6 shadow-sm">
          <h3 className="text-sm font-medium text-secondary">إجمالي تكلفة المشاريع المنفذة</h3>
          <p className="mt-2 text-3xl font-bold tracking-tight text-danger">{formatCurrency(Math.abs(totalProjectsCost))}</p>
        </div>
        <div className="flex flex-col justify-center rounded-xl border border-border bg-card p-6 shadow-sm">
          <h3 className="text-sm font-medium text-secondary">إجمالي إيرادات المشاريع</h3>
          <p className="mt-2 text-3xl font-bold tracking-tight text-ink">{formatCurrency(totalProjectsRevenue)}</p>
        </div>
        <div className="flex flex-col justify-center rounded-xl border border-border bg-card p-6 shadow-sm">
          <h3 className="text-sm font-medium text-secondary">إجمالي الأجور المحسوبة</h3>
          <p className="mt-2 text-3xl font-bold tracking-tight text-primary">{formatCurrency(totalWorkerWages)}</p>
        </div>
        <div className="flex flex-col justify-center rounded-xl border border-border bg-card p-6 shadow-sm">
          <h3 className="text-sm font-medium text-secondary" title="الفارق بين تكلفة المشاريع والمصروف الفعلي">فروق التحميل الإداري</h3>
          <p className={`mt-2 text-3xl font-bold tracking-tight ${overheadVariance >= 0 ? 'text-success' : 'text-danger'}`}>
            {overheadVariance > 0 ? '+' : ''}{formatCurrency(overheadVariance)}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-8 xl:grid-cols-2">
        <section className="rounded-xl border border-border bg-card p-6 shadow-sm xl:col-span-2">
          <h2 className="text-lg font-bold text-ink">الإيرادات والمصروفات عبر الوقت</h2>
          <p className="mt-1 text-sm text-secondary">تحليل شهري لتدفقات الخزينة (الإيرادات مقابل المصروفات).</p>
          <TreasuryChart data={treasuryData} />
        </section>

        <section className="rounded-xl border border-border bg-card p-6 shadow-sm">
          <h2 className="text-lg font-bold text-ink">تكلفة وربحية المشاريع</h2>
          <p className="mt-1 text-sm text-secondary">مقارنة إجمالي الإيرادات بالتكلفة المقدرة وصافي الربح لكل مشروع.</p>
          <ProjectProfitabilityChart data={projectsData} />
        </section>

        <section className="rounded-xl border border-border bg-card p-6 shadow-sm">
          <h2 className="text-lg font-bold text-ink">أداء العمال الشهري</h2>
          <p className="mt-1 text-sm text-secondary">تحليل لأيام العمل، الأجور المحسوبة، والسلف المسحوبة لكل عامل شهرياً.</p>
          <WorkerPerformanceChart data={workersData} />
        </section>
      </div>
    </div>
  )
}

function AnalyticsSkeleton() {
  return (
    <div className="flex flex-col gap-8">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-28 animate-pulse rounded-xl border border-border bg-card p-6"></div>
        ))}
      </div>
      <div className="grid grid-cols-1 gap-8 xl:grid-cols-2">
        <div className="h-[450px] animate-pulse rounded-xl border border-border bg-card p-6 xl:col-span-2"></div>
        <div className="h-[450px] animate-pulse rounded-xl border border-border bg-card p-6"></div>
        <div className="h-[450px] animate-pulse rounded-xl border border-border bg-card p-6"></div>
      </div>
    </div>
  )
}

export default function AnalyticsPage() {
  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:py-10">
        <header className="mb-8">
          <h1 className="text-2xl font-bold text-ink">التحليلات والتقارير</h1>
          <p className="mt-1 text-sm text-secondary">نظرة تحليلية شاملة لأداء الورشة المالي والتشغيلي</p>
        </header>

        <Suspense fallback={<AnalyticsSkeleton />}>
          <AnalyticsContent />
        </Suspense>
      </div>
    </main>
  )
}
