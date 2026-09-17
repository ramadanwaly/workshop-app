import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { ProjectActionBar } from '@/components/projects/project-action-bar'
import { getProjectTransactions, getProjectDetail } from '@/actions/projects'
import { ProjectTransactionsTab } from '@/components/projects/project-transactions-tab'

type ProjectCostPageProps = {
  params: Promise<{ id: string }>
  searchParams: Promise<{ tab?: string }>
}

function formatCurrency(value: number | null | undefined): string {
  return `${Number(value ?? 0).toLocaleString('ar-EG')} ج.م`
}

const STATUS_LABELS: Record<string, string> = {
  active: 'نشط',
  completed: 'مكتمل',
  on_hold: 'متوقف مؤقتاً',
  cancelled: 'ملغي',
}

export default async function ProjectCostPage({ params, searchParams }: ProjectCostPageProps) {
  const { id } = await params
  const resolvedSearchParams = await searchParams
  const activeTab = resolvedSearchParams?.tab === 'transactions' ? 'transactions' : 'summary'

  const supabase = await createClient()

  const [costSheet, project, authResult, transactionsData] = await Promise.all([
    supabase
      .from('v_project_direct_costs')
      .select('*')
      .eq('project_id', id)
      .maybeSingle(),
    getProjectDetail(id),
    supabase.auth.getUser(),
    activeTab === 'transactions' ? getProjectTransactions(id) : Promise.resolve(null),
  ])

  let isOwner = false
  if (authResult.data?.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authResult.data.user.id)
      .single()
    isOwner = profile?.role === 'owner'
  }

  if (costSheet.error) {
    console.error(
      '[project] فشل تحميل تفاصيل المشروع:',
      costSheet.error?.message
    )
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-destructive">تعذّر تحميل تفاصيل المشروع</h1>
          <p className="text-muted-foreground">
            حدث خطأ أثناء جلب بيانات المشروع، يرجى المحاولة مرة أخرى لاحقاً.
          </p>
        </div>
      </main>
    )
  }

  if (!costSheet.data || !project) {
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-foreground">المشروع غير موجود</h1>
          <p className="text-muted-foreground">لم يتم العثور على مشروع بهذا المعرّف.</p>
        </div>
      </main>
    )
  }

  const overheadRate = costSheet.data.overhead_percentage

  const lines: Array<{ label: string; value: number | null | undefined }> = [
    { label: 'تكلفة المواد', value: costSheet.data.material_cost },
    { label: 'النولون', value: costSheet.data.freight_cost },
    { label: 'عوائد الفائض', value: costSheet.data.surplus_returns },
    { label: 'استهلاك الفائض', value: costSheet.data.surplus_consumptions },
    { label: 'تكلفة العمالة', value: costSheet.data.labor_cost },
    { label: 'اتفاقيات المقاولين', value: costSheet.data.subcontract_cost },
  ]

  return (
    <main className="min-h-screen">

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-4">
          <Link
            href="/projects"
            className="inline-flex items-center gap-1 text-sm font-semibold text-muted-foreground transition hover:text-foreground"
          >
            <span aria-hidden>←</span> العودة للمشاريع
          </Link>
        </div>

        <header className="mb-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <h1 className="text-xl font-bold text-foreground sm:text-2xl">{project.name}</h1>
            <ProjectActionBar
              projectId={id}
              projectName={project.name}
              projectDescription={project.description}
              currentStatus={project.status}
              isOwner={isOwner}
            />
          </div>
          {project.description && (
            <p className="mt-1 text-sm text-muted-foreground">{project.description}</p>
          )}
          <span className="mt-3 inline-block rounded-full border border-accent/30 bg-accent/10 px-3 py-1 text-sm font-semibold text-accent">
            {STATUS_LABELS[project.status] ?? project.status}
          </span>
        </header>

        {/* نظام التبويبات (Tabs) */}
        <div className="mb-6 border-b border-border">
          <nav className="flex gap-4" aria-label="تبويبات المشروع">
            <Link
              href={`/projects/${id}?tab=summary`}
              className={`inline-flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-bold transition ${
                activeTab === 'summary'
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:border-border hover:text-foreground'
              }`}
            >
              ملخص التكاليف
            </Link>
            <Link
              href={`/projects/${id}?tab=transactions`}
              className={`inline-flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-bold transition ${
                activeTab === 'transactions'
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:border-border hover:text-foreground'
              }`}
            >
              الحركات التفصيلية
            </Link>
          </nav>
        </div>

        {activeTab === 'summary' ? (
          <section className="max-w-2xl overflow-hidden rounded-md border border-border bg-card shadow-sm">
            <div className="divide-y divide-border">
              {lines.map((line) => (
                <div key={line.label} className="flex items-center justify-between px-6 py-4">
                  <span className="text-foreground">{line.label}</span>
                  <span className="font-semibold tabular-nums text-primary">
                    {formatCurrency(line.value)}
                  </span>
                </div>
              ))}
            </div>

            <div className="border-t border-border bg-muted/50 px-6 py-4">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-foreground">التكلفة المباشرة للمشروع</span>
                <span className="font-bold tabular-nums text-primary">
                  {formatCurrency(costSheet.data.direct_project_cost)}
                </span>
              </div>
            </div>

            <div className="border-t border-border bg-muted/50 px-6 py-4">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">نسبة المصروفات العامة (الأوفر هيد)</span>
                <span className="font-semibold tabular-nums text-foreground">
                  {Number(overheadRate ?? 0)}%
                </span>
              </div>
            </div>

            <div className="border-t border-accent/30 bg-accent/10 px-6 py-5">
              <div className="flex items-center justify-between">
                <span className="text-lg font-bold text-primary">التكلفة التقديرية الإجمالية</span>
                <span className="text-xl font-bold tabular-nums text-accent">
                  {formatCurrency(costSheet.data.estimated_total_cost)}
                </span>
              </div>
            </div>
          </section>
        ) : (
          <ProjectTransactionsTab
            treasuryTransactions={transactionsData?.treasuryTransactions ?? []}
            workerLogs={transactionsData?.workerLogs ?? []}
            subcontractOrders={transactionsData?.subcontractOrders ?? []}
            costAdjustments={transactionsData?.costAdjustments ?? []}
          />
        )}
      </div>
    </main>
  )
}