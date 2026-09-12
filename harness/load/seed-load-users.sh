#!/usr/bin/env bash
# ============================================================================
# Seed load-test fixtures
# ============================================================================
# Registers N accounts through the API's own registration endpoint and writes
# fixtures/users.json, which the k6 scenarios read. It talks to the API only —
# no direct database access, no assumptions about your schema.
#
#   LOAD_USER_PASSWORD='...' ./seed-load-users.sh [count]
#
# If fixtures/users.json already exists it is left alone unless FORCE=1, so a
# hand-written fixture file is equally valid: the format is
#
#   {"generated":"<iso8601>","users":[{"email":"...","extra":{...}}, ...]}
#
# "extra" (optional) is merged into the login body for that user, for APIs that
# need more than an identifier and a secret.
#
# Env:
#   API_BASE            base URL (default: the project's configured API base)
#   AUTH_REGISTER_PATH  registration endpoint (default /auth/register)
#   AUTH_EMAIL_FIELD    body field for the identifier (default email)
#   AUTH_PASSWORD_FIELD body field for the secret (default password)
#   LOAD_USER_EXTRA     JSON object merged into every register body (default {})
#   LOAD_USER_DOMAIN    email domain for generated users (default example.com)
#   LOAD_USER_PREFIX    local-part prefix (default loaduser)
#   FORCE=1             re-seed even if fixtures/users.json exists
# ============================================================================
set -euo pipefail

: "${LOAD_USER_PASSWORD:?set LOAD_USER_PASSWORD (never commit it)}"

COUNT="${1:-${LOAD_USER_COUNT:-200}}"
API_BASE="${API_BASE:-{{API_BASE_URL}}}"
AUTH_REGISTER_PATH="${AUTH_REGISTER_PATH:-/auth/register}"
AUTH_EMAIL_FIELD="${AUTH_EMAIL_FIELD:-email}"
AUTH_PASSWORD_FIELD="${AUTH_PASSWORD_FIELD:-password}"
LOAD_USER_EXTRA="${LOAD_USER_EXTRA:-}"
[ -n "$LOAD_USER_EXTRA" ] || LOAD_USER_EXTRA='{}'
LOAD_USER_DOMAIN="${LOAD_USER_DOMAIN:-example.com}"
LOAD_USER_PREFIX="${LOAD_USER_PREFIX:-loaduser}"

# A browser User-Agent: services that score clients for risk, or block unknown
# agents, would otherwise refuse the seeding traffic.
UA="${LOAD_USER_AGENT:-Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36}"

command -v jq > /dev/null 2>&1 || { echo "[seed] jq is required" >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/fixtures/users.json"
mkdir -p "$HERE/fixtures"

if [ -f "$OUT" ] && [ "${FORCE:-0}" != "1" ]; then
  existing=$(jq '.users | length' "$OUT" 2>/dev/null || echo 0)
  echo "[seed] $OUT already exists ($existing users) — leaving it alone. FORCE=1 to re-seed."
  exit 0
fi

echo "[seed] registering $COUNT users at ${API_BASE}${AUTH_REGISTER_PATH}"

registered=0
failed=0
tmp="$(mktemp)"
echo '[]' > "$tmp"

for n in $(seq 1 "$COUNT"); do
  email="${LOAD_USER_PREFIX}-${n}@${LOAD_USER_DOMAIN}"

  body=$(jq -n \
    --arg ef "$AUTH_EMAIL_FIELD" --arg e "$email" \
    --arg pf "$AUTH_PASSWORD_FIELD" --arg p "$LOAD_USER_PASSWORD" \
    --argjson extra "$LOAD_USER_EXTRA" \
    '{($ef): $e, ($pf): $p} + $extra')

  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${API_BASE}${AUTH_REGISTER_PATH}" \
    -H "Content-Type: application/json" -A "$UA" -d "$body" || echo "000")

  case "$code" in
    2*)   registered=$((registered + 1));;
    409)  registered=$((registered + 1));;  # already there: fine, seeding is idempotent
    *)    failed=$((failed + 1)); echo "[seed] $email -> HTTP $code" >&2;;
  esac

  # Keep the account in the fixture when it exists, however it got there.
  case "$code" in
    2*|409)
      jq --arg e "$email" --argjson extra "$LOAD_USER_EXTRA" \
        '. + [{email: $e, extra: $extra}]' "$tmp" > "$tmp.next" && mv "$tmp.next" "$tmp"
      ;;
  esac

  if [ $((n % 50)) -eq 0 ]; then echo "[seed] $n/$COUNT"; fi
done

jq -n --arg g "$(date -u +%FT%TZ)" --slurpfile u "$tmp" \
  '{generated: $g, users: $u[0]}' > "$OUT"
rm -f "$tmp"

usable=$(jq '.users | length' "$OUT")
echo "[seed] wrote $OUT — $usable usable accounts ($registered ok, $failed failed)"

if [ "$usable" -eq 0 ]; then
  echo "[seed] no accounts registered — check API_BASE and AUTH_REGISTER_PATH" >&2
  exit 1
fi
