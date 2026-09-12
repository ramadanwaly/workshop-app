import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import { StatusBadge } from '@/components/layout/status-badge'
import { formatCurrency } from '@/lib/format'
import { WorkerListActions } from '@/components/workers/worker-list-actions'
import { Pagination } from '@/components/ui/pagination'
import { getWorkers } from '@/actions/labor'
import Link from 'next/link'

type WorkersPageProps = {
  searchParams: Promise<{ q?: string; page?: string }>
}

export default async function WorkersPage(props: WorkersPageProps) {
  const searchParams = await props.searchParams
  const query = searchParams?.q || undefined
  const pageNum = searchParams?.page || undefined
  const perPage = 50

  const supabase = await createClient()

  let workers: Array<{
    id: string
    name: string
    phone: string | null
    daily_rate: number
    is_active: boolean
  }> = []
  let total = 0
  let page = 1
  let loadError: string | null = null

  try {
    const result = await getWorkers({ q: query, page: pageNum, perPage })
    workers = (result?.rows ?? []) as typeof workers
    total = result?.total ?? 0
    page = result?.page ?? 1
  } catch (err) {
    console.error('[workers] فشل تحميل العمال:', err instanceof Error ? err.message : err)
    loadError = 'تعذّر تحميل العمال'
  }

  // صلاحية المالك تُقرأ من قاعدة البيانات server-side
  let isOwner = false
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    isOwner = profile?.role === 'owner'
  }

  if (loadError) {
    console.error('[workers] فشل تحميل العمال')
    return (
      <main className="min-h-screen">
        <WorkspaceHeader />
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل العمال</h1>
          <p className="text-secondary">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
        </div>
      </main>
    )
  }

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-ink sm:text-2xl">العمال</h1>
            <p className="mt-1 text-sm text-secondary">
              عمال الورشة وبياناتهم — النشطون أولاً
            </p>
          </div>
          <WorkerListActions input={{ isOwner }} />
        </header>

        <form
          method="get"
          action="/workers"
          className="mb-6 flex flex-col gap-3 rounded-2xl border border-secondary/30 bg-white p-4 sm:flex-row"
        >
          <input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم العامل..."
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
              href="/workers"
              className="rounded-xl border border-secondary/30 px-4 py-2 text-sm font-bold text-secondary transition hover:border-secondary/60"
            >
              مسح
            </Link>
          </div>
        </form>

        {workers.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
            <p className="text-secondary">لا يوجد عمال مسجلون بعد.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 xl:grid-cols-3">
            {workers.map((worker) => (
              <Link
                key={worker.id}
                href={`/workers/${worker.id}`}
                className="rounded-2xl border border-secondary/30 bg-white p-5 shadow-sm transition hover:border-accent/60 hover:shadow-md"
              >
                <div className="flex items-start justify-between gap-3">
                  <h2 className="font-bold text-primary">{worker.name}</h2>
                  <StatusBadge
                    label={worker.is_active ? 'نشط' : 'موقوف'}
                    className={
                      worker.is_active
                        ? 'border-success/50 bg-success/10 text-success'
                        : 'border-danger/50 bg-danger/10 text-danger'
                    }
                  />
                </div>

                <dl className="mt-4 space-y-1.5 border-t border-secondary/20 pt-3 text-sm">
                  <div className="flex items-center justify-between">
                    <dt className="text-secondary">السعر اليومي</dt>
                    <dd className="font-semibold tabular-nums text-ink">
                      {formatCurrency(worker.daily_rate)}
                    </dd>
                  </div>
                  <div className="flex items-center justify-between">
                    <dt className="text-secondary">رقم الهاتف</dt>
                    <dd className="font-semibold tabular-nums text-ink" dir="ltr">
                      {worker.phone ?? '—'}
                    </dd>
                  </div>
                </dl>
              </Link>
            ))}
          </div>
        )}

        <Pagination
          basePath="/workers"
          params={{ q: query }}
          page={page}
          perPage={perPage}
          total={total}
        />
      </div>
    </main>
  )
}