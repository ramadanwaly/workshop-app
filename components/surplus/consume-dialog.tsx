'use client'

import { useState, useTransition } from 'react'
import type { FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { consumeSurplus } from '@/actions/surplus'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'
import { Button } from '@/components/ui/button'

type SurplusItem = {
  id: string
  material_name: string
  unit: string
  quantity: number
  estimated_value: number
}

type ProjectOption = {
  id: string
  name: string
}

type ConsumeDialogProps = {
  item: SurplusItem
  projects: ProjectOption[]
  onClose: () => void
}

export function ConsumeDialog({ item, projects, onClose }: ConsumeDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [targetProjectId, setTargetProjectId] = useState('')
  const [consumeQuantity, setConsumeQuantity] = useState(() => String(item.quantity))
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  const parsedQty = consumeQuantity.trim() === '' ? NaN : Number(consumeQuantity)
  const exceedsAvailable = !isNaN(parsedQty) && parsedQty > item.quantity
  const invalidQty = isNaN(parsedQty) || parsedQty <= 0

  // احتساب القيمة التقديرية التناسبية للاستهلاك
  const unitPrice = item.quantity > 0 ? item.estimated_value / item.quantity : 0
  const estimatedConsumedValue =
    !invalidQty && !exceedsAvailable
      ? parsedQty === item.quantity
        ? item.estimated_value
        : Math.round(unitPrice * parsedQty * 100) / 100
      : 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (!targetProjectId) {
      setError('يرجى اختيار المشروع المستهدف')
      return
    }

    if (invalidQty) {
      setError('يرجى إدخال كمية صالحة أكبر من صفر')
      return
    }

    if (exceedsAvailable) {
      setError(`الكمية المطلوبة تتجاوز الكمية المتاحة (${item.quantity} ${item.unit})`)
      return
    }

    startTransition(async () => {
      const result = await consumeSurplus({
        surplusId: item.id,
        targetProjectId,
        consumeQuantity: parsedQty,
        notes: notes.trim() || undefined,
        idempotencyKey,
      })

      if (result.success) {
        onClose()
        router.refresh()
      } else {
        setError(result.error ?? 'حدث خطأ أثناء استهلاك الفائض')
      }
    })
  }

  return (
    <DialogShell title={`استهلاك فائض: ${item.material_name}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* ملخص المادة المتاحة */}
        <div className="overflow-hidden rounded-md border border-border bg-card p-3 text-sm">
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground">المادة</span>
            <span className="font-bold text-foreground">{item.material_name}</span>
          </div>
          <div className="mt-1.5 flex items-center justify-between">
            <span className="text-muted-foreground">الكمية المتاحة حالياً</span>
            <span className="font-semibold tabular-nums text-primary">
              {item.quantity} {item.unit}
            </span>
          </div>
          <div className="mt-1.5 flex items-center justify-between border-t border-border pt-1.5">
            <span className="text-muted-foreground">إجمالي القيمة التقديرية</span>
            <span className="font-semibold tabular-nums text-accent">
              {formatCurrency(item.estimated_value)}
            </span>
          </div>
        </div>

        {/* اختيار المشروع المستهدف */}
        <div>
          <Label
            htmlFor="target-project"
            className="mb-1 block"
          >
            المشروع المستهدف (سيتم ترحيل التكلفة إليه)
          </Label>
          <Select
            id="target-project"
            value={targetProjectId}
            onChange={(e) => setTargetProjectId(e.target.value)}
            required
            autoFocus
            className="w-full"
          >
            <option value="" disabled>
              اختر المشروع…
            </option>
            {projects.map((proj) => (
              <option key={proj.id} value={proj.id}>
                {proj.name}
              </option>
            ))}
          </Select>
        </div>

        {/* الكمية المستهلكة */}
        <div>
          <div className="mb-1 flex items-center justify-between">
            <Label htmlFor="consume-qty" className="block">
              الكمية المراد استهلاكها ({item.unit})
            </Label>
            <button
              type="button"
              onClick={() => setConsumeQuantity(String(item.quantity))}
              className="text-xs font-semibold text-accent hover:underline"
            >
              كامل الكمية ({item.quantity})
            </button>
          </div>
          <Input
            id="consume-qty"
            type="number"
            inputMode="decimal"
            step="0.01"
            min="0.01"
            max={item.quantity}
            value={consumeQuantity}
            onChange={(e) => setConsumeQuantity(e.target.value)}
            required
            className="w-full"
          />
          {exceedsAvailable && (
            <p className="mt-1 text-xs font-semibold text-danger">
              الكمية تتجاوز المتاح في بنك الفائض ({item.quantity} {item.unit})
            </p>
          )}
          {!invalidQty && !exceedsAvailable && (
            <p className="mt-1 text-xs text-muted-foreground">
              القيمة التقديرية المحولة للمشروع: {' '}
              <span className="font-semibold text-accent">
                {formatCurrency(estimatedConsumedValue)}
              </span>
            </p>
          )}
        </div>

        {/* ملاحظات */}
        <div>
          <Label htmlFor="consume-notes" className="mb-1 block">
            ملاحظات (اختياري)
          </Label>
          <Textarea
            id="consume-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={2}
            placeholder="مثال: تم التوريد لمرحلة التجميع"
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

        <Button
          type="submit"
          disabled={isPending || exceedsAvailable || invalidQty || !targetProjectId}
          className="w-full"
        >
          {isPending ? 'جارٍ تسجيل الاستهلاك…' : 'تأكيد استهلاك الفائض'}
        </Button>
      </form>
    </DialogShell>
  )
}
