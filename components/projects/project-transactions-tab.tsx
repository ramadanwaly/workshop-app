'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'

export type TreasuryTransactionRow = {
  id: string
  transaction_type: string
  category: string
  subcategory?: string | null
  amount: number
  description: string | null
  is_direct_owner_payment: boolean
  is_voided: boolean
  created_at: string
}

export type WorkerLogRow = {
  id: string
  log_date: string
  fraction: number
  daily_rate: number
  calculated_amount: number
  is_settled: boolean
  notes: string | null
  workers: { name: string } | Array<{ name: string }> | null
}

export type SubcontractOrderRow = {
  id: string
  contractor_name: string
  description: string
  total_agreed_amount: number
  status: string
  created_at: string
}

export type CostAdjustmentRow = {
  id: string
  adjustment_type: string
  amount: number
  notes: string | null
  created_at: string
  surplus_bank:
    | { material_name: string; unit: string }
    | Array<{ material_name: string; unit: string }>
    | null
}

export type ProjectTransactionsTabProps = {
  treasuryTransactions: TreasuryTransactionRow[]
  workerLogs: WorkerLogRow[]
  subcontractOrders: SubcontractOrderRow[]
  costAdjustments: CostAdjustmentRow[]
}

const CATEGORY_LABELS: Record<string, string> = {
  material: 'مواد',
  freight: 'شحن / نولون',
  owner_funding: 'تمويل مالك',
  advance: 'سلفة',
  settlement: 'تسوية',
  subcontract_payment: 'دفع مقاول',
  general_expense: 'مصروف عام',
  other: 'أخرى',
}

const FRACTION_LABELS: Record<number, string> = {
  1.0: 'يوم كامل (1.0)',
  0.5: 'نصف يوم (0.5)',
  0.25: 'ربع يوم (0.25)',
}

const SUBCONTRACT_STATUS_LABELS: Record<string, string> = {
  active: 'نشط',
  completed: 'مكتمل',
  cancelled: 'ملغي',
}

const ADJUSTMENT_TYPE_LABELS: Record<string, string> = {
  surplus_return: 'مرتجع فائض (خصم من التكلفة)',
  surplus_consumption: 'استهلاك فائض (إضافة للتكلفة)',
  surplus_scrap: 'هالك / إنقاذ',
}

