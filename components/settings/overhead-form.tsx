'use client'

import { useState, useTransition, FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { updateOverhead } from '@/actions/settings'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

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
    <div className="rounded-md border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="mb-4">
        <h2 className="text-lg font-bold text-foreground sm:text-xl">
          نسبة التكاليف الإدارية والتشغيلية (Overhead)
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          تستخدم هذه النسبة لتقدير إجمالي تكلفة المشاريع شاملاً المصاريف الإدارية العامة. النسبة الافتراضية هي 10.00%.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label htmlFor="overhead-input" className="mb-2 block">
            النسبة المئوية (%)
          </Label>
          <div className="relative max-w-xs">
            <Input
              id="overhead-input"
              type="number"
              inputMode="decimal"
              step="0.01"
              min="0"
              max="100"
              value={overheadPercentage}
              onChange={(e) => setOverheadPercentage(e.target.value)}
              required
              className="text-lg font-bold"
            />
            <span className="pointer-events-none absolute inset-y-0 end-3 flex items-center font-bold text-muted-foreground">
              %
            </span>
          </div>
        </div>

        {error && (
          <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/10 p-3 text-sm font-semibold text-destructive">
            {error}
          </p>
        )}

        {successMessage && (
          <p role="status" className="rounded-md border border-success/30 bg-success/10 p-3 text-sm font-semibold text-success">
            {successMessage}
          </p>
        )}

        <div className="flex items-center gap-3">
          <Button
            type="submit"
            disabled={isPending}
          >
            {isPending ? 'جارٍ الحفظ…' : 'حفظ التعديلات'}
          </Button>
        </div>
      </form>
    </div>
  )
}
