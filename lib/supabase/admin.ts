import { createClient } from '@supabase/supabase-js'
import { Database } from '@/types/database.types'

export function createAdminClient() {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!serviceRoleKey) {
    throw new Error('متغير SUPABASE_SERVICE_ROLE_KEY غير مضبوط على الخادم')
  }
  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}
