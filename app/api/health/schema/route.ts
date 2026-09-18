import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { env } from '@/lib/validations/env'
import { logError } from '@/lib/logger'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    })

    const { data: schemaValid, error } = await supabase.rpc('rpc_health_schema_check' as never)

    if (error || !schemaValid) {
      logError('health_schema_check_failed', error || 'Schema validation returned false')
      return NextResponse.json(
        {
          status: 'degraded',
          schema: 'invalid_or_missing_objects',
          timestamp: new Date().toISOString(),
        },
        { status: 503 }
      )
    }

    return NextResponse.json({
      status: 'ok',
      schema: 'valid',
      timestamp: new Date().toISOString(),
    })
  } catch (err) {
    logError('health_schema_check_error', err)
    return NextResponse.json(
      {
        status: 'degraded',
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    )
  }
}
