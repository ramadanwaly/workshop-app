#!/usr/bin/env bash
# backup-supabase.sh — automated pg_dump for the self-hosted Supabase DB.
# Runs on the homeserver (Debian 12). Installed from repo scripts/.
# Usage: /srv/scripts/backup-supabase.sh
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/srv/backups/supabase}"
SUPABASE_DIR="${SUPABASE_DIR:-/srv/compose/supabase}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
CONTAINER="supabase-db"
DB_NAME="postgres"
STAMP="$(date +%Y%m%d_%H%M%S)"
DUMP_HOST="$BACKUP_ROOT/supabase_${STAMP}.dump"
DUMP_IN_CONTAINER="/var/tmp/supabase_backup_${STAMP}.dump"
LOG="$BACKUP_ROOT/backup.log"

mkdir -p "$BACKUP_ROOT"
export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' "$SUPABASE_DIR/.env")"
[ -n "$POSTGRES_PASSWORD" ] || { echo "FATAL: POSTGRES_PASSWORD not found in $SUPABASE_DIR/.env" >&2; exit 1; }

echo "[$(date -Is)] backup start" >> "$LOG"
docker exec "$CONTAINER" pg_dump -U postgres -d "$DB_NAME" \
  --format=custom --file="$DUMP_IN_CONTAINER" >> "$LOG" 2>&1
docker cp "$CONTAINER:$DUMP_IN_CONTAINER" "$DUMP_HOST"
docker exec "$CONTAINER" rm -f "$DUMP_IN_CONTAINER"

SIZE="$(stat -c%s "$DUMP_HOST")"
if [ "$SIZE" -lt 1024 ]; then
  echo "FATAL: dump suspiciously small (${SIZE}B)" >> "$LOG"; exit 1
fi
docker run --rm -i --network supabase_default supabase/postgres:17.6.1.136 \
  pg_restore --list < "$DUMP_HOST" > /dev/null || {
  echo "FATAL: archive unreadable" >> "$LOG"; exit 1; }

find "$BACKUP_ROOT" -name 'supabase_*.dump' -mtime +"$RETENTION_DAYS" -delete >> "$LOG" 2>&1

echo "[$(date -Is)] OK $DUMP_HOST ($SIZE bytes)" >> "$LOG"
echo "BACKUP_OK $DUMP_HOST"