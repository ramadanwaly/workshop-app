'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { recordWorkerAdvance } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

function todayDate(): string {
  return new Date().toISOString().slice(0, 10)
}

type AdvanceDialogProps = {
  workerId: string
  workerName: string
  onClose: () => void
}

export function AdvanceDialog({ workerId, workerName, onClose }: AdvanceDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [amount, setAmount] = useState(0)
  const [advanceDate, setAdvanceDate] = useState(() => todayDate())
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (amount <= 0) {
      setError('يجب أن يكون المبلغ أكبر من صفر')
      return
    }

    startTransition(async () => {
      const result = await recordWorkerAdvance({
        workerId,
        amount,
        advanceDate,
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
    <DialogShell title={`سلفة للعامل: ${workerName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="advance-amount" className="mb-1 block text-sm font-semibold text-ink">
            مبلغ السلفة (ج.م)
          </label>
          <input
            id="advance-amount"
            type="number"
            min="1"
            step="0.01"
            value={amount || ''}
            onChange={(e) => setAmount(Number(e.target.value))}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="advance-date" className="mb-1 block text-sm font-semibold text-ink">
            التاريخ
          </label>
          <input
            id="advance-date"
            type="date"
            value={advanceDate}
            onChange={(e) => setAdvanceDate(e.target.value)}
            required
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="advance-notes" className="mb-1 block text-sm font-semibold text-ink">
            ملاحظات (اختياري)
          </label>
          <textarea
            id="advance-notes"
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
          {isPending ? 'جارٍ الحفظ…' : 'إصدار السلفة'}
        </button>
      </form>
    </DialogShell>
  )
}
