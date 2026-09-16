#!/bin/bash
# ============================================================================
# Shared Test Helpers
# ============================================================================
# Source this from a behavioral suite, after the configuration:
#
#   ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
#   source "$ROOT/{{PIPELINE_ROOT}}/harness/config/test-config.env"
#   source "$ROOT/{{PIPELINE_ROOT}}/harness/lib/test-helpers.sh"
#   (or start from core/templates/testing/SUITE-TEMPLATE.sh: `wo suite <n>` scaffolds it)
#
# Nothing here assumes a particular application. HTTP helpers need only
# API_BASE; SQL helpers are inert unless DB_NAME is set; the auth helpers are
# driven entirely by the AUTH_* variables in test-config.env and are only
# needed by suites that authenticate.
# ============================================================================

API_BASE="${API_BASE:-http://localhost:3001}"
HEALTH_PATH="${HEALTH_PATH:-/health}"
# The health endpoint is usually at the host root (/health), not under the API
# prefix. Try both and use the first that answers 200.
health_url() {
  local host; host="$(printf '%s' "$API_BASE" | sed -E 's|^(https?://[^/]+).*|\1|')"
  local u
  for u in "${API_BASE%/}${HEALTH_PATH}" "${host}${HEALTH_PATH}"; do
    [ "$(curl -s -o /dev/null -w '%{http_code}' -A "${TEST_USER_AGENT:-harness}" "$u" 2>/dev/null)" = "200" ] && { printf '%s' "$u"; return 0; }
  done
  printf '%s' "${API_BASE%/}${HEALTH_PATH}"; return 1
}

METRICS_PATH="${METRICS_PATH:-/metrics}"
TEST_USER_AGENT="${TEST_USER_AGENT:-Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36}"

# ====================================================================
# HTTP Test Helpers
# ====================================================================

# Assert an HTTP status code.
# Usage: assert_http_status "name" URL EXPECTED [METHOD] [JSON_BODY]
assert_http_status() {
  local test_name="$1"
  local url="$2"
  local expected_status="$3"
  local method="${4:-GET}"
  local data="${5:-}"

  echo "Test: $test_name"

  local -a args=(-s -w "\nHTTP_CODE:%{http_code}" -X "$method" -A "$TEST_USER_AGENT")
  [ -n "${ORIGIN:-}" ] && args+=(-H "Origin: $ORIGIN")
  if [ -n "$data" ]; then
    args+=(-H "Content-Type: application/json" -d "$data")
  fi

  RESPONSE=$(curl "${args[@]}" "$url")
  HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

  if [ "$HTTP_CODE" = "$expected_status" ]; then
    echo "  PASS (status: $HTTP_CODE)"
    return 0
  else
    echo "  FAIL (expected: $expected_status, got: $HTTP_CODE)"
    return 1
  fi
}

# Extract a JSON field from a response body.
# Usage: extract_json_field "$body" "user.id"
extract_json_field() {
  local response="$1"
  local field="$2"

  echo "$response" | jq -r ".$field"
}

# ====================================================================
# SQL Test Helpers  (no-ops when no database is configured)
# ====================================================================

db_configured() {
  [ -n "${DB_NAME:-}" ] && command -v psql > /dev/null 2>&1
}

# Execute SQL and return the result.
run_sql() {
  local query="$1"

  db_configured || { echo "run_sql: no database configured (set DB_NAME)" >&2; return 1; }

  PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}" psql \
    -h "${DB_HOST:-localhost}" \
    -p "${DB_PORT:-5432}" \
    -U "${DB_USER:-$USER}" \
    -d "$DB_NAME" \
    -t -A -c "$query"
}

# Execute SQL and check that the result contains a pattern.
assert_sql_contains() {
  local test_name="$1"
  local query="$2"
  local expected_pattern="$3"

  echo "SQL Test: $test_name"

  local result
  result=$(run_sql "$query" 2>&1)

  if echo "$result" | grep -q "$expected_pattern"; then
    echo "  PASS"
    return 0
  else
    echo "  FAIL (expected: $expected_pattern)"
    echo "  Got: $result"
    return 1
  fi
}

# ====================================================================
# Wait/Timing Helpers
# ====================================================================

# Wait for the service under test to answer.
wait_for_server() {
  local url="${1:-$(health_url || true)}"
  local max_wait="${2:-30}"

  echo "Waiting for server at $url..."

  local i
  for i in $(seq 1 "$max_wait"); do
    if curl -s -A "$TEST_USER_AGENT" "$url" > /dev/null 2>&1; then
      echo "  Server ready"
      return 0
    fi
    echo "  Waiting... ($i/$max_wait)"
    sleep 1
  done

  echo "  Server not ready after ${max_wait}s"
  return 1
}

