'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { formatCurrency, formatDate } from '@/lib/format'
import { ConsumeDialog } from './consume-dialog'
import { ScrapDialog } from './scrap-dialog'
import { SurplusDialog } from '@/components/mobile/surplus-dialog'

export type SurplusRecord = {
  id: string
  material_name: string
  unit: string
  quantity: number
  initial_quantity: number
  estimated_value: number
  source_project_id: string
  status: 'available' | 'consumed' | 'scrapped'
  notes: string | null
  created_at: string
  source_project?: {
    id: string
    name: string
  } | null
}

type ProjectOption = {
  id: string
  name: string
}

type SurplusTableProps = {
  items: SurplusRecord[]
  projects: ProjectOption[]
  currentStatus: 'available' | 'consumed' | 'scrapped'
}

export function SurplusTable({ items, projects, currentStatus }: SurplusTableProps) {
  const router = useRouter()
  const [consumeItem, setConsumeItem] = useState<SurplusRecord | null>(null)
  const [scrapItem, setScrapItem] = useState<SurplusRecord | null>(null)
  const [isReturnOpen, setIsReturnOpen] = useState(false)

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm font-semibold text-secondary">
          عدد العناصر: <span className="font-bold text-ink">{items.length}</span>
        </p>

        <button
          type="button"
          onClick={() => setIsReturnOpen(true)}
          className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-background transition hover:bg-primary/90"
        >
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="h-4 w-4"
          >
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          إرجاع فائض جديد
        </button>
      </div>

      {items.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-secondary/40 bg-white p-10 text-center">
          <p className="text-secondary">
            {currentStatus === 'available'
              ? 'لا توجد مواد فائضة متاحة حالياً.'
              : currentStatus === 'consumed'
                ? 'لا توجد مواد مستهلكة مسجلة.'
                : 'لا توجد مواد متلفة مسجلة.'}
          </p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-secondary/30 bg-white shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-end text-sm">
              <thead className="border-b border-secondary/20 bg-background/60 text-xs font-semibold text-secondary">
                <tr>
                  <th className="px-4 py-3.5 text-start">المادة</th>
                  <th className="px-4 py-3.5 text-center">الوحدة</th>
                  <th className="px-4 py-3.5 text-center">الكمية</th>
                  <th className="px-4 py-3.5 text-center">القيمة التقديرية</th>
                  <th className="px-4 py-3.5 text-start">المشروع المصدر</th>
                  <th className="px-4 py-3.5 text-center">التاريخ</th>
                  <th className="px-4 py-3.5 text-start">ملاحظات</th>
                  {currentStatus === 'available' && (
                    <th className="px-4 py-3.5 text-center">الإجراءات</th>
                  )}
                </tr>
              </thead>
              <tbody className="divide-y divide-secondary/15 text-ink">
                {items.map((item) => (
                  <tr key={item.id} className="transition hover:bg-background/30">
                    {/* اسم المادة */}
                    <td className="px-4 py-3.5 text-start font-bold text-primary">
                      {item.material_name}
                    </td>

                    {/* الوحدة */}
                    <td className="px-4 py-3.5 text-center text-secondary">
                      {item.unit}
                    </td>

                    {/* الكمية */}
                    <td className="px-4 py-3.5 text-center font-semibold tabular-nums text-ink">
                      {item.quantity}
                      {currentStatus === 'consumed' && item.initial_quantity > item.quantity && (
                        <span className="block text-[11px] font-normal text-secondary">
                          (من {item.initial_quantity})
                        </span>
                      )}
                    </td>

                    {/* القيمة التقديرية */}
                    <td className="px-4 py-3.5 text-center font-bold tabular-nums text-accent">
                      {formatCurrency(item.estimated_value)}
                    </td>

                    {/* المشروع المصدر */}
                    <td className="px-4 py-3.5 text-start">
                      {item.source_project ? (
                        <Link
                          href={`/projects/${item.source_project.id}`}
                          className="font-semibold text-primary hover:underline hover:text-accent"
                        >
                          {item.source_project.name}
                        </Link>
                      ) : (
                        <span className="text-secondary">—</span>
                      )}
                    </td>

                    {/* التاريخ */}
                    <td className="whitespace-nowrap px-4 py-3.5 text-center text-xs text-secondary">
                      {formatDate(item.created_at)}
                    </td>

                    {/* ملاحظات */}
                    <td className="max-w-xs truncate px-4 py-3.5 text-start text-xs text-secondary">
                      {item.notes || '—'}
                    </td>

                    {/* الأزرار / الإجراءات */}
                    {currentStatus === 'available' && (
                      <td className="whitespace-nowrap px-4 py-3.5 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            type="button"
                            onClick={() => setConsumeItem(item)}
                            className="inline-flex items-center gap-1 rounded-xl bg-accent/15 px-3 py-1.5 text-xs font-bold text-accent transition hover:bg-accent/25"
                          >
                            استهلاك
                          </button>
                          <button
                            type="button"
                            onClick={() => setScrapItem(item)}
                            className="inline-flex items-center gap-1 rounded-xl bg-danger/15 px-3 py-1.5 text-xs font-bold text-danger transition hover:bg-danger/25"
                          >
                            إتلاف
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* حوار استهلاك الفائض */}
      {consumeItem && (
        <ConsumeDialog
          item={consumeItem}
          projects={projects}
          onClose={() => setConsumeItem(null)}
        />
      )}

      {/* حوار إتلاف الفائض */}
      {scrapItem && (
        <ScrapDialog item={scrapItem} onClose={() => setScrapItem(null)} />
      )}

      {/* حوار إرجاع فائض جديد */}
      {isReturnOpen && (
        <SurplusDialog
          projects={projects}
          onClose={() => {
            setIsReturnOpen(false)
            router.refresh()
          }}
        />
      )}
    </>
  )
}
