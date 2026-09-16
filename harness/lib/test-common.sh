#!/usr/bin/env bash
# ============================================================================
# Shared test helpers — one definition of everything more than one library needs
# ============================================================================
# Sourced, never executed. test-helpers.sh, test-framework.sh and
# verbose-test-framework.sh all source this file, and none of them defines any
# of the names below for itself.
#
#   . "$(dirname "$0")/../lib/test-common.sh"
#
# It exists because they used to define them separately. Thirteen function
# names were defined twice across harness/lib, so which body a suite got
# depended on the order it happened to source the libraries in — and the worst
# pair was silent: verbose-test-framework.sh's own reset_test_environment
# hard-coded redis-cli and ignored CACHE_FLUSH_CMD, so a project whose limiter
# is not Redis had its "known state" step quietly do nothing.
#
# Where two definitions differed, the more general one is kept and the narrower
# call shape still works. Each function below says which, in the shape a caller
# reads: what it is called with, and what it leaves behind.
#
# Provides:
#   section_header      a titled rule, any title length
#   http_request        one request; sets HTTP_CODE, HTTP_BODY, HTTP_DURATION
#   http_get / http_post / http_put / http_patch / http_delete
#                       the same, per verb
#   run_sql             one query; echoes the bare result and sets SQL_RESULT
#                       and SQL_ROW_COUNT
#   auth_body           a JSON credential body from the configured field names
#   random_email        a unique throwaway address
#   create_test_user    register one through AUTH_REGISTER_PATH
#   delete_test_user    remove one through AUTH_USER_CLEANUP_SQL
#   assert_http_status  the status of a request, or of the last one made
#   assert_json_equals  a JSON field of a response, or of the last one
#   assert_sql_equals   a query returns exactly this value
#
# Two names that read as one pair:
#   assert_sql_equals <query> <expected> [description]     the equality form,
#                       defined here and available to every library
#   assert_sql <id> <name> <query> <expected>              the id-and-name form,
#                       defined in test-framework.sh, which records the result
#                       as a numbered test in that framework's report
#
# Environment primitives — API_BASE, TEST_USER_AGENT, health_url, db_configured,
# run_psql, flush_rate_limiter, reset_test_environment and its alias
# clean_risk_state — come from test-env.sh, which this file sources.
# ============================================================================

