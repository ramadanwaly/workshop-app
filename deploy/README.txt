# ✅ دليل تشغيل وإدارة برنامج الورشة (Operational Runbook)

برنامج إدارة الورشة والمحاسبة — دليل شامل للبيئات الإنتاجية وإرشادات الأمان والصيانة.

---

## قبل البدء: متطلبات البيئة

1. **خادم إنتاجي** يعمل عليه Docker و Docker Compose.
2. **مشروع Supabase** مفصّل ومهيّأ (Supabase Cloud أو Self-hosted).
3. **نطاق عام مؤمّن برمز SSL/TLS (HTTPS)** خلف بروكسي عاكس مثل Nginx أو Cloudflare.

---

## الخطوة 1: إعداد متغيرات البيئة (`.env.production`)

قم بتجهيز متغيرات البيئة المطلوبة للأمان:

```dotenv
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-public-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-private-service-role-key
NEXT_PUBLIC_SITE_URL=https://workshop.example.com
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

> 🚨 **تنبيه أمني صارم**:
> - لا تضف `NEXT_PUBLIC_` على `SUPABASE_SERVICE_ROLE_KEY`. هذا المفتاح محمي بنطاق `server-only`.
> - يجب أن تطابق قيمة `NEXT_PUBLIC_SITE_URL` النطاق الفعلي لمنع ثغرات Host Header Injection.

---

## الخطوة 2: تشغيل الحاوية عبر Docker

```bash
cd deploy
./start.sh
```

أو عبر Docker Compose مباشرة:

```bash
docker compose up -d --build
```

---

## المراقبة وفحوص الجاهزية (Health Checks)

يوفر التطبيق نقطتي فحص محماة ومصممة لنظم المراقبة والـ Load Balancers:

1. **فحص سلامة الخدمة الخفيفة**:
   - GET `/api/health`
   - يفحص الاتصال بقاعدة البيانات وحالة المعالج والـ uptime.

2. **فحص اكتمال الهيكل والهجرات**:
   - GET `/api/health/schema`
   - يستدعي الدالة الأمنية `rpc_health_schema_check()` للتأكد من تطبيق كافة الهجرات بنجاح.

3. **فحص اكتمال سياسات RLS**:
   - عبر SQL أو Supabase Client للمالك: `SELECT public.rpc_check_rls_completeness();`
   - يتحقق من تفعيل سياسات Row-Level Security على 100% من جداول القاعدة العامة.

---

## قواعد الهجرات والصيانة (Database Migrations)

- **القاعدة الذهبية**: جميع ملفات الهجرة في `supabase/migrations/*.sql` هي **Append-Only** (ممنوع تعديل أي ملف هجرة قديم بعد تطبيقه).
- **فحص الدخان المالي والتحقق من الهيكل**:
  ```bash
  psql -v ON_ERROR_STOP=1 -f supabase/verify_smoke.sql
  ```
- **فحص الصلابة في CI**:
  ```bash
  npm run check
  ```

---

## سجل الأخطاء والمراقبة المركزية (Sentry & Logging)

- يتم تسجيل جميع الأخطاء المالية والتشغيلية في صورة JSON منتظم مع حجب تلقائي للكلمات السرية والمفاتيح (Sanitization).
- عند تفعيل `SENTRY_DSN` أو `NEXT_PUBLIC_SENTRY_DSN` يتم إرسال الاستثناءات غير المعالجة تلقائياً إلى Sentry مع معرفات الحوادث (Request IDs).

---

## أوامر التشغيل والصيانة اليومية

| العملية | الأمر |
|---------|-------|
| تشغيل وبناء | `./start.sh` |
| إيقاف الخدمة | `./start.sh stop` |
| عرض السجلات الحية | `docker compose logs -f --tail=100` |
| فحص الصلابة الشامل | `npm run check` |
| فحص الهجرات | `psql -f supabase/verify_smoke.sql` |
