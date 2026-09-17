import { Skeleton } from '@/components/ui/skeleton'

export default function DashboardLoading() {
  return (
    <main className="min-h-screen">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:py-10">
        <div className="mb-8">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="mt-2 h-4 w-64" />
        </div>

        <div className="flex flex-col gap-8">
          <section>
            <Skeleton className="mb-4 h-4 w-32" />
            <Skeleton className="h-20 w-full rounded-md" />
          </section>

          <section>
            <Skeleton className="mb-4 h-4 w-32" />
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="flex flex-col rounded-md border border-border p-5 sm:p-6">
                  <Skeleton className="h-4 w-24" />
                  <Skeleton className="mt-3 h-8 w-32" />
                  <Skeleton className="mt-3 h-3 w-40" />
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>
    </main>
  )
}
