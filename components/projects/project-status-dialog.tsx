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
        <p className="text-sm text-secondary">
          تغيير حالة: <span className="font-semibold text-ink">{projectName}</span>
        </p>

        <div>
          <label
            htmlFor="project-status"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            الحالة
          </label>
          <select
            id="project-status"
            value={status}
            onChange={(event) => setStatus(event.target.value as ProjectStatus)}
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
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
          {isPending ? 'جارٍ الحفظ…' : 'حفظ الحالة'}
        </button>
      </form>
    </DialogShell>
  )
}
