'use client'

import { useState, useEffect } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { signOut } from '@/actions/auth'
import { createClient } from '@/lib/supabase/client'

type NavItem = {
  href: string
  label: string
  icon: React.ReactNode
}

type AppNavProps = {
  userRole?: string
}

function HomeIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  )
}

function FolderIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" />
    </svg>
  )
}

function UsersIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  )
}

function ContractIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="8" y1="13" x2="16" y2="13" />
      <line x1="8" y1="17" x2="13" y2="17" />
    </svg>
  )
}

function CashIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <rect x="2" y="6" width="20" height="12" rx="2" />
      <circle cx="12" cy="12" r="2" />
      <path d="M6 12h.01M18 12h.01" />
    </svg>
  )
}

function StoreIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
      <line x1="12" y1="22.08" x2="12" y2="12" />
    </svg>
  )
}

function SettingsIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.1a2 2 0 0 1-1-1.72v-.51a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

function ChartIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  )
}

function LogOutIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}

function GalleryIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <polyline points="21 15 16 10 5 21" />
    </svg>
  )
}

function MenuIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5 shrink-0"
      aria-hidden="true"
    >
      <line x1="4" y1="12" x2="20" y2="12" />
      <line x1="4" y1="6" x2="20" y2="6" />
      <line x1="4" y1="18" x2="20" y2="18" />
    </svg>
  )
}

const BASE_NAV_ITEMS: NavItem[] = [
  { href: '/dashboard', label: 'لوحة المعلومات', icon: <HomeIcon /> },
  { href: '/projects', label: 'المشاريع', icon: <FolderIcon /> },
  { href: '/workers', label: 'العمال', icon: <UsersIcon /> },
  { href: '/subcontracts', label: 'المقاولون', icon: <ContractIcon /> },
  { href: '/treasury', label: 'الخزينة', icon: <CashIcon /> },
  { href: '/surplus', label: 'بنك الفائض', icon: <StoreIcon /> },
  { href: '/analytics', label: 'التحليلات', icon: <ChartIcon /> },
  { href: '/gallery', label: 'المعرض العام', icon: <GalleryIcon /> },
]


function isActive(pathname: string, href: string): boolean {
  if (href === '/dashboard') return pathname === href
  return pathname === href || pathname.startsWith(`${href}/`)
}

type NavItemLinkProps = {
  item: NavItem
  variant: 'sidebar' | 'bottom'
  active: boolean
}

function NavItemLink({ item, variant, active }: NavItemLinkProps) {
  const verticalClass =
    variant === 'sidebar'
      ? 'flex items-center gap-3 rounded-md px-4 py-3 text-sm font-medium transition'
      : 'flex min-h-14 flex-col items-center justify-center gap-1 rounded-md text-[10px] sm:text-[11px] font-medium transition'

  const stateClass = active
    ? variant === 'sidebar'
      ? 'bg-accent/20 text-background'
      : 'bg-accent/15 text-accent'
    : 'text-background/75 hover:bg-background/10 hover:text-background'

  return (
    <Link
      href={item.href}
      className={`${verticalClass} ${stateClass}`}
      aria-current={active ? 'page' : undefined}
    >
      {item.icon}
      <span className="truncate">{item.label}</span>
    </Link>
  )
}

