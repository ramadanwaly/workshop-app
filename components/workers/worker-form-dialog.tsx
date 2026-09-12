'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { createWorker, updateWorker, toggleWorkerStatus } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

type WorkerFormDialogProps =
  | { mode: 'add'; onClose: () => void }
  | {
      mode: 'edit'
      worker: { id: string; name: string; phone: string | null; daily_rate: number; is_active: boolean }
      onClose: () => void
    }

export function WorkerFormDialog(props: WorkerFormDialogProps) {
  const router = useRouter()
  const { mode, onClose } = props
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  const editWorker = mode === 'edit' ? props.worker : null

  const [name, setName] = useState(editWorker?.name ?? '')
  const [phone, setPhone] = useState(editWorker?.phone ?? '')
  const [dailyRate, setDailyRate] = useState(editWorker?.daily_rate ?? 0)
  const [isActive, setIsActive] = useState(editWorker?.is_active ?? true)
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    startTransition(async () => {
      let result
      if (mode === 'add') {
        result = await createWorker({ name, phone: phone || null, dailyRate, idempotencyKey })
      } else if (editWorker) {
        result = await updateWorker({
          workerId: editWorker.id,
          name,
          phone: phone || null,
          dailyRate,
          idempotencyKey,
        })
      } else {
        return
      }

      if (result.success) {
        router.refresh()
        onClose()
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  async function handleToggle() {
    if (!editWorker) return
    setError(null)
    startTransition(async () => {
      const result = await toggleWorkerStatus({
        workerId: editWorker.id,
        isActive: !isActive,
        idempotencyKey: generateIdempotencyKey(),
      })
      if (result.success) {
        setIsActive(!isActive)
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  return (
    <DialogShell title={mode === 'add' ? 'عامل جديد' : 'تعديل بيانات العامل'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="worker-name" className="mb-1 block text-sm font-semibold text-ink">
            اسم العامل
          </label>
          <input
            id="worker-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="worker-phone" className="mb-1 block text-sm font-semibold text-ink">
            رقم الهاتف (اختياري)
          </label>
          <input
            id="worker-phone"
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            dir="ltr"
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="worker-rate" className="mb-1 block text-sm font-semibold text-ink">
            الأجر اليومي (ج.م)
          </label>
          <input
            id="worker-rate"
            type="number"
            min="1"
            step="0.01"
            value={dailyRate || ''}
            onChange={(e) => setDailyRate(Number(e.target.value))}
            required
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        {mode === 'edit' && (
          <button
            type="button"
            onClick={handleToggle}
            disabled={isPending}
            className={`w-full rounded-xl border p-3 text-sm font-bold transition ${
              isActive
                ? 'border-danger/40 bg-danger/10 text-danger hover:bg-danger/20'
                : 'border-success/40 bg-success/10 text-success hover:bg-success/20'
            } disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {isPending
              ? 'جارٍ التحديث…'
              : isActive
                ? 'إيقاف العامل'
                : 'تفعيل العامل'}
          </button>
        )}

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
          {isPending ? 'جارٍ الحفظ…' : mode === 'add' ? 'إضافة العامل' : 'حفظ التعديلات'}
        </button>
      </form>
    </DialogShell>
  )
}
