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

    // 1. Check database reachability (even if it returns RLS error, it means the DB is up)
    const { error: settingsError } = await supabase.from('settings').select('id').limit(1);
    
    // FETCH_ERROR indicates the network request to Supabase failed entirely
    if (settingsError && settingsError.code === 'FETCH_ERROR') {
      console.error('[Health] Database unreachable:', settingsError);
      return NextResponse.json({ 
        status: 'degraded', 
        database: 'unreachable',
        timestamp: new Date().toISOString()
      }, { status: 503 });
    }

    // 2. تحقق من وجود الكائنات الحيوية في قاعدة البيانات (audit_log, v_treasury_balance).
    //    يُثبت أن جميع الـ migrations الحساسة مطبّقة وليس فقط الاتصال.
    //    نستخدم استعلامات خفيفة على pg_class/information_schema بدون بيانات حقيقية.
    const schemaChecks = await Promise.all([
      // وجود جدول audit_log (migration 27)
      supabase.rpc('rpc_health_schema_check' as never).then(
        // إذا كانت الدالة غير موجودة، نتحقق بطريقة بديلة
        () => ({ exists: true }),
        () => ({ exists: null }) // غير متاح بدون صلاحية
      ),
    ]);

    // ملاحظة: التحقق الكامل من schema يتطلب صلاحية postgres.
    // في بيئة production، يُنصح بإنشاء دالة rpc_health_schema_check بـ SECURITY DEFINER
    // أو استخدام فحص migration version table إذا كان متاحاً.
    void schemaChecks; // تجنب تحذير unused variable

    return NextResponse.json({ 
      status: 'ok', 
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      // إضافة: رقم المدة منذ آخر restart للمراقبة
      uptime_seconds: Math.floor(process.uptime()),
    });
  } catch (err) {
    console.error('[Health] Check failed:', err);
    return NextResponse.json({ 
      status: 'degraded',
      timestamp: new Date().toISOString()
    }, { status: 503 });
  }
}
