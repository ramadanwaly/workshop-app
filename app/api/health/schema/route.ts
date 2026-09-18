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

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false }
    });

    const { data: schemaValid, error } = await supabase.rpc('rpc_health_schema_check' as never);

    if (error || !schemaValid) {
      console.error('[Health/Schema] Check failed:', error || 'Schema validation returned false');
      return NextResponse.json({ 
        status: 'degraded', 
        schema: 'invalid_or_missing_objects',
        timestamp: new Date().toISOString()
      }, { status: 503 });
    }

    return NextResponse.json({ 
      status: 'ok', 
      schema: 'valid',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('[Health/Schema] Check failed:', err);
    return NextResponse.json({ 
      status: 'degraded',
      timestamp: new Date().toISOString()
    }, { status: 503 });
  }
}
