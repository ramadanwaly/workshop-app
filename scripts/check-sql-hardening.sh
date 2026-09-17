#!/usr/bin/env bash
# Static hardening gate for supabase/migrations/*.sql (P1-06).
# Runs without a database (safe in CI): fails the build if any migration
# hands privileges to anonymous users or reintroduces blanket FOR ALL policies.
#
# Rules:
#   1. No GRANT ... TO anon/PUBLIC anywhere (only REVOKE lines may name them).
#   2. No other TO anon / TO PUBLIC recipient (e.g. CREATE POLICY ... TO anon).
#   3. No FOR ALL policy except the allowlisted deliberate one(s).
#      Legacy files 20260905000003/05 are skipped: their FOR ALL policies were
#      all superseded (dropped) by later migrations; applied files are
#      append-only and must never be edited (see AGENTS.md hard rules).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGR="$HERE/supabase/migrations"
FAIL=0

strip_comments() { sed 's/--.*$//'; }

echo "[sql-hardening] rule 1: no GRANT to anon/PUBLIC..."
# Rules 1+2 allowlist: two deliberate anon grants only —
#   (a) increment_rate_limit must be callable by unauthenticated login posts
#       (P2-04, migration 25). The function only writes rate counters for
#       well-formed buckets.
#   (b) SELECT on the single public gallery view v_portfolio_gallery_public
#       (portfolio gallery phase 1, migration 46). The view lists 7 public
#       columns by name only (no SELECT *, no financial column, no
#       project_id) and only completed projects that have at least one photo.
ALLOW_ANON_GRANT='GRANT EXECUTE ON FUNCTION public\.increment_rate_limit\(TEXT, INT, INT\) TO anon'
ALLOW_ANON_VIEW='GRANT SELECT ON public\.v_portfolio_gallery_public TO anon'
if grep -rhn --include='*.sql' -E '^[[:space:]]*GRANT[[:space:]]' "$MIGR" | strip_comments | grep -E 'TO[[:space:]]+(PUBLIC|anon)([^_a-zA-Z]|$)' | grep -v -E "$ALLOW_ANON_GRANT" | grep -v -E "$ALLOW_ANON_VIEW" ; then
  echo "[sql-hardening] FAIL: found GRANT ... TO anon/PUBLIC (rule 1)" >&2
  FAIL=1
else
  echo "[sql-hardening] rule 1 ok"
fi

echo "[sql-hardening] rule 2: no TO anon/PUBLIC recipient outside REVOKE..."
# Allowlist: the same two deliberate anon grants as rule 1 (rate-limit
# function + the single public gallery view). Any other TO anon/PUBLIC
# recipient — including any CREATE POLICY ... TO anon — still fails.
if grep -rhn --include='*.sql' -E 'TO[[:space:]]+(PUBLIC|anon)([^_a-zA-Z]|$)' "$MIGR" | strip_comments | grep -v -E '^[0-9]+:[[:space:]]*REVOKE' | grep -v -E "$ALLOW_ANON_GRANT" | grep -v -E "$ALLOW_ANON_VIEW" ; then
  echo "[sql-hardening] FAIL: found privilege recipient anon/PUBLIC outside REVOKE (rule 2)" >&2
  FAIL=1
else
  echo "[sql-hardening] rule 2 ok"
fi

echo "[sql-hardening] rule 3: no FOR ALL policies except allowlist..."
# shellcheck disable=SC2016
VIOLATIONS="$(for f in "$MIGR"/[0-9]*.sql; do
  case "$(basename "$f")" in
    20260905000003_rls_policies.sql|20260905000005_fix_security_lints.sql) continue;;
  esac
  awk -v file="$f" '
    /CREATE POLICY/ { if (match($0, /"[^"]+"/)) name = substr($0, RSTART, RLENGTH) }
    /FOR ALL/ && $0 !~ /^[[:space:]]*--/ {
      if (name != "\"settings_modify_owner_only\"") print file":"FNR": "name" :: "$0
    }
  ' "$f"
done)"
if [ -n "$VIOLATIONS" ]; then
  printf '%s\n' "$VIOLATIONS"
  echo "[sql-hardening] FAIL: non-allowlisted FOR ALL policy (rule 3)" >&2
  FAIL=1
else
  echo "[sql-hardening] rule 3 ok"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "[sql-hardening] FAILED — راجع سياسات الصلاحيات في الهجرات" >&2
  exit 1
fi
echo "[sql-hardening] PASSED — فحص صلابة الصلاحيات سليم"
