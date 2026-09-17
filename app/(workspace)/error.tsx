'use client'

import { useEffect } from 'react'

export default function WorkspaceErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // سجّل التفاصيل داخلياً فقط — لا نعرض أي تفاصيل تقنية للمستخدم
    console.error('Workspace error boundary:', { digest: error.digest, message: error.message })
  }, [error])

  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-4 p-6 bg-background text-ink">
      <p className="text-6xl">⚠️</p>
      <h1 className="text-2xl font-bold">حدث خطأ غير متوقع</h1>
      <p className="text-secondary text-center max-w-md">
        حدثت مشكلة أثناء معالجة طلبك. يرجى المحاولة مرة أخرى، وإذا استمرت المشكلة فتحدث مع مالك
        الورشة.
      </p>
      <button
        type="button"
        onClick={() => reset()}
        className="mt-2 rounded-md bg-primary px-5 py-2 font-semibold text-background hover:bg-primary/90 transition"
      >
        إعادة المحاولة
      </button>
    </main>
  )
}