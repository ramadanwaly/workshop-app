import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { safeNextPath } from '@/lib/safe-redirect'

// ----------------------------------------------------------------------------
// مسار استقبال الرابط السحري: Supabase يرسل ?code= هنا بعد فتح الرابط من البريد
// نستبدل الرمز بجلسة حقيقية ثم نعيد التوجيه للوحة التحكم
// ----------------------------------------------------------------------------
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl
  const code = searchParams.get('code')
  const type = searchParams.get('type')
  const next =
    type === 'recovery' ? '/auth/update-password' : safeNextPath(searchParams.get('next'))

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }
    console.error('[auth] فشل تبادل رمز الجلسة:', error.message)
  }

  return NextResponse.redirect(`${origin}/login?error=auth`)
}