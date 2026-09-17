'use client'

import { useState, useTransition } from 'react'
import type { FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { scrapSurplus } from '@/actions/surplus'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'

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
        <div className="rounded-md border border-danger/30 bg-danger/10 p-4 text-sm text-foreground">
          <p className="font-bold text-danger">تنبيه: سيتم تسجيل هذه المادة كـ &quot;هالك / متلف&quot;</p>
          <p className="mt-1 text-xs text-muted-foreground">
            سيتم تصفير الكمية المتوفرة وتسجيل القيمة التقديرية كـ خسران/هالك عام بالورشة دون تحميلها على أي مشروع.
          </p>

          <dl className="mt-3 space-y-1 border-t border-danger/20 pt-2 text-xs">
            <div className="flex justify-between">
              <dt className="text-muted-foreground">المادة:</dt>
              <dd className="font-bold text-foreground">{item.material_name}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">الكمية المتلفة:</dt>
              <dd className="font-semibold tabular-nums text-foreground">
                {item.quantity} {item.unit}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted-foreground">قيمة الهالك:</dt>
              <dd className="font-bold tabular-nums text-danger">
                {formatCurrency(item.estimated_value)}
              </dd>
            </div>
          </dl>
        </div>

        {/* سبب الإتلاف (إجباري) */}
        <div>
          <Label htmlFor="scrap-notes" className="mb-1 block">
            سبب الإتلاف (إجباري)
          </Label>
          <Textarea
            id="scrap-notes"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            placeholder="مثال: رطوبة وتلف التخزين، سوء استخدام..."
            className="w-full"
          />
        </div>

        {error && (
          <p
            role="alert"
            className="rounded-md border border-danger/40 bg-danger/10 p-3 text-sm font-semibold text-danger"
          >
            {error}
          </p>
        )}

        <div className="flex gap-3 pt-1">
          <Button
            type="submit"
            disabled={isPending}
            className="flex-1 bg-danger hover:bg-danger/90 text-white"
          >
            {isPending ? 'جارٍ تسجيل الإتلاف…' : 'تأكيد إتلاف المادة'}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={onClose}
            disabled={isPending}
          >
            إلغاء
          </Button>
        </div>
      </form>
    </DialogShell>
  )
}
