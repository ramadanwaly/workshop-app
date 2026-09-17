'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { getWorkerDayAttendance, recordWorkerAttendance } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from './dialog-shell'

const FRACTIONS = [
  { value: 0.25, label: 'ربع يوم' },
  { value: 0.5, label: 'نصف يوم' },
  { value: 1, label: 'يوم كامل' },
] as const

type SelectOption = { id: string; name: string }

type ExistingLogRow = {
  id: string
  fraction: number
  daily_rate: number
  project_id: string | null
}

function fractionLabel(fraction: number): string {
  if (fraction === 0.25) return 'ربع يوم'
  if (fraction === 0.5) return 'نصف يوم'
  return 'يوم كامل'
}

function todayDate(): string {
  return new Date().toISOString().slice(0, 10)
}

type AttendanceDialogProps = {
  workers: SelectOption[]
  projects: SelectOption[]
  onClose: () => void
}

export function AttendanceDialog({
  workers,
  projects,
  onClose,
}: AttendanceDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [workerId, setWorkerId] = useState('')
  const [projectId, setProjectId] = useState('')
  const [workDate, setWorkDate] = useState(() => todayDate())
  const [fraction, setFraction] = useState<0.25 | 0.5 | 1>(1)
  const [idempotencyKey] = useState(() => generateIdempotencyKey())
  const [confirming, setConfirming] = useState(false)
  const [existingRows, setExistingRows] = useState<ExistingLogRow[] | null>(null)

  function resetConfirmation() {
    setConfirming(false)
    setExistingRows(null)
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (workerId === '') {
      setError('يجب اختيار العامل')
      return
    }

    // قرار المالك: قبل إضافة سجل ثانٍ لنفس العامل في نفس اليوم، اطلب تأكيداً
    // صريحاً (اليوم المقسم مشروع، لكن التكرار بالخطأ يجب أن يظهر للمستخدم).
    if (!confirming) {
      startTransition(async () => {
        const result = await getWorkerDayAttendance({ workerId, workDate })
        if (!result.success) {
          setError(result.error ?? 'حدث خطأ غير متوقع')
          return
        }
        const rows = (result.data ?? []) as ExistingLogRow[]
        if (rows.length > 0) {
          setExistingRows(rows)
          setConfirming(true)
        } else {
          // لا سجلات اليوم — سجّل مباشرة
          void submitAttendance()
        }
      })
      return
    }

    void submitAttendance()
  }

  function submitAttendance() {
    startTransition(async () => {
      const result = await recordWorkerAttendance({
        workerId,
        projectId: projectId === '' ? null : projectId,
        workDate,
        fraction,
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
    <DialogShell title="تسجيل يومية عامل" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="attendance-worker"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            العامل
          </label>
          <select
            id="attendance-worker"
            value={workerId}
            onChange={(event) => setWorkerId(event.target.value)}
            required
            autoFocus
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          >
            <option value="" disabled>
              اختر العامل…
            </option>
            {workers.map((worker) => (
              <option key={worker.id} value={worker.id}>
                {worker.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label
            htmlFor="attendance-project"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            المشروع (اختياري)
          </label>
          <select
            id="attendance-project"
            value={projectId}
            onChange={(event) => setProjectId(event.target.value)}
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          >
            <option value="">عمل عام (بدون مشروع)</option>
            {projects.map((project) => (
              <option key={project.id} value={project.id}>
                {project.name}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label
            htmlFor="attendance-date"
            className="mb-1 block text-sm font-semibold text-ink"
          >
            التاريخ
          </label>
          <input
            id="attendance-date"
            type="date"
            value={workDate}
            onChange={(event) => setWorkDate(event.target.value)}
            required
            className="w-full rounded-xl border border-secondary/40 bg-background/60 p-3 text-base text-ink outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/30"
          />
        </div>

        <div>
          <span className="mb-1 block text-sm font-semibold text-ink">
            نسبة اليوم
          </span>
          <div className="grid grid-cols-3 gap-2" role="radiogroup" aria-label="نسبة اليوم">
            {FRACTIONS.map((fractionOption) => (
              <button
                key={fractionOption.value}
                type="button"
                onClick={() => setFraction(fractionOption.value)}
                aria-pressed={fraction === fractionOption.value}
                className={`rounded-xl border p-3 text-sm font-bold transition ${
                  fraction === fractionOption.value
                    ? 'border-accent bg-accent text-primary'
                    : 'border-secondary/40 bg-background/40 text-secondary hover:border-accent hover:text-accent'
                }`}
              >
                {fractionOption.label}
              </button>
            ))}
          </div>
        </div>

        {confirming && existingRows && (
          <div
            role="alert"
            className="rounded-xl border border-accent/50 bg-accent/10 p-3 text-sm text-ink"
          >
            <p className="mb-2 font-bold">
              هذا العامل مسجل اليوم بالفعل ({existingRows.length}{' '}
              {existingRows.length === 1 ? 'سجل' : 'سجلات'}:{' '}
              {existingRows
                .map((row) => fractionLabel(row.fraction))
                .join(' + ')}
              ). أضف سجلاً آخر معاً؟
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => void submitAttendance()}
                disabled={isPending}
                className="flex-1 rounded-xl bg-primary p-2.5 text-sm font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
              >
                نعم، أضف معاً
              </button>
              <button
                type="button"
                onClick={resetConfirmation}
                disabled={isPending}
                className="flex-1 rounded-xl border border-secondary/40 bg-background p-2.5 text-sm font-bold text-secondary transition hover:border-danger hover:text-danger disabled:cursor-not-allowed disabled:opacity-50"
              >
                تراجع
              </button>
            </div>
          </div>
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
          {isPending
            ? 'جارٍ الحفظ…'
            : confirming
              ? 'تأكيد الإضافة مع السجلات السابقة'
              : 'تسجيل اليومية'}
        </button>
      </form>
    </DialogShell>
  )
}