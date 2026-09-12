'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { createSubcontractOrder } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

type ProjectOption = {
  id: string
  name: string
  status: string
}

type CreateOrderDialogProps = {
  projects: ProjectOption[]
  onClose: () => void
}

export function CreateOrderDialog({ projects, onClose }: CreateOrderDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [contractorName, setContractorName] = useState('')
  const [projectId, setProjectId] = useState(projects[0]?.id ?? '')
  const [description, setDescription] = useState('')
  const [totalAgreedAmount, setTotalAgreedAmount] = useState(0)
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (!projectId) {
      setError('يرجى اختيار مشروع نشط')
      return
    }
    if (totalAgreedAmount <= 0) {
      setError('المبلغ المتفق عليه يجب أن يكون أكبر من صفر')
      return
    }

    startTransition(async () => {
      const result = await createSubcontractOrder({
        projectId,
        contractorName: contractorName.trim(),
        description: description.trim(),
        totalAgreedAmount,
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
    <DialogShell title="اتفاقية مقاول باطن جديدة" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="sub-contractor" className="mb-1 block text-sm font-semibold text-ink">
            اسم المقاول
          </label>
          <input
            id="sub-contractor"
            type="text"
            value={contractorName}
            onChange={(e) => setContractorName(e.target.value)}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="sub-project" className="mb-1 block text-sm font-semibold text-ink">
            المشروع
          </label>
          {projects.length === 0 ? (
            <p className="rounded-xl border border-warning/40 bg-warning/10 p-3 text-sm font-semibold text-warning">
              لا توجد مشاريع نشطة — أضف مشروعاً أولاً.
            </p>
          ) : (
            <select
              id="sub-project"
              value={projectId}
              onChange={(e) => setProjectId(e.target.value)}
              required
              className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
            >
              {projects.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          )}
        </div>

        <div>
          <label htmlFor="sub-description" className="mb-1 block text-sm font-semibold text-ink">
            وصف الاتفاقية
          </label>
          <textarea
            id="sub-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
            rows={3}
            placeholder="مثلاً: تنفيذ أعمال الدهان لـ 12 وحدة..."
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label htmlFor="sub-amount" className="mb-1 block text-sm font-semibold text-ink">
            المبلغ المتفق عليه (ج.م)
          </label>
          <input
            id="sub-amount"
            type="number"
            min="1"
            step="0.01"
            value={totalAgreedAmount || ''}
            onChange={(e) => setTotalAgreedAmount(Number(e.target.value))}
            required
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
          disabled={isPending || projects.length === 0}
          className="w-full rounded-xl bg-primary p-3 text-base font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isPending ? 'جارٍ الإنشاء…' : 'إنشاء الاتفاقية'}
        </button>
      </form>
    </DialogShell>
  )
}