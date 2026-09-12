import { type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

export async function proxy(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    /*
     * تطبيق البروكسي على جميع المسارات عدا الملفات الثابتة والصور.
     * ملاحظة: Server Actions تُنفَّذ كطلبات POST على نفس المسار، لذا لا يعتمد
     * أي Server Action على هذه الحماية وحدها — كل إجراء يتحقق من الهوية داخلياً.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
