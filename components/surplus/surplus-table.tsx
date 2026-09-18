'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { formatCurrency, formatDate } from '@/lib/format'
import dynamic from 'next/dynamic'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const ConsumeDialog = dynamic(() => import('./consume-dialog').then(mod => mod.ConsumeDialog))
const ScrapDialog = dynamic(() => import('./scrap-dialog').then(mod => mod.ScrapDialog))
const SurplusDialog = dynamic(() => import('@/components/mobile/surplus-dialog').then(mod => mod.SurplusDialog))

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
  const [searchQuery, setSearchQuery] = useState('')

  const q = searchQuery.toLowerCase()
  const filteredItems = items.filter((item) =>
    !q ||
    item.material_name.toLowerCase().includes(q) ||
    (item.notes || '').toLowerCase().includes(q) ||
    (item.source_project?.name || '').toLowerCase().includes(q) ||
    formatDate(item.created_at).includes(q)
  )

  return (
    <>
      <div className="mb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="flex items-center gap-4 w-full sm:w-auto">
          <p className="text-sm font-semibold text-muted-foreground whitespace-nowrap">
            عدد العناصر: <span className="font-bold text-foreground">{filteredItems.length}</span>
          </p>
          <Input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="بحث في العناصر..."
            className="w-full sm:w-64"
          />
        </div>

        <Button
          onClick={() => setIsReturnOpen(true)}
          className="gap-2"
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
        </Button>
      </div>

      {items.length === 0 ? (
        <div className="rounded-md border border-dashed border-border bg-card p-10 text-center">
          <p className="text-muted-foreground">
            {currentStatus === 'available'
              ? 'لا توجد مواد فائضة متاحة حالياً.'
              : currentStatus === 'consumed'
                ? 'لا توجد مواد مستهلكة مسجلة.'
                : 'لا توجد مواد متلفة مسجلة.'}
          </p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-md border border-border bg-card shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-end text-sm">
              <thead className="border-b border-border bg-muted/50 text-xs font-semibold text-muted-foreground">
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
              <tbody className="divide-y divide-border text-foreground">
                {filteredItems.map((item) => (
                  <tr key={item.id} className="transition hover:bg-muted/50">
                    {/* اسم المادة */}
                    <td className="px-4 py-3.5 text-start font-bold text-primary">
                      {item.material_name}
                    </td>

                    {/* الوحدة */}
                    <td className="px-4 py-3.5 text-center text-muted-foreground">
                      {item.unit}
                    </td>

                    {/* الكمية */}
                    <td className="px-4 py-3.5 text-center font-semibold tabular-nums text-foreground">
                      {item.quantity}
                      {currentStatus === 'consumed' && item.initial_quantity > item.quantity && (
                        <span className="block text-[11px] font-normal text-muted-foreground">
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
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>

                    {/* التاريخ */}
                    <td className="whitespace-nowrap px-4 py-3.5 text-center text-xs text-muted-foreground">
                      {formatDate(item.created_at)}
                    </td>

                    {/* ملاحظات */}
                    <td className="max-w-xs truncate px-4 py-3.5 text-start text-xs text-muted-foreground">
                      {item.notes || '—'}
                    </td>

                    {/* الأزرار / الإجراءات */}
                    {currentStatus === 'available' && (
                      <td className="whitespace-nowrap px-4 py-3.5 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => setConsumeItem(item)}
                            className="bg-accent/15 text-accent hover:bg-accent/25"
                          >
                            استهلاك
                          </Button>
                          <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => setScrapItem(item)}
                            className="bg-danger/15 text-danger hover:bg-danger/25"
                          >
                            إتلاف
                          </Button>
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
