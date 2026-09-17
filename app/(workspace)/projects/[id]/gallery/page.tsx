import Link from 'next/link'

import { getProjectDetail } from '@/actions/projects'
import { ManagePhotos } from '@/components/portfolio/manage-photos'
import { requireStaff } from '@/lib/actions/guard'

type ProjectGalleryPageProps = {
  params: Promise<{ id: string }>
}

export default async function ProjectGalleryPage({ params }: ProjectGalleryPageProps) {
  const { id } = await params

  // التأكد من الصلاحيات (للموظفين فقط)
  await requireStaff()

  const project = await getProjectDetail(id)

  if (!project) {
    return (
      <main className="min-h-screen">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <h1 className="mb-4 text-2xl font-bold text-foreground">المشروع غير موجود</h1>
          <p className="text-muted-foreground">لم يتم العثور على مشروع بهذا المعرّف.</p>
        </div>
      </main>
    )
  }

  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6 sm:py-8">
        <div className="mb-4">
          <Link
            href={`/projects/${id}`}
            className="inline-flex items-center gap-1 text-sm font-semibold text-muted-foreground transition hover:text-foreground"
          >
            <span aria-hidden>←</span> العودة لملخص المشروع
          </Link>
        </div>

        <header className="mb-6">
          <h1 className="text-xl font-bold text-foreground sm:text-2xl">
            معرض الأعمال: {project.name}
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            إدارة صور المشروع للعرض في المعرض العام.
          </p>
        </header>

        <section className="rounded-md border border-border bg-card p-6 shadow-sm">
          <ManagePhotos
            projectId={id}
            projectName={project.name}
            projectStatus={project.status}
          />
        </section>
      </div>
    </main>
  )
}
