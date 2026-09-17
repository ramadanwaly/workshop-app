'use client'

import Image from 'next/image'
import { usePathname } from 'next/navigation'
import { signOut } from '@/actions/auth'
import { ThemeToggle } from '@/components/theme-toggle'

const routeTitles: Record<string, string> = {
  '/dashboard': 'لوحة المعلومات',
  '/projects': 'المشاريع',
  '/workers': 'العمال',
  '/subcontracts': 'المقاولون',
  '/treasury': 'الخزينة',
  '/surplus': 'بنك الفائض',
  '/analytics': 'التحليلات والتقارير',
  '/settings': 'الإعدادات',
}

function getPageTitle(pathname: string) {
  if (pathname.startsWith('/projects/') && pathname !== '/projects') return 'تفاصيل المشروع'
  if (pathname.startsWith('/workers/') && pathname !== '/workers') return 'تفاصيل العامل'
  if (pathname.startsWith('/subcontracts/') && pathname !== '/subcontracts') return 'تفاصيل المقاولة'
  return routeTitles[pathname] || 'نظام إدارة الورشة'
}

function LogOutIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5 shrink-0" aria-hidden="true">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}

export function WorkspaceHeader() {
  const pathname = usePathname()
  const title = getPageTitle(pathname)

  return (
    <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-border bg-background px-4 sm:px-6">
      {/* Desktop Context (Title only, no logo) */}
      <div className="hidden lg:block">
        <h1 className="text-lg font-bold text-ink">{title}</h1>
      </div>

      {/* Mobile Context (Logo + Title) */}
      <div className="flex items-center gap-3 lg:hidden">
        <Image
          src="/logo.jpg"
          alt="شعار ورشة رمضان والي للنجارة"
          width={32}
          height={32}
          className="rounded-md ring-1 ring-border"
        />
        <h1 className="text-base font-bold text-ink">{title}</h1>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-2">
        <ThemeToggle />
        <form action={async () => { await signOut() }} className="lg:hidden">
          <button
            type="submit"
            aria-label="تسجيل الخروج"
            className="flex h-9 w-9 items-center justify-center rounded-md text-muted-foreground transition hover:bg-muted hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <LogOutIcon />
          </button>
        </form>
      </div>
    </header>
  )
}