# Guard: three libraries source this, and a suite may source two of them.
if [ -n "${_HARNESS_TEST_COMMON_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
_HARNESS_TEST_COMMON_LOADED=1

# Service, database, cache and known-state primitives.
# shellcheck source=./test-env.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/test-env.sh"

# ----------------------------------------------------------------------------
# Colours
# ----------------------------------------------------------------------------
# Defaults only: a library or suite that already set them keeps its own.
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
MAGENTA="${MAGENTA:-\033[0;35m}"
CYAN="${CYAN:-\033[0;36m}"
DIM="${DIM:-\033[2m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

# ----------------------------------------------------------------------------
# Talking to whichever framework is loaded
# ----------------------------------------------------------------------------
# A shared function cannot know whether the suite that called it loaded the
# verbose framework's transcript loggers, test-helpers.sh's counters, both, or
# neither. It asks, rather than assuming — that is what let the same name mean
# two different things before.

_harness_is_func() { [ "$(type -t "${1:-}" 2>/dev/null)" = function ]; }

# Call an optional logger if it is loaded, and be a no-op if it is not.
_harness_log() {
  _harness_is_func "${1:-}" || return 0
  "$@"
}

# Record one assertion. The printing goes to whichever framework is loaded, so
# output keeps that framework's shape; the counters of both are kept honest,
# because a suite that loaded both prints its summary from only one of them.
_harness_pass() {
  local message="${1:-}"
  if _harness_is_func log_pass; then
    log_pass "$message"                                   # counts PASSED_TESTS
    if _harness_is_func record_pass; then record_pass; fi # and PASSED, if loaded
  elif _harness_is_func test_pass; then
    test_pass "$message"                                  # counts PASSED
  else
    echo -e "${GREEN}  PASS${NC} $message"
    PASSED=$(( ${PASSED:-0} + 1 )); PASSED_TESTS=$(( ${PASSED_TESTS:-0} + 1 ))
  fi
  return 0
}

_harness_fail() {
  local message="${1:-}"
  if _harness_is_func log_fail; then
    log_fail "$message"
    if _harness_is_func record_fail; then record_fail; fi
  elif _harness_is_func test_fail; then
    test_fail "$message"
  else
    echo -e "${RED}  FAIL${NC} $message"
    FAILED=$(( ${FAILED:-0} + 1 )); FAILED_TESTS=$(( ${FAILED_TESTS:-0} + 1 ))
  fi
  return 0
}

# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------
# The rule form rather than the box the verbose framework drew: a box is drawn
# to a fixed width, and a title longer than it broke the frame. This one takes
# a title of any length, which is what made it the more general of the two.
section_header() {
  echo ""
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}  ${1:-}${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
}

# ----------------------------------------------------------------------------
# HTTP
# ----------------------------------------------------------------------------
# One request, with everything it produced left in variables:
#
#   http_request METHOD URL [BODY] [EXTRA_HEADER...]
#   http_get URL [BODY] [EXTRA_HEADER...]        and http_post/put/patch/delete
#
#   HTTP_CODE      the status code
#   HTTP_BODY      the response body
#   HTTP_DURATION  whole seconds the request took
#
# This is the general form of the two that existed: the other returned the body
# with the code appended and could carry neither extra headers nor a duration.
# Read the variables rather than capturing the call — `resp=$(http_get "$url")`
# runs it in a subshell, where everything it set dies with the subshell.
#
# A browser User-Agent is always sent, and an Origin header unless the caller
# supplies one, because a CSRF guard commonly requires it on a state change.
http_request() {
  local method="${1:-GET}" url="${2:-}" body="${3:-}"
  if [ "$#" -ge 3 ]; then shift 3; else shift "$#"; fi
  local -a extra_headers=()
  if [ "$#" -gt 0 ]; then extra_headers=("$@"); fi

  local header
  # The command as a caller could paste it, for the transcript.
  local curl_cmd="curl -s -X $method -H 'Content-Type: application/json' -H 'Accept: application/json'"
  for header in ${extra_headers[@]+"${extra_headers[@]}"}; do
    if [ -n "$header" ]; then curl_cmd="$curl_cmd -H '$header'"; fi
  done
  if [ -n "$body" ]; then curl_cmd="$curl_cmd -d '$body'"; fi
  curl_cmd="$curl_cmd '$url'"
  _harness_log log_command "$curl_cmd"

  local -a header_args=(-H "Content-Type: application/json" -H "Accept: application/json" -A "$TEST_USER_AGENT")

  local has_origin=false
  for header in ${extra_headers[@]+"${extra_headers[@]}"}; do
    case "$header" in Origin:*) has_origin=true;; esac
  done
  if [ "$has_origin" = false ] && [ -n "${ORIGIN:-}" ]; then
    header_args+=(-H "Origin: $ORIGIN")
  fi

  for header in ${extra_headers[@]+"${extra_headers[@]}"}; do
    if [ -n "$header" ]; then header_args+=(-H "$header"); fi
  done

  local start_time end_time response
  start_time=$(date +%s)
  if [ -n "$body" ]; then
    response=$(curl -s -w '\n---HTTP_META---\nHTTP_CODE:%{http_code}\n' \
      -X "$method" "${header_args[@]}" -d "$body" "$url" 2>&1)
  else
    response=$(curl -s -w '\n---HTTP_META---\nHTTP_CODE:%{http_code}\n' \
      -X "$method" "${header_args[@]}" "$url" 2>&1)
  fi
  end_time=$(date +%s)

  HTTP_BODY=$(echo "$response" | sed '/---HTTP_META---/,$d')
  # Anchored and last: curl writes the marker at the start of its own line, and
  # a response body is free to contain the word HTTP_CODE itself.
  HTTP_CODE=$(echo "$response" | grep '^HTTP_CODE:' | tail -1 | cut -d: -f2)
  HTTP_DURATION=$(( end_time - start_time ))

  _harness_log log_request "$method" "$url" "" "$body"
  _harness_log log_response "$HTTP_CODE" "$HTTP_BODY" "$HTTP_DURATION"
  return 0
}

