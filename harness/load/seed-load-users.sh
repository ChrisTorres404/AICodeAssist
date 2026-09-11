#!/usr/bin/env bash
# WO-50000: Seed load-test fixtures — 3 tenants, 500 users — and write fixtures/users.json.
# Idempotent: re-running tops up missing users. Never commits the password.
set -euo pipefail

: "${LOAD_USER_PASSWORD:?set LOAD_USER_PASSWORD (not committed)}"
API_BASE="${API_BASE:-http://localhost:4201/api/v1}"
DB_HOST="${DB_HOST:-localhost}"; DB_PORT="${DB_PORT:-4232}"
DB_USER="${DB_USER:-{{PROJECT_SLUG}}}"; DB_NAME="${DB_NAME:-{{DB_NAME}}}"
export PGPASSWORD="${DB_PASS:-password}"

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/fixtures/users.json"
mkdir -p "$HERE/fixtures"

# tenant_slug:count:tier
TENANTS=("load-alpha:200:enterprise" "load-bravo:200:enterprise" "load-charlie:100:free")
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36'

psql_do() { psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$1"; }

echo "[seed] resolving/creating tenants..."
declare -A TENANT_ID
for entry in "${TENANTS[@]}"; do
  slug="${entry%%:*}"
  tid=$(psql_do "SELECT id FROM org.tenants WHERE slug='$slug' LIMIT 1;" || true)
  if [ -z "$tid" ]; then
    echo "[seed] tenant $slug missing — create it via provisioning first (not auto-created here to avoid partial state)." >&2
    exit 1
  fi
  TENANT_ID[$slug]=$tid
done

echo '{"generated":"'"$(date -u +%FT%TZ)"'","users":[' > "$OUT"
first=1
for entry in "${TENANTS[@]}"; do
  slug="${entry%%:*}"; rest="${entry#*:}"; count="${rest%%:*}"
  tid="${TENANT_ID[$slug]}"
  echo "[seed] $slug (tenant $tid): $count users"
  for n in $(seq 1 "$count"); do
    email="loaduser-${slug}-${n}@loadtest.{{PROJECT_SLUG}}id.local"
    # Register if absent (best-effort); ignore 409 conflicts.
    curl -s -o /dev/null -X POST "$API_BASE/auth/register" \
      -H "Content-Type: application/json" -H "User-Agent: $UA" \
      -d "{\"email\":\"$email\",\"password\":\"$LOAD_USER_PASSWORD\",\"tenant_id\":$tid}" || true
    # Force-verify so risk/lockout doesn't interfere.
    psql_do "UPDATE auth.users SET email_verified=true, status='active' WHERE email='$email';" >/dev/null || true
    [ $first -eq 0 ] && echo ',' >> "$OUT"; first=0
    printf '{"email":"%s","tenant_id":%s,"tenant_slug":"%s"}' "$email" "$tid" "$slug" >> "$OUT"
  done
done
echo ']}' >> "$OUT"
echo "[seed] wrote $OUT"
