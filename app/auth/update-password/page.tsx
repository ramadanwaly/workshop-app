'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { updatePassword } from '@/actions/auth'

export default function UpdatePasswordPage() {
  const router = useRouter()
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  function handleSubmit(event: React.FormEvent) {
    event.preventDefault()
    setError(null)

    if (password !== confirmPassword) {
      setError('كلمتا المرور غير متطابقتين')
      return
    }

    startTransition(async () => {
      const result = await updatePassword({ password })
      if (result.success) {
        router.push('/login')
        router.refresh()
      } else {
        setError(result.error ?? 'خطأ غير متوقع')
      }
    })
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-background bg-[radial-gradient(ellipse_at_top_right,rgba(184,135,58,0.12),transparent_60%),radial-gradient(ellipse_at_bottom_left,rgba(62,36,23,0.10),transparent_60%)] p-6">
      <div className="w-full max-w-md rounded-3xl border border-secondary/30 bg-card p-8 shadow-xl shadow-primary/5">
        <h1 className="text-2xl font-bold text-primary">تغيير كلمة المرور</h1>
        <p className="mt-1 text-sm text-secondary">أدخل كلمة مرور جديدة بعد فتح رابط إعادة التعيين</p>

        {error && (
          <div className="mt-4 border border-danger/40 bg-danger/10 p-3 rounded-xl text-sm text-right text-danger">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label htmlFor="new-password" className="mb-1 block text-sm font-semibold text-ink">
              كلمة المرور الجديدة
            </label>
            <input
              id="new-password"
              type="password"
              required
              minLength={6}
              autoComplete="new-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full rounded-xl border border-secondary/40 bg-background/60 px-4 py-2.5 text-right text-ink placeholder:text-secondary/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/40"
              placeholder="6 أحرف على الأقل"
            />
          </div>

          <div>
            <label
              htmlFor="confirm-password"
              className="mb-1 block text-sm font-semibold text-ink"
            >
              تأكيد كلمة المرور
            </label>
            <input
              id="confirm-password"
              type="password"
              required
              minLength={6}
              autoComplete="new-password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              className="w-full rounded-xl border border-secondary/40 bg-background/60 px-4 py-2.5 text-right text-ink placeholder:text-secondary/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/40"
              placeholder="أعد إدخال كلمة المرور"
            />
          </div>

          <button
            type="submit"
            disabled={isPending}
            className="w-full rounded-xl bg-primary px-4 py-2.5 font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isPending ? 'جارٍ الحفظ…' : 'تحديث كلمة المرور'}
          </button>
        </form>
      </div>
    </main>
  )
}