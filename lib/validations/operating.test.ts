import { describe, it, expect } from 'vitest'
import {
    runOperatingAllocationSchema,
    voidAllocationCycleSchema,
    voidAllocationLineSchema,
    addOperatingExclusionSchema,
    removeOperatingExclusionSchema,
} from './operating'

const KEY = '11111111-1111-4111-8111-111111111126'

const validRun = { yearMonth: '2026-08', idempotencyKey: KEY }

describe('operating allocation validations', () => {
    it('accepts a valid manual-run input', () => {
        expect(runOperatingAllocationSchema.safeParse(validRun).success).toBe(true)
    })
    it('rejects a malformed yearMonth', () => {
        for (const bad of ['2026-8', '08-2026', '2026-13', 'abc', '']) {
            expect(runOperatingAllocationSchema.safeParse({ ...validRun, yearMonth: bad }).success).toBe(false)
        }
    })
    it('rejects a short idempotency key', () => {
        expect(runOperatingAllocationSchema.safeParse({ ...validRun, idempotencyKey: 'short' }).success).toBe(false)
    })
    it('voidAllocationCycleSchema requires a uuid cycle id + long reason', () => {
        const base = { reason: 'خطأ في التوزيع', idempotencyKey: KEY }
        expect(voidAllocationCycleSchema.safeParse({ ...base, cycleId: 'not-a-uuid' }).success).toBe(false)
        expect(voidAllocationCycleSchema.safeParse({ ...base, cycleId: crypto.randomUUID() }).success).toBe(true)
        expect(voidAllocationCycleSchema.safeParse({ ...base, cycleId: crypto.randomUUID(), reason: 'ab' }).success).toBe(false)
    })
    it('voidAllocationLineSchema mirrors void-cycle rules', () => {
        const base = { reason: 'سطر خاطئ', idempotencyKey: KEY }
        expect(voidAllocationLineSchema.safeParse({ ...base, adjustmentId: crypto.randomUUID() }).success).toBe(true)
    })
    it('add/remove exclusion accept a valid project/month and reject bad uuids', () => {
        const base = { yearMonth: '2026-08', idempotencyKey: KEY }
        expect(addOperatingExclusionSchema.safeParse({ ...base, projectId: crypto.randomUUID() }).success).toBe(true)
        expect(removeOperatingExclusionSchema.safeParse({ ...base, projectId: 'x', reason: 'عاد للمشاركة' }).success).toBe(false)
    })
    it('remove exclusion requires a reason', () => {
        const base = { yearMonth: '2026-08', projectId: crypto.randomUUID(), idempotencyKey: KEY }
        expect(removeOperatingExclusionSchema.safeParse({ ...base, reason: 'عاد للمشاركة' }).success).toBe(true)
        expect(removeOperatingExclusionSchema.safeParse(base).success).toBe(false)
    })
    it('rejects an overlong void reason', () => {
        const base = { cycleId: crypto.randomUUID(), idempotencyKey: KEY }
        const r = voidAllocationCycleSchema.safeParse({ ...base, reason: 'x'.repeat(1001) })
        expect(r.success).toBe(false)
    })
})
