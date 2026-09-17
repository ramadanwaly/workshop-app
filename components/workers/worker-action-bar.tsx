'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const WorkerFormDialog = dynamic(() => import('./worker-form-dialog').then(mod => mod.WorkerFormDialog))
const AdvanceDialog = dynamic(() => import('./advance-dialog').then(mod => mod.AdvanceDialog))
const SettleDialog = dynamic(() => import('./settle-dialog').then(mod => mod.SettleDialog))

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
        <Button
          type="button"
          onClick={() => setIsEditOpen(true)}
          variant="outline"
          className="font-bold text-primary hover:text-primary/80"
        >
          تعديل البيانات
        </Button>
      )}

      {isOwner && (
        <Button
          type="button"
          onClick={() => setIsAdvanceOpen(true)}
          variant="outline"
          className="border-accent text-accent hover:bg-accent/10 hover:text-accent"
        >
          سلفة
        </Button>
      )}

      {isOwner && (
        <Button
          type="button"
          onClick={() => setIsSettleOpen(true)}
          variant="outline"
          className="border-success text-success hover:bg-success/10 hover:text-success"
        >
          تسوية الحساب
        </Button>
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