http_get()    { http_request GET    "$@"; }
http_post()   { http_request POST   "$@"; }
http_put()    { http_request PUT    "$@"; }
http_patch()  { http_request PATCH  "$@"; }
http_delete() { http_request DELETE "$@"; }

# ----------------------------------------------------------------------------
# Database
# ----------------------------------------------------------------------------
# One query. The result is echoed unadorned, one value per line, so
#
#   count="$(run_sql "select count(*) from t" | tr -d ' ')"
#
# reads the value and nothing else; SQL_RESULT and SQL_ROW_COUNT hold the same
# answer for a caller that ran the query for its side effect. The transcript —
# when the verbose framework's loggers are loaded — goes to stderr, so it can
# never end up inside a captured value.
#
# Inert without a database: it says so on stderr and returns 1, rather than
# leaving a suite to compare against psql's error text.
run_sql() {
  local query="${1:-}" rc=0

  if ! db_configured; then
    echo "run_sql: no database configured (set DB_NAME)" >&2
    SQL_RESULT=""; SQL_ROW_COUNT=0
    return 1
  fi

  _harness_log log_sql "$query" >&2

  SQL_RESULT="$(run_psql "$query")" || rc=$?
  if [ -n "$SQL_RESULT" ]; then
    SQL_ROW_COUNT="$(printf '%s\n' "$SQL_RESULT" | grep -c '^' | tr -d '[:space:]')"
  else
    SQL_ROW_COUNT=0
  fi

  _harness_log log_sql_result "$SQL_RESULT" "$SQL_ROW_COUNT" >&2

  if [ -n "$SQL_RESULT" ]; then printf '%s\n' "$SQL_RESULT"; fi
  return "$rc"
}

# ----------------------------------------------------------------------------
# Credentials and accounts
# ----------------------------------------------------------------------------

# A JSON credential body from the configured field names, merged with a JSON
# object of extra fields — the third argument, or AUTH_EXTRA_LOGIN_FIELDS when
# it is left off. (The narrower of the two old definitions took no third
# argument at all; passing two still behaves exactly as it did.)
auth_body() {
  local email="${1:-}"
  local password="${2:-}"
  local extra="${3:-${AUTH_EXTRA_LOGIN_FIELDS:-}}"
  [ -n "$extra" ] || extra='{}'

  jq -n \
    --arg ef "${AUTH_EMAIL_FIELD:-email}" --arg e "$email" \
    --arg pf "${AUTH_PASSWORD_FIELD:-password}" --arg p "$password" \
    --argjson extra "$extra" \
    '{($ef): $e, ($pf): $p} + $extra'
}

# A unique address for a throwaway account. No dependency on a random-string
# helper: the clock and $RANDOM are in every shell, which is what makes this
# the portable one of the two definitions it replaces.
random_email() {
  echo "${TEST_USER_PREFIX:-harness_}$(date +%s)_$RANDOM@${TEST_EMAIL_DOMAIN:-example.com}"
}

