'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import type { FormEvent } from 'react'
import { recordExpense } from '@/actions/treasury'
import type { RecordExpenseInput } from '@/lib/validations/treasury'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { DialogShell } from './dialog-shell'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'

const EXPENSE_CATEGORIES = [
  { value: 'material', label: 'مواد' },
  { value: 'freight', label: 'شحن' },
  { value: 'workshop_operating', label: 'مصاريف تشغيل' },
  { value: 'general_expense', label: 'مصروف عام' },
  { value: 'other', label: 'أخرى' },
] as const satisfies ReadonlyArray<{
  value: RecordExpenseInput['category']
  label: string
}>

const SUBCATEGORY_OPTIONS: Record<string, Array<{ value: string; label: string }>> = {
  material: [
    { value: 'wood_boards', label: 'خشب وألواح' },
    { value: 'upholstery_fabric_textile', label: 'أقمشة وجلود تنجيد' },
    { value: 'foam_filling', label: 'إسفنج وحشو' },
    { value: 'hardware_hinges', label: 'إكسسوارات ومفصلات' },
    { value: 'glue_adhesives', label: 'غراء ومواد لصق' },
    { value: 'paints_varnishes', label: 'دهانات وورنيش' },
    { value: 'glass_mirrors', label: 'زجاج ومرايا' },
    { value: 'small_fasteners', label: 'مسامير وبراغي وخامات صغيرة' },
    { value: 'consumables_tools', label: 'أدوات ومعدات استهلاكية' },
    { value: 'machine_maintenance', label: 'صيانة ماكينات' },
  ],
  freight: [
    { value: 'site_transport', label: 'مواصلات من وإلى الموقع' },
    { value: 'merchant_transport', label: 'نقل من التاجر للورشة' },
    { value: 'workshop_machine_transport', label: 'نقل من الورشة للمكنة والعكس' },
    { value: 'tools_site_transport', label: 'نقل العدة للموقع والعكس' },
    { value: 'completed_work_transport', label: 'نقل الشغل المكتمل للموقع' },
  ],
  workshop_operating: [
    { value: 'electricity', label: 'كهرباء' },
    { value: 'rent', label: 'إيجار' },
    { value: 'waste_collection', label: 'جمع نفايات' },
  ],
}

type SelectOption = { id: string; name: string }

type ExpenseDialogProps = {
  projects: SelectOption[]
  onClose: () => void
}

export function ExpenseDialog({ projects, onClose }: ExpenseDialogProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [category, setCategory] = useState<RecordExpenseInput['category']>(
    'general_expense'
  )
  const [projectId, setProjectId] = useState('')
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [subcategory, setSubcategory] = useState('')
  const [idempotencyKey] = useState(() => generateIdempotencyKey())

  function handleCategoryChange(next: RecordExpenseInput['category']) {
    setCategory(next)
    setSubcategory('')
    if (next === 'workshop_operating') setProjectId('')
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    const parsedAmount = amount.trim() === '' ? NaN : Number(amount)

    startTransition(async () => {
      const result = await recordExpense({
        category,
        amount: parsedAmount,
        projectId: projectId === '' ? null : projectId,
        description: description.trim() === '' ? undefined : description.trim(),
        subcategory: subcategory === '' ? null : subcategory,
        isDirectOwnerPayment: false,
        idempotencyKey,
      })
      if (result.success) {
        router.refresh()
        onClose()
      } else {
        setError(result.error ?? 'حدث خطأ غير متوقع')
      }
    })
  }

  return (
    <DialogShell title="تسجيل مصروف" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label htmlFor="expense-amount" className="mb-2 block">
            المبلغ (جنيه)
          </Label>
          <Input
            id="expense-amount"
            type="number"
            inputMode="decimal"
            step="0.01"
            min="0"
            required
            autoFocus
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            placeholder="0.00"
          />
        </div>

        <div>
          <Label htmlFor="expense-category" className="mb-2 block">
            التصنيف
          </Label>
          <Select
            id="expense-category"
            value={category}
            onChange={(event) =>
              handleCategoryChange(event.target.value as RecordExpenseInput['category'])
            }
          >
            {EXPENSE_CATEGORIES.map((entry) => (
              <option key={entry.value} value={entry.value}>
                {entry.label}
              </option>
            ))}
          </Select>
        </div>

        {SUBCATEGORY_OPTIONS[category] && (
          <div>
            <Label htmlFor="expense-subcategory" className="mb-2 block">
              التصنيف الفرعي
            </Label>
            <Select
              id="expense-subcategory"
              value={subcategory}
              onChange={(event) => setSubcategory(event.target.value)}
              required
            >
              <option value="">اختر التصنيف الفرعي</option>
              {SUBCATEGORY_OPTIONS[category].map((entry) => (
                <option key={entry.value} value={entry.value}>{entry.label}</option>
              ))}
            </Select>
          </div>
        )}

        {category !== 'workshop_operating' && (
        <div>
          <Label htmlFor="expense-project" className="mb-2 block">
            المشروع (اختياري)
          </Label>
          <Select
            id="expense-project"
            value={projectId}
            onChange={(event) => setProjectId(event.target.value)}
          >
            <option value="">بدون مشروع</option>
            {projects.map((project) => (
              <option key={project.id} value={project.id}>
                {project.name}
              </option>
            ))}
          </Select>
        </div>
        )}

        <div>
          <Label htmlFor="expense-description" className="mb-2 block">
            الوصف (اختياري)
          </Label>
          <Input
            id="expense-description"
            type="text"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="مثال: شراء خشب للباب"
          />
        </div>

        {error && (
          <p
            role="alert"
            className="rounded-xl border border-danger/40 bg-danger/10 p-3 text-sm font-semibold text-danger"
          >
            {error}
          </p>
        )}

        <Button
          type="submit"
          disabled={isPending}
          className="w-full"
        >
          {isPending ? 'جارٍ الحفظ…' : 'حفظ المصروف'}
        </Button>
      </form>
    </DialogShell>
  )
}