'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { settleWorker } from '@/actions/labor'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency } from '@/lib/format'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

type SettleDialogProps = {
  workerId: string
  workerName: string
  pendingWages: number
  pendingAdvances: number
  netPayable: number
  carriedForwardCredit: number
  onClose: () => void
}

export function SettleDialog({
  workerId,
  workerName,
  pendingWages,
  pendingAdvances,
  netPayable,
  carriedForwardCredit,
  onClose,
}: SettleDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [notes, setNotes] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    startTransition(async () => {
      const result = await settleWorker({
        workerId,
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
    <DialogShell title={`تسوية العامل: ${workerName}`} onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* ملخص الأرقام القادمة من قاعدة البيانات */}
        <div className="overflow-hidden rounded-md border border-border bg-card">
          <div className="divide-y divide-border">
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-foreground">الأجر المستحق</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(pendingWages)}</span>
            </div>
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-foreground">السلف المستلمة</span>
              <span className="font-semibold tabular-nums text-primary">{formatCurrency(pendingAdvances)}</span>
            </div>
          </div>
          <div className="border-t border-border bg-muted/50 px-4 py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-bold text-primary">الصافي المستحق</span>
              <span className="text-base font-bold tabular-nums text-primary">{formatCurrency(netPayable)}</span>
            </div>
            {carriedForwardCredit > 0 && (
              <div className="mt-1 flex items-center justify-between text-xs">
                <span className="text-muted-foreground">سلفة محمولة (رصيد سالب)</span>
                <span className="font-semibold tabular-nums text-destructive">{formatCurrency(carriedForwardCredit)}</span>
              </div>
            )}
          </div>
        </div>

        {netPayable === 0 && carriedForwardCredit > 0 && (
          <p className="rounded-md border border-warning/40 bg-warning/10 p-3 text-sm font-semibold text-warning-foreground">
            لا يوجد صافي مستحق — سيتم حفظ الفرق كسلفة محمولة للفترة القادمة.
          </p>
        )}

        <div className="space-y-2">
          <Label htmlFor="settle-notes">
            ملاحظات (اختياري)
          </Label>
          <Textarea
            id="settle-notes"
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
          {isPending ? 'جارٍ التسوية…' : 'تسوية الحساب'}
        </Button>
      </form>
    </DialogShell>
  )
}
