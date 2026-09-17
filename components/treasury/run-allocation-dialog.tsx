'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { runOperatingAllocation } from '@/actions/operating'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

type RunAllocationDialogProps = { onClose: () => void }

export function RunAllocationDialog({ onClose }: RunAllocationDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [yearMonth, setYearMonth] = useState(() => {
    const now = new Date()
    const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1)
    const mm = String(prev.getMonth() + 1).padStart(2, '0')
    return `${prev.getFullYear()}-${mm}`
  })
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    startTransition(async () => {
      const result = await runOperatingAllocation({ yearMonth, idempotencyKey })
      if (result.success) { router.refresh(); onClose(); }
      else setError(result.error ?? 'حدث خطأ غير متوقع')
    })
  }

  return (
    <DialogShell title="تشغيل توزيع مصاريف التشغيل" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label htmlFor="run-month" className="mb-2 block">
            الشهر (السنة-الشهر)
          </Label>
          <Input
            id="run-month"
            type="month"
            required
            value={yearMonth}
            onChange={(event) => setYearMonth(event.target.value)}
          />
          <p className="mt-1 text-xs text-secondary">يوزَّع على المشاريع النشطة (بالدليل) بالتساوي</p>
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
          {isPending ? 'جارٍ التوزيع…' : 'تشغيل التوزيع'}
        </Button>
      </form>
    </DialogShell>
  )
}
