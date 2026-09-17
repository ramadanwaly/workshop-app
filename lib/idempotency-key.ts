/**
 * Generates a fresh client-side idempotency key for a submission dialog.
 *
 * The key is generated once per dialog open and reused for every retry of that
 * dialog instance, so a double-submit (or a network retry) of the SAME dialog
 * submission is rejected server-side instead of creating a duplicate record.
 */
export function generateIdempotencyKey(): string {
  return crypto.randomUUID()
}