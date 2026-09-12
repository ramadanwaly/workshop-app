'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { settleWorker } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'

type SettleDialogProps = {
  workerId: string
  workerName: string
  pendingWages: number
  pendingAdvances: number
  netPayable: number
  carriedForwardCredit: number
  onClose: () => void
}

export function SettleDialog({
  workerId,
  workerName,
  pendingWages,
  pendingAdvances,
  netPayable,
  carriedForwardCredit,
  onClose,
}: SettleDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    startTransition(async () => {
      const result = await settleWorker({
        workerId,
        notes: notes || undefined,
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
    <DialogShell title={`تسوية العامل: ${workerName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* ملخص الأرقام القادمة من قاعدة البيانات */}
        <div className="overflow-hidden rounded-xl border border-secondary/30 bg-background/40">
          <div className="divide-y divide-secondary/20">
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-ink">الأجر المستحق</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(pendingWages)}</span>
            </div>
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-ink">السلف المستلمة</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(pendingAdvances)}</span>
            </div>
          </div>
          <div className="border-t border-secondary/20 bg-accent/10 px-4 py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-bold text-primary">الصافي المستحق</span>
              <span className="text-base font-bold tabular-nums text-accent">{formatCurrency(netPayable)}</span>
            </div>
            {carriedForwardCredit > 0 && (
              <div className="mt-1 flex items-center justify-between text-xs">
                <span className="text-secondary">سلفة محمولة (رصيد سالب)</span>
                <span className="font-semibold tabular-nums text-danger">{formatCurrency(carriedForwardCredit)}</span>
              </div>
            )}
          </div>
        </div>

        {netPayable === 0 && carriedForwardCredit > 0 && (
          <p className="rounded-xl border border-warning/40 bg-warning/10 p-3 text-sm font-semibold text-warning">
            لا يوجد صافي مستحق — سيتم حفظ الفرق كسلفة محمولة للفترة القادمة.
          </p>
        )}

        <div>
          <label htmlFor="settle-notes" className="mb-1 block text-sm font-semibold text-ink">
            ملاحظات (اختياري)
          </label>
          <textarea
            id="settle-notes"
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
          disabled={isPending}
          className="w-full rounded-xl bg-primary p-3 text-base font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isPending ? 'جارٍ التسوية…' : 'تسوية الحساب'}
        </button>
      </form>
    </DialogShell>
  )
}
