import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    
    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ status: 'error', message: 'Missing Supabase environment variables' }, { status: 500 });
    }

    // Use a basic client without session persistence for the health check
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false }
    });

    // Check database reachability (even if it returns RLS error, it means the DB is up)
    const { error } = await supabase.from('settings').select('id').limit(1);
    
    // FETCH_ERROR indicates the network request to Supabase failed entirely
    if (error && error.code === 'FETCH_ERROR') {
      console.error('[Health] Database unreachable:', error);
      return NextResponse.json({ 
        status: 'degraded', 
        database: 'unreachable',
        timestamp: new Date().toISOString()
      }, { status: 503 });
    }

    return NextResponse.json({ 
      status: 'ok', 
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (err) {
    console.error('[Health] Check failed:', err);
    return NextResponse.json({ 
      status: 'degraded',
      timestamp: new Date().toISOString()
    }, { status: 503 });
  }
}
