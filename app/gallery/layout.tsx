import type { ReactNode } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'

export const metadata = {
  title: 'معرض الأعمال | الورشة',
  description: 'معرض الأعمال والمشاريع المكتملة',
}

export default async function GalleryLayout({ children }: { children: ReactNode }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <div className="min-h-screen bg-[#FAF5EE] text-[#3E2417] flex flex-col">
      <header className="bg-[#3E2417] text-[#FAF5EE] p-4 shadow-md">
        <div className="max-w-6xl mx-auto flex justify-between items-center">
          <h1 className="text-2xl font-bold">الورشة - معرض الأعمال</h1>
          {user ? (
            <Link 
              href="/dashboard"
              className="text-sm font-semibold bg-[#B8873A] hover:bg-[#a17531] text-[#FAF5EE] px-4 py-2 rounded transition"
            >
              العودة للوحة التحكم
            </Link>
          ) : (
            <Link 
              href="/login"
              className="text-sm font-semibold border border-[#B8873A] text-[#B8873A] hover:bg-[#B8873A] hover:text-[#FAF5EE] px-4 py-2 rounded transition"
            >
              دخول العاملين
            </Link>
          )}
        </div>
      </header>
      <main className="flex-1">
        {children}
      </main>
      <footer className="bg-[#3E2417] text-[#FAF5EE] p-4 text-center text-sm">
        <p>جميع الحقوق محفوظة &copy; {new Date().getFullYear()} الورشة</p>
      </footer>
    </div>
  )
}
