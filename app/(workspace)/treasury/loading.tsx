import { Skeleton } from '@/components/ui/skeleton'

export default function TreasuryLoading() {
  return (
    <div className="mx-auto max-w-6xl space-y-5 px-4 py-6 sm:px-6 sm:py-8" aria-label="جارٍ تحميل الخزينة">
      <div className="space-y-2">
        <Skeleton className="h-8 w-32" />
        <Skeleton className="h-4 w-60" />
      </div>

      <div className="mb-8 border border-secondary/20 bg-background p-6 sm:p-8">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div className="space-y-4">
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-10 w-48 sm:h-12" />
            <Skeleton className="h-4 w-full max-w-md" />
          </div>
          <div className="flex gap-8 border-t border-secondary/20 pt-6 lg:border-t-0 lg:pt-0">
            <div className="space-y-3"><Skeleton className="h-3 w-20" /><Skeleton className="h-7 w-28" /></div>
            <div className="space-y-3"><Skeleton className="h-3 w-20" /><Skeleton className="h-7 w-28" /></div>
          </div>
        </div>
      </div>

      <div className="mb-6">
        <div className="mb-3 flex items-center justify-between">
          <Skeleton className="h-4 w-32" />
        </div>
        <div className="border border-secondary/20 bg-background p-4">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-[2fr_1fr_1fr_1fr_auto]">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="space-y-2">
                <Skeleton className="h-3 w-24" />
                <Skeleton className="h-9 w-full" />
              </div>
            ))}
            <div className="flex items-end pt-2">
              <Skeleton className="h-9 w-20" />
            </div>
          </div>
        </div>
      </div>

      <div className="border border-secondary/20 bg-background">
        <div className="flex items-center justify-between p-4"><Skeleton className="h-5 w-32" /><Skeleton className="h-9 w-24" /></div>
        {Array.from({ length: 5 }).map((_, index) => (
          <div key={index} className="grid grid-cols-4 gap-4 border-t border-secondary/10 p-4"><Skeleton className="h-4 w-full" /><Skeleton className="h-4 w-full" /><Skeleton className="h-4 w-full" /><Skeleton className="h-4 w-full" /></div>
        ))}
      </div>
    </div>
  )
}
