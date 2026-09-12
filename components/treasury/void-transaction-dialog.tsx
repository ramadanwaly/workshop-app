'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { voidTransaction } from '@/actions/treasury'
import { formatCurrency } from '@/lib/format'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

type Transaction = {
  id: string
  transaction_type: string
  category: string
  amount: number
  description: string | null
  created_at: string
}

type VoidTransactionDialogProps = {
  transaction: Transaction
  onClose: () => void
}

export function VoidTransactionDialog({
  transaction,
  onClose,
}: VoidTransactionDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  const isIn = transaction.transaction_type === 'in'

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    startTransition(async () => {
      const result = await voidTransaction({
        transactionId: transaction.id,
        reason: reason.trim(),
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
    <DialogShell title="إلغاء حركة مالية" onClose={onClose}>
      <div className="mb-4 rounded-xl border border-secondary/30 bg-secondary/5 p-4">
        <p className="text-sm text-secondary">الحركة المطلوب إلغاؤها:</p>
        <p className="mt-1 font-bold text-ink">
          {isIn ? 'وارد' : 'صادر'} — {formatCurrency(transaction.amount)}
        </p>
        {transaction.description && (
          <p className="mt-1 text-sm text-secondary">{transaction.description}</p>
        )}
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="void-reason"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            سبب الإلغاء (إلزامي)
          </label>
          <textarea
            id="void-reason"
            required
            minLength={3}
            autoFocus
            value={reason}
            onChange={(event) => setReason(event.target.value)}
            placeholder="اكتب سبب الإلغاء..."
            rows={3}
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
          disabled={isPending}
          className="w-full rounded-xl bg-danger p-3 text-base font-bold text-background transition hover:bg-danger/90 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isPending ? 'جارٍ الإلغاء…' : 'تأكيد الإلغاء'}
        </button>
      </form>
    </DialogShell>
  )
}
