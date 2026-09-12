'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { StatusBadge } from '@/components/layout/status-badge'
import { VoidPaymentDialog } from './void-payment-dialog'
import { formatCurrency, formatDate } from '@/lib/format'

type Payment = {
  id: string
  amount: number
  payment_date: string
  notes: string | null
  is_voided: boolean
  created_at: string
}

type PaymentsTableProps = {
  payments: Payment[]
  contractorName: string
  isOwner: boolean
  canVoid: boolean
}

export function PaymentsTable({
  payments,
  contractorName,
  isOwner,
  canVoid,
}: PaymentsTableProps) {
  const [voiding, setVoiding] = useState<Payment | null>(null)
  const router = useRouter()

  return (
    <section>
      <h2 className="mb-3 text-lg font-bold text-ink">سجل الدفعات</h2>
      {payments.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
          <p className="text-secondary">لا توجد دفعات مسجلة بعد.</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-secondary/30 bg-white">
          <table className="w-full text-right text-sm">
            <thead>
              <tr className="border-b border-secondary/20 bg-background/40">
                <th className="px-4 py-3 font-semibold text-ink">التاريخ</th>
                <th className="px-4 py-3 font-semibold text-ink">المبلغ</th>
                <th className="px-4 py-3 font-semibold text-ink">ملاحظات</th>
                <th className="px-4 py-3 font-semibold text-ink">الحالة</th>
                {isOwner && canVoid && <th className="px-4 py-3 font-semibold text-ink">إجراء</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary/10">
              {payments.map((p) => (
                <tr
                  key={p.id}
                  className={p.is_voided ? 'bg-secondary/5 text-secondary' : 'hover:bg-background/20'}
                >
                  <td className="whitespace-nowrap px-4 py-3 tabular-nums text-ink">
                    {formatDate(p.payment_date)}
                  </td>
                  <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                    {formatCurrency(p.amount)}
                  </td>
                  <td className="px-4 py-3 text-secondary">{p.notes ?? '—'}</td>
                  <td className="px-4 py-3">
                    {p.is_voided ? (
                      <StatusBadge
                        label="ملغاة"
                        className="border-danger/50 bg-danger/10 text-danger"
                      />
                    ) : (
                      <StatusBadge
                        label="صحيحة"
                        className="border-success/50 bg-success/10 text-success"
                      />
                    )}
                  </td>
                  {isOwner && canVoid && (
                    <td className="px-4 py-3">
                      {!p.is_voided && (
                        <button
                          type="button"
                          onClick={() => setVoiding(p)}
                          className="rounded-lg border border-danger/40 px-3 py-1 text-xs font-bold text-danger transition hover:bg-danger/10"
                        >
                          إلغاء
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {voiding && (
        <VoidPaymentDialog
          paymentId={voiding.id}
          amount={Number(voiding.amount)}
          paymentDate={voiding.payment_date}
          contractorName={contractorName}
          onClose={() => {
            setVoiding(null)
            router.refresh()
          }}
        />
      )}
    </section>
  )
}