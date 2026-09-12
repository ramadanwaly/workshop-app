'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { paySubcontract } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'

function todayDate(): string {
  return new Date().toISOString().slice(0, 10)
}

type PaySubcontractDialogProps = {
  orderId: string
  contractorName: string
  totalAgreed: number
  remainingBalance: number
  onClose: () => void
}

export function PaySubcontractDialog({
  orderId,
  contractorName,
  totalAgreed,
  remainingBalance,
  onClose,
}: PaySubcontractDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [amount, setAmount] = useState(remainingBalance)
  const [paymentDate, setPaymentDate] = useState(() => todayDate())
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  const exceedsRemaining = amount > remainingBalance

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (amount <= 0) {
      setError('المبلغ يجب أن يكون أكبر من صفر')
      return
    }
    if (exceedsRemaining) {
      setError(`المبلغ يتجاوز الرصيد المتبقي (${formatCurrency(remainingBalance)})`)
      return
    }

    startTransition(async () => {
      const result = await paySubcontract({
        orderId,
        amount,
        paymentDate,
        notes: notes.trim() || undefined,
        idempotencyKey,
      })
      if (result.success) {
        router.refresh()
        onClose()
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  return (
    <DialogShell title={`دفعة لمقاول: ${contractorName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="overflow-hidden rounded-xl border border-secondary/30 bg-background/40">
          <div className="divide-y divide-secondary/20">
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-ink">المبلغ المتفق عليه</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(totalAgreed)}</span>
            </div>
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-ink">الرصيد المتبقي</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(remainingBalance)}</span>
            </div>
          </div>
        </div>

        <div>
          <label htmlFor="pay-amount" className="mb-1 block text-sm font-semibold text-ink">
            مبلغ الدفعة (ج.م)
          </label>
          <input
            id="pay-amount"
            type="number"
            min="0.01"
            max={remainingBalance}
            step="0.01"
            value={amount || ''}
            onChange={(e) => setAmount(Number(e.target.value))}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
          {exceedsRemaining && (
            <p className="mt-1 text-xs font-semibold text-danger">
              المبلغ يتجاوز الرصيد المتبقي المسموح به
            </p>
          )}
        </div>

        <div>
          <label htmlFor="pay-date" className="mb-1 block text-sm font-semibold text-ink">
            تاريخ الدفعة
          </label>
          <input
            id="pay-date"
            type="date"
            value={paymentDate}
            onChange={(e) => setPaymentDate(e.target.value)}
            required
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="pay-notes" className="mb-1 block text-sm font-semibold text-ink">
            ملاحظات (اختياري)
          </label>
          <textarea
            id="pay-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={2}
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        {error && (
          <p
            role="alert"
            className="rounded-xl border border-danger/40 bg-danger/10 p-3 text-sm font-semibold text-danger"
          >
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={isPending || exceedsRemaining}
          className="w-full rounded-xl bg-primary p-3 text-base font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isPending ? 'جارٍ السداد…' : 'تسجيل الدفعة'}
        </button>
      </form>
    </DialogShell>
  )
}