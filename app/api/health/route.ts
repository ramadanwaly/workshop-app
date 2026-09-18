import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { env } from '@/lib/validations/env'
import { logError } from '@/lib/logger'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    // Use a basic client without session persistence for the health check
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    })

    // 1. Check database reachability (even if it returns RLS error, it means the DB is up)
    const { error: settingsError } = await supabase.from('settings').select('id').limit(1)

    // FETCH_ERROR indicates the network request to Supabase failed entirely
    if (settingsError && settingsError.code === 'FETCH_ERROR') {
      logError('health_check_failed', settingsError)
      return NextResponse.json(
        {
          status: 'degraded',
          database: 'unreachable',
          timestamp: new Date().toISOString(),
        },
        { status: 503 }
      )
    }

    return NextResponse.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.floor(process.uptime()),
    })
  } catch (err) {
    logError('health_check_error', err)
    return NextResponse.json(
      {
        status: 'degraded',
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    )
  }
}
