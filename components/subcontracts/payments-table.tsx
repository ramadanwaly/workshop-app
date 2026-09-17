'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { StatusBadge } from '@/components/layout/status-badge'
import dynamic from 'next/dynamic'
const VoidPaymentDialog = dynamic(() => import('./void-payment-dialog').then(mod => mod.VoidPaymentDialog))
import { formatCurrency, formatDate } from '@/lib/format'
import { Button } from '@/components/ui/button'

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
      <h2 className="mb-3 text-lg font-bold text-foreground">سجل الدفعات</h2>
      {payments.length === 0 ? (
        <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
          <p className="text-muted-foreground">لا توجد دفعات مسجلة بعد.</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-md border border-border bg-card">
          <table className="w-full text-right text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="px-4 py-3 font-semibold text-muted-foreground">التاريخ</th>
                <th className="px-4 py-3 font-semibold text-muted-foreground">المبلغ</th>
                <th className="px-4 py-3 font-semibold text-muted-foreground">ملاحظات</th>
                <th className="px-4 py-3 font-semibold text-muted-foreground">الحالة</th>
                {isOwner && canVoid && <th className="px-4 py-3 font-semibold text-muted-foreground">إجراء</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {payments.map((p) => (
                <tr
                  key={p.id}
                  className={p.is_voided ? 'bg-muted/30 text-muted-foreground' : 'hover:bg-muted/50'}
                >
                  <td className="whitespace-nowrap px-4 py-3 tabular-nums text-foreground">
                    {formatDate(p.payment_date)}
                  </td>
                  <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                    {formatCurrency(p.amount)}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{p.notes ?? '—'}</td>
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
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => setVoiding(p)}
                        >
                          إلغاء
                        </Button>
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