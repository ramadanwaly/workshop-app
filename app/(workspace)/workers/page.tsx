import { Suspense } from 'react'
import { createClient } from '@/lib/supabase/server'
import { StatusBadge } from '@/components/layout/status-badge'
import { formatCurrency } from '@/lib/format'
import { WorkerListActions } from '@/components/workers/worker-list-actions'
import { Pagination } from '@/components/ui/pagination'
import { getWorkers } from '@/actions/labor'
import Link from 'next/link'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

type WorkersPageProps = {
  searchParams: Promise<{ q?: string; page?: string }>
}

export default async function WorkersPage(props: WorkersPageProps) {
  const searchParams = await props.searchParams
  const query = searchParams?.q || undefined
  const pageNum = searchParams?.page || undefined

  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-foreground sm:text-2xl">العمال</h1>
            <p className="mt-1 text-sm text-muted-foreground">
              عمال الورشة وبياناتهم — النشطون أولاً
            </p>
          </div>
          <Suspense fallback={<div className="h-10 w-24 rounded-md bg-muted/50 animate-pulse" />}>
            <WorkersActions />
          </Suspense>
        </header>

        <form
          method="get"
          action="/workers"
          className="mb-6 flex flex-col gap-3 rounded-md border border-border bg-card p-3 sm:flex-row sm:items-center"
        >
          <Input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم العامل..."
            maxLength={100}
            className="flex-1"
          />
          <div className="flex gap-2">
            <Button
              type="submit"
              className="flex-1 sm:flex-none"
            >
              بحث
            </Button>
            {query && (
              <Link
                href="/workers"
                className="inline-flex h-10 flex-1 items-center justify-center whitespace-nowrap rounded-md border border-input bg-background px-4 py-2 font-bold transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 sm:flex-none"
              >
                مسح
              </Link>
            )}
          </div>
        </form>

        <Suspense key={`${query ?? ''}-${pageNum ?? '1'}`} fallback={<WorkersSkeleton />}>
          <WorkersContent query={query} pageNum={pageNum} />
        </Suspense>
      </div>
    </main>
  )
}

function WorkersSkeleton() {
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

async function WorkersActions() {
  const supabase = await createClient()
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
  return <WorkerListActions input={{ isOwner }} />
}

async function WorkersContent({ query, pageNum }: { query?: string; pageNum?: string }) {
  const perPage = 50

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

  if (loadError) {
    return (
      <div>
        <h2 className="mb-4 text-xl font-bold text-destructive">تعذّر تحميل العمال</h2>
        <p className="text-muted-foreground">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
      </div>
    )
  }

  if (workers.length === 0) {
    return (
      <div className="rounded-md border border-border bg-card px-5 py-12 text-center">
        <p className="text-sm font-medium text-foreground">{query ? 'لا يوجد عمال يطابقون بحثك.' : 'لا يوجد عمال مسجلون بعد.'}</p>
      </div>
    )
  }

  return (
    <>
      <div className="hidden overflow-x-auto rounded-md border border-border bg-card md:block">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-muted/50 text-xs font-medium text-muted-foreground">
            <tr>
              <th scope="col" className="px-4 py-3">الاسم</th>
              <th scope="col" className="px-4 py-3">الحالة</th>
              <th scope="col" className="px-4 py-3">رقم الهاتف</th>
              <th scope="col" className="px-4 py-3 text-end">السعر اليومي</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {workers.map((worker) => (
              <tr key={worker.id} className="group transition-colors hover:bg-muted/50">
                <td className="px-4 py-3 text-foreground">
                  <Link href={`/workers/${worker.id}`} className="font-bold text-primary outline-none transition-colors hover:text-primary/80 focus-visible:underline">
                    {worker.name}
                  </Link>
                </td>
                <td className="px-4 py-3">
                  <StatusBadge
                    label={worker.is_active ? 'نشط' : 'موقوف'}
                    className={
                      worker.is_active
                        ? 'border-success/50 bg-success/10 text-success'
                        : 'border-destructive/50 bg-destructive/10 text-destructive'
                    }
                  />
                </td>
                <td className="px-4 py-3 tabular-nums text-muted-foreground" dir="ltr">
                  {worker.phone ?? '—'}
                </td>
                <td className="px-4 py-3 text-end font-semibold tabular-nums text-foreground">
                  {formatCurrency(worker.daily_rate)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="space-y-3 md:hidden">
        {workers.map((worker) => (
          <Link
            key={worker.id}
            href={`/workers/${worker.id}`}
            className="block rounded-md border border-border bg-card p-4 outline-none transition-colors hover:border-primary/50 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
          >
            <div className="flex items-start justify-between gap-3">
              <h2 className="font-bold text-primary">{worker.name}</h2>
              <StatusBadge
                label={worker.is_active ? 'نشط' : 'موقوف'}
                className={
                  worker.is_active
                    ? 'border-success/50 bg-success/10 text-success'
                    : 'border-destructive/50 bg-destructive/10 text-destructive'
                }
              />
            </div>
            
            <div className="mt-4 flex items-end justify-between border-t border-border pt-3">
              <div>
                <p className="text-[10px] font-medium text-muted-foreground">رقم الهاتف</p>
                <p className="mt-0.5 text-xs font-medium tabular-nums text-foreground" dir="ltr">{worker.phone ?? '—'}</p>
              </div>
              <div className="text-end">
                <p className="text-[10px] font-medium text-muted-foreground">السعر اليومي</p>
                <p className="mt-0.5 font-bold tabular-nums text-foreground">{formatCurrency(worker.daily_rate)}</p>
              </div>
            </div>
          </Link>
        ))}
      </div>

      <Pagination
        basePath="/workers"
        params={{ q: query }}
        page={page}
        perPage={perPage}
        total={total}
      />
    </>
  )
}