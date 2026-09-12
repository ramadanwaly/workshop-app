'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { createProject, updateProject } from '@/actions/projects'
import type { CreateProjectInput, UpdateProjectInput } from '@/lib/validations/projects'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'

type ProjectFormDialogProps = {
  mode: 'create' | 'edit'
  project?: { id: string; name: string; description: string | null }
  onClose: () => void
}

export function ProjectFormDialog({ mode, project, onClose }: ProjectFormDialogProps) {
  const router = useRouter()
  const isEdit = mode === 'edit'
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [name, setName] = useState(project?.name ?? '')
  const [description, setDescription] = useState(project?.description ?? '')

  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  const title = isEdit ? 'تعديل المشروع' : 'مشروع جديد'

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    startTransition(async () => {
      if (isEdit && project) {
        const input: UpdateProjectInput = {
          projectId: project.id,
          name: name.trim(),
          description: description.trim() === '' ? null : description.trim(),
          idempotencyKey,
        }
        const result = await updateProject(input)
        if (result.success) {
        router.refresh()
        onClose()
      } else {
          setError(result.error ?? 'حدث خطأ غير متوقع')
        }
        return
      }

      const input: CreateProjectInput = {
        name: name.trim(),
        description: description.trim() === '' ? undefined : description.trim(),
        idempotencyKey,
      }
      const result = await createProject(input)
      if (result.success) {
        router.refresh()
        onClose()
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  return (
    <DialogShell title={title} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="project-name"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            اسم المشروع
          </label>
          <input
            id="project-name"
            type="text"
            required
            autoFocus
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="مثال: غرفة نوم للمنزل"
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <label
            htmlFor="project-description"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            الوصف (اختياري)
          </label>
          <textarea
            id="project-description"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="تفاصيل المشروع إن وجدت"
            rows={3}
            className="w-full resize-none rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
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
          {isPending ? 'جارٍ الحفظ…' : isEdit ? 'حفظ التعديلات' : 'إنشاء المشروع'}
        </button>
      </form>
    </DialogShell>
  )
}
