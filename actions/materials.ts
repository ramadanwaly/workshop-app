'use server'

import { recordExpense } from '@/actions/treasury'
import { type RecordExpenseInput } from '@/lib/validations/treasury'

export async function purchaseMaterial(
  data: Omit<RecordExpenseInput, 'category'>
) {
  return await recordExpense({
    ...data,
    category: 'material',
  })
}
