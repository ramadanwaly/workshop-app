// Structured, sanitized server-side logger for financial actions.
// Never emits secrets: known secret-bearing keys are redacted before logging.
// Output is a single JSON line per event prefixed `[app]` for greppability.

const REDACT_KEYS = /(password|passwd|secret|token|jwt|api[_-]?key|authorization|cookie|supabase_)/i
const MAX_DEPTH = 5

type LogDetail = Record<string, unknown> | string | Error | unknown

function sanitize(value: unknown, depth = 0): unknown {
  if (depth > MAX_DEPTH) return '[max-depth]'
  if (value instanceof Error) {
    return { name: value.name, message: value.message, stack: value.stack }
  }
  if (Array.isArray(value)) {
    return value.map((v) => sanitize(v, depth + 1))
  }
  if (value !== null && typeof value === 'object' && !(value instanceof Date)) {
    const out: Record<string, unknown> = {}
    for (const [key, v] of Object.entries(value as Record<string, unknown>)) {
      if (typeof v === 'string' && REDACT_KEYS.test(key)) {
        out[key] = '[REDACTED]'
      } else {
        out[key] = sanitize(v, depth + 1)
      }
    }
    return out
  }
  return value
}

function write(level: 'info' | 'warn' | 'error', action: string, detail: LogDetail): void {
  const entry: Record<string, unknown> = {
    ts: new Date().toISOString(),
    level,
    action,
  }
  if (typeof detail === 'string') {
    entry.message = detail
  } else {
    Object.assign(entry, sanitize(detail) as Record<string, unknown>)
  }
  // Server-side structured logging sink.
  console.error(`[app] ${JSON.stringify(entry)}`)
}

export function logInfo(action: string, detail: LogDetail): void {
  write('info', action, detail)
}

export function logWarn(action: string, detail: LogDetail): void {
  write('warn', action, detail)
}

export function logError(action: string, detail: LogDetail): void {
  write('error', action, detail)
}

export const LOGGER = { info: logInfo, warn: logWarn, error: logError }