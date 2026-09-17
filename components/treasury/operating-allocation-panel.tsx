'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const RunAllocationDialog = dynamic(() => import('./run-allocation-dialog').then(mod => mod.RunAllocationDialog))
const AllocationExclusionDialog = dynamic(() => import('./allocation-exclusion-dialog').then(mod => mod.AllocationExclusionDialog))
import { StatusBadge } from '@/components/layout/status-badge'

type Cycle = {
  id: string
  year_month: string
  status: string
  total_amount: number
  eligible_project_ids: string[] | null
  notes: string | null
  is_voided: boolean
  void_reason: string | null
  created_at: string
}

type Exclusion = {
  id: string
  year_month: string
  project_id: string
  reason: string | null
  created_at: string
  project: { id: string; name: string } | null
}

type OperatingAllocationPanelProps = {
  cycles: Cycle[]
  exclusions: Exclusion[]
  projects: Array<{ id: string; name: string }>
  userRole: string
}

export function OperatingAllocationPanel({ cycles, exclusions, projects, userRole }: OperatingAllocationPanelProps) {
  const [showRun, setShowRun] = useState(false)
  const [showExclusion, setShowExclusion] = useState(false)
  const isOwner = userRole === 'owner'

  const exclusionsByMonth = exclusions.reduce<Record<string, Exclusion[]>>((acc, e) => {
    ;(acc[e.year_month] ??= []).push(e)
    return acc
  }, {})

  return (
    <section className="mt-12 border-t border-secondary/20 pt-8" aria-labelledby="allocation-title">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 id="allocation-title" className="text-lg font-bold text-ink">سجل توزيع التشغيل الشهري</h2>
          <p className="mt-1 text-xs text-muted-foreground">دورات التوزيع وعمليات الاستبعاد</p>
        </div>
        {isOwner && (
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => setShowRun(true)} variant="secondary" size="sm">
              تشغيل الدورة يدويًا
            </Button>
            <Button onClick={() => setShowExclusion(true)} variant="outline" size="sm">
              استثناء مشروع
            </Button>
          </div>
        )}
      </div>

      <div className="overflow-x-auto rounded-md border border-border bg-card">
        <table className="w-full text-right text-sm">
          <caption className="sr-only">سجل توزيع مصاريف التشغيل الشهري</caption>
          <thead className="border-b border-border bg-muted/50 text-xs font-bold text-secondary">
            <tr>
              <th scope="col" className="px-2 py-3">الشهر</th>
              <th scope="col" className="px-2 py-3">الحالة</th>
              <th scope="col" className="px-2 py-3 text-end">الإجمالي</th>
              <th scope="col" className="hidden px-2 py-3 text-center sm:table-cell">مشاريع مؤهلة</th>
              <th scope="col" className="px-2 py-3">الاستثناءات</th>
              <th scope="col" className="hidden px-2 py-3 text-end sm:table-cell">تاريخ الإنشاء</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {cycles.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-2 py-8 text-center text-secondary">
                  لا توجد دورات توزيع بعد
                </td>
              </tr>
            ) : (
              cycles.map((cycle) => {
                const excluded = exclusionsByMonth[cycle.year_month] ?? []
                return (
                  <tr key={cycle.id} className={`align-top ${cycle.is_voided ? 'text-secondary opacity-75' : 'text-ink'}`}>
                    <td className="whitespace-nowrap px-2 py-3 font-medium">{cycle.year_month}</td>
                    <td className="px-2 py-3">
                      {cycle.is_voided ? (
                        <StatusBadge label="ملغاة" className="border-danger/20 bg-danger/10 text-danger" title={cycle.void_reason ?? undefined} />
                      ) : cycle.status === 'applied' ? (
                        <StatusBadge label="موزعة" className="border-success/20 bg-success/10 text-success" />
                      ) : (
                        <StatusBadge label="لا مصروفات" className="border-secondary/20 bg-secondary/10 text-secondary" />
                      )}
                    </td>
                    <td className="whitespace-nowrap px-2 py-3 text-end font-semibold tabular-nums">{formatCurrency(cycle.total_amount)}</td>
                    <td className="hidden px-2 py-3 text-center sm:table-cell">{cycle.eligible_project_ids?.length ?? 0}</td>
                    <td className="px-2 py-3 text-xs leading-relaxed">
                      {excluded.length > 0 ? (
                        <span className="text-warning">مستثنى: {excluded.map((e) => e.project?.name ?? '؟').join('، ')}</span>
                      ) : (
                        <span className="text-secondary/60">بدون</span>
                      )}
                    </td>
                    <td className="hidden whitespace-nowrap px-2 py-3 text-end text-secondary sm:table-cell">{formatDate(cycle.created_at)}</td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {showRun && <RunAllocationDialog onClose={() => setShowRun(false)} />}
      {showExclusion && <AllocationExclusionDialog projects={projects} onClose={() => setShowExclusion(false)} />}
    </section>
  )
}
