import { z } from 'zod'
import { MAX_12_2, positiveAmount } from './money'
import { idempotencyKeyField, optionalText, reasonField } from './text'

const SUBCATEGORY_BY_CATEGORY: Record<string, string[]> = {
    material: [
        'wood_boards', 'upholstery_fabric_textile', 'foam_filling', 'hardware_hinges',
        'glue_adhesives', 'paints_varnishes', 'glass_mirrors', 'small_fasteners',
        'consumables_tools', 'machine_maintenance',
    ],
    freight: [
        'site_transport', 'merchant_transport', 'workshop_machine_transport',
        'tools_site_transport', 'completed_work_transport',
    ],
    workshop_operating: ['electricity', 'rent', 'waste_collection'],
}

export const injectFundingSchema = z.object({
    amount: positiveAmount({
        notNumber: 'المبلغ يجب أن يكون رقماً',
        notFinite: 'المبلغ غير صالح',
        tooSmall: 'المبلغ يجب أن يكون أكبر من صفر',
        max: MAX_12_2,
    }),
                                            description: optionalText(1000, 'الوصف طويل جداً'),
                                            idempotencyKey: idempotencyKeyField,
})

export const recordExpenseSchema = z.object({
    category: z.enum(
        ['material', 'freight', 'general_expense', 'other', 'workshop_operating'],
        { error: 'تصنيف المصروف غير صالح' }
    ),
    subcategory: z.string().trim().optional().nullable(),
    amount: positiveAmount({
        notNumber: 'المبلغ يجب أن يكون رقماً',
        notFinite: 'المبلغ غير صالح',
        tooSmall: 'المبلغ يجب أن يكون أكبر من صفر',
        max: MAX_12_2,
    }),
                                            description: optionalText(1000, 'الوصف طويل جداً'),
                                            projectId: z.string().uuid('معرف المشروع غير صالح').optional().nullable(),
                                            isDirectOwnerPayment: z.boolean().default(false),
                                            idempotencyKey: idempotencyKeyField,
}).superRefine((value, ctx) => {
    const allowed = SUBCATEGORY_BY_CATEGORY[value.category]
    if (allowed) {
        if (!value.subcategory) {
            ctx.addIssue({ code: 'custom', message: 'التصنيف الفرعي مطلوب لهذا التصنيف' })
        } else if (!allowed.includes(value.subcategory)) {
            ctx.addIssue({ code: 'custom', message: 'التصنيف الفرعي غير صالح لهذا التصنيف' })
        }
    }
    if (value.category === 'workshop_operating' && value.projectId) {
        ctx.addIssue({ code: 'custom', message: 'مصاريف تشغيل الورشة لا ترتبط بمشروع محدد' })
    }
    if (value.isDirectOwnerPayment && !value.projectId) {
        ctx.addIssue({ code: 'custom', message: 'المدفوعات المباشرة من المالك يجب أن ترتبط بمشروع محدد لزيادة تكلفته' })
    }
})

export const voidTransactionSchema = z.object({
    transactionId: z.string().uuid('معرف الحركة غير صالح'),
    reason: reasonField(),
    idempotencyKey: idempotencyKeyField,
})

export type InjectFundingInput = z.infer<typeof injectFundingSchema>
export type RecordExpenseInput = z.infer<typeof recordExpenseSchema>
export type VoidTransactionInput = z.infer<typeof voidTransactionSchema>
