# ✅ تشغيل برنامج الورشة

برنامج بسيط لا يحتاج خبرة تقنية — اتبع الخطوات بالترتيب.

---

## قبل ما نبدأ: إيه اللي تحتاجه؟

1. **سيرفر أو كمبيوتر دايم الشغل** عليه Docker (أو اتبع خطوات التثبيت أدناه)
2. **حساب Supabase** (ده مخزن البيانات) — لازم يكون فيه جاهز
3. **النطاق** (اختياري لكن يفضل)

---

## الخطوة 1: تثبيت Docker و Docker Compose

انسخ والصق هذا في الطرفية (terminal):

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
```

تأكد أنه شغال:

```bash
docker --version
```

---

## الخطوة 2: تجهيز قاعدة البيانات (Supabase)

> **لو عندك Supabase جاهز سابقاً من مـنصّ الورشة الأولى، استخدمه كما هو.**

اجعل Supabase يعمل على سيرفرك:

```bash
# على سيرفرك:
git clone https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
# عدّل ملف .env بقيمك
docker compose up -d
```

بعدها: الصق بيانات الاتصال في ملف `.env` (الخطوة 3).

---

## الخطوة 3: عدّل ملف `.env`

أول مرة تشغّل فيها `./start.sh`، هيتعمل ملف جديد اسمه `.env` تلقائياً (في نفس مجلد `deploy`). افتحه بعدها وعدّل القيمتين:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://الرابط-بتاعك
NEXT_PUBLIC_SUPABASE_ANON_KEY=المفتاح-العام-بتاعك
```

> سواء كانت Supabase على سيرفرك أو على سيرفر خارجي (مثلاً supabase.com)، ضع الرابط والمفتاح في `.env`.

---

## الخطوة 4: تشغيل البرنامج

```bash
cd deploy
./start.sh
```

بعد ثواني هتفتح المتصفح وتدخل على:

```
http://localhost:3000
```

(أو استخدم IP السيرفر إذا شغال عليه)

---

## الخطوة 5: إنشاء أول حساب

أول واحد يسجل حساب جديد في البرنامج، هو اللي يبقى **Owner (المالك)** — له كل الصلاحيات.

---

## أوامر تشغيل يومية

| العملية | الأمر |
|---------|-------|
| تشغيل | `./start.sh` |
| إيقاف | `./start.sh stop` |
| إعادة تشغيل | `./start.sh restart` |
| مشاهدة الأخطاء | `./start.sh logs` |
| حالة البرنامج | `./start.sh status` |

---

## لو عايز تنشره على الإنترنت (اختياري)

حط Nginx قدامه — مثال مبسط:

```bash
sudo apt install nginx certbot
# عدّل server_name باسم النطاق بتاعك
sudo nano /etc/nginx/sites-available/workshop
```

المحتوى:

```nginx
server {
    server_name workshop-nour.example.com;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

فعّل وأضف SSL:

```bash
sudo ln -s /etc/nginx/sites-available/workshop /etc/nginx/sites-enabled/
sudo certbot
sudo systemctl reload nginx
```

---

## ملاحظات مهمة

- 🔒 كلمة مرور Supabase وأي مفاتيح سرية — لا تشاركها مع أحد
- 💾 كل يوم أو أسبوعياً: اعمل backup (انظر ملفات `scripts/`)
- 🔄 عند تحديث البرنامج: `./start.sh update`