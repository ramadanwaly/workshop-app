'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { addOperatingAllocationExclusion } from '@/actions/operating'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'

type AllocationExclusionDialogProps = {
  projects: Array<{ id: string; name: string }>
  onClose: () => void
}

export function AllocationExclusionDialog({ projects, onClose }: AllocationExclusionDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [yearMonth, setYearMonth] = useState(() => {
    const now = new Date()
    const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1)
    const mm = String(prev.getMonth() + 1).padStart(2, '0')
    return `${prev.getFullYear()}-${mm}`
  })
  const [projectId, setProjectId] = useState('')
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (projectId === '') {
      setError('يجب اختيار مشروع')
      return
    }

    startTransition(async () => {
      const result = await addOperatingAllocationExclusion({
        yearMonth,
        projectId,
        reason: reason.trim() === '' ? undefined : reason.trim(),
        idempotencyKey,
      })
      if (result.success) { router.refresh(); onClose(); }
      else setError(result.error ?? 'حدث خطأ غير متوقع')
    })
  }

  return (
    <DialogShell title="استبعاد مشروع من توزيع التشغيل" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label htmlFor="exclusion-month" className="mb-2 block">
            الشهر (السنة-الشهر)
          </Label>
          <Input
            id="exclusion-month"
            type="month"
            required
            value={yearMonth}
            onChange={(event) => setYearMonth(event.target.value)}
          />
        </div>
        <div>
          <Label htmlFor="exclusion-project" className="mb-2 block">
            المشروع
          </Label>
          <Select
            id="exclusion-project"
            required
            value={projectId}
            onChange={(event) => setProjectId(event.target.value)}
          >
            <option value="">اختر المشروع</option>
            {projects.map((project) => (
              <option key={project.id} value={project.id}>
                {project.name}
              </option>
            ))}
          </Select>
        </div>
        <div>
          <Label htmlFor="exclusion-reason" className="mb-2 block">
            السبب (اختياري)
          </Label>
          <Input
            id="exclusion-reason"
            type="text"
            value={reason}
            onChange={(event) => setReason(event.target.value)}
            placeholder="مثال: مشروع مجمد"
          />
        </div>
        {error && (
          <p role="alert" className="rounded-xl border border-danger/40 bg-danger/10 p-3 text-sm font-semibold text-danger">
            {error}
          </p>
        )}
        <Button
          type="submit"
          disabled={isPending}
          className="w-full"
        >
          {isPending ? 'جارٍ الحفظ…' : 'حفظ الاستبعاد'}
        </Button>
      </form>
    </DialogShell>
  )
}
