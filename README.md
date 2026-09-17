# نظام إدارة ورشة الأثاث والتكاليف المالية

## Workshop Operations & Financial Management System

نظام ويب لإدارة العمليات التشغيلية والمالية داخل ورش الأثاث والتصنيع. يهدف المشروع إلى استبدال السجلات الورقية والإجراءات اليدوية بتدفق عمل رقمي يساعد على متابعة المشاريع، الخامات، العمال، الموردين، المقاولين، والتكاليف المالية من خلال واجهة موحدة.

A web-based system for managing workshop operations and finances. It replaces paper-based records and manual processes with a digital workflow for tracking projects, materials, workers, suppliers, subcontractors, cash flow, and project costs in one place.

> **الحالة / Status:** مشروع قيد التطوير / Work in progress

---

## المحتويات / Table of Contents

- [الوظائف الرئيسية / Key Features](#الوظائف-الرئيسية--key-features)
- [المعمارية / Architecture](#المعمارية--architecture)
- [التقنيات / Technology Stack](#التقنيات--technology-stack)
- [الأمان وسلامة البيانات / Security & Data Integrity](#الأمان-وسلامة-البيانات--security--data-integrity)
- [المتطلبات / Prerequisites](#المتطلبات--prerequisites)
- [التشغيل المحلي / Local Development](#التشغيل-المحلي--local-development)
- [Docker والنشر / Docker & Deployment](#docker-والنشر--docker--deployment)
- [الاختبارات / Quality Checks](#الاختبارات--quality-checks)
- [هيكل المشروع / Project Structure](#هيكل-المشروع--project-structure)
- [المساهمة / Contributing](#المساهمة--contributing)
- [الترخيص / License](#الترخيص--license)

---

## الوظائف الرئيسية / Key Features

### إدارة المشاريع والتكاليف / Projects & Cost Tracking

- إنشاء ومتابعة مشاريع الورشة.
- ربط المشتريات والمصروفات والتكاليف بالمشروع المناسب.
- متابعة التكلفة الفعلية للمشروع وبنود الإنفاق.

- Create and track workshop projects.
- Associate purchases, expenses, and other costs with the relevant project.
- Monitor actual project costs and spending categories.

### إدارة الخامات والفوائض / Materials & Surplus Management

- تسجيل شراء الخامات وحركتها داخل الورشة.
- متابعة المرتجعات والفوائض وإعادة استخدامها.
- دعم احتساب التكلفة بعد إعادة تدوير المواد.

- Record material purchases and workshop movements.
- Track returns, surplus materials, and reuse.
- Support cost adjustments when materials are recycled or returned.

### العمال والأجور والسلف / Workers, Wages & Advances

- تسجيل الأعمال اليومية وأجور العمال.
- إدارة السلف والخصومات وفق السياسة المحاسبية المعتمدة.
- فصل السلف عن تكلفة المشروع عند تطبيق هذه السياسة.

- Record daily work and worker wages.
- Manage advances and deductions according to the configured accounting policy.
- Keep advances separate from project costs when required by that policy.

### الخزينة والمصروفات / Treasury & Expenses

- تسجيل تمويلات المالك والسحوبات والمصروفات.
- متابعة الرصيد النقدي وحركات الخزينة.
- تطبيق القيود المالية قبل اعتماد المعاملة.

- Record owner funding, withdrawals, and expenses.
- Track cash balance and treasury movements.
- Apply financial constraints before a transaction is committed.

### الموردون والمقاولون / Suppliers & Subcontractors

- إدارة الموردين والمقاولين.
- تسجيل العقود والدفعات وربطها بالمشاريع.
- متابعة الالتزامات والمدفوعات المستحقة.

- Manage suppliers and subcontractors.
- Record contracts and payments and associate them with projects.
- Track outstanding commitments and payable amounts.

### التقارير والمتابعة / Reporting & Monitoring

- عرض مؤشرات التشغيل والتكاليف.
- توفير بيانات تساعد على اتخاذ قرارات مالية وتشغيلية أفضل.
- دعم المراجعة اللاحقة للحركات والتعديلات المهمة.

- Display operational and cost indicators.
- Provide information for better operational and financial decisions.
- Support later review of important transactions and changes.

---

## المعمارية / Architecture

يعتمد النظام على فصل مسؤوليات الواجهة، التطبيق، وقاعدة البيانات. الهدف هو عدم الاعتماد على التحقق في المتصفح وحده، ووضع القواعد الحساسة في طبقات يمكن التحكم فيها ومراجعتها.

The system separates the presentation, application, and data layers. The goal is to avoid relying on client-side validation alone and to keep sensitive rules in controlled, reviewable layers.

```text
[ Web UI / واجهة الويب ]
          │
          ▼
[ Next.js App Router ]
          │
          ▼
[ Server Actions / Validation / Authorization ]
          │
          ▼
[ Supabase Client & Database Access ]
          │
          ▼
[ PostgreSQL / Transactions / Constraints ]
```

- **واجهة المستخدم / UI:** شاشات إدخال ومتابعة مناسبة للحاسوب والأجهزة المحمولة.
- **طبقة التطبيق / Application:** تنفيذ الإجراءات، التحقق من المدخلات، والتحكم في الصلاحيات.
- **طبقة البيانات / Data:** تخزين البيانات وتطبيق القيود والمعاملات والقواعد المالية الأساسية.

---

## التقنيات / Technology Stack

- **Next.js 16.3.4** باستخدام App Router.
- **React 19.2.8**.
- **TypeScript** مع فحص الأنواع.
- **Supabase** و `@supabase/ssr` للوصول إلى خدمات قاعدة البيانات وإدارة الجلسات.
- **PostgreSQL** كقاعدة البيانات المستهدفة.
- **Zod 4** للتحقق من صحة المدخلات.
- **Tailwind CSS 4** لتنسيق الواجهات.
- **Vitest** للاختبارات.
- **Docker / Docker Compose** للتشغيل والنشر.
- **Node.js 20+**.

---

## الأمان وسلامة البيانات / Security & Data Integrity

يركز المشروع على حماية الحركات المالية وتقليل احتمالات الخطأ أو التكرار من خلال:

The project focuses on protecting financial transactions and reducing errors or duplicate operations through:

- التحقق من المدخلات قبل تنفيذ العمليات باستخدام Zod.
- تطبيق الصلاحيات في طبقة الخادم وعدم الاعتماد على الواجهة فقط.
- استخدام معاملات قاعدة البيانات والقيود المناسبة للحركات الحساسة.
- دعم منع تكرار العمليات عند الحاجة من خلال مفاتيح idempotency وسياق العملية.
- التعامل مع التزامن في نقاط حساسة مثل تحديث الأرصدة وحركات الخزينة.
- الاحتفاظ بسجل واضح للحركات والتعديلات المهمة حسب تصميم قاعدة البيانات.

- Input validation before execution using Zod.
- Server-side authorization instead of relying on the UI alone.
- Database transactions and constraints for sensitive operations.
- Idempotency keys and operation context where duplicate prevention is required.
- Concurrency control at sensitive points such as balance updates and treasury movements.
- A clear record of important transactions and changes, according to the database design.

> يجب مراجعة إعدادات Supabase وRLS ومتغيرات البيئة قبل استخدام النظام في الإنتاج.
>
> Supabase, RLS, and environment settings must be reviewed and hardened before production use.

---

## المتطلبات / Prerequisites

- Node.js 20 أو أحدث / Node.js 20 or later
- npm
- حساب أو مشروع Supabase مُعدّ للتطبيق / A configured Supabase project
- Docker وDocker Compose عند استخدام النشر بالحاويات / Docker and Docker Compose for containerized deployment
- متغيرات البيئة المطلوبة في إعداد المشروع / The environment variables required by the project configuration

---

## التشغيل المحلي / Local Development

### 1. استنساخ المستودع / Clone the repository

```bash
git clone https://github.com/ramadanwaly/workshop-app.git
cd workshop-app
```

### 2. تثبيت الاعتماديات / Install dependencies

```bash
npm install
```

### 3. إعداد متغيرات البيئة / Configure environment variables

أنشئ ملف البيئة المناسب لإعدادك المحلي، ثم أضف قيم Supabase وبقية المتغيرات المطلوبة. لا تضع الأسرار في المستودع ولا تشارك ملفات البيئة مع الآخرين.

Create the environment file required by your local setup and add the Supabase values and other required variables. Do not commit secrets or share environment files.

### 4. تشغيل خادم التطوير / Start the development server

```bash
npm run dev
```

ثم افتح:

```text
http://localhost:3000
```

Then open the URL above in your browser.

---

## Docker والنشر / Docker & Deployment

يحتوي المستودع على إعدادين مختلفين:

The repository contains two deployment-oriented Compose configurations:

- `deploy/docker-compose.yml`: يبني الصورة من `Dockerfile` ويعرض التطبيق على المنفذ `3000`.
- `docker-compose.yml`: يشغّل صورة منشورة باسم `ramadanwaly/workshop-app:latest` ضمن شبكة Docker خارجية باسم `accounting-app_default`.

- `deploy/docker-compose.yml`: builds the image from the `Dockerfile` and publishes port `3000`.
- `docker-compose.yml`: runs the published image `ramadanwaly/workshop-app:latest` on the external Docker network `accounting-app_default`.

للتشغيل من إعداد النشر المحلي:

To use the local deployment configuration:

```bash
docker compose -f deploy/docker-compose.yml up -d --build
```

تحقق من صحة الخدمة بعد التشغيل من خلال المسار:

Check the service health after startup using:

```text
http://localhost:3000/login
```

> تأكد من إعداد ملف البيئة والشبكة الخارجية المطلوبة قبل استخدام `docker-compose.yml` الأساسي.
>
> Configure the environment file and required external network before using the root `docker-compose.yml`.

---

## أوامر المشروع / Project Commands

| الأمر / Command | الاستخدام / Purpose |
| --- | --- |
| `npm run dev` | تشغيل بيئة التطوير / Start development server |
| `npm run build` | بناء نسخة الإنتاج / Build for production |
| `npm run start` | تشغيل نسخة الإنتاج / Start production server |
| `npm run lint` | فحص أسلوب وجودة الكود / Run lint checks |
| `npm run typecheck` | فحص TypeScript / Run TypeScript checks |
| `npm test` | تشغيل الاختبارات / Run tests |
| `npm run sql-hardening` | فحص التحصين الخاص بـ SQL / Run SQL hardening checks |
| `npm run check` | تشغيل فحوصات المشروع كاملة / Run the complete check suite |

---

## الاختبارات / Quality Checks

قبل إرسال أي تغيير، يُنصح بتشغيل:

Before submitting a change, run:

```bash
npm run check
```

يتضمن الأمر فحوصات SQL، وفحص TypeScript، وESLint، واختبارات Vitest.

This command runs SQL hardening checks, TypeScript validation, ESLint, and Vitest tests.

---

## هيكل المشروع / Project Structure

```text
.
├── app/                  # صفحات ومسارات Next.js / Next.js routes and pages
├── components/           # مكونات الواجهة / UI components
├── lib/                  # منطق مشترك وتكاملات / Shared logic and integrations
├── scripts/              # أدوات الفحص والتشغيل / Utility and validation scripts
├── deploy/               # إعدادات النشر المحلي / Local deployment configuration
├── Dockerfile            # تعريف صورة التطبيق / Application image definition
├── docker-compose.yml    # إعداد تشغيل الصورة المنشورة / Published-image deployment
└── package.json          # الاعتماديات والأوامر / Dependencies and scripts
```

> قد تختلف بعض المسارات حسب تطور المشروع. يُرجى اعتبار بنية المستودع الحالية هي المرجع النهائي.
>
> Paths may evolve as the project grows. Treat the current repository structure as the source of truth.

---

## المساهمة / Contributing

نرحب بالمساهمات التي تحسن جودة الكود، سلامة البيانات، تجربة المستخدم، أو التوثيق.

Contributions that improve code quality, data integrity, user experience, or documentation are welcome.

1. أنشئ فرعًا جديدًا للتغيير / Create a branch for your change.
2. نفّذ التعديل مع إضافة الاختبارات المناسبة / Implement the change with appropriate tests.
3. شغّل `npm run check` / Run `npm run check`.
4. افتح Pull Request يوضح المشكلة والحل / Open a Pull Request describing the problem and solution.

لا ترسل أسرارًا أو بيانات إنتاج حقيقية داخل Pull Request أو Issues.

Never submit secrets or real production data in Pull Requests or Issues.

---

## ملاحظات الإنتاج / Production Notes

- استخدم أسرارًا قوية وفريدة لكل بيئة.
- فعّل إعدادات RLS المناسبة في Supabase.
- لا تعرض قاعدة البيانات مباشرة على الإنترنت.
- استخدم HTTPS وخادمًا عكسيًا موثوقًا في بيئة الإنتاج.
- راجع النسخ الاحتياطية وسياسة استعادة البيانات قبل الاعتماد على النظام.
- اختبر الترحيلات وقواعد الصلاحيات على بيئة تجريبية أولًا.

- Use strong, environment-specific secrets.
- Enable appropriate Supabase RLS policies.
- Do not expose the database directly to the public internet.
- Use HTTPS and a trusted reverse proxy in production.
- Review backups and data-recovery procedures before relying on the system.
- Test migrations and authorization policies in a staging environment first.

---

## الترخيص / License

لم يتم تحديد ترخيص مفتوح المصدر في هذا المستودع حتى الآن. لا تفترض أن الكود متاح لإعادة الاستخدام التجاري أو إعادة التوزيع قبل إضافة ملف `LICENSE` أو الحصول على إذن صريح من مالك المشروع.

No open-source license has been specified in this repository at this time. Do not assume that the code may be commercially reused or redistributed until a `LICENSE` file is added or explicit permission is obtained from the project owner.

---

## التواصل / Contact

للاطلاع على آخر التحديثات أو إرسال اقتراحات، استخدم قسم Issues وPull Requests في المستودع:

For updates, bug reports, and suggestions, use the repository's Issues and Pull Requests:

https://github.com/ramadanwaly/workshop-app
