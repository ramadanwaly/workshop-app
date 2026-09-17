#!/bin/bash
# ============================================
#  تشغيل/إيقاف تطبيق الورشة
#  ملف سهل: عدّل .env ثم شغّل هذا الملف
# ============================================

set -e
cd "$(dirname "$0")"

create_env() {
  cat > .env << 'EOF'
# =====================================================
#  بيانات الاتصال بقاعدة البيانات (Supabase)
#  عدّل القيمتين اللي تحت ببياناتك
# =====================================================

# رابط Supabase بتاعك (مثلاً: https://supabase.example.com)
NEXT_PUBLIC_SUPABASE_URL=https://supabase.اسم-الموقع-بتاعك.com

# المفتاح العام (Anon Key) من Supabase
NEXT_PUBLIC_SUPABASE_ANON_KEY=الصق-المفتاح-من-Supabase-هنا
EOF
  echo "تم إنشاء ملف .env — عدّل القيمتين بداخله ثم شغّل الملف مرة أخرى"
}

valid_env() {
  grep -q "NEXT_PUBLIC_SUPABASE_URL=." .env &&
    ! grep -q "supabase.اسم-الموقع-بتاعك.com" .env &&
    ! grep -q "الصق-المفتاح-من-Supabase-هنا" .env
}

case "${1:-start}" in
  start)
    if [ ! -f .env ]; then
      create_env
      exit 1
    fi
    if ! valid_env; then
      echo "⚠️  ملف .env غير مكتمل — لازم تحدّث فيه رابط Supabase والمفتاح بتاعك أولاً"
      if [ ! -s .env ]; then create_env; fi
      exit 1
    fi
    echo "جارٍ تثبيت البرنامج وتشغيله..."
    docker compose up -d --build
    echo ""
    echo "✅ تم التشغيل بنجاح"
    echo "🌐 افتح المتصفح على: http://localhost:3000"
    echo "   (أو استخدم IP السيرفر بدل localhost)"
    ;;
  stop)
    docker compose down
    echo "🛑 تم إيقاف البرنامج"
    ;;
  restart)
    docker compose restart
    echo "🔄 تم إعادة التشغيل"
    ;;
  logs)
    docker compose logs -f --tail=100
    ;;
  status)
    docker compose ps
    ;;
  update)
    docker compose down
    # عدّل هذا السطر إذا كان الكود بيجي من GitHub بدل مجلد معرف
    docker compose up -d --build
    echo "✅ تم التحديث"
    ;;
  *)
    echo "الاستخدام: ./start.sh [start|stop|restart|logs|status]"
    ;;
esac