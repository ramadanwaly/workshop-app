export default function Loading() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 p-6 bg-background text-ink">
      <div className="h-10 w-10 animate-spin rounded-full border-4 border-accent/30 border-t-accent" />
      <p className="text-secondary text-sm">جارٍ التحميل...</p>
    </div>
  )
}