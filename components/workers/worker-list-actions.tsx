'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const WorkerFormDialog = dynamic(() => import('./worker-form-dialog').then(mod => mod.WorkerFormDialog))

type WorkerListActionsProps = {
  input: { isOwner: boolean }
}

export function WorkerListActions({ input }: WorkerListActionsProps) {
  const { isOwner } = input
  const [isAddOpen, setIsAddOpen] = useState(false)
  const router = useRouter()

  if (!isOwner) return null

  return (
    <>
      <Button
        type="button"
        onClick={() => setIsAddOpen(true)}
      >
        عامل جديد +
      </Button>

      {isAddOpen && (
        <WorkerFormDialog
          mode="add"
          onClose={() => {
            setIsAddOpen(false)
            router.refresh()
          }}
        />
      )}
    </>
  )
}
