import Link from 'next/link'

export default function NotFound() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-4 p-6 bg-background text-ink">
      <p className="text-7xl font-bold text-secondary">٤٠٤</p>
      <h1 className="text-2xl font-bold">الصفحة غير موجودة</h1>
      <p className="text-secondary">الصفحة التي تبحث عنها غير متوفرة أو ربما تم نقلها.</p>
      <Link
        href="/dashboard"
        className="mt-2 rounded-md bg-primary px-5 py-2 font-semibold text-background hover:bg-primary/90 transition"
      >
        العودة للوحة التحكم
      </Link>
    </main>
  )
}