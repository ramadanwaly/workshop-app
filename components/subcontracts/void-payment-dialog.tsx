'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { voidSubcontractPayment } from '@/actions/subcontracts'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from '@/components/mobile/dialog-shell'
import { formatCurrency, formatDate } from '@/lib/format'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

type VoidPaymentDialogProps = {
  paymentId: string
  amount: number
  paymentDate: string
  contractorName: string
  onClose: () => void
}

export function VoidPaymentDialog({
  paymentId,
  amount,
  paymentDate,
  contractorName,
  onClose,
}: VoidPaymentDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (reason.trim().length < 3) {
      setError('سبب الإلغاء يجب أن يكون 3 أحرف على الأقل')
      return
    }

    startTransition(async () => {
      const result = await voidSubcontractPayment({
        paymentId,
        reason: reason.trim(),
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
    <DialogShell title="إلغاء دفعة مقاول" onClose={onClose}>
      <div className="mb-4 rounded-md border border-border bg-muted/50 p-4">
        <p className="text-sm text-muted-foreground">الدفعة المطلوب إلغاؤها:</p>
        <p className="mt-1 font-bold text-foreground">
          {contractorName} — {formatCurrency(amount)}
        </p>
        <p className="mt-1 text-sm text-muted-foreground">بتاريخ {formatDate(paymentDate)}</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="void-sub-reason">
            سبب الإلغاء (إلزامي)
          </Label>
          <Textarea
            id="void-sub-reason"
            required
            minLength={3}
            autoFocus
            value={reason}
            onChange={(event) => setReason(event.target.value)}
            placeholder="اكتب سبب الإلغاء..."
            rows={3}
          />
        </div>

        <p className="rounded-md border border-warning/40 bg-warning/10 p-3 text-xs font-semibold text-warning">
          سيتم إلغاء حركة الخزينة المرتبطة بهذه الدفعة وإرجاعها للرصيد — العملية لا تحذف البيانات
          لأغراض التدقيق.
        </p>

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
          disabled={isPending}
          variant="destructive"
          className="w-full"
        >
          {isPending ? 'جارٍ الإلغاء…' : 'تأكيد الإلغاء'}
        </Button>
      </form>
    </DialogShell>
  )
}