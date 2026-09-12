import { getProjects } from '@/actions/projects'
import { getWorkers } from '@/actions/labor'
import { MobileActionBar } from './action-bar'

// مكوّن خادم (Server Component): يجلب بيانات القوائم ويعرض شريط الإجراءات
// العمليات المالية تبقى موثوقة في الخادم؛ هذه القوائم لعرض البيانات فقط.
export async function MobileActionBarData() {
  const [projects, workersResult] = await Promise.all([getProjects(), getWorkers({ perPage: 200 })])
  const workers = ((workersResult?.rows ?? []) as Array<{ id: string; name: string }>).map((w) => ({
    id: w.id,
    name: w.name,
  }))
  return <MobileActionBar projects={projects ?? []} workers={workers} />
}