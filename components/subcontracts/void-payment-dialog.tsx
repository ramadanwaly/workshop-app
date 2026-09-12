'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { voidSubcontractPayment } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency, formatDate } from '@/lib/format'

type VoidPaymentDialogProps = {
  paymentId: string
  amount: number
  paymentDate: string
  contractorName: string
  onClose: () => void
}

export function VoidPaymentDialog({
  paymentId,
  amount,
  paymentDate,
  contractorName,
  onClose,
}: VoidPaymentDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (reason.trim().length < 3) {
      setError('سبب الإلغاء يجب أن يكون 3 أحرف على الأقل')
      return
    }

    startTransition(async () => {
      const result = await voidSubcontractPayment({
        paymentId,
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
    <DialogShell title="إلغاء دفعة مقاول" onClose={onClose}>
      <div className="mb-4 rounded-xl border border-secondary/30 bg-secondary/5 p-4">
        <p className="text-sm text-secondary">الدفعة المطلوب إلغاؤها:</p>
        <p className="mt-1 font-bold text-ink">
          {contractorName} — {formatCurrency(amount)}
        </p>
        <p className="mt-1 text-sm text-secondary">بتاريخ {formatDate(paymentDate)}</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="void-sub-reason" className="mb-1 block text-sm font-semibold text-ink">
            سبب الإلغاء (إلزامي)
          </label>
          <textarea
            id="void-sub-reason"
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

        <p className="rounded-xl border border-warning/40 bg-warning/10 p-3 text-xs font-semibold text-warning">
          سيتم إلغاء حركة الخزينة المرتبطة بهذه الدفعة وإرجاعها للرصيد — العملية لا تحذف البيانات
          لأغراض التدقيق.
        </p>

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