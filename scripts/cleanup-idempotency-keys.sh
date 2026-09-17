#!/usr/bin/env bash
# Deletes expired idempotency keys (public.cleanup_expired_idempotency_keys,
# migration 20260905000014). Keys default to a 24h expiry, so a daily run keeps
# the table lean. Scheduled by cron daily at 03:00 (see التقرير-النهائي.md §4).
set -euo pipefail

LOG_DIR="/srv/backups/supabase"
LOG_FILE="${LOG_DIR}/cleanup-idempotency-keys.log"
mkdir -p "${LOG_DIR}"

export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"

CLEANED="$(docker exec supabase-db psql -U postgres -d postgres -t -A -v ON_ERROR_STOP=1 \
  -c "SELECT public.cleanup_expired_idempotency_keys();")"

echo "IDEMPOTENCY_CLEANUP_OK deleted=${CLEANED} $(date)" >> "${LOG_FILE}"