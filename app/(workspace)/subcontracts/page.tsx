import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import { StatusBadge } from '@/components/layout/status-badge'
import { SubcontractsHeaderActions } from '@/components/subcontracts/subcontracts-header-actions'
import { Pagination } from '@/components/ui/pagination'
import { getSubcontractOrders } from '@/actions/subcontracts'
import { formatCurrency, formatDate } from '@/lib/format'

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

  const [projectsRes, paymentsRes, authResult] = await Promise.all([
    supabase.from('projects').select('id, name, status').eq('status', 'active'),
    supabase
      .from('subcontract_payments')
      .select('subcontract_order_id, amount, is_voided'),
    supabase.auth.getUser(),
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
      <main className="min-h-screen">
        <WorkspaceHeader />
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل اتفاقيات المقاولات</h1>
          <p className="text-secondary">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
        </div>
      </main>
    )
  }

  let isOwner = false
  if (authResult.data?.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authResult.data.user.id)
      .single()
    isOwner = profile?.role === 'owner'
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

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <header className="mb-6 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-xl font-bold text-ink sm:text-2xl">المقاولون</h1>
            <p className="mt-1 text-sm text-secondary">
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
          className="mb-6 flex flex-col gap-3 rounded-2xl border border-secondary/30 bg-white p-4 sm:flex-row"
        >
          <input
            type="search"
            name="q"
            defaultValue={query ?? ''}
            placeholder="بحث باسم المقاول..."
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
              href="/subcontracts"
              className="rounded-xl border border-secondary/30 px-4 py-2 text-sm font-bold text-secondary transition hover:border-secondary/60"
            >
              مسح
            </Link>
          </div>
        </form>

        {orders.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
            <p className="text-secondary">لا توجد اتفاقيات مقاولات بعد.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 xl:grid-cols-3">
            {orders.map((order) => {
              const meta = STATUS_META[order.status] ?? {
                label: order.status,
                cls: 'border-secondary/50 bg-secondary/10 text-secondary',
              }
              const paid = paidByOrder.get(order.id) ?? 0
              const remaining = Number(order.total_agreed_amount) - paid
              return (
                <Link
                  key={order.id}
                  href={`/subcontracts/${order.id}`}
                  className="group flex flex-col rounded-2xl border border-secondary/30 bg-white p-5 shadow-sm transition hover:border-accent/60 hover:shadow-md"
                >
                  <div className="flex items-start justify-between gap-3">
                    <h2 className="font-bold text-primary transition-colors group-hover:text-accent">
                      {order.contractor_name}
                    </h2>
                    <StatusBadge label={meta.label} className={meta.cls} />
                  </div>

                  <p className="mt-1 text-sm font-semibold text-secondary">
                    {projectNames.get(order.project_id) ?? 'مشروع غير معروف'}
                  </p>

                  {order.description && (
                    <p className="mt-2 line-clamp-2 text-sm text-secondary">{order.description}</p>
                  )}

                  <dl className="mt-4 space-y-1.5 border-t border-secondary/20 pt-3 text-sm">
                    <div className="flex items-center justify-between">
                      <dt className="text-secondary">المبلغ المتفق عليه</dt>
                      <dd className="font-bold tabular-nums text-primary">
                        {formatCurrency(order.total_agreed_amount)}
                      </dd>
                    </div>
                    {order.status === 'active' && (
                      <div className="flex items-center justify-between">
                        <dt className="text-secondary">المتبقي</dt>
                        <dd className={`font-bold tabular-nums ${remaining > 0 ? 'text-warning' : 'text-success'}`}>
                          {formatCurrency(remaining)}
                        </dd>
                      </div>
                    )}
                    <div className="flex items-center justify-between">
                      <dt className="text-secondary">تاريخ الإنشاء</dt>
                      <dd className="font-semibold text-ink">{formatDate(order.created_at)}</dd>
                    </div>
                  </dl>
                </Link>
              )
            })}
          </div>
        )}

        <Pagination
          basePath="/subcontracts"
          params={{ q: query }}
          page={ordersPage}
          perPage={perPage}
          total={ordersTotal}
        />
      </div>
    </main>
  )
}