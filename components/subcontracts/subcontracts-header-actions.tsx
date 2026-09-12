'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { CreateOrderDialog } from './create-order-dialog'

type ProjectOption = {
  id: string
  name: string
  status: string
}

type SubcontractsHeaderActionsProps = {
  projects: ProjectOption[]
}

export function SubcontractsHeaderActions({ projects }: SubcontractsHeaderActionsProps) {
  const [isOpen, setIsOpen] = useState(false)
  const router = useRouter()

  return (
    <>
      <button
        type="button"
        onClick={() => setIsOpen(true)}
        className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-background transition hover:bg-primary/90"
      >
        اتفاقية جديدة +
      </button>

      {isOpen && (
        <CreateOrderDialog
          projects={projects}
          onClose={() => {
            setIsOpen(false)
            router.refresh()
          }}
        />
      )}
    </>
  )
}