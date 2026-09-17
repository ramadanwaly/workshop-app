'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import Link from 'next/link'
import { returnSurplusToBank } from '@/actions/surplus'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from './dialog-shell'

const COMMON_UNITS = ['كجم', 'متر', 'متر مربع', 'لتر', 'قطعة', 'طن']

type SelectOption = { id: string; name: string }

type SurplusDialogProps = {
  projects: SelectOption[]
  onClose: () => void
}

export function SurplusDialog({ projects, onClose }: SurplusDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [projectId, setProjectId] = useState('')
  const [materialName, setMaterialName] = useState('')
  const [unit, setUnit] = useState('')
  const [quantity, setQuantity] = useState('')
  const [estimatedValue, setEstimatedValue] = useState('')
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (projectId === '') {
      setError('يجب اختيار مصدر الفائض (المشروع)')
      return
    }

    const parsedQuantity = quantity.trim() === '' ? NaN : Number(quantity)
    const parsedValue = estimatedValue.trim() === '' ? NaN : Number(estimatedValue)

    startTransition(async () => {
      const result = await returnSurplusToBank({
        projectId,
        materialName: materialName.trim(),
        unit: unit.trim(),
        quantity: parsedQuantity,
        estimatedValue: parsedValue,
        notes: notes.trim() === '' ? undefined : notes.trim(),
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
    <DialogShell title="إرجاع فائض مواد" onClose={onClose}>
      <div className="mb-4 flex items-center justify-between rounded-xl border border-accent/30 bg-accent/10 px-3 py-2 text-xs">
        <span className="font-semibold text-ink">سجل بنك الفائض والمواد المتاحة</span>
        <Link
          href="/surplus"
          onClick={onClose}
          className="font-bold text-accent hover:underline"
        >
          عرض بنك الفائض ←
        </Link>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="surplus-project"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            مصدر الفائض (المشروع)
          </label>
          <select
            id="surplus-project"
            value={projectId}
            onChange={(event) => setProjectId(event.target.value)}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          >
            <option value="" disabled>
              اختر المشروع…
            </option>
            {projects.map((project) => (
              <option key={project.id} value={project.id}>
                {project.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label
            htmlFor="surplus-material"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            اسم المادة
          </label>
          <input
            id="surplus-material"
            type="text"
            value={materialName}
            onChange={(event) => setMaterialName(event.target.value)}
            placeholder="مثال: خشب سويد، مسامير"
            required
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label
              htmlFor="surplus-unit"
              className="mb-1 block text-sm font-semibold text-ink"
            >
              الوحدة
            </label>
            <input
              id="surplus-unit"
              type="text"
              list="surplus-unit-options"
              value={unit}
              onChange={(event) => setUnit(event.target.value)}
              placeholder="كجم، متر…"
              required
              className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
            />
            <datalist id="surplus-unit-options">
              {COMMON_UNITS.map((commonUnit) => (
                <option key={commonUnit} value={commonUnit} />
              ))}
            </datalist>
          </div>

          <div>
            <label
              htmlFor="surplus-quantity"
              className="mb-1 block text-sm font-semibold text-ink"
            >
              الكمية
            </label>
            <input
              id="surplus-quantity"
              type="number"
              inputMode="decimal"
              step="0.01"
              min="0"
              required
              value={quantity}
              onChange={(event) => setQuantity(event.target.value)}
              placeholder="0"
              className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
            />
          </div>
        </div>

        <div>
          <label
            htmlFor="surplus-value"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            القيمة التقديرية (جنيه)
          </label>
          <input
            id="surplus-value"
            type="number"
            inputMode="decimal"
            step="0.01"
            min="0"
            required
            value={estimatedValue}
            onChange={(event) => setEstimatedValue(event.target.value)}
            placeholder="0.00"
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label
            htmlFor="surplus-notes"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            ملاحظات (اختياري)
          </label>
          <input
            id="surplus-notes"
            type="text"
            value={notes}
            onChange={(event) => setNotes(event.target.value)}
            placeholder="أي تفاصيل إضافية"
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
          {isPending ? 'جارٍ الحفظ…' : 'إرجاع الفائض'}
        </button>
      </form>
    </DialogShell>
  )
}