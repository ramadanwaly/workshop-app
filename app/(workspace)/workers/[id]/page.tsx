import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
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
        <WorkspaceHeader />
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-ink">العامل غير موجود</h1>
          <p className="text-secondary">لم يتم العثور على عامل بهذا المعرّف.</p>
        </div>
      </main>
    )
  }

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-4">
          <Link
            href="/workers"
            className="inline-flex items-center gap-1 text-sm font-semibold text-secondary transition hover:text-accent"
          >
            <span aria-hidden>←</span> العودة للعمال
          </Link>
        </div>

        <header className="mb-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <h1 className="text-xl font-bold text-ink sm:text-2xl">{worker.name}</h1>
            <StatusBadge
              label={worker.is_active ? 'نشط' : 'موقوف'}
              className={
                worker.is_active
                  ? 'border-success/50 bg-success/10 text-success'
                  : 'border-danger/50 bg-danger/10 text-danger'
              }
            />
          </div>
          <div className="mt-2 flex items-center gap-4 text-sm text-secondary">
            <span>
              السعر اليومي: <span className="font-semibold text-ink">{formatCurrency(worker.daily_rate)}</span>
            </span>
            {worker.phone && (
              <span dir="ltr">
                الهاتف: <span className="font-semibold text-ink">{worker.phone}</span>
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
        <section className="mb-6 max-w-2xl overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-lg shadow-primary/5">
          <div className="divide-y divide-secondary/20">
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-ink">الأجر المستحق (أيام لم تُسَوَّ)</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(liabilities.pending_wages)}</span>
            </div>
            <div className="flex items-center justify-between px-6 py-4">
              <span className="text-ink">السلف المستلمة (غير مسددة)</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(liabilities.pending_advances)}</span>
            </div>
          </div>
          <div className="border-t border-accent/30 bg-accent/10 px-6 py-5">
            <div className="flex items-center justify-between">
              <span className="text-lg font-bold text-primary">الصافي المستحق</span>
              <span className="text-xl font-bold tabular-nums text-accent">{formatCurrency(liabilities.net_payable)}</span>
            </div>
            {liabilities.carried_forward_credit > 0 && (
              <div className="mt-2 flex items-center justify-between text-sm">
                <span className="text-secondary">سلفة محمولة (رصيد سالب)</span>
                <span className="font-semibold tabular-nums text-danger">{formatCurrency(liabilities.carried_forward_credit)}</span>
              </div>
            )}
          </div>
        </section>

        {/* جدول آخر الحضور */}
        <section className="mb-6">
          <h2 className="mb-3 text-lg font-bold text-ink">آخر سجلات الحضور</h2>
          {(!logs || logs.length === 0) ? (
            <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
              <p className="text-secondary">لا توجد سجلات حضور بعد.</p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-2xl border border-secondary/30 bg-white">
              <table className="w-full text-right text-sm">
                <thead>
                  <tr className="border-b border-secondary/20 bg-background/40">
                    <th className="px-4 py-3 font-semibold text-ink">التاريخ</th>
                    <th className="px-4 py-3 font-semibold text-ink">المشروع</th>
                    <th className="px-4 py-3 font-semibold text-ink">النسبة</th>
                    <th className="px-4 py-3 font-semibold text-ink">المبلغ</th>
                    <th className="px-4 py-3 font-semibold text-ink">الحالة</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-secondary/10">
                  {logs.map((log) => (
                    <tr key={log.id} className="hover:bg-background/20">
                      <td className="whitespace-nowrap px-4 py-3 tabular-nums text-ink">{formatDate(log.log_date)}</td>
                      <td className="px-4 py-3 text-ink">
                        {(log as { projects?: { name: string } | null }).projects?.name ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-ink">{FRACTION_LABELS[log.fraction] ?? log.fraction}</td>
                      <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                        {formatCurrency(log.calculated_amount)}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge
                          label={log.is_settled ? 'مسدّد' : 'غير مسدّد'}
                          className={
                            log.is_settled
                              ? 'border-success/50 bg-success/10 text-success'
                              : 'border-warning/50 bg-warning/10 text-warning'
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
          <h2 className="mb-3 text-lg font-bold text-ink">السلف غير المسددة</h2>
          {(!advances || advances.length === 0) ? (
            <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
              <p className="text-secondary">لا توجد سلف غير مسددة.</p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-2xl border border-secondary/30 bg-white">
              <table className="w-full text-right text-sm">
                <thead>
                  <tr className="border-b border-secondary/20 bg-background/40">
                    <th className="px-4 py-3 font-semibold text-ink">التاريخ</th>
                    <th className="px-4 py-3 font-semibold text-ink">المبلغ</th>
                    <th className="px-4 py-3 font-semibold text-ink">ملاحظات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-secondary/10">
                  {advances.map((adv) => (
                    <tr key={adv.id} className="hover:bg-background/20">
                      <td className="whitespace-nowrap px-4 py-3 tabular-nums text-ink">
                        {formatDate(adv.advance_date)}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                        {formatCurrency(adv.amount)}
                      </td>
                      <td className="px-4 py-3 text-secondary">{adv.notes ?? '—'}</td>
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
