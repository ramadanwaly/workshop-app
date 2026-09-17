
import { GalleryCard } from './gallery-card'

export type PublicGalleryPhoto = {
  entry_id: string
  display_title: string
  public_description: string | null
  storage_path: string
  alt_text: string | null
  sort_order: number
  completed_at: string | null
}

export type GalleryGroup = {
  entryId: string
  displayTitle: string
  publicDescription: string | null
  completedAt: string | null
  photos: PublicGalleryPhoto[]
}

type GalleryGridProps = {
  photos: PublicGalleryPhoto[]
}

export function GalleryGrid({ photos }: GalleryGridProps) {
  if (photos.length === 0) {
    return (
      <div className="flex justify-center items-center h-64 text-[#3E2417] opacity-60">
        <p className="text-xl">لا توجد أعمال لعرضها حالياً.</p>
      </div>
    )
  }

  // Group photos by entry_id
  const groups = photos.reduce<Record<string, GalleryGroup>>((acc, photo) => {
    if (!acc[photo.entry_id]) {
      acc[photo.entry_id] = {
        entryId: photo.entry_id,
        displayTitle: photo.display_title,
        publicDescription: photo.public_description,
        completedAt: photo.completed_at,
        photos: [],
      }
    }
    acc[photo.entry_id].photos.push(photo)
    return acc
  }, {})

  const sortedGroups = Object.values(groups).sort((a, b) => {
    const timeA = a.completedAt ? new Date(a.completedAt).getTime() : 0
    const timeB = b.completedAt ? new Date(b.completedAt).getTime() : 0
    return timeB - timeA
  })

  return (
    <div className="space-y-16">
      {sortedGroups.map((group) => (
        <section key={group.entryId} className="space-y-6">
          <div className="border-b border-[#B8873A] pb-2 mb-4">
            <h2 className="text-3xl font-bold text-[#3E2417]">{group.displayTitle}</h2>
            {group.publicDescription && (
              <p className="text-[#3E2417] opacity-80 mt-2">{group.publicDescription}</p>
            )}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {group.photos.map((photo, idx) => (
              <GalleryCard key={`${photo.entry_id}-${idx}`} photo={photo} />
            ))}
          </div>
        </section>
      ))}
    </div>
  )
}
