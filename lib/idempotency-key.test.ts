import { describe, expect, it } from 'vitest'
import { generateIdempotencyKey } from './idempotency-key'

const UUID_V4_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

describe('generateIdempotencyKey', () => {
  it('returns a UUID v4 string', () => {
    const key = generateIdempotencyKey()
    expect(key).toMatch(UUID_V4_REGEX)
  })

  it('produces keys long enough for the schema minimum (10 chars)', () => {
    expect(generateIdempotencyKey().length).toBeGreaterThanOrEqual(10)
  })

  it('produces a unique key on every call', () => {
    const a = generateIdempotencyKey()
    const b = generateIdempotencyKey()
    const c = generateIdempotencyKey()
    expect(a).not.toBe(b)
    expect(b).not.toBe(c)
    expect(a).not.toBe(c)
  })
})