# ====================================================================
# Authentication Helpers  (optional — only for suites that log in)
# ====================================================================

# Build a JSON credential body from the configured field names, merged with
# AUTH_EXTRA_LOGIN_FIELDS (a JSON object; empty by default).
auth_body() {
  local email="$1"
  local password="$2"
  local extra="${AUTH_EXTRA_LOGIN_FIELDS:-}"
  [ -n "$extra" ] || extra='{}'

  jq -n \
    --arg ef "${AUTH_EMAIL_FIELD:-email}" --arg e "$email" \
    --arg pf "${AUTH_PASSWORD_FIELD:-password}" --arg p "$password" \
    --argjson extra "$extra" \
    '{($ef): $e, ($pf): $p} + $extra'
}

# Log in and echo the token. Returns non-zero if no token came back.
# Usage: TOKEN=$(auth_login "$email" "$password")
auth_login() {
  local email="$1"
  local password="$2"

  local body response token
  body="$(auth_body "$email" "$password")"
  response=$(curl -s -X POST "${API_BASE}${AUTH_LOGIN_PATH:-/auth/login}" \
    -H "Content-Type: application/json" \
    ${ORIGIN:+-H "Origin: $ORIGIN"} \
    -A "$TEST_USER_AGENT" \
    -d "$body")

  token=$(echo "$response" | jq -r "${AUTH_TOKEN_JQ:-.access_token} // empty" 2>/dev/null)
  if [ -z "$token" ]; then
    echo "auth_login: no token at '${AUTH_TOKEN_JQ:-.access_token}' in login response" >&2
    return 1
  fi
  echo "$token"
}

# Register a user through the configured register path. Echoes the raw response.
create_test_user() {
  local email="$1"
  local password="${2:-${TEST_PASSWORD:-TestPassword123!}}"

  curl -s -X POST "${API_BASE}${AUTH_REGISTER_PATH:-/auth/register}" \
    -H "Content-Type: application/json" \
    ${ORIGIN:+-H "Origin: $ORIGIN"} \
    -A "$TEST_USER_AGENT" \
    -d "$(auth_body "$email" "$password")"
}

# Remove a user the harness created. Requires AUTH_USER_CLEANUP_SQL, whose
# {email} placeholder is substituted. Without it, cleanup is skipped loudly
# rather than guessing at a schema.
delete_test_user() {
  local email="$1"

  if [ -z "${AUTH_USER_CLEANUP_SQL:-}" ]; then
    echo "delete_test_user: AUTH_USER_CLEANUP_SQL not set — skipping cleanup of $email" >&2
    return 0
  fi

  run_sql "${AUTH_USER_CLEANUP_SQL//\{email\}/$email}"
}

# A unique address for a throwaway account.
random_email() {
  echo "${TEST_USER_PREFIX:-harness_}$(date +%s)_$RANDOM@${TEST_EMAIL_DOMAIN:-example.com}"
}

# ====================================================================
# Metric Helpers  (Prometheus text format, when the service exposes it)
# ====================================================================

get_metric_value() {
  local metric_name="$1"

  curl -s -A "$TEST_USER_AGENT" "${API_BASE}${METRICS_PATH}" \
    | grep "^$metric_name " \
    | awk '{print $2}'
}

# Measure how much a counter moved across an action.
measure_metric_delta() {
  local metric_name="$1"
  local action_command="$2"

  local before after
  before=$(get_metric_value "$metric_name")
  eval "$action_command"
  after=$(get_metric_value "$metric_name")

  echo $(( ${after:-0} - ${before:-0} ))
}

# --- small assertions the original methodology used constantly -----------------
assert_contains() { # haystack needle label — the response carries the value that was sent
  case "$1" in *"$2"*) echo "  PASS ${3:-contains $2}"; return 0;; *) echo "  FAIL ${3:-contains $2} (not found: $2)"; return 1;; esac
}
assert_not_empty() { # value label — an id, a token, a row came back at all
  if [ -n "$1" ]; then echo "  PASS ${2:-not empty}"; return 0; else echo "  FAIL ${2:-not empty} (empty)"; return 1; fi
}
assert_gte() { # actual minimum label — counts and totals, never asserted as "some"
  if [ "${1:-0}" -ge "${2:-0}" ] 2>/dev/null; then echo "  PASS ${3:-$1 >= $2}"; return 0; else echo "  FAIL ${3:-$1 >= $2} (got ${1:-nothing})"; return 1; fi
}
