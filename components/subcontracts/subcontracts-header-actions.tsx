'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const CreateOrderDialog = dynamic(() => import('./create-order-dialog').then(mod => mod.CreateOrderDialog))

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
      <Button
        onClick={() => setIsOpen(true)}
      >
        اتفاقية جديدة +
      </Button>

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