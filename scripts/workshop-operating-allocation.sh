#!/usr/bin/env bash
# Runs the workshop operating allocation engine for the previous completed month.
# Scheduled by cron on the 1st of each month at 01:00 (see التقرير-النهائي.md §4).
set -euo pipefail

LOG_DIR="/srv/backups/supabase"
LOG_FILE="${LOG_DIR}/operating-allocation.log"
mkdir -p "${LOG_DIR}"

PREV_MONTH="$(date -d "$(date +%Y-%m-01) -1 month" +%Y-%m-01)"

export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"

docker exec supabase-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "SELECT app_private.run_operating_allocation('${PREV_MONTH}'::date);" \
  >> "${LOG_FILE}" 2>&1

echo "OPERATING_ALLOCATION_OK month=${PREV_MONTH} $(date)" >> "${LOG_FILE}"