export function AppNav({ userRole }: AppNavProps) {
  const pathname = usePathname()
  const [fetchedRole, setFetchedRole] = useState<string | undefined>(undefined)
  const role = userRole ?? fetchedRole
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  useEffect(() => {
    if (userRole !== undefined) return

    async function checkRole() {
      try {
        const supabase = createClient()
        const {
          data: { user },
        } = await supabase.auth.getUser()
        if (user) {
          const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single()

          if (profile?.role) {
            setFetchedRole(profile.role)
          }
        }
      } catch (err) {
        console.error('Failed to fetch role in AppNav:', err)
      }
    }

    checkRole()
  }, [userRole])

  const navItems = [...BASE_NAV_ITEMS]
  if (role === 'owner') {
    navItems.push({ href: '/settings', label: 'الإعدادات', icon: <SettingsIcon /> })
  }

  // Mobile Bottom Nav specific items
  const mobilePrimaryPaths = ['/dashboard', '/projects', '/treasury']
  const mobilePrimaryItems = navItems.filter((item) => mobilePrimaryPaths.includes(item.href))
  // The rest go to the drawer
  const mobileSecondaryItems = navItems.filter((item) => !mobilePrimaryPaths.includes(item.href))

  return (
    <>
      <aside className="fixed inset-y-0 start-0 z-40 hidden w-64 flex-col overflow-y-auto bg-primary lg:flex">
        <div className="flex items-center gap-3 px-5 py-5">
          <Image
            src="/logo.jpg"
            alt="شعار ورشة رمضان والي للنجارة"
            width={44}
            height={44}
            className="rounded-md ring-2 ring-accent/40"
          />
          <div>
            <p className="text-sm font-bold leading-tight text-background">ورشة رمضان والي</p>
            <p className="text-xs text-background/60">نظام إدارة الورشة</p>
          </div>
        </div>

        <nav aria-label="التنقل الرئيسي" className="flex-1 space-y-1 px-3 py-2">
          {navItems.map((item) => (
            <NavItemLink
              key={item.href}
              item={item}
              variant="sidebar"
              active={isActive(pathname, item.href)}
            />
          ))}
        </nav>

        <div className="border-t border-background/10 px-3 py-4">
          <form
            action={async () => {
              await signOut()
            }}
          >
            <button
              type="submit"
              className="flex w-full items-center gap-3 rounded-md px-4 py-3 text-sm font-medium text-background/75 transition hover:bg-danger/30 hover:text-background"
            >
              <LogOutIcon />
              تسجيل الخروج
            </button>
          </form>
        </div>
      </aside>

      {/* Mobile Drawer Overlay */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden transition-opacity"
          onClick={() => setIsMobileMenuOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Mobile Drawer Menu */}
      <div 
        className={`fixed inset-y-0 start-0 z-50 w-64 transform flex-col bg-primary transition-transform duration-300 ease-in-out lg:hidden ${
          isMobileMenuOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
        style={{ direction: 'rtl' }}
      >
        <div className="flex items-center justify-between border-b border-background/10 px-4 py-4">
          <div className="flex items-center gap-3">
            <Image
              src="/logo.jpg"
              alt="شعار ورشة رمضان والي للنجارة"
              width={36}
              height={36}
              className="rounded-md ring-1 ring-accent/40"
            />
            <p className="text-sm font-bold text-background">ورشة رمضان والي</p>
          </div>
          <button 
            onClick={() => setIsMobileMenuOpen(false)}
            className="flex h-8 w-8 items-center justify-center rounded-md text-background/70 hover:bg-background/10 hover:text-background"
            aria-label="إغلاق القائمة"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        <nav aria-label="تنقل إضافي" className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          {mobileSecondaryItems.map((item) => (
            <div key={item.href} onClick={() => setIsMobileMenuOpen(false)}>
              <NavItemLink
                item={item}
                variant="sidebar"
                active={isActive(pathname, item.href)}
              />
            </div>
          ))}
        </nav>
        
        <div className="border-t border-background/10 p-4">
          <form
            action={async () => {
              await signOut()
            }}
          >
            <button
              type="submit"
              className="flex w-full items-center gap-3 rounded-md px-4 py-3 text-sm font-medium text-background/75 transition hover:bg-danger/30 hover:text-background"
            >
              <LogOutIcon />
              تسجيل الخروج
            </button>
          </form>
        </div>
      </div>

      {/* Mobile Bottom Nav */}
      <nav
        aria-label="التنقل الرئيسي"
        className="fixed inset-x-0 bottom-0 z-30 border-t border-accent/20 bg-primary lg:hidden"
      >
        <div className="grid grid-cols-4 gap-0.5 px-0.5 pb-[max(0.25rem,env(safe-area-inset-bottom))] pt-1">
          {mobilePrimaryItems.map((item) => (
            <NavItemLink
              key={item.href}
              item={item}
              variant="bottom"
              active={isActive(pathname, item.href)}
            />
          ))}
          <button
            type="button"
            onClick={() => setIsMobileMenuOpen(true)}
            aria-label="القائمة"
            aria-expanded={isMobileMenuOpen}
            className="flex min-h-14 flex-col items-center justify-center gap-1 rounded-md text-[10px] sm:text-[11px] font-medium text-background/75 transition hover:bg-background/10 hover:text-background"
          >
            <MenuIcon />
            <span className="truncate">المزيد</span>
          </button>
        </div>
      </nav>
    </>
  )
}