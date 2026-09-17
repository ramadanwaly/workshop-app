'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const ProjectFormDialog = dynamic(() => import('./project-form-dialog').then(mod => mod.ProjectFormDialog))
const ProjectStatusDialog = dynamic(() => import('./project-status-dialog').then(mod => mod.ProjectStatusDialog))

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
      <Button
        variant="outline"
        onClick={() => setIsEditOpen(true)}
      >
        تعديل
      </Button>

      {isOwner && (
        <Button
          variant="secondary"
          onClick={() => setIsStatusOpen(true)}
        >
          تغيير الحالة
        </Button>
      )}

      {currentStatus === 'completed' && (
        <Button
          variant="default"
          onClick={() => router.push(`/projects/${projectId}/gallery`)}
        >
          إدارة المعرض
        </Button>
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
