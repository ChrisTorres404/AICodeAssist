#!/bin/bash
# ============================================================================
# {{PROJECT_NAME}} Enhanced Test Framework v3.0
# ============================================================================
# Core testing utilities with enhanced reporting, navigation, and UX.
# Application-agnostic: the database and metric sections of a summary are
# driven by DB_STATS_QUERIES and API_STAT_METRICS and print nothing when those
# are unset. Load the configuration first:
#
#   ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
#   source "$ROOT/{{PIPELINE_ROOT}}/harness/config/test-config.env"
#   source "$ROOT/{{PIPELINE_ROOT}}/harness/lib/test-framework.sh"
#   ...
#   end_test_suite        # prints the summary and exits 1 if anything failed
# ============================================================================

# pipefail only: a library must not abort the suite that sourced it on the first
# failed assertion. End every suite with end_test_suite so the exit code is honest.
set -o pipefail

# ============================================================================
# COLORS & STYLING
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Box drawing characters
BOX_TL='╔'
BOX_TR='╗'
BOX_BL='╚'
BOX_BR='╝'
BOX_H='═'
BOX_V='║'
BOX_ML='╠'
BOX_MR='╣'

# ============================================================================
# GLOBAL STATE
# ============================================================================
declare -a TEST_RESULTS=()
declare -a TEST_NAMES=()
declare -a TEST_DURATIONS=()
declare -a TEST_DATA=()
declare -a MENU_HISTORY=()
CURRENT_MENU="main"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
START_TIME=0
END_TIME=0

# Milliseconds since the epoch. GNU date and current BSD date both understand
# %N; older BSD date prints a literal "N" instead, so fall back to whole
# seconds rather than producing a nonsense duration.
now_ms() {
  local t; t="$(date +%s%N)"   # portability-ok: date-flags — the case below catches BSD's literal N
  case "$t" in
    ''|*[!0-9]*) echo "$(( $(date +%s) * 1000 ))";;
    *)           echo "$(( t / 1000000 ))";;
  esac
}

# Everything shared with the other two libraries — section_header, the HTTP
# verbs, run_sql, the credential and account helpers, assert_http_status,
# assert_json_equals, assert_sql_equals — comes from test-common.sh, which
# sources test-env.sh in turn for the connection details, health_url,
# db_configured and the known-state helpers. Nothing below redefines any of
# them, so this framework and test-helpers.sh cannot disagree about where the
# service is, what counts as a configured database, or what an assertion means.
# shellcheck source=./test-common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/test-common.sh"

# ============================================================================
# NAVIGATION SYSTEM
# ============================================================================

push_menu() {
  MENU_HISTORY+=("$CURRENT_MENU")
  CURRENT_MENU="$1"
}

pop_menu() {
  # Indexed from the length rather than with [-1]: negative subscripts need
  # bash 4.3 and macOS ships 3.2.
  local last=$(( ${#MENU_HISTORY[@]} - 1 ))
  if [ "$last" -ge 0 ]; then
    CURRENT_MENU="${MENU_HISTORY[$last]}"
    unset "MENU_HISTORY[$last]"
  else
    CURRENT_MENU="main"
  fi
}

# ============================================================================
# UI COMPONENTS
# ============================================================================

clear_screen() {
  [ -t 1 ] || return 0            # no terminal (wo verify --run, CI): never emit escape codes
  clear 2>/dev/null || true
  tput cup 0 0 2>/dev/null || true
}

draw_box() {
  local width=$1
  local title="$2"
  local color="${3:-$CYAN}"

  local title_len=${#title}
  local padding=$(( (width - title_len - 2) / 2 ))

  echo -e "${color}${BOX_TL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")${BOX_TR}${NC}"
  if [ -n "$title" ]; then
    echo -e "${color}${BOX_V}$(printf '%*s' $padding '')${WHITE}${BOLD} $title ${NC}${color}$(printf '%*s' $((width - padding - title_len - 2)) '')${BOX_V}${NC}"
    echo -e "${color}${BOX_ML}$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")${BOX_MR}${NC}"
  fi
}

draw_box_bottom() {
  local width=$1
  local color="${2:-$CYAN}"
  echo -e "${color}${BOX_BL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")${BOX_BR}${NC}"
}

show_progress_bar() {
  local current=$1
  local total=$2
  local width=40
  local percent=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))

  printf "\r  ["
  printf "${GREEN}%*s${NC}" $filled '' | tr ' ' '#'
  printf "${DIM}%*s${NC}" $empty '' | tr ' ' '-'
  printf "] %3d%% (%d/%d)" $percent $current $total
}

