#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scp -q "$HERE/supabase/verify_operating.sql" homeserver:/tmp/verify_operating.sql
ssh homeserver 'bash -s' <<'EOF'
  set -euo pipefail
  export POSTGRES_PASSWORD="$(sed -n 's/^POSTGRES_PASSWORD=//p' /srv/compose/supabase/.env)"
  docker run --rm -i --network supabase_default \
    supabase/postgres:17.6.1.136 \
    psql "postgresql://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/postgres?sslmode=disable" \
      -v ON_ERROR_STOP=1 < /tmp/verify_operating.sql
EOF
