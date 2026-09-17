import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { StatusBadge } from '@/components/layout/status-badge'
import { WorkerActionBar } from '@/components/workers/worker-action-bar'
import { formatCurrency, formatDate } from '@/lib/format'
import { getWorkerDetail } from '@/actions/labor'

type WorkerDetailPageProps = {
  params: Promise<{ id: string }>
}

const FRACTION_LABELS: Record<number, string> = {
  0.25: 'ربع يوم',
  0.5: 'نصف يوم',
  1: 'يوم كامل',
}

export default async function WorkerDetailPage({ params }: WorkerDetailPageProps) {
  const { id } = await params

  const { worker, logs, advances, liabilities } = await getWorkerDetail(id)

  const supabase = await createClient()
  const { data: authResult } = await supabase.auth.getUser()

  let isOwner = false
  if (authResult.user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authResult.user.id)
      .single()
    isOwner = profile?.role === 'owner'
  }

  if (!worker) {
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-foreground">العامل غير موجود</h1>
          <p className="text-muted-foreground">لم يتم العثور على عامل بهذا المعرّف.</p>
        </div>
      </main>
    )
  }

  return (
    <main className="min-h-screen">

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-4">
          <Link
            href="/workers"
            className="inline-flex items-center gap-1 text-sm font-semibold text-muted-foreground transition hover:text-foreground"
          >
            <span aria-hidden>←</span> العودة للعمال
          </Link>
        </div>

        <header className="mb-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <h1 className="text-xl font-bold text-foreground sm:text-2xl">{worker.name}</h1>
            <StatusBadge
              label={worker.is_active ? 'نشط' : 'موقوف'}
              className={
                worker.is_active
                  ? 'border-success/50 bg-success/10 text-success'
                  : 'border-destructive/50 bg-destructive/10 text-destructive'
              }
            />
          </div>
          <div className="mt-2 flex items-center gap-4 text-sm text-muted-foreground">
            <span>
              السعر اليومي: <span className="font-semibold text-foreground">{formatCurrency(worker.daily_rate)}</span>
            </span>
            {worker.phone && (
              <span dir="ltr">
                الهاتف: <span className="font-semibold text-foreground">{worker.phone}</span>
              </span>
            )}
          </div>
        </header>

        <WorkerActionBar
          workerId={worker.id}
          workerName={worker.name}
          phone={worker.phone}
          dailyRate={worker.daily_rate}
          isActive={worker.is_active}
          isOwner={isOwner}
          pendingWages={liabilities.pending_wages}
          pendingAdvances={liabilities.pending_advances}
          netPayable={liabilities.net_payable}
          carriedForwardCredit={liabilities.carried_forward_credit}
        />

        {/* ملخص الرصيد */}
        <section className="mb-6 max-w-2xl overflow-hidden rounded-md border border-border bg-card shadow-sm">
          <div className="divide-y divide-border">
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">الأجر المستحق (أيام لم تُسَوَّ)</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(liabilities.pending_wages)}</span>
            </div>
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-foreground">السلف المستلمة (غير مسددة)</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(liabilities.pending_advances)}</span>
            </div>
          </div>
          <div className="border-t border-border bg-muted/50 px-6 py-5">
            <div className="flex items-center justify-between">
              <span className="text-lg font-bold text-primary">الصافي المستحق</span>
              <span className="text-xl font-bold tabular-nums text-primary">{formatCurrency(liabilities.net_payable)}</span>
            </div>
            {liabilities.carried_forward_credit > 0 && (
              <div className="mt-2 flex items-center justify-between text-sm">
                <span className="text-muted-foreground">سلفة محمولة (رصيد سالب)</span>
                <span className="font-semibold tabular-nums text-destructive">{formatCurrency(liabilities.carried_forward_credit)}</span>
              </div>
            )}
          </div>
        </section>

        {/* جدول آخر الحضور */}
        <section className="mb-6">
          <h2 className="mb-3 text-lg font-bold text-foreground">آخر سجلات الحضور</h2>
          {(!logs || logs.length === 0) ? (
            <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
              <p className="text-muted-foreground">لا توجد سجلات حضور بعد.</p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-md border border-border bg-card">
              <table className="w-full text-right text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 font-semibold text-muted-foreground">التاريخ</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">المشروع</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">النسبة</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">المبلغ</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">الحالة</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {logs.map((log) => (
                    <tr key={log.id} className="hover:bg-muted/50">
                      <td className="whitespace-nowrap px-4 py-3 tabular-nums text-foreground">{formatDate(log.log_date)}</td>
                      <td className="px-4 py-3 text-foreground">
                        {(log as { projects?: { name: string } | null }).projects?.name ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-foreground">{FRACTION_LABELS[log.fraction] ?? log.fraction}</td>
                      <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                        {formatCurrency(log.calculated_amount)}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge
                          label={log.is_settled ? 'مسدّد' : 'غير مسدّد'}
                          className={
                            log.is_settled
                              ? 'border-success/50 bg-success/10 text-success'
                              : 'border-warning/50 bg-warning/10 text-warning-foreground'
                          }
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        {/* جدول السلف غير المسددة */}
        <section>
          <h2 className="mb-3 text-lg font-bold text-foreground">السلف غير المسددة</h2>
          {(!advances || advances.length === 0) ? (
            <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
              <p className="text-muted-foreground">لا توجد سلف غير مسددة.</p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-md border border-border bg-card">
              <table className="w-full text-right text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 font-semibold text-muted-foreground">التاريخ</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">المبلغ</th>
                    <th className="px-4 py-3 font-semibold text-muted-foreground">ملاحظات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {advances.map((adv) => (
                    <tr key={adv.id} className="hover:bg-muted/50">
                      <td className="whitespace-nowrap px-4 py-3 tabular-nums text-foreground">
                        {formatDate(adv.advance_date)}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                        {formatCurrency(adv.amount)}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{adv.notes ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>
    </main>
  )
}
