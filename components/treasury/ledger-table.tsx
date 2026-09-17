'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'

const ExpenseDialog = dynamic(() => import('@/components/mobile/expense-dialog').then(mod => mod.ExpenseDialog))
const VoidTransactionDialog = dynamic(() => import('./void-transaction-dialog').then(mod => mod.VoidTransactionDialog))
const FundInjectionDialog = dynamic(() => import('./fund-injection-dialog').then(mod => mod.FundInjectionDialog))
import { StatusBadge } from '@/components/layout/status-badge'

const CATEGORY_LABELS: Record<string, string> = {
  owner_funding: 'تمويل المالك', material: 'مواد', freight: 'شحن', workshop_operating: 'مصاريف تشغيل', advance: 'سلفة', settlement: 'تسوية', subcontract_payment: 'دفع مقاول', general_expense: 'مصروف عام', carried_forward_advance: 'سلفة مُحولة', other: 'أخرى',
}

const SUBCATEGORY_LABELS: Record<string, string> = {
  wood_boards: 'خشب وألواح', upholstery_fabric_textile: 'أقمشة وجلود تنجيد', foam_filling: 'إسفنج وحشو', hardware_hinges: 'إكسسوارات ومفصلات', glue_adhesives: 'غراء ومواد لصق', paints_varnishes: 'دهانات وورنيش', glass_mirrors: 'زجاج ومرايا', small_fasteners: 'مسامير وبراغي وخامات صغيرة', consumables_tools: 'أدوات ومعدات استهلاكية', machine_maintenance: 'صيانة ماكينات', site_transport: 'مواصلات من وإلى الموقع', merchant_transport: 'نقل من التاجر للورشة', workshop_machine_transport: 'نقل من الورشة للمكنة والعكس', tools_site_transport: 'نقل العدة للموقع والعكس', completed_work_transport: 'نقل الشغل المكتمل للموقع', electricity: 'كهرباء', rent: 'إيجار', waste_collection: 'جمع نفايات',
}

type LedgerTransaction = {
  id: string
  transaction_type: string
  category: string
  subcategory: string | null
  amount: number
  description: string | null
  is_direct_owner_payment: boolean
  is_voided: boolean
  voided_at: string | null
  void_reason: string | null
  created_at: string
  project: { id: string; name: string } | null
}

type LedgerTableProps = {
  transactions: LedgerTransaction[]
  userRole: string
  projects: Array<{ id: string; name: string }>
  canRecordExpense: boolean
  canInjectFunding: boolean
  hasActiveFilters: boolean
}

function TransactionStatus({ transaction }: { transaction: LedgerTransaction }) {
  if (transaction.is_voided) {
    return <StatusBadge label="ملغاة" className="border-danger/20 bg-danger/10 text-danger" />
  }
  if (transaction.is_direct_owner_payment) {
    return <StatusBadge label="دفع مباشر" className="border-primary/20 bg-primary/10 text-primary" />
  }
  return <StatusBadge label="مكتملة" className="border-success/20 bg-success/10 text-success" />
}

function TransactionType({ transaction }: { transaction: LedgerTransaction }) {
  const isIn = transaction.transaction_type === 'in'
  return <span className={`inline-flex items-center text-xs font-bold ${isIn ? 'text-success' : 'text-danger'}`}>{isIn ? 'وارد' : 'صادر'}</span>
}

function TransactionAmount({ transaction }: { transaction: LedgerTransaction }) {
  const isIn = transaction.transaction_type === 'in'
  const color = transaction.is_voided ? 'text-ink/60' : isIn ? 'text-success' : 'text-danger'
  return <span className={`whitespace-nowrap font-bold tabular-nums tracking-tight ${color}`}>{isIn ? '+' : '−'}{formatCurrency(transaction.amount)}</span>
}

