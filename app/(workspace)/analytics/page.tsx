import { Suspense } from 'react'
import {
  getMonthlyTreasuryStats,
  getProjectProfitability,
  getWorkerPerformanceStats
} from '@/actions/analytics'
import {
  TreasuryChart,
  ProjectProfitabilityChart,
  WorkerPerformanceChart
} from '@/components/analytics/charts'

export const metadata = {
  title: 'التحليلات والتقارير | إدارة الورشة',
  description: 'نظرة تحليلية شاملة لأداء الورشة المالي والتشغيلي',
}

async function AnalyticsContent() {
  const [treasuryRes, projectsRes, workersRes] = await Promise.all([
    getMonthlyTreasuryStats(),
    getProjectProfitability(),
    getWorkerPerformanceStats()
  ])

  if (!treasuryRes.success || !projectsRes.success || !workersRes.success) {
    return (
      <div className="rounded-md border border-danger/30 bg-danger/5 p-6">
        <h2 className="mb-2 text-lg font-bold text-danger">تعذّر تحميل البيانات</h2>
        <p className="text-sm text-danger/80">
          {treasuryRes.error || projectsRes.error || workersRes.error}
        </p>
      </div>
    )
  }

  const treasuryData = Array.isArray(treasuryRes.data) ? treasuryRes.data : []
  const projectsData = Array.isArray(projectsRes.data) ? projectsRes.data : []
  const workersData = Array.isArray(workersRes.data) ? workersRes.data : []

  return (
    <div className="flex flex-col gap-8">
      <section className="rounded-xl border border-border bg-card p-6 shadow-sm">
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
  )
}

function AnalyticsSkeleton() {
  return (
    <div className="flex flex-col gap-8">
      {[1, 2, 3].map((i) => (
        <div key={i} className="h-[450px] animate-pulse rounded-xl border border-border bg-card p-6"></div>
      ))}
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
