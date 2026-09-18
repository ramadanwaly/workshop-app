'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'
import { Input } from '@/components/ui/input'
import { StatusBadge } from '@/components/layout/status-badge'

const FRACTION_LABELS: Record<number, string> = {
  0.25: 'ربع يوم',
  0.5: 'نصف يوم',
  1: 'يوم كامل',
}

// Defining exact structures expected from worker detail
type WorkerLog = {
  id: string
  log_date: string
  fraction: number
  calculated_amount: number
  is_settled: boolean
  projects?: { name: string } | null
}

type WorkerAdvance = {
  id: string
  advance_date: string
  amount: number
  notes: string | null
}

type WorkerTransactionsTabProps = {
  logs: WorkerLog[]
  advances: WorkerAdvance[]
}

export function WorkerTransactionsTab({ logs, advances }: WorkerTransactionsTabProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const q = searchQuery.toLowerCase()

  const filteredLogs = logs.filter(
    (log) =>
      !q ||
      formatDate(log.log_date).includes(q) ||
      (log.projects?.name || '').toLowerCase().includes(q) ||
      (FRACTION_LABELS[log.fraction] ?? log.fraction.toString()).toLowerCase().includes(q) ||
      log.calculated_amount.toString().includes(q)
  )

  const filteredAdvances = advances.filter(
    (adv) =>
      !q ||
      formatDate(adv.advance_date).includes(q) ||
      (adv.notes || '').toLowerCase().includes(q) ||
      adv.amount.toString().includes(q)
  )

  return (
    <div className="space-y-6">
      <div className="rounded-md border border-border bg-card p-4 shadow-sm">
        <Input
          type="search"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="بحث في السجلات أو السلف (تاريخ، مبلغ، ملاحظات)..."
          className="w-full"
        />
      </div>

      {/* جدول آخر الحضور */}
      <section>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold text-foreground">آخر سجلات الحضور</h2>
          <span className="text-sm font-semibold text-muted-foreground">{filteredLogs.length} سجل</span>
        </div>
        {filteredLogs.length === 0 ? (
          <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
            <p className="text-muted-foreground">لا توجد سجلات حضور مطابقة.</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-md border border-border bg-card">
            <table className="w-full text-right text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 font-semibold text-muted-foreground">التاريخ</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">المشروع</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">النسبة</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">المبلغ</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">الحالة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-muted/50">
                    <td className="whitespace-nowrap px-4 py-3 tabular-nums text-foreground">
                      {formatDate(log.log_date)}
                    </td>
                    <td className="px-4 py-3 text-foreground">{log.projects?.name ?? '—'}</td>
                    <td className="px-4 py-3 text-foreground">
                      {FRACTION_LABELS[log.fraction] ?? log.fraction}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                      {formatCurrency(log.calculated_amount)}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge
                        label={log.is_settled ? 'مسدّد' : 'غير مسدّد'}
                        className={
                          log.is_settled
                            ? 'border-success/50 bg-success/10 text-success'
                            : 'border-warning/50 bg-warning/10 text-warning-foreground'
                        }
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* جدول السلف غير المسددة */}
      <section>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold text-foreground">السلف غير المسددة</h2>
          <span className="text-sm font-semibold text-muted-foreground">{filteredAdvances.length} سلفة</span>
        </div>
        {filteredAdvances.length === 0 ? (
          <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
            <p className="text-muted-foreground">لا توجد سلف غير مسددة مطابقة.</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-md border border-border bg-card">
            <table className="w-full text-right text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 font-semibold text-muted-foreground">التاريخ</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">المبلغ</th>
                  <th className="px-4 py-3 font-semibold text-muted-foreground">ملاحظات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredAdvances.map((adv) => (
                  <tr key={adv.id} className="hover:bg-muted/50">
                    <td className="whitespace-nowrap px-4 py-3 tabular-nums text-foreground">
                      {formatDate(adv.advance_date)}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 font-semibold tabular-nums text-primary">
                      {formatCurrency(adv.amount)}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{adv.notes ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  )
}
