'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { recordWorkerAdvance } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

function todayDate(): string {
  return new Date().toISOString().slice(0, 10)
}

type AdvanceDialogProps = {
  workerId: string
  workerName: string
  onClose: () => void
}

export function AdvanceDialog({ workerId, workerName, onClose }: AdvanceDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [amount, setAmount] = useState(0)
  const [advanceDate, setAdvanceDate] = useState(() => todayDate())
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (amount <= 0) {
      setError('يجب أن يكون المبلغ أكبر من صفر')
      return
    }

    startTransition(async () => {
      const result = await recordWorkerAdvance({
        workerId,
        amount,
        advanceDate,
        notes: notes || undefined,
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
    <DialogShell title={`سلفة للعامل: ${workerName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="advance-amount">
            مبلغ السلفة (ج.م)
          </Label>
          <Input
            id="advance-amount"
            type="number"
            min="1"
            step="0.01"
            value={amount || ''}
            onChange={(e) => setAmount(Number(e.target.value))}
            required
            autoFocus
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="advance-date">
            التاريخ
          </Label>
          <Input
            id="advance-date"
            type="date"
            value={advanceDate}
            onChange={(e) => setAdvanceDate(e.target.value)}
            required
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="advance-notes">
            ملاحظات (اختياري)
          </Label>
          <Textarea
            id="advance-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={2}
          />
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
          {isPending ? 'جارٍ الحفظ…' : 'إصدار السلفة'}
        </Button>
      </form>
    </DialogShell>
  )
}
