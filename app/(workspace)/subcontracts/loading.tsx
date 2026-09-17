import { Skeleton } from '@/components/ui/skeleton'

export default function SubcontractsLoading() {
  return (
    <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      <div className="flex items-end justify-between gap-4">
        <div className="space-y-2">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-4 w-64" />
        </div>
        <Skeleton className="h-10 w-32" />
      </div>

      <div className="flex flex-col gap-3 sm:flex-row">
        <Skeleton className="h-10 flex-1" />
        <Skeleton className="h-10 w-full sm:w-24" />
      </div>

      <div className="hidden rounded-md border border-border bg-card md:block">
        <div className="flex items-center justify-between border-b border-border bg-muted/50 p-4">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-24" />
        </div>
        {Array.from({ length: 6 }).map((_, index) => (
          <div key={index} className="grid grid-cols-5 gap-4 border-b border-border p-4 last:border-0">
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-24" />
            <Skeleton className="h-4 w-20" />
            <Skeleton className="h-4 w-24 justify-self-end" />
            <Skeleton className="h-4 w-24 justify-self-end" />
          </div>
        ))}
      </div>

      <div className="space-y-3 md:hidden">
        {Array.from({ length: 5 }).map((_, index) => (
          <div key={index} className="block rounded-md border border-border bg-card p-4">
            <div className="flex items-start justify-between gap-3">
              <Skeleton className="h-5 w-32" />
              <Skeleton className="h-5 w-16" />
            </div>
            <Skeleton className="mt-4 h-3 w-full max-w-[80%]" />
            <div className="mt-4 flex items-end justify-between border-t border-border pt-3">
              <div className="space-y-2">
                <Skeleton className="h-2 w-12" />
                <Skeleton className="h-4 w-24" />
              </div>
              <div className="space-y-2 text-end">
                <Skeleton className="h-2 w-16" />
                <Skeleton className="h-4 w-20" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
