'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const PaySubcontractDialog = dynamic(() => import('./pay-subcontract-dialog').then(mod => mod.PaySubcontractDialog))
const CloseOrderDialog = dynamic(() => import('./close-order-dialog').then(mod => mod.CloseOrderDialog))

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
      <Button
        onClick={() => setIsPayOpen(true)}
        disabled={remainingBalance <= 0}
        variant="default"
      >
        تسجيل دفعة
      </Button>

      <Button
        onClick={() => setIsCloseOpen(true)}
        variant="outline"
      >
        إغلاق الاتفاقية
      </Button>

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