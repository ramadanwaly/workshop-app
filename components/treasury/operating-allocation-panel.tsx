'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'
import { RunAllocationDialog } from './run-allocation-dialog'
import { AllocationExclusionDialog } from './allocation-exclusion-dialog'

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
    <section className="mt-8">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-bold text-ink">توزيع مصاريف التشغيل الشهري</h2>
        {isOwner && (
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => setShowRun(true)}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-background transition hover:bg-primary/90"
            >
              تشغيل يدوي
            </button>
            <button
              type="button"
              onClick={() => setShowExclusion(true)}
              className="rounded-xl bg-secondary/10 px-4 py-2 text-sm font-bold text-ink transition hover:bg-secondary/20"
            >
              استبعاد مشروع
            </button>
          </div>
        )}
      </div>

      <div className="overflow-x-auto rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <table className="w-full text-right text-sm">
          <thead>
            <tr className="border-b border-secondary/20 bg-secondary/5 text-xs font-semibold uppercase text-secondary">
              <th className="px-4 py-3">الشهر</th>
              <th className="px-4 py-3">الحالة</th>
              <th className="px-4 py-3">الإجمالي</th>
              <th className="px-4 py-3 hidden sm:table-cell">المشاريع المؤهلة</th>
              <th className="px-4 py-3 hidden sm:table-cell">التاريخ</th>
            </tr>
          </thead>
          <tbody>
            {cycles.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-secondary">
                  لا توجد دورات توزيع بعد
                </td>
              </tr>
            ) : (
              cycles.map((cycle) => {
                const excluded = exclusionsByMonth[cycle.year_month] ?? []
                return (
                  <tr key={cycle.id} className={`border-b border-secondary/10 last:border-0 ${cycle.is_voided ? 'bg-secondary/5 text-secondary line-through' : ''}`}>
                    <td className="whitespace-nowrap px-4 py-3">{cycle.year_month}</td>
                    <td className="px-4 py-3">
                      {cycle.is_voided ? (
                        <span className="text-xs text-danger" title={cycle.void_reason ?? undefined}>ملغاة</span>
                      ) : cycle.status === 'applied' ? (
                        <span className="text-xs text-success">موزعة</span>
                      ) : (
                        <span className="text-xs text-secondary">لا مصروفات</span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 font-bold tabular-nums">{formatCurrency(cycle.total_amount)}</td>
                    <td className="hidden px-4 py-3 sm:table-cell">{cycle.eligible_project_ids?.length ?? 0}</td>
                    <td className="hidden whitespace-nowrap px-4 py-3 sm:table-cell">{formatDate(cycle.created_at)}</td>
                    {excluded.length > 0 && (
                      <td className="px-4 py-3">
                        <span className="text-xs text-secondary">مستثنى: {excluded.map((e) => e.project?.name ?? '؟').join('، ')}</span>
                      </td>
                    )}
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