export function LedgerTable({ transactions, userRole, projects, canRecordExpense, canInjectFunding, hasActiveFilters }: LedgerTableProps) {
  const [voidTarget, setVoidTarget] = useState<LedgerTransaction | null>(null)
  const [showInject, setShowInject] = useState(false)
  const [showExpense, setShowExpense] = useState(false)
  const canVoid = userRole === 'owner'

  const actions = (
    <div className="flex flex-wrap gap-2">
      {canRecordExpense && (
        <Button onClick={() => setShowExpense(true)} variant="default">
          تسجيل مصروف
        </Button>
      )}
      {canInjectFunding && (
        <Button onClick={() => setShowInject(true)} variant="outline" className="border-success/30 bg-success/5 text-success hover:bg-success/10 hover:text-success">
          إيداع تمويل
        </Button>
      )}
    </div>
  )

  return (
    <section aria-labelledby="ledger-title">
      <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 id="ledger-title" className="text-lg font-bold text-ink">دفتر الحركات</h2>
          <p className="mt-1 text-xs text-secondary">{hasActiveFilters ? 'نتائج البحث والتصفية الحالية' : 'آخر الحركات المسجلة في الخزينة'}</p>
        </div>
        {actions}
      </div>

      {transactions.length === 0 ? (
        <div className="border border-secondary/20 bg-background/50 px-5 py-12 text-center">
          <p className="text-sm font-medium text-ink">{hasActiveFilters ? 'لا توجد حركات مطابقة' : 'لا توجد حركات مالية بعد'}</p>
          <p className="mt-1 text-sm text-secondary">{hasActiveFilters ? 'غيّر كلمات البحث أو الفترة أو التصنيف، ثم أعد المحاولة.' : 'ستظهر هنا الحركات المسجلة بعد إضافة أول إيداع أو مصروف.'}</p>
          {hasActiveFilters && <p className="mt-4 text-xs font-medium text-warning">المرشحات النشطة تخفي حركات أخرى.</p>}
        </div>
      ) : (
        <>
          <div className="hidden overflow-x-auto rounded-md border border-border bg-card md:block">
            <table className="w-full text-right text-sm">
              <caption className="sr-only">دفتر حركات الخزينة</caption>
              <thead className="border-b border-border bg-muted/50 text-xs font-bold text-secondary">
                <tr>
                  <th scope="col" className="whitespace-nowrap px-4 py-3">التاريخ</th>
                  <th scope="col" className="px-4 py-3">النوع</th>
                  <th scope="col" className="px-4 py-3">التصنيف</th>
                  <th scope="col" className="px-4 py-3 text-end">المبلغ</th>
                  <th scope="col" className="px-4 py-3">المشروع / الوصف</th>
                  <th scope="col" className="px-4 py-3">الحالة</th>
                  {canVoid && <th scope="col" className="px-4 py-3 text-end">إجراء</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {transactions.map((transaction) => (
                  <tr key={transaction.id} className={`align-top transition-colors ${transaction.is_voided ? 'bg-muted/30' : 'hover:bg-muted/50'}`}>
                    <td className="whitespace-nowrap px-4 py-3 text-secondary">{formatDate(transaction.created_at)}</td>
                    <td className="px-4 py-3"><TransactionType transaction={transaction} /></td>
                    <td className="px-4 py-3 text-ink">
                      <span className="font-medium">{CATEGORY_LABELS[transaction.category] ?? transaction.category}</span>
                      {transaction.subcategory && <span className="mt-0.5 block text-xs text-secondary">{SUBCATEGORY_LABELS[transaction.subcategory] ?? transaction.subcategory}</span>}
                    </td>
                    <td className="px-4 py-3 text-end"><TransactionAmount transaction={transaction} /></td>
                    <td className="px-4 py-3 text-ink">
                      {transaction.project?.name && <span className="font-medium">{transaction.project.name}</span>}
                      {transaction.description && <span className={`block text-xs ${transaction.project?.name ? 'mt-0.5 text-secondary' : 'text-ink'}`}>{transaction.description}</span>}
                      {!transaction.project?.name && !transaction.description && <span className="text-secondary">—</span>}
                    </td>
                    <td className="px-4 py-3">
                      <TransactionStatus transaction={transaction} />
                      {transaction.is_voided && transaction.void_reason && <p className="mt-1 max-w-40 text-[11px] leading-relaxed text-secondary">سبب الإلغاء: {transaction.void_reason}</p>}
                    </td>
                    {canVoid && (
                      <td className="px-4 py-3 text-end">
                        {!transaction.is_voided && (
                          <Button type="button" onClick={() => setVoidTarget(transaction)} variant="ghost" size="sm" className="text-danger hover:bg-danger/10 hover:text-danger">
                            إلغاء الحركة
                          </Button>
                        )}
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="space-y-3 md:hidden">
            {transactions.map((transaction) => (
              <article key={transaction.id} className={`rounded-md border p-4 ${transaction.is_voided ? 'border-border bg-muted/30' : 'border-border bg-card'}`}>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex flex-col gap-1">
                    <TransactionType transaction={transaction} />
                    <div>
                      <p className="text-sm font-medium text-ink">{CATEGORY_LABELS[transaction.category] ?? transaction.category}</p>
                      {transaction.subcategory && <p className="text-[11px] text-secondary">{SUBCATEGORY_LABELS[transaction.subcategory] ?? transaction.subcategory}</p>}
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <TransactionAmount transaction={transaction} />
                    <p className="text-[11px] text-secondary">{formatDate(transaction.created_at)}</p>
                  </div>
                </div>
                
                <div className="mt-3 text-sm">
                  {transaction.project?.name && <p className="text-ink font-medium">{transaction.project.name}</p>}
                  {transaction.description && <p className={`text-xs ${transaction.project?.name ? 'mt-1 text-secondary' : 'text-ink'}`}>{transaction.description}</p>}
                </div>

                <div className="mt-4 flex items-center justify-between border-t border-border pt-3">
                  <div className="flex flex-col gap-1">
                    <TransactionStatus transaction={transaction} />
                    {transaction.is_voided && transaction.void_reason && <span className="text-[10px] text-secondary">سبب: {transaction.void_reason}</span>}
                  </div>
                  {canVoid && !transaction.is_voided && (
                    <Button type="button" onClick={() => setVoidTarget(transaction)} variant="outline" size="sm" className="h-8 border-danger/30 text-danger hover:bg-danger/5 hover:text-danger">
                      إلغاء الحركة
                    </Button>
                  )}
                </div>
              </article>
            ))}
          </div>
        </>
      )}

      {showExpense && <ExpenseDialog projects={projects} onClose={() => setShowExpense(false)} />}
      {showInject && <FundInjectionDialog onClose={() => setShowInject(false)} />}
      {voidTarget && <VoidTransactionDialog transaction={voidTarget} onClose={() => setVoidTarget(null)} />}
    </section>
  )
}
