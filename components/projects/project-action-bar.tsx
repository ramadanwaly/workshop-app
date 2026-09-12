'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ProjectFormDialog } from './project-form-dialog'
import { ProjectStatusDialog } from './project-status-dialog'

type ProjectActionBarProps = {
  projectId: string
  projectName: string
  projectDescription: string | null
  currentStatus: string
  isOwner: boolean
}

export function ProjectActionBar({
  projectId,
  projectName,
  projectDescription,
  currentStatus,
  isOwner,
}: ProjectActionBarProps) {
  const [isEditOpen, setIsEditOpen] = useState(false)
  const [isStatusOpen, setIsStatusOpen] = useState(false)
  const router = useRouter()

  return (
    <div className="flex flex-wrap items-center gap-3">
      <button
        type="button"
        onClick={() => setIsEditOpen(true)}
        className="inline-flex items-center gap-2 rounded-xl border border-primary/30 bg-white px-4 py-2.5 text-sm font-bold text-primary transition hover:border-accent/60 hover:text-accent"
      >
        تعديل
      </button>

      {isOwner && (
        <button
          type="button"
          onClick={() => setIsStatusOpen(true)}
          className="inline-flex items-center gap-2 rounded-xl border border-accent/50 bg-accent/10 px-4 py-2.5 text-sm font-bold text-accent transition hover:bg-accent/20"
        >
          تغيير الحالة
        </button>
      )}

      {isEditOpen && (
        <ProjectFormDialog
          mode="edit"
          project={{
            id: projectId,
            name: projectName,
            description: projectDescription,
          }}
          onClose={() => {
            setIsEditOpen(false)
            router.refresh()
          }}
        />
      )}

      {isStatusOpen && (
        <ProjectStatusDialog
          projectId={projectId}
          projectName={projectName}
          currentStatus={currentStatus}
          onClose={() => {
            setIsStatusOpen(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}
