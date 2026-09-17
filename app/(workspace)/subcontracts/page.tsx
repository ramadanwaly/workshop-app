import { Suspense } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { StatusBadge } from '@/components/layout/status-badge'
import { SubcontractsHeaderActions } from '@/components/subcontracts/subcontracts-header-actions'
import { Pagination } from '@/components/ui/pagination'
import { getSubcontractOrders } from '@/actions/subcontracts'
import { formatCurrency } from '@/lib/format'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

const STATUS_META: Record<string, { label: string; cls: string }> = {
  active: { label: 'قيد التنفيذ', cls: 'border-success/50 bg-success/10 text-success' },
  completed: { label: 'مكتملة', cls: 'border-accent/50 bg-accent/10 text-accent' },
  cancelled: { label: 'ملغية', cls: 'border-danger/50 bg-danger/10 text-danger' },
}

type SubcontractsPageProps = {
  searchParams: Promise<{ q?: string; page?: string }>
}

export default async function SubcontractsPage(props: SubcontractsPageProps) {
  const searchParams = await props.searchParams
  const query = searchParams?.q || undefined
  const pageNum = searchParams?.page || undefined

  const supabase = await createClient()

  let projectRows: Array<{ id: string; name: string; status: string }> | null = []
  
  let isOwner = false
  const [projectsRes, authResult] = await Promise.all([
    supabase.from('projects').select('id, name, status').eq('status', 'active'),
    supabase.auth.getUser(),
  ])
  projectRows = projectsRes.data

  if (authResult.data?.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authResult.data.user.id)
      .single()
    isOwner = profile?.role === 'owner'
  }

  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-xl font-bold text-foreground sm:text-2xl">المقاولون</h1>
            <p className="mt-1 text-sm text-muted-foreground">
              اتفاقيات مقاولي الباطن — الأحدث أولاً
            </p>
          </div>
          {isOwner && (
            <SubcontractsHeaderActions projects={projectRows ?? []} />
          )}
        </header>

        <form
          method="get"
          action="/subcontracts"
          className="mb-6 flex flex-col gap-3 rounded-md border border-border bg-card p-3 sm:flex-row"
        >
          <Input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم المقاول..."
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
                href="/subcontracts"
                className="inline-flex h-10 flex-1 items-center justify-center whitespace-nowrap rounded-md border border-input bg-background px-4 py-2 font-bold transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 sm:flex-none"
              >
                مسح
              </Link>
            )}
          </div>
        </form>

        <Suspense key={`${query ?? ''}-${pageNum ?? '1'}`} fallback={<SubcontractsSkeleton />}>
          <SubcontractsList query={query} pageNum={pageNum} />
        </Suspense>
      </div>
    </main>
  )
}

