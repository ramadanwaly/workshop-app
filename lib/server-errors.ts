// Error masking for financial actions.
//
// Principle: the client only ever sees intentional, human-safe messages.
// Internal details (Postgres/Supabase errors, stack traces, table/constraint
// names) are logged server-side and never shipped to the browser.
//
// What DOES reach the client untouched:
//   - Zod validation messages (client-controlled input)
//   - Business rejection messages raised deliberately inside the secure RPCs
//     via RAISE EXCEPTION (Postgres code P0001) — these are authored Arabic text.
// Everything else is masked to a generic message while its full detail is logged.

import { logError, logWarn } from '@/lib/logger'
import type { PostgrestError } from '@supabase/supabase-js'
import { IdempotencyError } from '@/lib/supabase/idempotency'

export const GENERIC_ERROR_MESSAGE = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى لاحقاً'

/** Raise PostgreSQL/supabase business error deliberately from secure RPC. */
export function isBusinessError(error: { code?: string; message?: string } | null | undefined): boolean {
  return error?.code === 'P0001' && typeof error.message === 'string'
}

/**
 * Log the full internal error and return the generic client-safe message.
 * Use inside `catch` blocks of financial actions.
 */
export function maskAndLogError(action: string, err: unknown): string {
  logError(action, err)
  if (err instanceof IdempotencyError) return err.message
  return GENERIC_ERROR_MESSAGE
}

/**
 * Route a supabase-js query/RPC error: intentional RPC business rejections are
 * relayed verbatim; anything else is logged and masked.
 */
export function routeActionError(
  action: string,
  error: PostgrestError | { code?: string; message?: string } | null | undefined
): string {
  if (isBusinessError(error)) {
    logWarn(action, { businessRejection: error?.message })
    return error!.message as string
  }
  return maskAndLogError(action, error)
}

/**
 * Read-path variant: log internally then throw only the generic message, so an
 * upstream error/not-found boundary never renders internal detail either.
 */
export function maskAndThrow(action: string, err: unknown): never {
  logError(action, err)
  throw new Error(GENERIC_ERROR_MESSAGE)
}