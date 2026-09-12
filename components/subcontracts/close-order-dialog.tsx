'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { closeSubcontractOrder } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'

type CloseOrderDialogProps = {
  orderId: string
  contractorName: string
  remainingBalance: number
  onClose: () => void
}

type CloseStatus = 'completed' | 'cancelled'

export function CloseOrderDialog({
  orderId,
  contractorName,
  remainingBalance,
  onClose,
}: CloseOrderDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [status, setStatus] = useState<CloseStatus>('completed')
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  const tryingCompleted = status === 'completed'
  const blockedCompletion = tryingCompleted && remainingBalance > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (blockedCompletion) {
      setError('لا يمكن إغلاق الاتفاقية كمكتملة — يوجد رصيد متبقي غير مدفوع')
      return
    }

    if (reason.trim().length < 3) {
      setError('يجب كتابة سبب الإغلاق (3 أحرف على الأقل)')
      return
    }

    startTransition(async () => {
      const result = await closeSubcontractOrder({
        orderId,
        status,
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
    <DialogShell title={`إغلاق اتفاقية: ${contractorName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="rounded-xl border border-secondary/30 bg-secondary/5 p-4">
          <p className="text-sm text-secondary">الرصيد المتبقي حالياً:</p>
          <p className={`mt-1 text-base font-bold ${remainingBalance > 0 ? 'text-warning' : 'text-success'}`}>
            {formatCurrency(remainingBalance)}
          </p>
        </div>

        <fieldset className="space-y-2">
          <legend className="mb-2 text-sm font-semibold text-ink">نوع الإغلاق</legend>

          <label
            className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 transition ${
              status === 'completed'
                ? 'border-accent/60 bg-accent/10'
                : 'border-secondary/40 bg-background/60'
            }`}
          >
            <input
              type="radio"
              name="close-status"
              value="completed"
              checked={status === 'completed'}
              onChange={() => setStatus('completed')}
              className="mt-1"
            />
            <span className="flex-1">
              <span className="block font-bold text-ink">مكتملة</span>
              <span className="block text-xs text-secondary">
                تتطلب أن يكون الرصيد المتبقي صفراً
              </span>
              {tryingCompleted && remainingBalance > 0 && (
                <span className="mt-1 block text-xs font-semibold text-danger">
                  غير متاح — يوجد {formatCurrency(remainingBalance)} متبقي
                </span>
              )}
            </span>
          </label>

          <label
            className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 transition ${
              status === 'cancelled'
                ? 'border-danger/60 bg-danger/10'
                : 'border-secondary/40 bg-background/60'
            }`}
          >
            <input
              type="radio"
              name="close-status"
              value="cancelled"
              checked={status === 'cancelled'}
              onChange={() => setStatus('cancelled')}
              className="mt-1"
            />
            <span className="flex-1">
              <span className="block font-bold text-ink">ملغية</span>
              <span className="block text-xs text-secondary">
                إغلاق الاتفاقية دون اشتراط السداد الكامل
              </span>
            </span>
          </label>
        </fieldset>

        <div>
          <label htmlFor="close-reason" className="mb-1 block text-sm font-semibold text-ink">
            سبب الإغلاق (إجباري)
          </label>
          <textarea
            id="close-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={2}
            placeholder="مثال: انتهت الأعمال وتم الاستلام..."
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/30"
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
          disabled={isPending || blockedCompletion}
          className={`w-full rounded-xl p-3 text-base font-bold text-background transition disabled:cursor-not-allowed disabled:opacity-50 ${
            status === 'cancelled'
              ? 'bg-danger hover:bg-danger/90'
              : 'bg-primary hover:bg-primary/90'
          }`}
        >
          {isPending
            ? 'جارٍ الإغلاق…'
            : status === 'completed'
              ? 'إغلاق كمكتملة'
              : 'إغلاق كملغية'}
        </button>
      </form>
    </DialogShell>
  )
}