export function ProjectTransactionsTab({
  treasuryTransactions,
  workerLogs,
  subcontractOrders,
  costAdjustments,
}: ProjectTransactionsTabProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const q = searchQuery.toLowerCase()

  const filteredTreasury = treasuryTransactions.filter(tx => 
    !q ||
    formatDate(tx.created_at).includes(q) ||
    (CATEGORY_LABELS[tx.category] ?? tx.category).toLowerCase().includes(q) ||
    (tx.description || '').toLowerCase().includes(q)
  )

  const filteredWorkerLogs = workerLogs.filter(log =>
    !q ||
    formatDate(log.log_date).includes(q) ||
    'عمالة'.includes(q) ||
    (Array.isArray(log.workers) ? log.workers.map(w => w.name).join(' ') : log.workers?.name || '').toLowerCase().includes(q) ||
    (log.notes || '').toLowerCase().includes(q)
  )

  const filteredSubcontracts = subcontractOrders.filter(order =>
    !q ||
    formatDate(order.created_at).includes(q) ||
    'مقاول'.includes(q) ||
    (order.contractor_name || '').toLowerCase().includes(q) ||
    (order.description || '').toLowerCase().includes(q)
  )

  const filteredAdjustments = costAdjustments.filter(adj =>
    !q ||
    formatDate(adj.created_at).includes(q) ||
    (ADJUSTMENT_TYPE_LABELS[adj.adjustment_type] ?? adj.adjustment_type).toLowerCase().includes(q) ||
    (adj.notes || '').toLowerCase().includes(q) ||
    (Array.isArray(adj.surplus_bank) ? adj.surplus_bank[0]?.material_name : adj.surplus_bank?.material_name || '').toLowerCase().includes(q)
  )

  // 1. حساب إجمالي المواد والنولون (المعاملات الفعالة غير الملغاة)
  const totalTreasury = filteredTreasury
    .filter((t) => !t.is_voided)
    .reduce((sum, t) => sum + Number(t.amount || 0), 0)

  // 2. حساب إجمالي أجور العمالة
  const totalLabor = filteredWorkerLogs.reduce(
    (sum, l) => sum + Number(l.calculated_amount || 0),
    0
  )

  // 3. حساب إجمالي المقاولين (غير الملغاة)
  const totalSubcontract = filteredSubcontracts
    .filter((s) => s.status !== 'cancelled')
    .reduce((sum, s) => sum + Number(s.total_agreed_amount || 0), 0)

  // 4. حساب إجمالي الفائض
  const totalReturns = filteredAdjustments
    .filter((a) => a.adjustment_type === 'surplus_return')
    .reduce((sum, a) => sum + Number(a.amount || 0), 0)
  const totalConsumptions = filteredAdjustments
    .filter((a) => a.adjustment_type === 'surplus_consumption')
    .reduce((sum, a) => sum + Number(a.amount || 0), 0)

  return (
    <div className="space-y-8">
      <div className="rounded-2xl border border-secondary/30 bg-white p-4 shadow-sm">
        <input
          type="search"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="بحث في الحركات بحسب التاريخ، التصنيف، أو البيان..."
          className="w-full rounded-xl border border-secondary/30 bg-background/40 px-4 py-3 text-sm text-ink outline-none transition focus:border-accent"
        />
      </div>

      {/* 1. قسم المواد والنولون */}
      <section className="overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-primary/20 bg-primary/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <span className="flex h-3 w-3 rounded-full bg-primary" />
            <h2 className="text-lg font-bold text-primary">المواد والنولون (حركات الخزينة)</h2>
            <span className="rounded-full bg-primary/15 px-2.5 py-0.5 text-xs font-bold text-primary">
              {filteredTreasury.length} حركة
            </span>
          </div>
          <div className="text-sm font-semibold text-primary">
            الإجمالي النشط: <span className="text-base font-bold tabular-nums">{formatCurrency(totalTreasury)}</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-secondary/20 bg-background/60 text-xs font-semibold text-secondary">
              <tr>
                <th className="px-6 py-3">التاريخ</th>
                <th className="px-6 py-3">التصنيف</th>
                <th className="px-6 py-3">البيان</th>
                <th className="px-6 py-3">مصدر الدفع</th>
                <th className="px-6 py-3">المبلغ</th>
                <th className="px-6 py-3">الحالة</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary/15">
              {filteredTreasury.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-secondary">
                    لا توجد معاملات مطابقة للبحث.
                  </td>
                </tr>
              ) : (
                filteredTreasury.map((tx) => (
                  <tr
                    key={tx.id}
                    className={`transition hover:bg-background/40 ${
                      tx.is_voided ? 'opacity-50 line-through bg-danger/5' : ''
                    }`}
                  >
                    <td className="whitespace-nowrap px-6 py-4 font-medium text-ink">
                      {formatDate(tx.created_at)}
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-block rounded-md bg-secondary/10 px-2.5 py-1 text-xs font-semibold text-ink">
                        {CATEGORY_LABELS[tx.category] ?? tx.category}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-ink max-w-xs truncate">
                      {tx.description || '—'}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-secondary">
                      {tx.is_direct_owner_payment ? (
                        <span className="rounded bg-accent/15 px-2 py-0.5 text-xs font-semibold text-accent">
                          مباشر من المالك
                        </span>
                      ) : (
                        <span className="rounded bg-secondary/15 px-2 py-0.5 text-xs font-semibold text-secondary">
                          من الخزينة
                        </span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 font-bold tabular-nums text-primary">
                      {formatCurrency(tx.amount)}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      {tx.is_voided ? (
                        <span className="rounded-full bg-danger/15 px-2.5 py-0.5 text-xs font-semibold text-danger">
                          ملغاة
                        </span>
                      ) : (
                        <span className="rounded-full bg-success/15 px-2.5 py-0.5 text-xs font-semibold text-success">
                          مكتملة
                        </span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* 2. قسم العمالة */}
      <section className="overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-amber-500/20 bg-amber-500/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <span className="flex h-3 w-3 rounded-full bg-amber-500" />
            <h2 className="text-lg font-bold text-amber-700 dark:text-amber-400">سجلات العمالة (أجور العمال)</h2>
            <span className="rounded-full bg-amber-500/15 px-2.5 py-0.5 text-xs font-bold text-amber-700 dark:text-amber-400">
              {filteredWorkerLogs.length} سجل
            </span>
          </div>
          <div className="text-sm font-semibold text-amber-700 dark:text-amber-400">
            إجمالي أجور العمال: <span className="text-base font-bold tabular-nums">{formatCurrency(totalLabor)}</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-secondary/20 bg-background/60 text-xs font-semibold text-secondary">
              <tr>
                <th className="px-6 py-3">تاريخ العمل</th>
                <th className="px-6 py-3">اسم العامل</th>
                <th className="px-6 py-3">مدة اليومية</th>
                <th className="px-6 py-3">الأجر اليومي</th>
                <th className="px-6 py-3">المستحق</th>
                <th className="px-6 py-3">التسوية</th>
                <th className="px-6 py-3">ملاحظات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary/15">
              {filteredWorkerLogs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-8 text-center text-secondary">
                    لا توجد سجلات عمالة مطابقة للبحث.
                  </td>
                </tr>
              ) : (
                filteredWorkerLogs.map((log) => {
                  const workerObj = Array.isArray(log.workers) ? log.workers[0] : log.workers
                  const workerName = workerObj?.name ?? '—'
                  return (
                    <tr key={log.id} className="transition hover:bg-background/40">
                      <td className="whitespace-nowrap px-6 py-4 font-medium text-ink">
                        {formatDate(log.log_date)}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 font-semibold text-ink">
                        {workerName}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 text-secondary">
                        {FRACTION_LABELS[Number(log.fraction)] ?? log.fraction}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 tabular-nums text-secondary">
                        {formatCurrency(log.daily_rate)}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 font-bold tabular-nums text-primary">
                        {formatCurrency(log.calculated_amount)}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        {log.is_settled ? (
                          <span className="rounded-full bg-success/15 px-2.5 py-0.5 text-xs font-semibold text-success">
                            تمت التسوية
                          </span>
                        ) : (
                          <span className="rounded-full bg-warning/15 px-2.5 py-0.5 text-xs font-semibold text-warning">
                            معلق
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-secondary max-w-xs truncate">
                        {log.notes || '—'}
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* 3. قسم المقاولون */}
      <section className="overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-accent/20 bg-accent/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <span className="flex h-3 w-3 rounded-full bg-accent" />
            <h2 className="text-lg font-bold text-accent">اتفاقيات مقاولي الباطن</h2>
            <span className="rounded-full bg-accent/15 px-2.5 py-0.5 text-xs font-bold text-accent">
              {filteredSubcontracts.length} اتفاق
            </span>
          </div>
          <div className="text-sm font-semibold text-accent">
            إجمالي الاتفاقيات النشطة/المكتملة: <span className="text-base font-bold tabular-nums">{formatCurrency(totalSubcontract)}</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-secondary/20 bg-background/60 text-xs font-semibold text-secondary">
              <tr>
                <th className="px-6 py-3">تاريخ الاتفاق</th>
                <th className="px-6 py-3">اسم المقاول</th>
                <th className="px-6 py-3">بيان العمل</th>
                <th className="px-6 py-3">إجمالي المتفق عليه</th>
                <th className="px-6 py-3">الحالة</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary/15">
              {filteredSubcontracts.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-secondary">
                    لا توجد اتفاقيات مقاولي باطن مطابقة للبحث.
                  </td>
                </tr>
              ) : (
                filteredSubcontracts.map((order) => (
                  <tr key={order.id} className="transition hover:bg-background/40">
                    <td className="whitespace-nowrap px-6 py-4 font-medium text-ink">
                      {formatDate(order.created_at)}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 font-semibold text-ink">
                      {order.contractor_name}
                    </td>
                    <td className="px-6 py-4 text-ink max-w-xs truncate">
                      {order.description}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 font-bold tabular-nums text-accent">
                      {formatCurrency(order.total_agreed_amount)}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                          order.status === 'completed'
                            ? 'bg-success/15 text-success'
                            : order.status === 'cancelled'
                            ? 'bg-danger/15 text-danger line-through'
                            : 'bg-accent/15 text-accent'
                        }`}
                      >
                        {SUBCONTRACT_STATUS_LABELS[order.status] ?? order.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* 4. قسم الفائض وتعديلات التكلفة */}
      <section className="overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-success/20 bg-success/10 px-6 py-4">
          <div className="flex items-center gap-3">
            <span className="flex h-3 w-3 rounded-full bg-success" />
            <h2 className="text-lg font-bold text-success">الفائض وتعديلات التكلفة</h2>
            <span className="rounded-full bg-success/15 px-2.5 py-0.5 text-xs font-bold text-success">
              {filteredAdjustments.length} حركة
            </span>
          </div>
          <div className="flex flex-wrap items-center gap-4 text-sm font-semibold text-ink">
            <span className="text-success">
              المرتجعات (تخصم): <span className="font-bold tabular-nums">{formatCurrency(totalReturns)}</span>
            </span>
            <span className="text-primary">
              الاستهلاك (يضاف): <span className="font-bold tabular-nums">{formatCurrency(totalConsumptions)}</span>
            </span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-secondary/20 bg-background/60 text-xs font-semibold text-secondary">
              <tr>
                <th className="px-6 py-3">التاريخ</th>
                <th className="px-6 py-3">نوع الحركة</th>
                <th className="px-6 py-3">الصنف / المادة</th>
                <th className="px-6 py-3">القيمة</th>
                <th className="px-6 py-3">ملاحظات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary/15">
              {filteredAdjustments.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-secondary">
                    لا توجد حركات فائض أو تعديلات تكلفة مطابقة للبحث.
                  </td>
                </tr>
              ) : (
                filteredAdjustments.map((adj) => {
                  const surplusObj = Array.isArray(adj.surplus_bank)
                    ? adj.surplus_bank[0]
                    : adj.surplus_bank
                  const materialName = surplusObj?.material_name
                    ? `${surplusObj.material_name}${surplusObj.unit ? ` (${surplusObj.unit})` : ''}`
                    : '—'
                  const isReturn = adj.adjustment_type === 'surplus_return'

                  return (
                    <tr key={adj.id} className="transition hover:bg-background/40">
                      <td className="whitespace-nowrap px-6 py-4 font-medium text-ink">
                        {formatDate(adj.created_at)}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <span
                          className={`rounded px-2.5 py-1 text-xs font-semibold ${
                            isReturn
                              ? 'bg-success/15 text-success'
                              : 'bg-primary/15 text-primary'
                          }`}
                        >
                          {ADJUSTMENT_TYPE_LABELS[adj.adjustment_type] ?? adj.adjustment_type}
                        </span>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 font-semibold text-ink">
                        {materialName}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 font-bold tabular-nums">
                        <span className={isReturn ? 'text-success' : 'text-primary'}>
                          {isReturn ? `- ${formatCurrency(adj.amount)}` : `+ ${formatCurrency(adj.amount)}`}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-secondary max-w-xs truncate">
                        {adj.notes || '—'}
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  )
}
