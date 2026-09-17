import { Suspense } from 'react'
import { createClient } from '@/lib/supabase/server'
import StatCard from '@/components/dashboard/stat-card'

function formatCurrency(value: number | null | undefined): string {
  return `${Number(value ?? 0).toLocaleString('ar-EG')} ج.م`
}

function DashboardSkeleton() {
  return (
    <div className="flex flex-col gap-8">
      <div className="h-24 animate-pulse rounded-md border border-border bg-card"></div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="h-32 animate-pulse rounded-md border border-border bg-card"></div>
        ))}
      </div>
    </div>
  )
}

async function DashboardContent() {
  const supabase = await createClient()

  const [treasury, liabilities, projects, surplus] = await Promise.all([
    supabase.from('v_treasury_balance').select('*').single(),
    supabase.from('v_pending_liabilities').select('*').single(),
    supabase
      .from('projects')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'active'),
    supabase.from('v_surplus_available').select('*').single(),
  ])

  if (treasury.error || liabilities.error || projects.error || surplus.error) {
    console.error(
      '[dashboard] فشل تحميل البيانات:',
      treasury.error?.message,
      liabilities.error?.message,
      projects.error?.message,
      surplus.error?.message
    )
    return (
      <div className="rounded-md border border-danger/30 bg-danger/5 p-6">
        <h1 className="mb-2 text-lg font-bold text-danger">تعذّر تحميل لوحة المعلومات</h1>
        <p className="text-sm text-danger/80">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
      </div>
    )
  }

  const isTreasuryNegative = Number(treasury.data?.current_balance) < 0
  const pendingWorker = Number(liabilities.data?.total_worker_liabilities)
  const pendingSubcontract = Number(liabilities.data?.total_subcontract_liabilities)
  const hasPendingLiabilities = pendingWorker > 0 || pendingSubcontract > 0

  return (
    <div className="flex flex-col gap-8">
      {/* Action / Attention Area */}
      <section aria-labelledby="triage-title">
        <h2 id="triage-title" className="mb-4 text-sm font-bold text-secondary">
          مهام تتطلب الانتباه
        </h2>
        {isTreasuryNegative || hasPendingLiabilities ? (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {isTreasuryNegative && (
              <div className="flex items-start gap-4 rounded-md border border-danger/30 bg-danger/5 p-5">
                <div className="mt-0.5 flex shrink-0 items-center justify-center rounded-full bg-danger/20 p-1 text-danger">
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-sm font-bold text-danger">رصيد الخزينة مكشوف</h3>
                  <p className="mt-1 text-xs leading-relaxed text-danger/80">
                    الرصيد الحالي بالسالب ولا يغطي الالتزامات. يتطلب تدخلاً عاجلاً لمراجعة الحركات المالية أو إضافة تمويل.
                  </p>
                </div>
              </div>
            )}
            {hasPendingLiabilities && (
              <div className="flex items-start gap-4 rounded-md border border-warning/30 bg-warning/5 p-5">
                <div className="mt-0.5 flex shrink-0 items-center justify-center rounded-full bg-warning/20 p-1 text-warning-foreground">
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-sm font-bold text-warning-foreground">التزامات مالية معلقة</h3>
                  <p className="mt-1 text-xs leading-relaxed text-warning-foreground/80">
                    توجد مستحقات متأخرة الدفع: {formatCurrency(pendingWorker)} للعمال و
                    {formatCurrency(pendingSubcontract)} لمقاولي الباطن.
                  </p>
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="flex items-center gap-3 rounded-md border border-border bg-card p-4">
            <div className="flex shrink-0 items-center justify-center rounded-full bg-success/10 p-1 text-success">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
            </div>
            <div>
              <h3 className="text-sm font-bold text-ink">لا توجد إجراءات عاجلة اليوم</h3>
              <p className="text-xs text-secondary">جميع المؤشرات التشغيلية والمالية في نطاقها الطبيعي.</p>
            </div>
          </div>
        )}
      </section>

      {/* Stats Area */}
      <section aria-labelledby="stats-title">
        <h2 id="stats-title" className="mb-4 text-sm font-bold text-secondary">
          المؤشرات العامة
        </h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="الخزينة لحظياً"
            value={formatCurrency(treasury.data?.current_balance)}
            accent={isTreasuryNegative ? 'danger' : 'accent'}
          />
          <StatCard
            title="الالتزامات المعلقة"
            value={formatCurrency(liabilities.data?.total_pending_liabilities)}
            subtitle={`عمال ${formatCurrency(pendingWorker)} + باطن ${formatCurrency(pendingSubcontract)}`}
            accent={hasPendingLiabilities ? 'warning' : 'secondary'}
          />
          <StatCard
            title="المشاريع النشطة"
            value={String(projects.count ?? 0)}
            subtitle="مشاريع قيد التنفيذ"
            accent="primary"
          />
          <StatCard
            title="الفائض المتاح"
            value={formatCurrency(surplus.data?.total_surplus_value)}
            subtitle={`${surplus.data?.total_surplus_quantity ?? 0} وحدة في ${surplus.data?.item_count ?? 0} عنصر`}
            accent="success"
          />
        </div>
      </section>
    </div>
  )
}

export default function DashboardPage() {
  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:py-10">
        <header className="mb-8">
          <h1 className="text-2xl font-bold text-ink">لوحة المعلومات</h1>
          <p className="mt-1 text-sm text-secondary">نظرة عامة على الخزينة والمشاريع والالتزامات</p>
        </header>

        <Suspense fallback={<DashboardSkeleton />}>
          <DashboardContent />
        </Suspense>
      </div>
    </main>
  )
}