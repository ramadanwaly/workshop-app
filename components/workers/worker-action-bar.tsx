'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { WorkerFormDialog } from './worker-form-dialog'
import { AdvanceDialog } from './advance-dialog'
import { SettleDialog } from './settle-dialog'

type WorkerActionBarProps = {
  workerId: string
  workerName: string
  phone: string | null
  dailyRate: number
  isActive: boolean
  isOwner: boolean
  pendingWages: number
  pendingAdvances: number
  netPayable: number
  carriedForwardCredit: number
}

export function WorkerActionBar({
  workerId,
  workerName,
  phone,
  dailyRate,
  isActive,
  isOwner,
  pendingWages,
  pendingAdvances,
  netPayable,
  carriedForwardCredit,
}: WorkerActionBarProps) {
  const [isEditOpen, setIsEditOpen] = useState(false)
  const [isAdvanceOpen, setIsAdvanceOpen] = useState(false)
  const [isSettleOpen, setIsSettleOpen] = useState(false)
  const router = useRouter()

  return (
    <div className="mb-6 flex flex-wrap items-center gap-3">
      {isOwner && (
        <button
          type="button"
          onClick={() => setIsEditOpen(true)}
          className="inline-flex items-center gap-2 rounded-xl border border-primary/30 bg-white px-4 py-2.5 text-sm font-bold text-primary transition hover:border-accent/60 hover:text-accent"
        >
          تعديل البيانات
        </button>
      )}

      {isOwner && (
        <button
          type="button"
          onClick={() => setIsAdvanceOpen(true)}
          className="inline-flex items-center gap-2 rounded-xl border border-accent/50 bg-accent/10 px-4 py-2.5 text-sm font-bold text-accent transition hover:bg-accent/20"
        >
          سلفة
        </button>
      )}

      {isOwner && (
        <button
          type="button"
          onClick={() => setIsSettleOpen(true)}
          className="inline-flex items-center gap-2 rounded-xl border border-success/50 bg-success/10 px-4 py-2.5 text-sm font-bold text-success transition hover:bg-success/20"
        >
          تسوية الحساب
        </button>
      )}

      {isEditOpen && (
        <WorkerFormDialog
          mode="edit"
          worker={{ id: workerId, name: workerName, phone, daily_rate: dailyRate, is_active: isActive }}
          onClose={() => {
            setIsEditOpen(false)
            router.refresh()
          }}
        />
      )}

      {isAdvanceOpen && (
        <AdvanceDialog
          workerId={workerId}
          workerName={workerName}
          onClose={() => {
            setIsAdvanceOpen(false)
            router.refresh()
          }}
        />
      )}

      {isSettleOpen && (
        <SettleDialog
          workerId={workerId}
          workerName={workerName}
          pendingWages={pendingWages}
          pendingAdvances={pendingAdvances}
          netPayable={netPayable}
          carriedForwardCredit={carriedForwardCredit}
          onClose={() => {
            setIsSettleOpen(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}
