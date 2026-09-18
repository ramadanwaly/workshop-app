import 'server-only'
import { createClient } from '@supabase/supabase-js'
import { Database } from '@/types/database.types'
import { env } from '@/lib/validations/env'

export function createAdminClient() {
  const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY
  if (!serviceRoleKey) {
    throw new Error('متغير SUPABASE_SERVICE_ROLE_KEY غير مضبوط على الخادم')
  }
  return createClient<Database>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}
