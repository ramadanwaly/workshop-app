import Image from 'next/image'
import { signOut } from '@/actions/auth'

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

export function WorkspaceHeader() {
  async function handleSignOut() {
    'use server'
    await signOut()
  }

  return (
    <header className="sticky top-0 z-30 border-b border-secondary/30 bg-background/90 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center gap-3 px-4 py-3 sm:px-6">
        <Image
          src="/logo.jpg"
          alt="شعار ورشة رمضان والي للنجارة"
          width={40}
          height={40}
          className="rounded-md ring-2 ring-accent/30"
        />
        <div>
          <p className="text-sm font-bold leading-tight text-primary">ورشة رمضان والي</p>
          <p className="text-xs text-secondary">نظام إدارة الورشة</p>
        </div>

        <form action={handleSignOut} className="ms-auto">
          <button
            type="submit"
            aria-label="تسجيل الخروج"
            className="flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-secondary transition hover:bg-danger/10 hover:text-danger"
          >
            <LogOutIcon />
            تسجيل الخروج
          </button>
        </form>
      </div>
    </header>
  )
}