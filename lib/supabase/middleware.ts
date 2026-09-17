import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import { Database } from '@/types/database.types'
import { checkRateLimit, hashId } from '@/lib/rate-limit'

// Security headers applied to every proxied response.
// The CSP allows only same-origin assets plus the Supabase API origin used for
// auth/REST calls; inline styles/scripts are needed by Next.js hydration.
function securityHeaders(): Record<string, string> {
  const supabaseOrigin = (process.env.NEXT_PUBLIC_SUPABASE_URL ?? '')
    .replace(/\/$/, '')
  const connectSrc = supabaseOrigin
    ? `'self' ${supabaseOrigin} ws: wss:`
    : `'self' ws: wss:`
  const evalSrc = process.env.NODE_ENV === 'development' ? " 'unsafe-eval'" : ''
  return {
    'Content-Security-Policy': [
      "default-src 'self'",
      `script-src 'self' 'unsafe-inline' https://static.cloudflareinsights.com${evalSrc}`,
      "style-src 'self' 'unsafe-inline'",
      `img-src 'self' data: blob: ${supabaseOrigin}`,
      "font-src 'self' data:",
      `connect-src ${connectSrc}`,
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join('; '),
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Resource-Policy': 'same-origin',
    'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
  }
}

function applySecurityHeaders(response: NextResponse): NextResponse {
  for (const [name, value] of Object.entries(securityHeaders())) {
    response.headers.set(name, value)
  }
  return response
}

const LOGIN_RATE_MESSAGE =
  'تم تجاوز عدد محاولات الدخول المسموح بها. يرجى الانتظار دقيقة قبل المحاولة مرة أخرى.'

export async function updateSession(request: NextRequest) {
  const { pathname, search } = request.nextUrl

  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 1. Rate Limiting مشترك (جدول القاعدة) لطلبات POST على /login (ضد التخمين)
  if (request.method === 'POST' && pathname === '/login') {
    const ip =
      (request as NextRequest & { ip?: string }).ip ||
      request.headers.get('x-forwarded-for')?.split(',').pop()?.trim() ||
      '127.0.0.1'
    const rl = await checkRateLimit(supabase, `login:${hashId(ip)}`, 5)
    if (!rl.allowed) {
      const blocked = applySecurityHeaders(
        NextResponse.json({ error: LOGIN_RATE_MESSAGE }, { status: 429 })
      )
      blocked.headers.set('Retry-After', String(Math.max(1, rl.retryAfter)))
      return blocked
    }
  }

  // تجديد الجلسة والتحقق من هوية المستخدم
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // المسارات العامة: صفحة الدخول، مسار استقبال الرابط السحري، ومعرض الأعمال
  const isPublicPath = pathname === '/login' || pathname.startsWith('/auth') || pathname === '/gallery'

  // زائر غير مسجل يحاول الوصول لصفحة محمية => توجيه لصفحة الدخول
  if (!user && !isPublicPath) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.search = ''
    loginUrl.searchParams.set('next', pathname + search)
    return applySecurityHeaders(NextResponse.redirect(loginUrl))
  }

  // مستخدم مسجل يفتح صفحة الدخول => توجيه للوحة التحكم
  if (user && pathname === '/login') {
    const dashboardUrl = request.nextUrl.clone()
    dashboardUrl.pathname = '/dashboard'
    dashboardUrl.search = ''
    return applySecurityHeaders(NextResponse.redirect(dashboardUrl))
  }

  return applySecurityHeaders(supabaseResponse)
}
