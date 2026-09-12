'use client'

import { useState } from 'react'
import { formatCurrency, formatDate } from '@/lib/format'
import { VoidTransactionDialog } from './void-transaction-dialog'
import { FundInjectionDialog } from './fund-injection-dialog'

const CATEGORY_LABELS: Record<string, string> = {
  owner_funding: 'تمويل المالك',
  material: 'مواد',
  freight: 'شحن',
  workshop_operating: 'مصاريف تشغيل',
  advance: 'سلفة',
  settlement: 'تسوية',
  subcontract_payment: 'دفع مقاول',
  general_expense: 'مصروف عام',
  carried_forward_advance: 'سلفة مُحولة',
  other: 'أخرى',
}

const SUBCATEGORY_LABELS: Record<string, string> = {
  wood_boards: 'خشب وألواح',
  upholstery_fabric_textile: 'أقمشة وجلود تنجيد',
  foam_filling: 'إسفنج وحشو',
  hardware_hinges: 'إكسسوارات ومفصلات',
  glue_adhesives: 'غراء ومواد لصق',
  paints_varnishes: 'دهانات وورنيش',
  glass_mirrors: 'زجاج ومرايا',
  small_fasteners: 'مسامير وبراغي وخامات صغيرة',
  consumables_tools: 'أدوات ومعدات استهلاكية',
  machine_maintenance: 'صيانة ماكينات',
  site_transport: 'مواصلات من وإلى الموقع',
  merchant_transport: 'نقل من التاجر للورشة',
  workshop_machine_transport: 'نقل من الورشة للمكنة والعكس',
  tools_site_transport: 'نقل العدة للموقع والعكس',
  completed_work_transport: 'نقل الشغل المكتمل للموقع',
  electricity: 'كهرباء',
  rent: 'إيجار',
  waste_collection: 'جمع نفايات',
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
}

export function LedgerTable({ transactions, userRole }: LedgerTableProps) {
  const [voidTarget, setVoidTarget] = useState<LedgerTransaction | null>(null)
  const [showInject, setShowInject] = useState(false)

  return (
    <>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-bold text-ink">آخر الحركات</h2>
        <button
          type="button"
          onClick={() => setShowInject(true)}
          className="rounded-xl bg-success px-4 py-2 text-sm font-bold text-background transition hover:bg-success/90"
        >
          + إيداع
        </button>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-secondary/30 bg-white shadow-sm">
        <table className="w-full text-right text-sm">
          <thead>
            <tr className="border-b border-secondary/20 bg-secondary/5 text-xs font-semibold uppercase text-secondary">
              <th className="px-4 py-3">التاريخ</th>
              <th className="px-4 py-3">النوع</th>
              <th className="px-4 py-3">التصنيف</th>
              <th className="px-4 py-3">المبلغ</th>
              <th className="px-4 py-3 hidden sm:table-cell">المشروع</th>
              <th className="px-4 py-3 hidden sm:table-cell">الوصف</th>
              <th className="px-4 py-3">الحالة</th>
              {userRole === 'owner' && <th className="px-4 py-3">إجراء</th>}
            </tr>
          </thead>
          <tbody>
            {transactions.length === 0 ? (
              <tr>
                <td
                  colSpan={userRole === 'owner' ? 8 : 7}
                  className="px-4 py-8 text-center text-secondary"
                >
                  لا توجد حركات مالية بعد
                </td>
              </tr>
            ) : (
              transactions.map((tx) => {
                const isIn = tx.transaction_type === 'in'
                const isVoided = tx.is_voided

                return (
                  <tr
                    key={tx.id}
                    className={`border-b border-secondary/10 transition last:border-0 ${
                      isVoided
                        ? 'bg-secondary/5 text-secondary line-through'
                        : isIn
                          ? 'hover:bg-success/5'
                          : 'hover:bg-danger/5'
                    }`}
                  >
                    <td className="whitespace-nowrap px-4 py-3">
                      {formatDate(tx.created_at)}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-block rounded-full px-2 py-0.5 text-xs font-bold ${
                          isVoided
                            ? 'bg-secondary/20 text-secondary'
                            : isIn
                              ? 'bg-success/10 text-success'
                              : 'bg-danger/10 text-danger'
                        }`}
                      >
                        {isIn ? 'وارد' : 'صادر'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {CATEGORY_LABELS[tx.category] ?? tx.category}
                      {tx.subcategory && (
                        <div className="mt-0.5 text-xs text-secondary">
                          {SUBCATEGORY_LABELS[tx.subcategory] ?? tx.subcategory}
                        </div>
                      )}
                    </td>
                    <td
                      className={`whitespace-nowrap px-4 py-3 font-bold tabular-nums ${
                        isVoided
                          ? 'text-secondary'
                          : isIn
                            ? 'text-success'
                            : 'text-danger'
                      }`}
                    >
                      {isIn ? '+' : '-'}{formatCurrency(tx.amount)}
                    </td>
                    <td className="hidden px-4 py-3 sm:table-cell">
                      {tx.project?.name ?? '—'}
                    </td>
                    <td className="hidden max-w-[200px] truncate px-4 py-3 sm:table-cell">
                      {tx.description ?? '—'}
                    </td>
                    <td className="px-4 py-3">
                      {isVoided ? (
                        <span className="text-xs text-danger" title={tx.void_reason ?? undefined}>
                          ملغاة
                        </span>
                      ) : tx.is_direct_owner_payment ? (
                        <span className="text-xs text-accent">دفع مباشر</span>
                      ) : (
                        <span className="text-xs text-success">نشط</span>
                      )}
                    </td>
                    {userRole === 'owner' && (
                      <td className="px-4 py-3">
                        {!isVoided && (
                          <button
                            type="button"
                            onClick={() => setVoidTarget(tx)}
                            className="rounded-lg bg-danger/10 px-3 py-1 text-xs font-bold text-danger transition hover:bg-danger/20"
                          >
                            إلغاء
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {showInject && (
        <FundInjectionDialog onClose={() => setShowInject(false)} />
      )}

      {voidTarget && (
        <VoidTransactionDialog
          transaction={voidTarget}
          onClose={() => setVoidTarget(null)}
        />
      )}
    </>
  )
}