# ============================================================================
# TEST EXECUTION FRAMEWORK
# ============================================================================

begin_test_suite() {
  local suite_name="$1"

  TEST_RESULTS=()
  TEST_NAMES=()
  TEST_DURATIONS=()
  TEST_DATA=()
  TOTAL_TESTS=0
  PASSED_TESTS=0
  FAILED_TESTS=0
  SKIPPED_TESTS=0
  START_TIME=$(date +%s)

  clear_screen
  echo ""
  draw_box 70 "$suite_name" "$CYAN"
  echo -e "${CYAN}${BOX_V}${NC}  Started: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "${CYAN}${BOX_V}${NC}  Database: ${DB_NAME:-none} @ $DB_HOST"
  echo -e "${CYAN}${BOX_V}${NC}  API: $API_BASE"
  draw_box_bottom 70 "$CYAN"
  echo ""
}

run_test() {
  local test_id="$1"
  local test_name="$2"
  local test_command="$3"
  local expected="${4:-}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  local test_start; test_start=$(now_ms)

  echo -e "${YELLOW}[$test_id]${NC} $test_name"

  # Execute test
  local result
  local exit_code=0
  result=$(eval "$test_command" 2>&1) || exit_code=$?

  local test_end; test_end=$(now_ms)
  local duration_ms=$(( test_end - test_start ))

  TEST_NAMES+=("$test_name")
  TEST_DURATIONS+=("$duration_ms")

  # Evaluate result
  if [ $exit_code -eq 0 ]; then
    if [ -n "$expected" ]; then
      if echo "$result" | grep -q "$expected"; then
        TEST_RESULTS+=("PASS")
        TEST_DATA+=("$result")
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "  ${GREEN}PASS${NC} (${duration_ms}ms)"
        return 0
      else
        TEST_RESULTS+=("FAIL")
        TEST_DATA+=("Expected: $expected | Got: $result")
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "  ${RED}FAIL${NC} - Expected: $expected"
        echo -e "  ${DIM}Got: $result${NC}"
        return 1
      fi
    else
      TEST_RESULTS+=("PASS")
      TEST_DATA+=("$result")
      PASSED_TESTS=$((PASSED_TESTS + 1))
      echo -e "  ${GREEN}PASS${NC} (${duration_ms}ms)"
      return 0
    fi
  else
    TEST_RESULTS+=("FAIL")
    TEST_DATA+=("Exit code: $exit_code | Output: $result")
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "  ${RED}FAIL${NC} - Exit code: $exit_code"
    echo -e "  ${DIM}$result${NC}"
    return 1
  fi
}

skip_test() {
  local test_id="$1"
  local test_name="$2"
  local reason="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
  TEST_NAMES+=("$test_name")
  TEST_RESULTS+=("SKIP")
  TEST_DURATIONS+=("0")
  TEST_DATA+=("$reason")

  echo -e "${YELLOW}[$test_id]${NC} $test_name"
  echo -e "  ${BLUE}SKIP${NC} - $reason"
}

# ============================================================================
# SQL HELPERS
# ============================================================================

# db_configured comes from test-env.sh; run_sql from test-common.sh. query_db
# is this framework's own: single-value output for run_test to grep.

query_db() {
  local query="$1"
  db_configured || return 1
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null
}

query_db_verbose() {
  local query="$1"
  db_configured || return 1
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$query" 2>/dev/null
}

# The id-and-name form of a database assertion: it records a numbered test in
# this framework's report, which is what the summary and the failure details
# are built from. test-common.sh's assert_sql_equals is the equality form of
# the same idea — same query, same comparison, no test id — and is available to
# every library, including this one.
#
#   assert_sql 3.1 "the row was written" "SELECT count(*) FROM t;" 1
#   assert_sql_equals "SELECT count(*) FROM t;" 1 "the row was written"
assert_sql() {
  local test_id="$1"
  local test_name="$2"
  local query="$3"
  local expected="$4"

  run_test "$test_id" "$test_name" "query_db \"$query\"" "$expected"
}

