import { AppNav } from '@/components/layout/app-nav'
import { MobileActionBarData } from '@/components/mobile/action-bar-data'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import { createClient } from '@/lib/supabase/server'
import { ToastProvider } from '@/components/ui/toast'

// Layout لمساحة العمل المحمية (لوحة التحكم والمشاريع).
// التنقل الموحد (سايدبار ديسكتوب + شريط سفلي موبايل) وشريط الإجراءات السريع
// موجودان هنا فقط، وليسا في صفحة الدخول العامة.
export default async function WorkspaceLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  let userRole = 'manager'
  if (user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    userRole = profile?.role ?? 'manager'
  }

  return (
    <ToastProvider>
      <div className="min-h-screen pb-[calc(7.75rem+env(safe-area-inset-bottom))] lg:ps-64 lg:pb-28">
        <WorkspaceHeader />
        {children}
        <AppNav userRole={userRole} />
        <MobileActionBarData userRole={userRole} />
      </div>
    </ToastProvider>
  )
}