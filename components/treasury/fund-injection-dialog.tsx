'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { injectOwnerFunding } from '@/actions/treasury'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

type FundInjectionDialogProps = {
  onClose: () => void
}

export function FundInjectionDialog({ onClose }: FundInjectionDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    const parsedAmount = amount.trim() === '' ? NaN : Number(amount)

    startTransition(async () => {
      const result = await injectOwnerFunding({
        amount: parsedAmount,
        description: description.trim() === '' ? undefined : description.trim(),
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
    <DialogShell title="إيداع أموال في الخزينة" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="inject-amount"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            المبلغ (جنيه)
          </label>
          <input
            id="inject-amount"
            type="number"
            inputMode="decimal"
            step="0.01"
            min="0"
            required
            autoFocus
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            placeholder="0.00"
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label
            htmlFor="inject-description"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            الوصف (اختياري)
          </label>
          <input
            id="inject-description"
            type="text"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="مثال: تمويل نقدي من المالك"
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
          className="w-full rounded-xl bg-success p-3 text-base font-bold text-background transition hover:bg-success/90 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isPending ? 'جارٍ الإيداع…' : 'إيداع في الخزينة'}
        </button>
      </form>
    </DialogShell>
  )
}