count_rows() {
  local table="$1"
  local where="${2:-1=1}"
  query_db "SELECT COUNT(*) FROM $table WHERE $where;"
}

# ============================================================================
# HTTP HELPERS
# ============================================================================

# http_get and http_post come from test-common.sh. They leave the result in
# HTTP_CODE, HTTP_BODY and HTTP_DURATION rather than echoing the body with the
# code appended, so read those variables — a captured call, resp=$(http_get
# "$url"), runs in a subshell where everything they set is discarded.
#
# extract_http_code and extract_http_body below remain for a response a suite
# built with its own curl -w.

extract_http_code() {
  echo "$1" | grep "HTTP_CODE:" | cut -d: -f2
}

extract_http_body() {
  echo "$1" | grep -v "HTTP_CODE:"
}

assert_http() {
  local test_id="$1"
  local test_name="$2"
  local method="$3"
  local url="$4"
  local expected_code="$5"
  local data="${6:-}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  local test_start; test_start=$(now_ms)

  echo -e "${YELLOW}[$test_id]${NC} $test_name"

  # Not captured in a subshell: http_get and http_post answer in HTTP_CODE and
  # HTTP_BODY, and a subshell would throw both away.
  if [ "$method" = "GET" ]; then
    http_get "$url"
  else
    http_post "$url" "$data"
  fi

  local http_code="${HTTP_CODE:-}"
  local body="${HTTP_BODY:-}"

  local test_end; test_end=$(now_ms)
  local duration_ms=$(( test_end - test_start ))

  TEST_NAMES+=("$test_name")
  TEST_DURATIONS+=("$duration_ms")

  if [ "$http_code" = "$expected_code" ]; then
    TEST_RESULTS+=("PASS")
    TEST_DATA+=("HTTP $http_code | ${body:0:100}")
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "  ${GREEN}PASS${NC} - HTTP $http_code (${duration_ms}ms)"
    return 0
  else
    TEST_RESULTS+=("FAIL")
    TEST_DATA+=("Expected HTTP $expected_code, got $http_code | ${body:0:200}")
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "  ${RED}FAIL${NC} - Expected HTTP $expected_code, got $http_code"
    return 1
  fi
}

# ============================================================================
# DATA COLLECTION FOR SUMMARIES
# ============================================================================

# DB_STATS_QUERIES holds "label=SQL" lines, one per statistic, each returning a
# single value. Unset (the default) means no database section is printed.
collect_database_stats() {
  [ -n "${DB_STATS_QUERIES:-}" ] || return 0
  db_configured || return 0

  local line label query value
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in \#*) continue;; esac
    label="${line%%=*}"
    query="${line#*=}"
    [ -n "$query" ] && [ "$query" != "$line" ] || continue
    value=$(query_db "$query" | head -1)
    echo "$label: ${value:-n/a}"
  done <<< "$DB_STATS_QUERIES"
}

