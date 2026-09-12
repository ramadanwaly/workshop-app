import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import { StatusBadge } from '@/components/layout/status-badge'
import { NewProjectButton } from '@/components/projects/new-project-button'
import { formatCurrency } from '@/lib/format'

const STATUS_META: Record<string, { label: string; cls: string }> = {
  active: { label: 'نشط', cls: 'border-success/50 bg-success/10 text-success' },
  completed: { label: 'مكتمل', cls: 'border-accent/50 bg-accent/10 text-accent' },
  on_hold: { label: 'متوقف مؤقتاً', cls: 'border-secondary/50 bg-secondary/10 text-secondary' },
  cancelled: { label: 'ملغي', cls: 'border-danger/50 bg-danger/10 text-danger' },
}

const STATUS_ORDER: Record<string, number> = {
  active: 0,
  on_hold: 1,
  cancelled: 2,
  completed: 3,
}

type ProjectsPageProps = {
  searchParams: Promise<{ q?: string }>
}

export default async function ProjectsPage(props: ProjectsPageProps) {
  const supabase = await createClient()

  const searchParams = await props.searchParams
  const query = searchParams?.q || undefined

  let projectsQuery = supabase.from('projects').select('*').order('name', { ascending: true })
  if (query) {
    projectsQuery = projectsQuery.ilike('name', `%${query}%`)
  }

  const [{ data: projects, error: projectsError }, { data: costs, error: costsError }] =
    await Promise.all([
      projectsQuery,
      supabase.from('v_project_direct_costs').select('*'),
    ])

  if (projectsError || costsError) {
    console.error(
      '[projects] فشل تحميل المشاريع:',
      projectsError?.message,
      costsError?.message
    )
    return (
      <main className="min-h-screen">
        <WorkspaceHeader />
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل المشاريع</h1>
          <p className="text-secondary">
            حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.
          </p>
        </div>
      </main>
    )
  }

  const costByProject = new Map((costs ?? []).map((c) => [c.project_id, c]))

  const sorted = [...(projects ?? [])].sort((a, b) => {
    const byStatus = (STATUS_ORDER[a.status] ?? 4) - (STATUS_ORDER[b.status] ?? 4)
    return byStatus !== 0 ? byStatus : a.name.localeCompare(b.name, 'ar')
  })

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6 flex items-end justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-ink sm:text-2xl">المشاريع</h1>
            <p className="mt-1 text-sm text-secondary">
              كل مشروع في الورشة — اضغط على أي مشروع لعرض تفاصيل التكلفة
            </p>
          </div>
          <NewProjectButton />
        </header>

        <form
          method="get"
          action="/projects"
          className="mb-6 flex flex-col gap-3 rounded-2xl border border-secondary/30 bg-white p-4 sm:flex-row"
        >
          <input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم المشروع..."
            maxLength={100}
            className="flex-1 rounded-xl border border-secondary/30 bg-background/40 px-3 py-2 text-sm text-ink outline-none focus:border-accent"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              className="flex-1 rounded-xl bg-primary px-6 py-2 text-sm font-bold text-white transition hover:bg-primary/90 focus:ring-2 focus:ring-accent sm:flex-none"
            >
              بحث
            </button>
            {query && (
              <Link
                href="/projects"
                className="flex flex-1 items-center justify-center rounded-xl border border-secondary/30 bg-white px-6 py-2 text-sm font-bold text-ink transition hover:bg-background sm:flex-none"
              >
                مسح
              </Link>
            )}
          </div>
        </form>

        {sorted.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
            <p className="text-secondary">لا توجد مشاريع بعد.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 xl:grid-cols-3">
            {sorted.map((project) => {
              const meta = STATUS_META[project.status] ?? {
                label: project.status,
                cls: 'border-secondary/50 bg-secondary/10 text-secondary',
              }
              const cost = costByProject.get(project.id)
              return (
                <Link
                  key={project.id}
                  href={`/projects/${project.id}`}
                  className="group flex flex-col rounded-2xl border border-secondary/30 bg-white p-5 shadow-sm transition hover:border-accent/60 hover:shadow-md"
                >
                  <div className="flex items-start justify-between gap-3">
                    <h2 className="font-bold text-primary transition-colors group-hover:text-accent">
                      {project.name}
                    </h2>
                    <StatusBadge label={meta.label} className={meta.cls} />
                  </div>

                  {project.description && (
                    <p className="mt-2 line-clamp-2 text-sm text-secondary">
                      {project.description}
                    </p>
                  )}

                  <dl className="mt-4 space-y-1.5 border-t border-secondary/20 pt-3 text-sm">
                    <div className="flex items-center justify-between">
                      <dt className="text-secondary">التكلفة المباشرة</dt>
                      <dd className="font-semibold tabular-nums text-ink">
                        {formatCurrency(cost?.direct_project_cost)}
                      </dd>
                    </div>
                    <div className="flex items-center justify-between">
                      <dt className="text-secondary">التكلفة التقديرية الإجمالية</dt>
                      <dd className="font-bold tabular-nums text-accent">
                        {formatCurrency(cost?.estimated_total_cost)}
                      </dd>
                    </div>
                  </dl>
                </Link>
              )
            })}
          </div>
        )}
      </div>
    </main>
  )
}