'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { voidTransaction } from '@/actions/treasury'
import { formatCurrency } from '@/lib/format'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'

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
        <p className="mt-3 border-t border-secondary/20 pt-3 text-xs leading-5 text-secondary">
          سيبقى سجل الحركة ظاهرًا في دفتر الخزينة بحالة «ملغاة» لأغراض المراجعة، ولن يُحذف.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label
            htmlFor="void-reason"
            className="mb-2 block"
          >
            سبب الإلغاء (إلزامي)
          </Label>
          <Textarea
            id="void-reason"
            required
            minLength={3}
            autoFocus
            value={reason}
            onChange={(event) => setReason(event.target.value)}
            placeholder="اكتب سبب الإلغاء..."
            rows={3}
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

        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <Button
            type="button"
            onClick={onClose}
            disabled={isPending}
            variant="outline"
          >
            رجوع
          </Button>
          <Button
            type="submit"
            disabled={isPending}
            variant="destructive"
          >
            {isPending ? 'جارٍ الإلغاء…' : 'تأكيد الإلغاء'}
          </Button>
        </div>
      </form>
    </DialogShell>
  )
}
