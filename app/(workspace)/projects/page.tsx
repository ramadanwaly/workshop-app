import { Suspense } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { StatusBadge } from '@/components/layout/status-badge'
import { NewProjectButton } from '@/components/projects/new-project-button'
import { formatCurrency } from '@/lib/format'
import { DebouncedSearchInput } from '@/components/ui/debounced-search-input'

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
  const searchParams = await props.searchParams
  const query = searchParams?.q || undefined

  return (
    <main className="min-h-screen">
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

        <div className="mb-6 flex flex-col sm:flex-row sm:items-center rounded-md border border-border bg-card p-3">
          <DebouncedSearchInput
            initialValue={query ?? ''}
            placeholder="بحث باسم المشروع..."
            paramName="q"
          />
        </div>

        <Suspense key={query ?? ''} fallback={<ProjectsSkeleton />}>
          <ProjectsList query={query} />
        </Suspense>
      </div>
    </main>
  )
}

function ProjectsSkeleton() {
  return (
    <div className="animate-pulse space-y-4">
      <div className="space-y-3 md:hidden">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 w-full rounded-md border border-border bg-card/50" />
        ))}
      </div>
      <div className="hidden h-64 w-full rounded-md border border-border bg-card/50 md:block" />
    </div>
  )
}

async function ProjectsList({ query }: { query?: string }) {
  const supabase = await createClient()

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
      <div>
        <h2 className="mb-4 text-xl font-bold text-danger">تعذّر تحميل المشاريع</h2>
        <p className="text-secondary">
          حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.
        </p>
      </div>
    )
  }

  const costByProject = new Map((costs ?? []).map((c) => [c.project_id, c]))

  const sorted = [...(projects ?? [])].sort((a, b) => {
    const byStatus = (STATUS_ORDER[a.status] ?? 4) - (STATUS_ORDER[b.status] ?? 4)
    return byStatus !== 0 ? byStatus : a.name.localeCompare(b.name, 'ar')
  })

  if (sorted.length === 0) {
    return (
      <div className="rounded-md border border-border bg-card px-5 py-12 text-center">
        <p className="text-sm font-medium text-ink">{query ? 'لا توجد مشاريع تطابق بحثك.' : 'لا توجد مشاريع بعد.'}</p>
      </div>
    )
  }

  return (
    <>
      <div className="hidden overflow-x-auto rounded-md border border-border bg-card md:block">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-muted/50 text-xs font-bold text-secondary">
            <tr>
              <th scope="col" className="px-4 py-3">المشروع</th>
              <th scope="col" className="px-4 py-3">الحالة</th>
              <th scope="col" className="px-4 py-3">الوصف</th>
              <th scope="col" className="px-4 py-3 text-end">التكلفة المباشرة</th>
              <th scope="col" className="px-4 py-3 text-end">التكلفة الإجمالية التقديرية</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {sorted.map((project) => {
              const meta = STATUS_META[project.status] ?? {
                label: project.status,
                cls: 'border-secondary/50 bg-secondary/10 text-secondary',
              }
              const cost = costByProject.get(project.id)
              return (
                <tr key={project.id} className="group transition-colors hover:bg-muted/50">
                  <td className="px-4 py-3 text-ink">
                    <Link href={`/projects/${project.id}`} className="font-bold text-primary outline-none transition-colors hover:text-accent focus-visible:underline">
                      {project.name}
                    </Link>
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge label={meta.label} className={meta.cls} />
                  </td>
                  <td className="max-w-64 truncate px-4 py-3 text-secondary">
                    {project.description ?? '—'}
                  </td>
                  <td className="px-4 py-3 text-end font-semibold tabular-nums text-ink">
                    {formatCurrency(cost?.direct_project_cost)}
                  </td>
                  <td className="px-4 py-3 text-end font-bold tabular-nums text-accent">
                    {formatCurrency(cost?.estimated_total_cost)}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <div className="space-y-3 md:hidden">
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
              className="block rounded-md border border-border bg-card p-4 outline-none transition-colors hover:border-primary/50 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
            >
              <div className="flex items-start justify-between gap-3">
                <h2 className="font-bold text-primary">{project.name}</h2>
                <StatusBadge label={meta.label} className={meta.cls} />
              </div>
              
              {project.description && (
                <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-secondary">
                  {project.description}
                </p>
              )}

              <div className="mt-4 flex items-end justify-between border-t border-border pt-3">
                <div>
                  <p className="text-[10px] font-medium text-secondary">المباشرة</p>
                  <p className="mt-0.5 font-semibold tabular-nums text-ink">{formatCurrency(cost?.direct_project_cost)}</p>
                </div>
                <div className="text-end">
                  <p className="text-[10px] font-medium text-secondary">التقديرية الإجمالية</p>
                  <p className="mt-0.5 font-bold tabular-nums text-accent">{formatCurrency(cost?.estimated_total_cost)}</p>
                </div>
              </div>
            </Link>
          )
        })}
      </div>
    </>
  )
}