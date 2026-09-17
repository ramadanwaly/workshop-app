'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const ProjectFormDialog = dynamic(() => import('./project-form-dialog').then(mod => mod.ProjectFormDialog))

export function NewProjectButton() {
  const [isOpen, setIsOpen] = useState(false)
  const router = useRouter()

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>
        <span aria-hidden="true" className="ml-1.5">+</span>
        مشروع جديد
      </Button>

      {isOpen && (
        <ProjectFormDialog
          mode="create"
          onClose={() => {
            setIsOpen(false)
            router.refresh()
          }}
        />
      )}
    </>
  )
}
