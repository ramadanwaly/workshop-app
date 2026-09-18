// Centralized Error Monitoring abstraction (Sentry support).
// When SENTRY_DSN or NEXT_PUBLIC_SENTRY_DSN is configured in environment,
// errors are forwarded to Sentry for server-side and client-side monitoring.
//
// Server-side: relies on @sentry/node being initialized externally (e.g. via
// instrumentation.ts or sentry.server.config.ts). If @sentry/node is installed
// and initialized, errors will be captured. Otherwise this is a no-op.
//
// Client-side: relies on window.Sentry being available (loaded via script tag
// or @sentry/nextjs client SDK).

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _sentryNodeModule: any = undefined

async function getSentryNode() {
  if (_sentryNodeModule !== undefined) return _sentryNodeModule
  try {
    // @ts-expect-error - dynamic import for optional dependency
    _sentryNodeModule = await import(/* webpackIgnore: true */ '@sentry/node')
    if (_sentryNodeModule && typeof _sentryNodeModule.captureException === 'function') {
      return _sentryNodeModule
    }
  } catch {
    // @sentry/node not installed — expected during development
  }
  _sentryNodeModule = null
  return null
}

export function reportToSentry(action: string, detail: unknown): void {
  const dsn = process.env.SENTRY_DSN || process.env.NEXT_PUBLIC_SENTRY_DSN
  if (!dsn) return

  const errorToReport = detail instanceof Error
    ? detail
    : new Error(typeof detail === 'string' ? detail : JSON.stringify(detail))

  // Server-side: use @sentry/node if available
  if (typeof window === 'undefined') {
    getSentryNode().then((sentry) => {
      if (sentry && typeof sentry.captureException === 'function') {
        sentry.captureException(errorToReport, { extra: { action } })
      }
    }).catch(() => {
      // Silently ignore Sentry relay errors
    })
    return
  }

  // Client-side: use window.Sentry if loaded via script tag
  try {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const win = window as any
    if (win.Sentry && typeof win.Sentry.captureException === 'function') {
      win.Sentry.captureException(errorToReport, { extra: { action } })
    }
  } catch {
    // Silently ignore
  }
}
