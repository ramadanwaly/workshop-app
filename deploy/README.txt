# ✅ تشغيل برنامج الورشة

برنامج بسيط لا يحتاج خبرة تقنية — اتبع الخطوات بالترتيب.

---

## قبل ما نبدأ: إيه اللي تحتاجه؟

1. **سيرفر أو كمبيوتر دايم الشغل** عليه Docker و Docker Compose
2. **مشروع Supabase** جاهز (على Supabase Cloud أو مستضاف عندك)
3. **النطاق** اختياري؛ استخدم `http://localhost:3000` للتجربة المحلية

> ملاحظة: هذا الملف يشغّل تطبيق الورشة فقط. تشغيل Supabase ذاتياً يحتاج إعداداً منفصلاً وموارد كافية.

---

## الخطوة 1: تثبيت Docker و Docker Compose

على Ubuntu/Debian، انسخ والصق التالي في الطرفية:

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
```

تأكد أنهما شغالان:

```bash
docker --version
docker compose version
```

---

## الخطوة 2: تجهيز قيم Supabase

من إعدادات مشروع Supabase، احصل على:

- **Project URL** — مثال: `https://your-project.supabase.co`
- **Anon/Public key** — المفتاح العام فقط، وليس `service_role`

إذا كنت تستضيف Supabase بنفسك، استخدم عنوان الـ API الذي يستطيع المتصفح والسيرفر الوصول إليه، وليس عنواناً داخلياً مثل `localhost` عند تشغيل التطبيق على سيرفر بعيد.

---

## الخطوة 3: إعداد ملف `.env`

من داخل مجلد `deploy`، أنشئ الملف تلقائياً لأول مرة:

```bash
cd deploy
./start.sh
```

سيتوقف السكربت ويطلب منك تعديل `.env`. افتحه وضع القيم الصحيحة:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-public-anon-key
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

غيّر `NEXT_PUBLIC_SITE_URL` إلى عنوان الموقع النهائي، مثل `https://workshop.example.com`، عند استخدام نطاق عام.

> لا تضع كلمة مرور قاعدة البيانات أو `SUPABASE_SERVICE_ROLE_KEY` في هذا الملف إلا إذا كان التطبيق يحتاجها فعلاً، ولا تشارك أي مفتاح سري. المفتاح `NEXT_PUBLIC_SUPABASE_ANON_KEY` عام بطبيعته لكنه يجب أن يكون محمياً بسياسات RLS الصحيحة.

---

## الخطوة 4: تشغيل البرنامج

```bash
./start.sh
```

يفتح التطبيق على:

```
http://localhost:3000
```

أو استخدم عنوان IP/النطاق الخاص بالسيرفر.

> يتم تمرير قيم `NEXT_PUBLIC_*` إلى مرحلة البناء لأن Next.js يضمّنها في JavaScript الخاص بالمتصفح. لذلك أعد البناء بعد تغيير هذه القيم.

---

## الخطوة 5: إنشاء أول حساب

أول واحد يسجل حساباً جديداً في البرنامج يصبح **Owner (المالك)** وله كل الصلاحيات.

---

## أوامر تشغيل يومية

نفّذ الأوامر من مجلد `deploy`:

| العملية | الأمر |
|---------|-------|
| تشغيل/بناء | `./start.sh` |
| إيقاف | `./start.sh stop` |
| إعادة تشغيل | `./start.sh restart` |
| مشاهدة الأخطاء | `./start.sh logs` |
| حالة البرنامج | `./start.sh status` |
| تحديث وإعادة بناء | `./start.sh update` |

---

## النشر على الإنترنت (اختياري)

لا تعرّض منفذ التطبيق للعامة مباشرة إذا كان لديك Nginx أو reverse proxy. مثال مبسط:

```bash
sudo apt install nginx certbot python3-certbot-nginx
sudo nano /etc/nginx/sites-available/workshop
```

المحتوى:

```nginx
server {
    server_name workshop.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

فعّل الموقع وأضف SSL:

```bash
sudo ln -s /etc/nginx/sites-available/workshop /etc/nginx/sites-enabled/workshop
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d workshop.example.com
```

بعدها حدّث `NEXT_PUBLIC_SITE_URL` في `.env` إلى نطاق HTTPS ثم نفّذ:

```bash
./start.sh update
```

---

## النسخ الاحتياطي والملاحظات المهمة

- 🔒 لا تشارك كلمات المرور أو مفاتيح `service_role`.
- 💾 اعمل نسخاً احتياطية دورية لقاعدة Supabase؛ ملفات التطبيق لا تحتوي على بيانات قاعدة البيانات.
- 🔄 عند تحديث الكود، نفّذ `git pull` ثم `./start.sh update`.
- 🔐 تأكد من تفعيل RLS وسياسات الوصول المناسبة في Supabase.
