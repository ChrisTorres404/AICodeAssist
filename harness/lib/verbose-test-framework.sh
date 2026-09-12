#!/bin/bash
# ============================================================================
# {{PROJECT_NAME}} VERBOSE TEST FRAMEWORK v2.0
# ============================================================================
# This framework provides DETAILED, TRANSPARENT test output showing:
# - Exact commands being executed
# - Full request payloads
# - Complete responses
# - SQL queries and results
# - Why each test passed or failed
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Auto-source test-config.env if available (provides correct per-environment defaults)
_FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TEST_CONFIG="$_FRAMEWORK_DIR/../config/test-config.env"
if [ -f "$_TEST_CONFIG" ] && [ -z "$_TEST_CONFIG_LOADED" ]; then
  source "$_TEST_CONFIG"
  export _TEST_CONFIG_LOADED=1
fi

# API Configuration — test-config.env supplies these; the fallbacks keep the
# framework usable when sourced on its own.
_default_api_base='{{API_BASE_URL}}'
_default_origin='{{WEB_ORIGIN}}'
export API_BASE="${API_BASE:-$_default_api_base}"
export ORIGIN="${ORIGIN:-$_default_origin}"
export HEALTH_PATH="${HEALTH_PATH:-/health}"
export METRICS_PATH="${METRICS_PATH:-/metrics}"

# Authentication (optional — only the auth helpers read these)
export AUTH_LOGIN_PATH="${AUTH_LOGIN_PATH:-/auth/login}"
export AUTH_REGISTER_PATH="${AUTH_REGISTER_PATH:-/auth/register}"
export AUTH_TOKEN_JQ="${AUTH_TOKEN_JQ:-.access_token}"
export AUTH_EMAIL_FIELD="${AUTH_EMAIL_FIELD:-email}"
export AUTH_PASSWORD_FIELD="${AUTH_PASSWORD_FIELD:-password}"
_default_extra_fields='{}'
export AUTH_EXTRA_LOGIN_FIELDS="${AUTH_EXTRA_LOGIN_FIELDS:-$_default_extra_fields}"

# Database Configuration (optional — SQL helpers are inert without DB_NAME)
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USER="${DB_USER:-$USER}"
export DB_NAME="${DB_NAME:-}"
export PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}"

# A browser User-Agent by default: services that score clients for risk, or
# block unknown agents, treat curl-like agents as suspicious — the harness
# would then measure the bot filter instead of the behaviour under test.
export TEST_USER_AGENT="${TEST_USER_AGENT:-Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36}"

# Test Configuration
export TEST_TIMEOUT="${TEST_TIMEOUT:-30}"
export VERBOSE="${VERBOSE:-true}"
export SHOW_CURL_COMMANDS="${SHOW_CURL_COMMANDS:-true}"
export SHOW_SQL_QUERIES="${SHOW_SQL_QUERIES:-true}"
export SHOW_FULL_RESPONSE="${SHOW_FULL_RESPONSE:-true}"

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m'

# Test Counters
export TOTAL_TESTS=0
export PASSED_TESTS=0
export FAILED_TESTS=0
export SKIPPED_TESTS=0

