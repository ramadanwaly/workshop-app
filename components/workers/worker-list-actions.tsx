'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { WorkerFormDialog } from './worker-form-dialog'

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
      <button
        type="button"
        onClick={() => setIsAddOpen(true)}
        className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-background transition hover:bg-primary/90"
      >
        عامل جديد +
      </button>

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
