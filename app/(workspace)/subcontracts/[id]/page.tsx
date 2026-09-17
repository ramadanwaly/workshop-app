import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { StatusBadge } from '@/components/layout/status-badge'
import { SubcontractActionBar } from '@/components/subcontracts/subcontract-action-bar'
import { PaymentsTable } from '@/components/subcontracts/payments-table'
import { formatCurrency, formatDate } from '@/lib/format'

const STATUS_META: Record<string, { label: string; cls: string }> = {
  active: { label: 'قيد التنفيذ', cls: 'border-success/50 bg-success/10 text-success' },
  completed: { label: 'مكتملة', cls: 'border-accent/50 bg-accent/10 text-accent' },
  cancelled: { label: 'ملغية', cls: 'border-danger/50 bg-danger/10 text-danger' },
}

type OrderDetailPageProps = {
  params: Promise<{ id: string }>
}

export default async function SubcontractOrderPage({ params }: OrderDetailPageProps) {
  const { id } = await params
  const supabase = await createClient()

  const [
    { data: order, error: orderError },
    { data: payments, error: paymentsError },
    authResult,
  ] = await Promise.all([
    supabase.from('subcontract_orders').select('*').eq('id', id).single(),
    supabase
      .from('subcontract_payments')
      .select('*')
      .eq('subcontract_order_id', id)
      .order('payment_date', { ascending: false })
      .order('created_at', { ascending: false }),
    supabase.auth.getUser(),
  ])

  const { data: project } = order
    ? await supabase
        .from('projects')
        .select('id, name, status')
        .eq('id', order.project_id)
        .maybeSingle()
    : { data: null }

  let isOwner = false
  if (authResult.data?.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authResult.data.user.id)
      .single()
    isOwner = profile?.role === 'owner'
  }

  if (orderError || paymentsError) {
    console.error(
      '[subcontracts] فشل تحميل الاتفاقية:',
      orderError?.message,
      paymentsError?.message
    )
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-danger">تعذّر تحميل الاتفاقية</h1>
          <p className="text-secondary">حدث خطأ أثناء جلب البيانات، يرجى المحاولة مرة أخرى لاحقاً.</p>
          <Link
            href="/subcontracts"
            className="mt-4 inline-block text-sm font-bold text-accent underline-offset-4 hover:underline"
          >
            العودة لقائمة المقاولين
          </Link>
        </div>
      </main>
    )
  }

  if (!order) {
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-ink">الاتفاقية غير موجودة</h1>
          <p className="text-secondary">لم يتم العثور على اتفاقية بهذا المعرّف.</p>
          <Link
            href="/subcontracts"
            className="mt-4 inline-block text-sm font-bold text-accent underline-offset-4 hover:underline"
          >
            العودة لقائمة المقاولين
          </Link>
        </div>
      </main>
    )
  }

  const paid = (payments ?? [])
    .filter((p) => !p.is_voided)
    .reduce((sum, p) => sum + Number(p.amount), 0)

  const totalAgreed = Number(order.total_agreed_amount)
  const remainingBalance = totalAgreed - paid

  const meta = STATUS_META[order.status] ?? {
    label: order.status,
    cls: 'border-secondary/50 bg-secondary/10 text-secondary',
  }

  return (
    <main className="min-h-screen">

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-4">
          <Link
            href="/subcontracts"
            className="inline-flex items-center gap-1 text-sm font-semibold text-muted-foreground transition hover:text-accent"
          >
            <span aria-hidden>←</span> العودة للمقاولين
          </Link>
        </div>

        <header className="mb-6 flex flex-wrap items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-xl font-bold text-foreground sm:text-2xl">{order.contractor_name}</h1>
              <StatusBadge label={meta.label} className={meta.cls} />
            </div>
            <p className="mt-1 text-sm text-muted-foreground">
              المشروع:{' '}
              <span className="font-semibold text-foreground">
                {project?.name ?? 'مشروع غير معروف'}
              </span>
              {project?.status && project.status !== 'active' && (
                <span className="ms-2 text-xs text-muted-foreground">({project.status})</span>
              )}
            </p>
            <p className="mt-3 text-sm text-foreground">{order.description}</p>
          </div>
        </header>

        <SubcontractActionBar
          orderId={order.id}
          contractorName={order.contractor_name}
          totalAgreed={totalAgreed}
          paid={paid}
          remainingBalance={remainingBalance}
          status={order.status as 'active' | 'completed' | 'cancelled'}
          isOwner={isOwner}
        />

        <section className="mb-6 overflow-hidden rounded-md border border-border bg-card">
          <div className="divide-y divide-border">
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">المبلغ المتفق عليه</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(totalAgreed)}</span>
            </div>
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">إجمالي المدفوع</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(paid)}</span>
            </div>
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">عدد الدفعات (تشمل الملغاة)</span>
              <span className="font-semibold tabular-nums text-primary">{payments?.length ?? 0}</span>
            </div>
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">تاريخ الإنشاء</span>
              <span className="font-semibold text-foreground">{formatDate(order.created_at)}</span>
            </div>
          </div>
          <div className="border-t border-accent/30 bg-accent/10 px-6 py-5">
            <div className="flex items-center justify-between">
              <span className="text-lg font-bold text-primary">الرصيد المتبقي</span>
              <span
                className={`text-xl font-bold tabular-nums ${
                  remainingBalance > 0 ? 'text-warning' : 'text-success'
                }`}
              >
                {formatCurrency(remainingBalance)}
              </span>
            </div>
          </div>
        </section>

        <PaymentsTable
          payments={payments ?? []}
          contractorName={order.contractor_name}
          isOwner={isOwner}
          canVoid={order.status === 'active'}
        />
      </div>
    </main>
  )
}