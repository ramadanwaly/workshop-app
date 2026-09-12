import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import StatCard from '@/components/dashboard/stat-card'

function formatCurrency(value: number | null | undefined): string {
  return `${Number(value ?? 0).toLocaleString('ar-EG')} ج.م`
}

export default async function DashboardPage() {
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
      <main className="min-h-screen p-8">
        <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل لوحة المعلومات</h1>
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
          <h1 className="text-xl font-bold text-ink sm:text-2xl">لوحة المعلومات</h1>
          <p className="mt-1 text-sm text-secondary">
            نظرة عامة على الخزينة والمشاريع والالتزامات
          </p>
        </div>

        {Number(treasury.data?.current_balance) < 0 && (
          <div className="mb-6 rounded-xl border border-danger bg-danger/10 p-4 text-danger">
            ⚠️ تنبيه: رصيد الخزينة مكشوف (بالسالب). يرجى مراجعة الحركات المالية.
          </div>
        )}

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 xl:grid-cols-4">
          <StatCard
            title="الخزينة لحظياً"
            value={formatCurrency(treasury.data?.current_balance)}
            accent={Number(treasury.data?.current_balance) < 0 ? 'danger' : 'accent'}
          />
          <StatCard
            title="المشاريع النشطة"
            value={String(projects.count ?? 0)}
            subtitle="مشاريع قيد التنفيذ"
            accent="primary"
          />
          <StatCard
            title="الالتزامات المعلقة"
            value={formatCurrency(liabilities.data?.total_pending_liabilities)}
            subtitle={`عمال ${formatCurrency(liabilities.data?.total_worker_liabilities)} + باطن ${formatCurrency(liabilities.data?.total_subcontract_liabilities)}`}
            accent="danger"
          />
          <StatCard
            title="قيمة الفائض المتاح"
            value={formatCurrency(surplus.data?.total_surplus_value)}
            subtitle={`${surplus.data?.total_surplus_quantity ?? 0} وحدة في ${surplus.data?.item_count ?? 0} عنصر`}
            accent="success"
          />
        </div>
      </div>
    </main>
  )
}