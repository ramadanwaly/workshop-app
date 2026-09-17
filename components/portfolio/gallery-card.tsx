'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { PublicGalleryPhoto } from './gallery-grid'

export function GalleryCard({ photo }: { photo: PublicGalleryPhoto }) {
  const [isOpen, setIsOpen] = useState(false)
  const supabase = createClient()
  
  const {
    data: { publicUrl },
  } = supabase.storage.from('portfolio').getPublicUrl(photo.storage_path)

  const alt = photo.alt_text || photo.display_title || 'صورة من المشروع'

  return (
    <>
      <div 
        className="group relative rounded-xl overflow-hidden shadow-sm hover:shadow-xl transition-shadow duration-300 border border-[#B8873A]/20 bg-white cursor-pointer"
        onClick={() => setIsOpen(true)}
      >
        <div className="aspect-[4/3] w-full overflow-hidden bg-gray-100">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={publicUrl}
            alt={alt}
            loading="lazy"
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
        </div>
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/10">
          <span className="bg-[#3E2417]/80 text-[#FAF5EE] px-4 py-2 rounded-full text-sm font-semibold shadow-lg backdrop-blur-sm transform translate-y-2 group-hover:translate-y-0 transition-all duration-300">
            تكبير الصورة
          </span>
        </div>
      </div>

      {isOpen && (
        <div 
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm"
          onClick={() => setIsOpen(false)}
        >
          <button 
            className="absolute top-6 right-6 text-white bg-white/10 hover:bg-white/20 p-3 rounded-full transition z-50"
            onClick={() => setIsOpen(false)}
            aria-label="إغلاق"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={publicUrl}
            alt={alt}
            className="max-h-[95vh] max-w-[95vw] object-contain rounded-md shadow-2xl transition-transform duration-300 scale-100"
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </>
  )
}
