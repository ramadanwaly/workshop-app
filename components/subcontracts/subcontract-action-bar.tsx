'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { PaySubcontractDialog } from './pay-subcontract-dialog'
import { CloseOrderDialog } from './close-order-dialog'

type SubcontractActionBarProps = {
  orderId: string
  contractorName: string
  totalAgreed: number
  paid: number
  remainingBalance: number
  status: 'active' | 'completed' | 'cancelled'
  isOwner: boolean
}

export function SubcontractActionBar({
  orderId,
  contractorName,
  totalAgreed,
  remainingBalance,
  status,
  isOwner,
}: SubcontractActionBarProps) {
  const [isPayOpen, setIsPayOpen] = useState(false)
  const [isCloseOpen, setIsCloseOpen] = useState(false)
  const router = useRouter()

  if (!isOwner) return null
  if (status !== 'active') return null

  return (
    <div className="mb-6 flex flex-wrap items-center gap-3">
      <button
        type="button"
        onClick={() => setIsPayOpen(true)}
        disabled={remainingBalance <= 0}
        className="inline-flex items-center gap-2 rounded-xl border border-accent/50 bg-accent/10 px-4 py-2.5 text-sm font-bold text-accent transition hover:bg-accent/20 disabled:cursor-not-allowed disabled:opacity-50"
      >
        تسجيل دفعة
      </button>

      <button
        type="button"
        onClick={() => setIsCloseOpen(true)}
        className="inline-flex items-center gap-2 rounded-xl border border-secondary/40 bg-white px-4 py-2.5 text-sm font-bold text-primary transition hover:border-accent/60 hover:text-accent"
      >
        إغلاق الاتفاقية
      </button>

      {isPayOpen && (
        <PaySubcontractDialog
          orderId={orderId}
          contractorName={contractorName}
          totalAgreed={totalAgreed}
          remainingBalance={remainingBalance}
          onClose={() => {
            setIsPayOpen(false)
            router.refresh()
          }}
        />
      )}

      {isCloseOpen && (
        <CloseOrderDialog
          orderId={orderId}
          contractorName={contractorName}
          remainingBalance={remainingBalance}
          onClose={() => {
            setIsCloseOpen(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}