'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { updateProjectStatus } from '@/actions/projects'
import type {
  ProjectStatus,
  UpdateProjectStatusInput,
} from '@/lib/validations/projects'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'

const STATUS_OPTIONS: ReadonlyArray<{ value: ProjectStatus; label: string }> = [
  { value: 'active', label: 'نشط' },
  { value: 'on_hold', label: 'متوقف مؤقتاً' },
  { value: 'completed', label: 'مكتمل' },
  { value: 'cancelled', label: 'ملغي' },
]

type ProjectStatusDialogProps = {
  projectId: string
  projectName: string
  currentStatus: string
  onClose: () => void
}

export function ProjectStatusDialog({
  projectId,
  projectName,
  currentStatus,
  onClose,
}: ProjectStatusDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [status, setStatus] = useState<ProjectStatus>(() =>
    STATUS_OPTIONS.some((option) => option.value === currentStatus)
      ? (currentStatus as ProjectStatus)
      : 'active'
  )
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    const input: UpdateProjectStatusInput = {
      projectId,
      status,
      idempotencyKey,
    }

    startTransition(async () => {
      const result = await updateProjectStatus(input)
      if (result.success) {
        router.refresh()
        onClose()
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  return (
    <DialogShell title="تغيير حالة المشروع" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <p className="text-sm text-muted-foreground">
          تغيير حالة: <span className="font-semibold text-foreground">{projectName}</span>
        </p>

        <div className="space-y-2">
          <Label htmlFor="project-status">الحالة</Label>
          <select
            id="project-status"
            value={status}
            onChange={(event) => setStatus(event.target.value as ProjectStatus)}
            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {STATUS_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        {error && (
          <p
            role="alert"
            className="rounded-md border border-destructive/40 bg-destructive/10 p-3 text-sm font-semibold text-destructive"
          >
            {error}
          </p>
        )}

        <Button
          type="submit"
          disabled={isPending}
          className="w-full"
        >
          {isPending ? 'جارٍ الحفظ…' : 'حفظ الحالة'}
        </Button>
      </form>
    </DialogShell>
  )
}
