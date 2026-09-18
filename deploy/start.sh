#!/usr/bin/env bash
# ============================================
# تشغيل/إيقاف تطبيق الورشة
# عدّل deploy/.env ثم شغّل هذا الملف
# ============================================

set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "خطأ: يلزم تثبيت Docker Compose (docker compose أو docker-compose)." >&2
    exit 1
  fi
}

create_env() {
  if [ -e .env ]; then
    echo "لن أستبدل ملف .env الموجود. عدّله يدوياً ثم أعد المحاولة." >&2
    return 1
  fi

  cat > .env <<'EOF'
# بيانات الاتصال بقاعدة البيانات (Supabase)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=paste-your-public-anon-key-here
NEXT_PUBLIC_SITE_URL=http://localhost:3000
EOF
  chmod 600 .env
  echo "تم إنشاء deploy/.env — عدّل القيم ثم شغّل الملف مرة أخرى"
}

valid_env() {
  [ -f .env ] || return 1
  grep -Eq '^NEXT_PUBLIC_SUPABASE_URL=https?://[^[:space:]]+$' .env || return 1
  grep -Eq '^NEXT_PUBLIC_SUPABASE_ANON_KEY=.+$' .env || return 1
  grep -Eq '^NEXT_PUBLIC_SITE_URL=https?://[^[:space:]]+$' .env || return 1
  ! grep -qE 'your-project\.supabase\.co|paste-your-public-anon-key-here' .env
}

require_env() {
  if [ ! -f .env ]; then
    create_env
    exit 1
  fi
  if ! valid_env; then
    echo "⚠️ ملف .env غير مكتمل أو يحتوي على قيم تجريبية." >&2
    echo "عدّل NEXT_PUBLIC_SUPABASE_URL وNEXT_PUBLIC_SUPABASE_ANON_KEY وNEXT_PUBLIC_SITE_URL." >&2
    exit 1
  fi
}

case "${1:-start}" in
  start)
    require_env
    echo "جارٍ بناء البرنامج وتشغيله..."
    compose up -d --build
    echo ""
    echo "✅ تم التشغيل بنجاح"
    echo "🌐 افتح المتصفح على: http://localhost:3000"
    ;;
  stop)
    compose down
    echo "🛑 تم إيقاف البرنامج"
    ;;
  restart)
    require_env
    compose restart
    echo "🔄 تم إعادة التشغيل"
    ;;
  logs)
    compose logs -f --tail=100
    ;;
  status)
    compose ps
    ;;
  update)
    require_env
    compose down
    compose up -d --build
    echo "✅ تم التحديث"
    ;;
  *)
    echo "الاستخدام: ./start.sh [start|stop|restart|logs|status|update]" >&2
    exit 2
    ;;
esac