# API_STAT_METRICS is a space-separated list of Prometheus-format metric names.
# Unset (the default) means no metrics section is printed.
collect_api_stats() {
  [ -n "${API_STAT_METRICS:-}" ] || return 0

  local metrics
  metrics=$(curl -s -A "$TEST_USER_AGENT" "${API_BASE}${METRICS_PATH}" 2>/dev/null || echo "")
  if [ -z "$metrics" ]; then
    echo "metrics endpoint unavailable at ${API_BASE}${METRICS_PATH}"
    return 0
  fi

  local name value
  for name in $API_STAT_METRICS; do
    value=$(echo "$metrics" | grep "^$name" | head -1 | awk '{print $NF}')
    echo "$name: ${value:-0}"
  done
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_summary_report() {
  END_TIME=$(date +%s)
  local total_duration=$((END_TIME - START_TIME))

  echo ""
  echo ""
  draw_box 70 "TEST RESULTS SUMMARY" "$CYAN"
  echo ""

  # Overall status
  local status_color=$GREEN
  local status_icon="PASSED"
  if [ $FAILED_TESTS -gt 0 ]; then
    status_color=$RED
    status_icon="FAILED"
  fi

  echo -e "  ${BOLD}Overall Status:${NC} ${status_color}${BOLD}$status_icon${NC}"
  SUITE_EXIT_CODE=$(( FAILED_TESTS > 0 ? 1 : 0 ))
  echo ""

  # Statistics box
  echo -e "  ${BOLD}Test Statistics:${NC}"
  echo -e "  ├─ Total Tests:    ${BOLD}$TOTAL_TESTS${NC}"
  echo -e "  ├─ ${GREEN}Passed:${NC}         ${GREEN}$PASSED_TESTS${NC}"
  echo -e "  ├─ ${RED}Failed:${NC}         ${RED}$FAILED_TESTS${NC}"
  echo -e "  ├─ ${BLUE}Skipped:${NC}        ${BLUE}$SKIPPED_TESTS${NC}"
  echo -e "  └─ Duration:      ${BOLD}${total_duration}s${NC}"
  echo ""

  # Pass rate
  if [ $TOTAL_TESTS -gt 0 ]; then
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "  ${BOLD}Pass Rate:${NC} ${pass_rate}%"

    # Visual pass rate bar
    local bar_width=40
    local filled=$((pass_rate * bar_width / 100))
    local empty=$((bar_width - filled))

    echo -n "  ["
    if [ $pass_rate -ge 80 ]; then
      printf "${GREEN}%*s${NC}" $filled '' | tr ' ' '#'
    elif [ $pass_rate -ge 50 ]; then
      printf "${YELLOW}%*s${NC}" $filled '' | tr ' ' '#'
    else
      printf "${RED}%*s${NC}" $filled '' | tr ' ' '#'
    fi
    printf "${DIM}%*s${NC}" $empty '' | tr ' ' '-'
    echo "]"
  fi

  echo ""
  draw_box_bottom 70 "$CYAN"

  # Detailed results (if failures exist)
  if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    draw_box 70 "FAILED TESTS DETAILS" "$RED"
    echo ""

    for i in "${!TEST_RESULTS[@]}"; do
      if [ "${TEST_RESULTS[$i]}" = "FAIL" ]; then
        echo -e "  ${RED}X${NC} ${TEST_NAMES[$i]}"
        echo -e "    ${DIM}${TEST_DATA[$i]}${NC}"
        echo ""
      fi
    done

    draw_box_bottom 70 "$RED"
  fi

  # Real data summary — only when the project configured something to show
  local db_stats api_stats
  db_stats="$(collect_database_stats)"
  api_stats="$(collect_api_stats)"

  if [ -n "$db_stats" ] || [ -n "$api_stats" ]; then
    echo ""
    draw_box 70 "ACTUAL DATA SUMMARY" "$GREEN"
    echo ""
    if [ -n "$db_stats" ]; then
      echo -e "  ${BOLD}Database Statistics:${NC}"
      echo "$db_stats" | while read -r line; do echo "  $line"; done
      echo ""
    fi
    if [ -n "$api_stats" ]; then
      echo -e "  ${BOLD}Metrics:${NC}"
      echo "$api_stats" | while read -r line; do echo "  $line"; done
      echo ""
    fi
    draw_box_bottom 70 "$GREEN"
  fi
}

# ============================================================================
# USER-FRIENDLY PROMPTS
# ============================================================================

show_welcome_message() {
  echo ""
  echo -e "  ${CYAN}${BOLD}Welcome to the {{PROJECT_NAME}} Test Suite!${NC}"
  echo ""
  echo -e "  This tool runs real requests against a running system and"
  echo -e "  checks the state that changed. Each test covers one behaviour."
  echo ""
  echo -e "  ${BOLD}Quick Tips:${NC}"
  echo -e "  ${DIM}- Type the number next to an option to select it${NC}"
  echo -e "  ${DIM}- Type 'b' to go back to the previous menu${NC}"
  echo -e "  ${DIM}- Type 'h' for help at any time${NC}"
  echo -e "  ${DIM}- Type '0' to exit${NC}"
  echo ""
}

show_help() {
  clear_screen
  draw_box 70 "HELP - How to Use This Tool" "$CYAN"
  echo ""
  echo -e "  ${BOLD}Navigation:${NC}"
  echo -e "  ├─ Enter a number to select that option"
  echo -e "  ├─ Type ${BOLD}b${NC} or ${BOLD}back${NC} to go to previous menu"
  echo -e "  ├─ Type ${BOLD}m${NC} or ${BOLD}menu${NC} to go to main menu"
  echo -e "  └─ Type ${BOLD}0${NC} or ${BOLD}exit${NC} to quit"
  echo ""
  echo -e "  ${BOLD}Test Categories:${NC}"
  echo -e "  ├─ ${CYAN}Quick Tests${NC} - Fast tests (~2 min) for daily checks"
  echo -e "  ├─ ${CYAN}Full Suite${NC} - Comprehensive tests (~10 min)"
  echo -e "  ├─ ${CYAN}Individual Tests${NC} - Test specific features"
  echo -e "  └─ ${CYAN}Stress Tests${NC} - Performance and load testing"
  echo ""
  echo -e "  ${BOLD}Understanding Results:${NC}"
  echo -e "  ├─ ${GREEN}PASS${NC} - Test succeeded as expected"
  echo -e "  ├─ ${RED}FAIL${NC} - Test did not meet expectations"
  echo -e "  └─ ${BLUE}SKIP${NC} - Test was skipped (see reason)"
  echo ""
  echo -e "  ${BOLD}After Tests Complete:${NC}"
  echo -e "  You'll see a summary showing:"
  echo -e "  ├─ How many tests passed/failed"
  echo -e "  ├─ Real data from your database"
  echo -e "  └─ Specific details about any failures"
  echo ""
  draw_box_bottom 70 "$CYAN"
  echo ""
  read -p "$(echo -e "${DIM}Press Enter to continue...${NC}")"
}

prompt_user() {
  local prompt_text="$1"
  local default="${2:-}"

  # The prompt goes to stderr so the answer is the only thing on stdout:
  #   answer="$(prompt_user "Suite number")"
  if [ -n "$default" ]; then
    echo -ne "${CYAN}${BOLD}> ${NC}$prompt_text ${DIM}[$default]${NC}: " >&2
  else
    echo -ne "${CYAN}${BOLD}> ${NC}$prompt_text: " >&2
  fi

  read user_input

  if [ -z "$user_input" ] && [ -n "$default" ]; then
    echo "$default"
  else
    echo "$user_input"
  fi
}

confirm_action() {
  local message="$1"
  echo -ne "${YELLOW}? ${NC}$message ${DIM}(y/n)${NC}: "
  read confirm

  case "$confirm" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

wait_for_key() {
  echo ""
  read -p "$(echo -e "${DIM}Press Enter to continue...${NC}")"
}

# ============================================================================
# SERVER CHECK
# ============================================================================

check_server_status() {
  local url="${1:-$(health_url || true)}"
  local max_wait="${2:-10}"

  echo -e "${CYAN}Checking server status...${NC}"

  for i in $(seq 1 $max_wait); do
    if curl -s -A "$TEST_USER_AGENT" "$url" > /dev/null 2>&1; then
      echo -e "${GREEN}Server is ready!${NC}"
      return 0
    fi
    echo -ne "\r  Waiting... ($i/$max_wait)"
    sleep 1
  done

  echo ""
  echo -e "${RED}Server not responding at $url${NC}"
  echo -e "${YELLOW}Start the service under test, then run this again.${NC}"
  return 1
}

check_database_status() {
  if ! db_configured; then
    echo -e "${DIM}No database configured — skipping database check${NC}"
    return 0
  fi

  echo -e "${CYAN}Checking database connection...${NC}"

  if query_db "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}Database connected!${NC}"
    return 0
  else
    echo -e "${RED}Cannot connect to database${NC}"
    echo -e "${YELLOW}Please check your database settings${NC}"
    return 1
  fi
}

# ============================================================================
# EXPORT FOR USE IN OTHER SCRIPTS
# ============================================================================

export -f draw_box draw_box_bottom show_progress_bar
export -f begin_test_suite run_test skip_test
export -f query_db query_db_verbose assert_sql assert_sql_equals count_rows
export -f http_request http_get http_post extract_http_code extract_http_body assert_http
export -f generate_summary_report
export -f show_welcome_message show_help prompt_user confirm_action wait_for_key
export -f check_server_status check_database_status db_configured run_psql run_sql
# The shared internals the functions above call, so an exported function still
# works in a child shell that inherited it.
export -f _harness_is_func _harness_log _harness_pass _harness_fail
export -f push_menu pop_menu clear_screen
export -f collect_database_stats collect_api_stats

# End the suite honestly: summary, then the exit code wo verify --run records.
end_test_suite() {
  generate_summary_report
  exit "${SUITE_EXIT_CODE:-$(( ${FAILED_TESTS:-0} > 0 ? 1 : 0 ))}"
}
