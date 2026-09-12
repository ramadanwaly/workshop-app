import type { Metadata } from 'next'
import { LoginForm } from '@/components/auth/login-form'

export const metadata: Metadata = {
  title: 'تسجيل الدخول | نظام إدارة الورشة',
}

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>
}) {
  const { next } = await searchParams
  const redirectTo =
    next && next.startsWith('/') && !next.startsWith('//') ? next : '/dashboard'

  return (
    <main className="flex min-h-screen items-center justify-center bg-background bg-[radial-gradient(ellipse_at_top_right,rgba(184,135,58,0.12),transparent_60%),radial-gradient(ellipse_at_bottom_left,rgba(62,36,23,0.10),transparent_60%)] p-6">
      <div className="w-full max-w-md">
        <LoginForm redirectTo={redirectTo} />
      </div>
    </main>
  )
}