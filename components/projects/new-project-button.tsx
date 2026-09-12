'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ProjectFormDialog } from './project-form-dialog'

export function NewProjectButton() {
  const [isOpen, setIsOpen] = useState(false)
  const router = useRouter()

  return (
    <>
      <button
        type="button"
        onClick={() => setIsOpen(true)}
        className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-background transition hover:bg-primary/90"
      >
        <span aria-hidden="true">+</span>
        مشروع جديد
      </button>

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