# Test State
export CURRENT_SUITE=""
export CURRENT_TEST=""
export TEST_START_TIME=""

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Print a section header
section_header() {
  local title="$1"
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${CYAN}║${NC} %-70s ${BOLD}${CYAN}║${NC}\n" "$title"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Print a subsection header
subsection_header() {
  local title="$1"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}$title${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print test number and name
test_header() {
  local test_id="$1"
  local test_name="$2"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  CURRENT_TEST="$test_name"
  TEST_START_TIME=$(date +%s)

  echo ""
  echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${YELLOW}│${NC} ${BOLD}TEST $test_id: $test_name${NC}"
  echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Log what action we're about to perform
log_action() {
  echo -e "${DIM}ACTION:${NC} $1"
}

# Log the exact command being run
log_command() {
  if [ "$SHOW_CURL_COMMANDS" = "true" ]; then
    echo -e "${MAGENTA}COMMAND:${NC}"
    echo "$1" | sed 's/^/  /'
  fi
}

# Log request details
log_request() {
  local method="$1"
  local url="$2"
  local headers="$3"
  local body="$4"

  echo -e "${BLUE}REQUEST:${NC}"
  echo -e "  ${BOLD}$method${NC} $url"

  if [ -n "$headers" ]; then
    echo -e "  ${DIM}Headers:${NC}"
    echo "$headers" | sed 's/^/    /'
  fi

  if [ -n "$body" ]; then
    echo -e "  ${DIM}Body:${NC}"
    echo "$body" | jq '.' 2>/dev/null | sed 's/^/    /' || echo "    $body"
  fi
}

# Log response details
log_response() {
  local http_code="$1"
  local body="$2"
  local duration="$3"

  echo -e "${BLUE}RESPONSE:${NC}"
  echo -e "  ${DIM}HTTP Status:${NC} ${BOLD}$http_code${NC}"

  if [ -n "$duration" ]; then
    echo -e "  ${DIM}Duration:${NC} ${duration}s"
  fi

  if [ "$SHOW_FULL_RESPONSE" = "true" ] && [ -n "$body" ]; then
    echo -e "  ${DIM}Body:${NC}"
    # Pretty print JSON if possible, limit to 50 lines
    local formatted=$(echo "$body" | jq '.' 2>/dev/null || echo "$body")
    local lines=$(echo "$formatted" | wc -l)
    if [ "$lines" -gt 50 ]; then
      echo "$formatted" | head -50 | sed 's/^/    /'
      echo -e "    ${DIM}... ($(($lines - 50)) more lines)${NC}"
    else
      echo "$formatted" | sed 's/^/    /'
    fi
  fi
}

# Log SQL query
log_sql() {
  local query="$1"

  if [ "$SHOW_SQL_QUERIES" = "true" ]; then
    echo -e "${MAGENTA}SQL QUERY:${NC}"
    echo "$query" | sed 's/^/  /'
  fi
}

# Log SQL result
log_sql_result() {
  local result="$1"
  local row_count="$2"

  echo -e "${BLUE}SQL RESULT:${NC}"
  if [ -n "$result" ]; then
    echo "$result" | head -20 | sed 's/^/  /'
    local lines=$(echo "$result" | wc -l)
    if [ "$lines" -gt 20 ]; then
      echo -e "  ${DIM}... ($((lines - 20)) more rows)${NC}"
    fi
  else
    echo "  (no rows returned)"
  fi

  if [ -n "$row_count" ]; then
    echo -e "  ${DIM}Row count:${NC} $row_count"
  fi
}

# Log what we're validating
log_validation() {
  echo -e "${YELLOW}VALIDATION:${NC} $1"
}

# Log expected vs actual
log_comparison() {
  local expected="$1"
  local actual="$2"

  echo -e "${DIM}Expected:${NC} $expected"
  echo -e "${DIM}Actual:${NC}   $actual"
}

# Log test pass
log_pass() {
  local message="$1"
  local duration=""

  if [ -n "$TEST_START_TIME" ]; then
    local end_time=$(date +%s)
    duration=" ($((end_time - TEST_START_TIME))s)"
  fi

  PASSED_TESTS=$((PASSED_TESTS + 1))
  echo -e "${GREEN}RESULT: ✅ PASS${NC} - $message$duration"
}

# Log test fail
log_fail() {
  local message="$1"

  FAILED_TESTS=$((FAILED_TESTS + 1))
  echo -e "${RED}RESULT: ❌ FAIL${NC} - $message"
}

# Log test skip
log_skip() {
  local reason="$1"

  SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
  echo -e "${YELLOW}RESULT: ⚠️ SKIP${NC} - $reason"
}

# Log warning (doesn't affect pass/fail)
log_warn() {
  echo -e "${YELLOW}WARNING:${NC} $1"
}

# Log info
log_info() {
  echo -e "${CYAN}INFO:${NC} $1"
}

# Log debug (only when VERBOSE=true)
log_debug() {
  if [ "$VERBOSE" = "true" ]; then
    echo -e "${DIM}DEBUG:${NC} $1"
  fi
}

# ============================================================================
# HTTP REQUEST FUNCTIONS
# ============================================================================

# Make HTTP request and capture full details
# Usage: http_request METHOD URL [BODY] [EXTRA_HEADERS...]
# Returns: Sets HTTP_CODE, HTTP_BODY, HTTP_HEADERS, HTTP_DURATION
http_request() {
  local method="$1"
  local url="$2"
  local body="$3"
  shift 3
  local extra_headers=("$@")

  # Build curl command
  local curl_cmd="curl -s -w '\n---HTTP_META---\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}\nTIME_CONNECT:%{time_connect}\n'"
  curl_cmd="$curl_cmd -X $method"
  curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
  curl_cmd="$curl_cmd -H 'Accept: application/json'"

  # Add extra headers
  for header in "${extra_headers[@]}"; do
    curl_cmd="$curl_cmd -H '$header'"
  done

  # Add body if present
  if [ -n "$body" ]; then
    curl_cmd="$curl_cmd -d '$body'"
  fi

  curl_cmd="$curl_cmd '$url'"

  # Log the command
  log_command "$curl_cmd"

  # Execute request
  local start_time=$(date +%s)
  local response

  # Build header args array — a browser User-Agent always, plus an Origin
  # header, which CSRF guards commonly require on state-changing requests.
  local -a header_args=(-H "Content-Type: application/json" -H "Accept: application/json" -A "$TEST_USER_AGENT")

  # Check if caller already provides an Origin header
  local has_origin=false
  for header in "${extra_headers[@]}"; do
    [[ "$header" == Origin:* ]] && has_origin=true
  done

  if [ "$has_origin" = "false" ] && [ -n "${ORIGIN:-}" ]; then
    header_args+=(-H "Origin: $ORIGIN")
  fi

  for header in "${extra_headers[@]}"; do
    [ -n "$header" ] && header_args+=(-H "$header")
  done

  if [ -n "$body" ]; then
    response=$(curl -s -w '\n---HTTP_META---\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}\n' \
      -X "$method" \
      "${header_args[@]}" \
      -d "$body" \
      "$url" 2>&1)
  else
    response=$(curl -s -w '\n---HTTP_META---\nHTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}\n' \
      -X "$method" \
      "${header_args[@]}" \
      "$url" 2>&1)
  fi

  local end_time=$(date +%s)

  # Parse response
  HTTP_BODY=$(echo "$response" | sed '/---HTTP_META---/,$d')
  HTTP_CODE=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
  HTTP_DURATION=$((end_time - start_time))

  # Log request and response
  log_request "$method" "$url" "" "$body"
  log_response "$HTTP_CODE" "$HTTP_BODY" "$HTTP_DURATION"
}

# Convenience wrappers
http_get() {
  http_request "GET" "$@"
}

http_post() {
  http_request "POST" "$@"
}

http_put() {
  http_request "PUT" "$@"
}

http_patch() {
  http_request "PATCH" "$@"
}

http_delete() {
  http_request "DELETE" "$@"
}

# ============================================================================
# DATABASE FUNCTIONS
# ============================================================================

# Execute SQL query
# Usage: run_sql "SELECT * FROM table"
# Returns: Sets SQL_RESULT, SQL_ROW_COUNT
db_configured() {
  [ -n "${DB_NAME:-}" ] && command -v psql > /dev/null 2>&1
}

run_sql() {
  local query="$1"

  if ! db_configured; then
    log_warn "no database configured (set DB_NAME) — skipping query"
    SQL_RESULT=""; SQL_ROW_COUNT=0
    return 1
  fi

  log_sql "$query"

  SQL_RESULT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    SQL_ROW_COUNT=$(echo "$SQL_RESULT" | grep -c "^" || echo "0")
    log_sql_result "$SQL_RESULT" "$SQL_ROW_COUNT"
  else
    log_sql_result "ERROR: $SQL_RESULT" "0"
    SQL_ROW_COUNT=0
  fi

  return $exit_code
}

# Execute SQL and return single value
sql_value() {
  local query="$1"
  db_configured || return 1
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null | head -1
}

# Execute SQL and return row count
sql_count() {
  local query="$1"
  db_configured || { echo 0; return 1; }
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null | wc -l
}

# ============================================================================
# ASSERTION FUNCTIONS
# ============================================================================

# Assert HTTP status code
# Usage: assert_http_status 200
assert_http_status() {
  local expected="$1"
  local message="${2:-HTTP status should be $expected}"

  log_validation "Checking HTTP status code"
  log_comparison "$expected" "$HTTP_CODE"

  if [ "$HTTP_CODE" = "$expected" ]; then
    log_pass "$message"
    return 0
  else
    log_fail "Expected HTTP $expected, got $HTTP_CODE"
    return 1
  fi
}

# Assert response contains JSON field
# Usage: assert_json_field "user.id" "should have user ID"
assert_json_field() {
  local field="$1"
  local message="${2:-Response should contain $field}"

  local value=$(echo "$HTTP_BODY" | jq -r ".$field" 2>/dev/null)

  log_validation "Checking for JSON field: $field"
  log_comparison "non-null value" "$value"

  if [ -n "$value" ] && [ "$value" != "null" ]; then
    log_pass "$message (value: $value)"
    return 0
  else
    log_fail "Field $field is missing or null"
    return 1
  fi
}

# Assert response JSON field equals value
# Usage: assert_json_equals "status" "active" "Status should be active"
assert_json_equals() {
  local field="$1"
  local expected="$2"
  local message="${3:-$field should equal $expected}"

  local actual=$(echo "$HTTP_BODY" | jq -r ".$field" 2>/dev/null)

  log_validation "Checking $field equals expected value"
  log_comparison "$expected" "$actual"

  if [ "$actual" = "$expected" ]; then
    log_pass "$message"
    return 0
  else
    log_fail "Expected $field='$expected', got '$actual'"
    return 1
  fi
}

# Assert response contains string
# Usage: assert_response_contains "success" "Should indicate success"
assert_response_contains() {
  local pattern="$1"
  local message="${2:-Response should contain '$pattern'}"

  log_validation "Checking response contains: $pattern"

  if echo "$HTTP_BODY" | grep -q "$pattern"; then
    log_pass "$message"
    return 0
  else
    log_fail "Response does not contain '$pattern'"
    return 1
  fi
}

# Assert SQL returns expected value
# Usage: assert_sql_equals "SELECT count FROM table" "5" "Should have 5 rows"
assert_sql_equals() {
  local query="$1"
  local expected="$2"
  local message="${3:-SQL result should equal $expected}"

  run_sql "$query"
  local actual=$(echo "$SQL_RESULT" | head -1 | xargs)

  log_validation "Checking SQL result equals expected"
  log_comparison "$expected" "$actual"

  if [ "$actual" = "$expected" ]; then
    log_pass "$message"
    return 0
  else
    log_fail "Expected '$expected', got '$actual'"
    return 1
  fi
}

# Assert SQL returns rows
# Usage: assert_sql_has_rows "SELECT * FROM table WHERE x = 1"
assert_sql_has_rows() {
  local query="$1"
  local message="${2:-Query should return rows}"

  run_sql "$query"

  log_validation "Checking query returns rows"

  if [ "$SQL_ROW_COUNT" -gt 0 ]; then
    log_pass "$message ($SQL_ROW_COUNT rows)"
    return 0
  else
    log_fail "Query returned no rows"
    return 1
  fi
}

# Assert SQL returns no rows
# Usage: assert_sql_no_rows "SELECT * FROM table WHERE x = 'deleted'"
assert_sql_no_rows() {
  local query="$1"
  local message="${2:-Query should return no rows}"

  run_sql "$query"

  log_validation "Checking query returns no rows"

  if [ "$SQL_ROW_COUNT" -eq 0 ]; then
    log_pass "$message"
    return 0
  else
    log_fail "Query returned $SQL_ROW_COUNT rows (expected 0)"
    return 1
  fi
}

# ============================================================================
# TEST SETUP/TEARDOWN
# ============================================================================

# Build a JSON credential body from the configured field names, merged with
# AUTH_EXTRA_LOGIN_FIELDS (a JSON object, empty by default).
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

# Register a throwaway account through AUTH_REGISTER_PATH.
# Sets TEST_USER_EMAIL, TEST_USER_PASSWORD and, when the response carries one,
# TEST_ACCESS_TOKEN (read with AUTH_TOKEN_JQ).
create_test_user() {
  local email="${1:-$(random_email)}"
  local password="${2:-${TEST_PASSWORD:-TestPassword123!}}"

  log_action "Registering test user: $email"

  http_post "${API_BASE}${AUTH_REGISTER_PATH}" "$(auth_body "$email" "$password")"

  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    TEST_USER_EMAIL="$email"
    TEST_USER_PASSWORD="$password"
    TEST_ACCESS_TOKEN=$(echo "$HTTP_BODY" | jq -r "${AUTH_TOKEN_JQ} // empty" 2>/dev/null)
    log_info "Registered $email"
    return 0
  fi

  log_warn "Failed to register test user: HTTP $HTTP_CODE"
  return 1
}

# Log in through AUTH_LOGIN_PATH. Sets TEST_ACCESS_TOKEN from AUTH_TOKEN_JQ.
login_test_user() {
  local email="${1:-$TEST_USER_EMAIL}"
  local password="${2:-$TEST_USER_PASSWORD}"

  log_action "Logging in as: $email"

  http_post "${API_BASE}${AUTH_LOGIN_PATH}" "$(auth_body "$email" "$password")"

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    TEST_ACCESS_TOKEN=$(echo "$HTTP_BODY" | jq -r "${AUTH_TOKEN_JQ} // empty" 2>/dev/null)
    if [ -z "$TEST_ACCESS_TOKEN" ]; then
      log_warn "Login succeeded but no token at '${AUTH_TOKEN_JQ}'"
      return 1
    fi
    log_info "Login successful"
    return 0
  fi

  log_warn "Login failed: HTTP $HTTP_CODE"
  return 1
}

# Remove a user the harness created. Requires AUTH_USER_CLEANUP_SQL, whose
# {email} placeholder is substituted; without it, cleanup is skipped loudly
# rather than guessing at a schema.
delete_test_user() {
  local email="${1:-$TEST_USER_EMAIL}"

  if [ -z "${AUTH_USER_CLEANUP_SQL:-}" ]; then
    log_warn "AUTH_USER_CLEANUP_SQL not set — skipping cleanup of $email"
  else
    log_action "Deleting test user: $email"
    run_sql "${AUTH_USER_CLEANUP_SQL//\{email\}/$email}"
  fi

  unset TEST_USER_EMAIL TEST_USER_PASSWORD TEST_ACCESS_TOKEN
}

# Reset captured request/response state between tests.
reset_test_state() {
  unset HTTP_CODE HTTP_BODY HTTP_DURATION
  unset SQL_RESULT SQL_ROW_COUNT
}

# Put the system into a known state before a batch of tests.
# REDIS_FLUSH=1 flushes the configured Redis database (rate limiters, caches);
# TEST_PREP_SQL, when set, is executed against DB_NAME. Both default to off, so
# this is a no-op unless the project asks for it.
reset_test_environment() {
  if [ "${REDIS_FLUSH:-0}" = "1" ] && command -v redis-cli > /dev/null 2>&1; then
    log_action "Flushing Redis at ${REDIS_HOST:-localhost}:${REDIS_PORT:-6379}"
    redis-cli -h "${REDIS_HOST:-localhost}" -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || \
      log_warn "Redis flush failed"
  fi

  if [ -n "${TEST_PREP_SQL:-}" ] && db_configured; then
    log_action "Running TEST_PREP_SQL"
    run_sql "$TEST_PREP_SQL" > /dev/null 2>&1 || log_warn "TEST_PREP_SQL failed"
  fi
}

# ============================================================================
# TEST SUITE FUNCTIONS
# ============================================================================

# Start a test suite
# Usage: start_suite "Suite Name"
start_suite() {
  local name="$1"
  CURRENT_SUITE="$name"
  TOTAL_TESTS=0
  PASSED_TESTS=0
  FAILED_TESTS=0
  SKIPPED_TESTS=0

  section_header "$name"

  echo -e "${DIM}Configuration:${NC}"
  echo -e "  API Base:  ${BOLD}$API_BASE${NC}"
  echo -e "  Database:  ${BOLD}${DB_NAME:-none}${NC} @ ${BOLD}$DB_HOST${NC}"
  echo -e "  Verbose:   ${BOLD}$VERBOSE${NC}"
  echo ""
}

# End a test suite and print summary
# Usage: end_suite
end_suite() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║                         TEST SUITE SUMMARY                           ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  Suite:     ${BOLD}$CURRENT_SUITE${NC}"
  echo -e "  Total:     ${BOLD}$TOTAL_TESTS${NC}"
  echo -e "  ${GREEN}Passed:    $PASSED_TESTS${NC}"
  echo -e "  ${RED}Failed:    $FAILED_TESTS${NC}"
  echo -e "  ${YELLOW}Skipped:   $SKIPPED_TESTS${NC}"
  echo ""

  # Calculate pass rate
  if [ $TOTAL_TESTS -gt 0 ]; then
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "  Pass Rate: ${BOLD}${pass_rate}%${NC}"
  fi
  echo ""

  # Final verdict
  if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED ✅${NC}"
    return 0
  else
    echo -e "${RED}${BOLD}$FAILED_TESTS TEST(S) FAILED ❌${NC}"
    return 1
  fi
}

# Print real database statistics as evidence of system state.
# Driven by DB_STATS_QUERIES: "label=SQL" lines, each query returning a single
# value. Prints nothing at all when unset.
print_db_stats() {
  [ -n "${DB_STATS_QUERIES:-}" ] || return 0
  db_configured || return 0

  subsection_header "ACTUAL DATABASE STATISTICS"
  echo ""

  local line label query value
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in \#*) continue;; esac
    label="${line%%=*}"
    query="${line#*=}"
    [ -n "$query" ] && [ "$query" != "$line" ] || continue
    value=$(sql_value "$query")
    printf "  %-24s %s\n" "$label:" "${value:-n/a}"
  done <<< "$DB_STATS_QUERIES"
  echo ""
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Wait for API to be ready
wait_for_api() {
  local max_wait="${1:-30}"
  local url="${2:-${API_BASE}${HEALTH_PATH}}"

  log_action "Waiting for API at $url..."

  for i in $(seq 1 $max_wait); do
    if curl -s -A "$TEST_USER_AGENT" "$url" > /dev/null 2>&1; then
      log_info "API ready after ${i}s"
      return 0
    fi
    sleep 1
  done

  log_fail "API not ready after ${max_wait}s"
  return 1
}

# Generate random string
random_string() {
  local length="${1:-16}"
  cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n 1
}

# Generate random email
random_email() {
  echo "${TEST_USER_PREFIX:-harness_}$(random_string 8)_$(date +%s)@${TEST_EMAIL_DOMAIN:-example.com}"
}

# Sleep with message
sleep_with_message() {
  local seconds="$1"
  local message="${2:-Waiting ${seconds}s...}"

  log_info "$message"
  sleep "$seconds"
}

# ============================================================================
# EXPORT ALL FUNCTIONS
# ============================================================================

export -f section_header subsection_header test_header
export -f log_action log_command log_request log_response
export -f log_sql log_sql_result log_validation log_comparison
export -f log_pass log_fail log_skip log_warn log_info log_debug
export -f http_request http_get http_post http_put http_patch http_delete
export -f run_sql sql_value sql_count db_configured
export -f assert_http_status assert_json_field assert_json_equals
export -f assert_response_contains assert_sql_equals assert_sql_has_rows assert_sql_no_rows
export -f auth_body create_test_user login_test_user delete_test_user
export -f reset_test_state reset_test_environment
export -f start_suite end_suite print_db_stats
export -f wait_for_api random_string random_email sleep_with_message

echo -e "${DIM}Verbose Test Framework v2.0 loaded${NC}"
