import { createClient } from '@/lib/supabase/server'
import { GalleryGrid, type PublicGalleryPhoto } from '@/components/portfolio/gallery-grid'

export const metadata = {
  title: 'معرض الأعمال | الورشة',
  description: 'معرض الأعمال والمشاريع المكتملة',
}

export default async function PublicGalleryPage() {
  const supabase = await createClient()

  // هذا الاستعلام يقرأ من View عام مفتوح للـ anon role
  // لا يقرأ أي بيانات مالية ولا يحتاج لجلسة (Session)
  const { data, error } = await supabase
    .from('v_portfolio_gallery_public')
    .select('*')
    .order('completed_at', { ascending: false })
    .order('sort_order', { ascending: true })

  if (error) {
    console.error('[gallery] فشل تحميل المعرض:', error.message)
    return (
      <div className="max-w-6xl mx-auto p-8">
        <div className="bg-red-50 text-red-700 p-4 rounded border border-red-200">
          حدث خطأ أثناء تحميل المعرض. يرجى المحاولة مرة أخرى لاحقاً.
        </div>
      </div>
    )
  }

  const photos = (data || []) as PublicGalleryPhoto[]

  return (
    <div className="max-w-6xl mx-auto p-4 sm:p-6 lg:p-8">
      <div className="mb-8">
        <p className="text-[#3E2417] opacity-80 text-lg">
          مجموعة من مشاريعنا المكتملة التي نفخر بتقديمها.
        </p>
      </div>
      <GalleryGrid photos={photos} />
    </div>
  )
}
