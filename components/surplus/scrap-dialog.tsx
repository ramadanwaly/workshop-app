'use client'

import { useState, useTransition } from 'react'
import type { FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { scrapSurplus } from '@/actions/surplus'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'

type SurplusItem = {
  id: string
  material_name: string
  unit: string
  quantity: number
  estimated_value: number
}

type ScrapDialogProps = {
  item: SurplusItem
  onClose: () => void
}

export function ScrapDialog({ item, onClose }: ScrapDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (reason.trim().length < 3) {
      setError('يجب كتابة سبب الإتلاف (3 أحرف على الأقل)')
      return
    }

    startTransition(async () => {
      const result = await scrapSurplus({
        surplusId: item.id,
        reason: reason.trim(),
        idempotencyKey,
      })

      if (result.success) {
        onClose()
        router.refresh()
      } else {
        setError(result.error ?? 'حدث خطأ أثناء إتلاف الفائض')
      }
    })
  }

  return (
    <DialogShell title={`إتلاف / كهنة: ${item.material_name}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* تحذير وتلخيص */}
        <div className="rounded-xl border border-danger/30 bg-danger/10 p-4 text-sm text-ink">
          <p className="font-bold text-danger">تنبيه: سيتم تسجيل هذه المادة كـ &quot;هالك / متلف&quot;</p>
          <p className="mt-1 text-xs text-secondary">
            سيتم تصفير الكمية المتوفرة وتسجيل القيمة التقديرية كـ خسران/هالك عام بالورشة دون تحميلها على أي مشروع.
          </p>

          <dl className="mt-3 space-y-1 border-t border-danger/20 pt-2 text-xs">
            <div className="flex justify-between">
              <dt className="text-secondary">المادة:</dt>
              <dd className="font-bold text-ink">{item.material_name}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-secondary">الكمية المتلفة:</dt>
              <dd className="font-semibold tabular-nums text-ink">
                {item.quantity} {item.unit}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-secondary">قيمة الهالك:</dt>
              <dd className="font-bold tabular-nums text-danger">
                {formatCurrency(item.estimated_value)}
              </dd>
            </div>
          </dl>
        </div>

        {/* سبب الإتلاف (إجباري) */}
        <div>
          <label htmlFor="scrap-notes" className="mb-1 block text-sm font-semibold text-ink">
            سبب الإتلاف (إجباري)
          </label>
          <textarea
            id="scrap-notes"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            placeholder="مثال: رطوبة وتلف التخزين، سوء استخدام..."
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-danger focus:ring-2 focus:ring-danger/30"
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

        <div className="flex gap-3 pt-1">
          <button
            type="submit"
            disabled={isPending}
            className="flex-1 rounded-xl bg-danger p-3 text-base font-bold text-white transition hover:bg-danger/90 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isPending ? 'جارٍ تسجيل الإتلاف…' : 'تأكيد إتلاف المادة'}
          </button>
          <button
            type="button"
            onClick={onClose}
            disabled={isPending}
            className="rounded-xl border border-secondary/40 bg-white px-5 py-3 text-base font-semibold text-secondary hover:bg-secondary/10"
          >
            إلغاء
          </button>
        </div>
      </form>
    </DialogShell>
  )
}
