'use client'

import { useState, useTransition, FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { updateOverhead } from '@/actions/settings'
import { generateIdempotencyKey } from '@/lib/idempotency-key'

type OverheadFormProps = {
  initialOverheadPercentage: number
}

export function OverheadForm({ initialOverheadPercentage }: OverheadFormProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [overheadPercentage, setOverheadPercentage] = useState<string>(
    String(initialOverheadPercentage)
  )
  const [error, setError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [idempotencyKey, setIdempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError(null)
    setSuccessMessage(null)

    const numValue = Number(overheadPercentage)
    if (isNaN(numValue) || numValue < 0 || numValue > 100) {
      setError('يرجى إدخال نسبة مئوية صالحة بين 0 و 100')
      return
    }

    startTransition(async () => {
      const res = await updateOverhead({
        overheadPercentage: numValue,
        idempotencyKey,
      })

      if (res.success) {
        setSuccessMessage('تم تحديث نسبة الأوفر هيد بنجاح')
        setIdempotencyKey(generateIdempotencyKey())
        router.refresh()
      } else {
        setError(res.error ?? 'حدث خطأ أثناء تحديث نسبة الأوفر هيد')
      }
    })
  }

  return (
    <div className="rounded-2xl border border-secondary/20 bg-card p-5 shadow-sm sm:p-6">
      <div className="mb-4">
        <h2 className="text-lg font-bold text-ink sm:text-xl">
          نسبة التكاليف الإدارية والتشغيلية (Overhead)
        </h2>
        <p className="mt-1 text-sm text-secondary">
          تستخدم هذه النسبة لتقدير إجمالي تكلفة المشاريع شاملاً المصاريف الإدارية العامة. النسبة الافتراضية هي 10.00%.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="overhead-input" className="mb-1 block text-sm font-semibold text-ink">
            النسبة المئوية (%)
          </label>
          <div className="relative max-w-xs">
            <input
              id="overhead-input"
              type="number"
              inputMode="decimal"
              step="0.01"
              min="0"
              max="100"
              value={overheadPercentage}
              onChange={(e) => setOverheadPercentage(e.target.value)}
              required
              className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-lg font-bold text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
            />
            <span className="pointer-events-none absolute inset-y-0 end-3 flex items-center font-bold text-secondary">
              %
            </span>
          </div>
        </div>

        {error && (
          <p role="alert" className="rounded-xl border border-danger/30 bg-danger/10 p-3 text-sm font-semibold text-danger">
            {error}
          </p>
        )}

        {successMessage && (
          <p role="status" className="rounded-xl border border-success/30 bg-success/10 p-3 text-sm font-semibold text-success">
            {successMessage}
          </p>
        )}

        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={isPending}
            className="rounded-xl bg-primary px-5 py-3 text-sm font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isPending ? 'جارٍ الحفظ…' : 'حفظ التعديلات'}
          </button>
        </div>
      </form>
    </div>
  )
}
