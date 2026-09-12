import { createClient } from '@/lib/supabase/server'
import { WorkspaceHeader } from '@/components/layout/workspace-header'
import { getSettings, getProfiles } from '@/actions/settings'
import { OverheadForm } from '@/components/settings/overhead-form'
import { UserList } from '@/components/settings/user-list'

export default async function SettingsPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return (
      <main className="min-h-screen p-8">
        <h1 className="mb-4 text-2xl font-bold text-danger">غير مصرح</h1>
        <p className="text-secondary">يرجى تسجيل الدخول للوصول إلى صفحة الإعدادات.</p>
      </main>
    )
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'owner') {
    return (
      <main className="min-h-screen p-8">
        <h1 className="mb-4 text-2xl font-bold text-danger">غير مصرح</h1>
        <p className="text-secondary">صفحة الإعدادات مخصصة لمالك الورشة فقط.</p>
      </main>
    )
  }

  let settings = { overhead_percentage: 10.0 }
  let profiles: Awaited<ReturnType<typeof getProfiles>> = []

  try {
    const [settingsData, profilesData] = await Promise.all([
      getSettings(),
      getProfiles(),
    ])
    settings = settingsData
    profiles = profilesData
  } catch (err) {
    console.error('[settings] فشل تحميل بيانات الإعدادات:', err)
  }

  return (
    <main className="min-h-screen">
      <WorkspaceHeader />

      <div className="mx-auto max-w-5xl px-4 py-6 sm:px-6 sm:py-8 space-y-6">
        <div>
          <h1 className="text-xl font-bold text-ink sm:text-2xl">إعدادات النظام والتحكم</h1>
          <p className="mt-1 text-sm text-secondary">
            إدارة نسبة الأوفر هيد ومستجدي المستخدمين (للمالك فقط)
          </p>
        </div>

        <OverheadForm initialOverheadPercentage={Number(settings.overhead_percentage ?? 10)} />

        <UserList profiles={profiles} />
      </div>
    </main>
  )
}
