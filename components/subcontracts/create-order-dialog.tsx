'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { createSubcontractOrder } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'


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
        <div className="space-y-2">
          <Label htmlFor="sub-contractor">
            اسم المقاول
          </Label>
          <Input
            id="sub-contractor"
            type="text"
            value={contractorName}
            onChange={(e) => setContractorName(e.target.value)}
            required
            autoFocus
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="sub-project">
            المشروع
          </Label>
          {projects.length === 0 ? (
            <p className="rounded-md border border-warning/40 bg-warning/10 p-3 text-sm font-semibold text-warning">
              لا توجد مشاريع نشطة — أضف مشروعاً أولاً.
            </p>
          ) : (
            <select
              id="sub-project"
              value={projectId}
              onChange={(e) => setProjectId(e.target.value)}
              required
              className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {projects.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="sub-description">
            وصف الاتفاقية
          </Label>
          <Textarea
            id="sub-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
            rows={3}
            placeholder="مثلاً: تنفيذ أعمال الدهان لـ 12 وحدة..."
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="sub-amount">
            المبلغ المتفق عليه (ج.م)
          </Label>
          <Input
            id="sub-amount"
            type="number"
            min="1"
            step="0.01"
            value={totalAgreedAmount || ''}
            onChange={(e) => setTotalAgreedAmount(Number(e.target.value))}
            required
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
          disabled={isPending || projects.length === 0}
          className="w-full"
        >
          {isPending ? 'جارٍ الإنشاء…' : 'إنشاء الاتفاقية'}
        </Button>
      </form>
    </DialogShell>
  )
}