# Register a throwaway account through AUTH_REGISTER_PATH.
#
#   create_test_user [email] [password]      # both default: a random address
#                                            # and TEST_PASSWORD
#
# Echoes the response body, as the plainer of the two old definitions did, and
# additionally leaves behind everything the richer one did: TEST_USER_EMAIL and
# TEST_USER_PASSWORD, the session variables of whichever library is loaded, and
# HTTP_CODE / HTTP_BODY. Returns non-zero when the registration was refused.
#
# AUTH_POST_REGISTER_SQL is for a project that will not let a brand-new account
# log in until something outside the API has happened — an address confirmed,
# an approval flag set. Its {email} is substituted; unset, nothing runs.
create_test_user() {
  local email="${1:-$(random_email)}"
  local password="${2:-${TEST_PASSWORD:-TestPassword123!}}"

  _harness_log log_action "Registering test user: $email"
  http_request POST "${API_BASE}${AUTH_REGISTER_PATH:-/auth/register}" \
    "$(auth_body "$email" "$password")"

  case "${HTTP_CODE:-}" in
    200|201)
      TEST_USER_EMAIL="$email"
      TEST_USER_PASSWORD="$password"
      _harness_log capture_session_vars "$HTTP_BODY"     # verbose framework's TEST_*
      _harness_log _capture_session "$HTTP_BODY"         # test-helpers' CURRENT_*

      if [ -n "${AUTH_POST_REGISTER_SQL:-}" ] && db_configured; then
        _harness_log log_action "Applying AUTH_POST_REGISTER_SQL for $email"
        run_sql "${AUTH_POST_REGISTER_SQL//\{email\}/$email}" > /dev/null 2>&1 || \
          _harness_log log_warn "AUTH_POST_REGISTER_SQL failed"
      fi

      _harness_log log_info "Registered $email${TEST_USER_ID:+ (id $TEST_USER_ID)}"
      printf '%s\n' "${HTTP_BODY:-}"
      return 0
      ;;
  esac

  _harness_log log_warn "Failed to register test user: HTTP ${HTTP_CODE:-none}"
  printf '%s\n' "${HTTP_BODY:-}"
  return 1
}

# Remove a user the harness created.
#
#   delete_test_user [email]                 # defaults to TEST_USER_EMAIL
#
# Requires AUTH_USER_CLEANUP_SQL, whose {email} is substituted. Without it the
# cleanup is skipped loudly rather than guessing at a schema, because a harness
# inventing a DELETE against an unknown table is how test cleanup becomes an
# incident. The captured session is forgotten either way.
delete_test_user() {
  local email="${1:-${TEST_USER_EMAIL:-}}"

  if [ -z "${AUTH_USER_CLEANUP_SQL:-}" ]; then
    echo "delete_test_user: AUTH_USER_CLEANUP_SQL not set — skipping cleanup of ${email:-the test user}" >&2
    _harness_log log_warn "AUTH_USER_CLEANUP_SQL not set — skipping cleanup of ${email:-the test user}"
  else
    _harness_log log_action "Deleting test user: $email"
    run_sql "${AUTH_USER_CLEANUP_SQL//\{email\}/$email}"
  fi

  unset TEST_USER_EMAIL TEST_USER_PASSWORD TEST_ACCESS_TOKEN \
        TEST_REFRESH_TOKEN TEST_CSRF_TOKEN TEST_USER_ID TEST_SESSION_ID
  return 0
}

# ----------------------------------------------------------------------------
# Assertions
# ----------------------------------------------------------------------------
# Each records into the counters of whichever framework is loaded and returns
# non-zero on failure, so a suite can also stop where it matters.