function SubcontractsSkeleton() {
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

async function SubcontractsList({ query, pageNum }: { query?: string; pageNum?: string }) {
  const perPage = 50
  const supabase = await createClient()

  let orders: Array<{
    id: string
    project_id: string
    contractor_name: string
    description: string
    total_agreed_amount: number
    status: string
    created_at: string
  }> = []
  let ordersTotal = 0
  let ordersPage = 1
  let ordersError: string | null = null
  let projectRows: Array<{ id: string; name: string; status: string }> | null = []
  let projectsError: string | null = null
  let paymentRows: Array<{ subcontract_order_id: string; amount: number; is_voided: boolean }> | null = []
  let paymentsError: string | null = null

  try {
    const ordersResult = await getSubcontractOrders({ q: query, page: pageNum, perPage })
    orders = (ordersResult?.rows ?? []) as typeof orders
    ordersTotal = ordersResult?.total ?? 0
    ordersPage = ordersResult?.page ?? 1
  } catch (err) {
    ordersError = err instanceof Error ? err.message : 'خطأ غير معروف'
  }

  const [projectsRes, paymentsRes] = await Promise.all([
    supabase.from('projects').select('id, name, status'),
    supabase
      .from('subcontract_payments')
      .select('subcontract_order_id, amount, is_voided'),
  ])
  projectRows = projectsRes.data
  projectsError = projectsRes.error?.message ?? null
  paymentRows = paymentsRes.data
  paymentsError = paymentsRes.error?.message ?? null

  if (ordersError || projectsError || paymentsError) {
    console.error(
      '[subcontracts] فشل تحميل اتفاقيات المقاولات:',
      ordersError,
      projectsError,
      paymentsError
    )
    return (
      <div>
        <h2 className="mb-4 text-xl font-bold text-danger">تعذّر تحميل اتفاقيات المقاولات</h2>
        <p className="text-secondary">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
      </div>
    )
  }

  const projectNames = new Map((projectRows ?? []).map((p) => [p.id, p.name]))

  const paidByOrder = new Map<string, number>()
  for (const p of paymentRows ?? []) {
    if (p.is_voided) continue
    paidByOrder.set(
      p.subcontract_order_id,
      (paidByOrder.get(p.subcontract_order_id) ?? 0) + Number(p.amount)
    )
  }

  if (orders.length === 0) {
    return (
      <div className="rounded-md border border-border bg-card px-5 py-12 text-center">
        <p className="text-sm font-medium text-foreground">{query ? 'لا توجد اتفاقيات تطابق بحثك.' : 'لا توجد اتفاقيات مقاولات بعد.'}</p>
      </div>
    )
  }

  return (
    <>
      <div className="hidden overflow-x-auto rounded-md border border-border bg-card md:block">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-muted/50 text-xs font-medium text-muted-foreground">
            <tr>
              <th scope="col" className="px-4 py-3">المقاول</th>
              <th scope="col" className="px-4 py-3">المشروع</th>
              <th scope="col" className="px-4 py-3">الحالة</th>
              <th scope="col" className="px-4 py-3 text-end">المتفق عليه</th>
              <th scope="col" className="px-4 py-3 text-end">المتبقي</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {orders.map((order) => {
              const meta = STATUS_META[order.status] ?? {
                label: order.status,
                cls: 'border-border bg-muted/50 text-muted-foreground',
              }
              const paid = paidByOrder.get(order.id) ?? 0
              const remaining = Number(order.total_agreed_amount) - paid
              return (
                <tr key={order.id} className="group transition-colors hover:bg-muted/50">
                  <td className="px-4 py-3 text-foreground">
                    <Link href={`/subcontracts/${order.id}`} className="font-bold text-primary outline-none transition-colors hover:text-accent focus-visible:underline">
                      {order.contractor_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {projectNames.get(order.project_id) ?? 'مشروع غير معروف'}
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge label={meta.label} className={meta.cls} />
                  </td>
                  <td className="px-4 py-3 text-end font-semibold tabular-nums text-foreground">
                    {formatCurrency(order.total_agreed_amount)}
                  </td>
                  <td className="px-4 py-3 text-end font-bold tabular-nums">
                    {order.status === 'active' ? (
                      <span className={remaining > 0 ? 'text-warning' : 'text-success'}>
                        {formatCurrency(remaining)}
                      </span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <div className="space-y-3 md:hidden">
        {orders.map((order) => {
          const meta = STATUS_META[order.status] ?? {
            label: order.status,
            cls: 'border-border bg-muted/50 text-muted-foreground',
          }
          const paid = paidByOrder.get(order.id) ?? 0
          const remaining = Number(order.total_agreed_amount) - paid
          return (
            <Link
              key={order.id}
              href={`/subcontracts/${order.id}`}
              className="block rounded-md border border-border bg-card p-4 outline-none transition-colors hover:border-primary/50 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
            >
              <div className="flex items-start justify-between gap-3">
                <h2 className="font-bold text-primary">{order.contractor_name}</h2>
                <StatusBadge label={meta.label} className={meta.cls} />
              </div>
              
              <p className="mt-1 text-xs font-semibold text-muted-foreground">
                {projectNames.get(order.project_id) ?? 'مشروع غير معروف'}
              </p>

              {order.description && (
                <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-muted-foreground">
                  {order.description}
                </p>
              )}

              <div className="mt-4 flex items-end justify-between border-t border-border pt-3">
                <div>
                  <p className="text-[10px] font-medium text-muted-foreground">المتفق عليه</p>
                  <p className="mt-0.5 font-semibold tabular-nums text-foreground">{formatCurrency(order.total_agreed_amount)}</p>
                </div>
                <div className="text-end">
                  <p className="text-[10px] font-medium text-muted-foreground">المتبقي</p>
                  {order.status === 'active' ? (
                    <p className={`mt-0.5 font-bold tabular-nums ${remaining > 0 ? 'text-warning' : 'text-success'}`}>
                      {formatCurrency(remaining)}
                    </p>
                  ) : (
                    <p className="mt-0.5 text-muted-foreground">—</p>
                  )}
                </div>
              </div>
            </Link>
          )
        })}
      </div>

      <Pagination
        basePath="/subcontracts"
        params={{ q: query }}
        page={ordersPage}
        perPage={perPage}
        total={ordersTotal}
      />
    </>
  )
}