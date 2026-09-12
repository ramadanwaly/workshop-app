'use client'

// ----------------------------------------------------------------------------
// P2-08 — الحد الجذري للأخطاء: يمسك أي عطل في التخطيط الجذري نفسه
// (app/error.tsx لا يستطيع إمساكه). نفس القاعدة: لا تفاصيل تقنية للمستخدم.
// ملاحظة Next.js: هذا الملف يجب أن يحتوي <html> و<body> بنفسه.
// ----------------------------------------------------------------------------

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <main
          style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '1rem',
            padding: '1.5rem',
            background: '#FAF5EE',
            color: '#3E2417',
            fontFamily: 'inherit',
          }}
        >
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>حدث خطأ غير متوقع</h1>
          <p style={{ textAlign: 'center', maxWidth: '28rem' }}>
            حدثت مشكلة أثناء معالجة طلبك. يرجى المحاولة مرة أخرى، وإذا استمرت المشكلة فتحدث مع
            مالك الورشة.
          </p>
          <button
            type="button"
            onClick={() => reset()}
            style={{
              marginTop: '0.5rem',
              borderRadius: '0.375rem',
              background: '#3E2417',
              color: '#FAF5EE',
              padding: '0.5rem 1.25rem',
              fontWeight: 600,
            }}
          >
            إعادة المحاولة
          </button>
        </main>
      </body>
    </html>
  )
}