# The status code of a request.
#
#   assert_http_status <expected> [message]
#       the request just made — HTTP_CODE, from http_get and friends
#   assert_http_status <name> <url> <expected> [method] [body]
#       make the request here and check it
#
# The first argument decides: three digits on their own, or with a message, is
# the first form; anything else is a test name and the second form. Any three
# digits, not only 1xx-5xx — curl reports 000 when nothing answered, and
# "assert nothing answered" is a check a suite makes on purpose.
# Both were real call shapes before this file existed, and both still work.
assert_http_status() {
  case "${1:-}" in
    [0-9][0-9][0-9])
      if [ "$#" -le 2 ]; then
        local expected="$1" message="${2:-HTTP status should be $1}"
        _harness_log log_validation "Checking HTTP status code"
        _harness_log log_comparison "$expected" "${HTTP_CODE:-}"
        if [ "${HTTP_CODE:-}" = "$expected" ]; then
          _harness_pass "$message"
          return 0
        fi
        _harness_fail "Expected HTTP $expected, got ${HTTP_CODE:-nothing}"
        return 1
      fi
      ;;
  esac

  local test_name="${1:-HTTP status check}" url="${2:-}" expected="${3:-}"
  local method="${4:-GET}" data="${5:-}"

  echo "Test: $test_name"
  http_request "$method" "$url" "$data"
  # The shape the request form used to leave behind, for a suite that reads it.
  RESPONSE="${HTTP_BODY:-}
HTTP_CODE:${HTTP_CODE:-}"

  if [ "${HTTP_CODE:-}" = "$expected" ]; then
    _harness_pass "$test_name (HTTP ${HTTP_CODE:-})"
    return 0
  fi
  _harness_fail "$test_name - expected HTTP $expected, got ${HTTP_CODE:-nothing}"
  return 1
}

# A JSON field of a response equals a value.
#
#   assert_json_equals <field> <expected> [message]
#       the last response — HTTP_BODY, from http_get and friends
#   assert_json_equals <response> <field> <expected> [description]
#       a response captured by hand, with or without a status marker appended
#
# Four arguments is always the second form and two is always the first. With
# three, the first argument decides: a jq path is a bare token, and a response
# body carries a brace, a quote or whitespace.
assert_json_equals() {
  local response field expected description

  if [ "$#" -ge 4 ]; then
    response="$1"; field="$2"; expected="$3"; description="${4:-JSON field check}"
  elif [ "$#" -le 2 ]; then
    response="${HTTP_BODY:-}"; field="${1:-}"; expected="${2:-}"
    description="$field should equal $expected"
  else
    case "${1:-}" in
      ''|*[\{\"]*|*[[:space:]]*)
        response="$1"; field="$2"; expected="$3"; description="JSON field check";;
      *)
        response="${HTTP_BODY:-}"; field="$1"; expected="$2"; description="$3";;
    esac
  fi

  local body actual
  body="$(printf '%s\n' "$response" | grep -v 'HTTP_STATUS:' | grep -v '^HTTP_CODE:')"
  actual="$(printf '%s' "$body" | jq -r ".$field // empty" 2>/dev/null)"

  _harness_log log_validation "Checking $field equals expected value"
  _harness_log log_comparison "$expected" "$actual"

  if [ "$actual" = "$expected" ]; then
    _harness_pass "$description ($field=$actual)"
    return 0
  fi
  _harness_fail "$description - expected $field='$expected', got '${actual:-}'"
  return 1
}

# A query returns exactly this value.
#
#   assert_sql_equals <query> <expected> [description]
#
# The query and its result are shown first: a database assertion whose query is
# not printed proves nothing. test-framework.sh's assert_sql is the id-and-name
# form of the same assertion, recorded as a numbered test in that framework's
# report; this is the form every library has.
assert_sql_equals() {
  local query="${1:-}" expected="${2:-}" description="${3:-SQL check}"

  _harness_log show_sql "$query"
  local actual
  actual="$(run_sql "$query" | head -1 | tr -d '[:space:]')"
  _harness_log show_result "$actual"
  _harness_log log_validation "Checking SQL result equals expected"
  _harness_log log_comparison "$expected" "$actual"

  if [ "$actual" = "$expected" ]; then
    _harness_pass "$description ($actual)"
    return 0
  fi
  _harness_fail "$description - expected '$expected', got '${actual:-}'"
  return 1
}
