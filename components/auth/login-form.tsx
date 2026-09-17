'use client'

import { useState, useTransition } from 'react'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { requestPasswordReset, signInWithOtp, signInWithPassword } from '@/actions/auth'
import Link from 'next/link'

export function LoginForm({ redirectTo = '/dashboard' }: { redirectTo?: string }) {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  function handlePasswordSubmit(event: React.FormEvent) {
    event.preventDefault()
    setError(null)
    setInfo(null)

    startTransition(async () => {
      const result = await signInWithPassword({ email, password })
      if (result.success) {
        router.push(redirectTo)
        router.refresh()
      } else {
        setError(result.error ?? 'خطأ غير متوقع')
      }
    })
  }

  function handleMagicLink() {
    setError(null)
    setInfo(null)

    startTransition(async () => {
      const result = await signInWithOtp({ email })
      if (result.success) {
        setInfo(result.message ?? 'تم إرسال الرابط السحري')
      } else {
        setError(result.error ?? 'خطأ غير متوقع')
      }
    })
  }

  function handleForgotPassword() {
    setError(null)
    setInfo(null)

    if (!email) {
      setError('أدخل بريدك الإلكتروني أولاً لإرسال رابط إعادة التعيين')
      return
    }

    startTransition(async () => {
      const result = await requestPasswordReset({ email })
      if (result.success) {
        setInfo(result.message ?? 'تم إرسال رابط إعادة التعيين')
      } else {
        setError(result.error ?? 'خطأ غير متوقع')
      }
    })
  }

  return (
    <div className="rounded-3xl border border-secondary/30 bg-card p-8 shadow-xl shadow-primary/5">
      <div className="mb-6 flex flex-col items-center text-center">
        <Image
          src="/logo.jpg"
          alt="شعار ورشة رمضان والي للنجارة"
          width={128}
          height={128}
          priority
          className="rounded-2xl ring-4 ring-accent/20"
        />
        <h1 className="mt-5 text-2xl font-bold text-primary">ورشة رمضان والي للنجارة</h1>
        <p className="mt-1 text-secondary text-sm">نظام إدارة الورشة — سجّل الدخول للمتابعة</p>
      </div>

      {error && (
        <div className="mb-4 border border-danger/40 bg-danger/10 text-danger p-3 rounded-xl text-sm text-right">
          {error}
        </div>
      )}
      {info && (
        <div className="mb-4 border border-success/40 bg-success/10 text-success p-3 rounded-xl text-sm text-right">
          {info}
        </div>
      )}

      <form onSubmit={handlePasswordSubmit} className="space-y-4">
        <div>
          <label htmlFor="email" className="mb-1 block text-sm font-semibold text-ink">
            البريد الإلكتروني
          </label>
          <input
            id="email"
            type="email"
            required
            dir="ltr"
            autoComplete="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="w-full rounded-xl border border-secondary/40 bg-background/60 px-4 py-2.5 text-right text-ink placeholder:text-secondary/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/40"
            placeholder="you@example.com"
          />
        </div>

        <div>
          <div className="mb-1 flex items-center justify-between">
            <label htmlFor="password" className="block text-sm font-semibold text-ink">
              كلمة المرور
            </label>
            <button
              type="button"
              onClick={handleForgotPassword}
              disabled={isPending}
              className="text-xs font-semibold text-accent transition hover:text-primary disabled:opacity-60"
            >
              نسيت كلمة المرور؟
            </button>
          </div>
          <div className="relative">
            <input
              id="password"
              type={showPassword ? 'text' : 'password'}
              required
              dir="ltr"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full rounded-xl border border-secondary/40 bg-background/60 px-4 py-2.5 pl-11 text-right text-ink placeholder:text-secondary/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/40"
              placeholder="••••••••"
            />
            <button
              type="button"
              onClick={() => setShowPassword((value) => !value)}
              aria-label={showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور'}
              aria-pressed={showPassword}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary transition hover:text-primary"
            >
              {showPassword ? <EyeOffIcon /> : <EyeIcon />}
            </button>
          </div>
        </div>

        <button
          type="submit"
          disabled={isPending}
          className="w-full rounded-xl bg-primary px-4 py-2.5 font-bold text-background transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isPending ? 'جارٍ الدخول…' : 'تسجيل الدخول'}
        </button>
      </form>

      <div className="mt-5 flex items-center gap-3">
        <div className="h-px flex-1 bg-secondary/30" />
        <span className="text-xs text-secondary">أو</span>
        <div className="h-px flex-1 bg-secondary/30" />
      </div>

      <button
        type="button"
        onClick={handleMagicLink}
        disabled={isPending || !email}
        className="mt-4 w-full rounded-xl border border-secondary/40 bg-background/40 px-4 py-2.5 font-bold text-primary transition hover:border-accent hover:text-accent disabled:cursor-not-allowed disabled:opacity-60"
      >
        إرسال رابط دخول سحري للبريد
      </button>

      <p className="mt-4 text-center text-xs text-secondary">
        الرابط السحري يغنيك عن كلمة المرور في كل مرة
      </p>

      <div className="mt-8 text-center border-t border-secondary/20 pt-6">
        <p className="mb-3 text-sm text-ink">هل أنت زائر؟</p>
        <Link 
          href="/gallery" 
          className="inline-block rounded-xl bg-accent px-6 py-2.5 font-bold text-background transition hover:bg-accent/90"
        >
          تصفح معرض أعمالنا
        </Link>
      </div>
    </div>
  )
}

function EyeIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="h-5 w-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
      />
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
      />
    </svg>
  )
}

function EyeOffIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="h-5 w-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88"
      />
    </svg>
  )
}