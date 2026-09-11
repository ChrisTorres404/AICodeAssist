#!/bin/bash
# ============================================================================
# {{PROJECT_NAME}}ID Enhanced Test Framework v3.0
# ============================================================================
# Core testing utilities with enhanced reporting, navigation, and UX
# For non-technical users: Clear prompts, summaries, and guidance
# ============================================================================

# Strict mode
set -eo pipefail

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

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-{{PROJECT_SLUG}}}"
DB_NAME="${DB_NAME:-{{DB_NAME}}}"
export PGPASSWORD="${PGPASSWORD:-password}"

# API connection
API_BASE="${API_BASE:-http://localhost:3001/api/v1}"

# ============================================================================
# NAVIGATION SYSTEM
# ============================================================================

push_menu() {
  MENU_HISTORY+=("$CURRENT_MENU")
  CURRENT_MENU="$1"
}

pop_menu() {
  if [ ${#MENU_HISTORY[@]} -gt 0 ]; then
    CURRENT_MENU="${MENU_HISTORY[-1]}"
    unset 'MENU_HISTORY[-1]'
  else
    CURRENT_MENU="main"
  fi
}

# ============================================================================
# UI COMPONENTS
# ============================================================================

clear_screen() {
  clear
  tput cup 0 0
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
  echo -e "${CYAN}${BOX_V}${NC}  Database: $DB_NAME @ $DB_HOST"
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
  local test_start=$(date +%s%N)

  echo -e "${YELLOW}[$test_id]${NC} $test_name"

  # Execute test
  local result
  local exit_code=0
  result=$(eval "$test_command" 2>&1) || exit_code=$?

  local test_end=$(date +%s%N)
  local duration_ms=$(( (test_end - test_start) / 1000000 ))

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

query_db() {
  local query="$1"
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null
}

query_db_verbose() {
  local query="$1"
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "$query" 2>/dev/null
}

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

http_get() {
  local url="$1"
  curl -s -w "\nHTTP_CODE:%{http_code}" "$url" 2>/dev/null
}

http_post() {
  local url="$1"
  local data="$2"
  curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$data" 2>/dev/null
}

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
  local test_start=$(date +%s%N)

  echo -e "${YELLOW}[$test_id]${NC} $test_name"

  local response
  if [ "$method" = "GET" ]; then
    response=$(http_get "$url")
  else
    response=$(http_post "$url" "$data")
  fi

  local http_code=$(extract_http_code "$response")
  local body=$(extract_http_body "$response")

  local test_end=$(date +%s%N)
  local duration_ms=$(( (test_end - test_start) / 1000000 ))

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

collect_database_stats() {
  local stats=""

  # Users count
  local user_count=$(count_rows "auth.users")
  stats+="Users: $user_count\n"

  # Active sessions
  local session_count=$(count_rows "auth.sessions" "is_revoked = false AND not_after > NOW()")
  stats+="Active Sessions: $session_count\n"

  # Recent audit events
  local audit_count=$(count_rows "auth.audit_events" "created_at > NOW() - INTERVAL '24 hours'")
  stats+="Audit Events (24h): $audit_count\n"

  # Tenants
  local tenant_count=$(count_rows "auth.tenants")
  stats+="Tenants: $tenant_count\n"

  echo -e "$stats"
}

collect_api_stats() {
  local metrics=$(curl -s "$API_BASE/metrics" 2>/dev/null || echo "")

  if [ -n "$metrics" ]; then
    local logins=$(echo "$metrics" | grep "auth_logins_total" | grep "success" | awk '{print $2}' | head -1)
    local rotations=$(echo "$metrics" | grep "auth_token_rotations_total" | awk '{print $2}' | head -1)
    local lockouts=$(echo "$metrics" | grep "auth_account_lockouts_total" | awk '{print $2}' | head -1)

    echo -e "Successful Logins: ${logins:-0}"
    echo -e "Token Rotations: ${rotations:-0}"
    echo -e "Account Lockouts: ${lockouts:-0}"
  else
    echo -e "API metrics unavailable"
  fi
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

  # Real data summary
  echo ""
  draw_box 70 "ACTUAL DATA SUMMARY" "$GREEN"
  echo ""
  echo -e "  ${BOLD}Database Statistics:${NC}"
  collect_database_stats | while read line; do echo "  $line"; done
  echo ""
  echo -e "  ${BOLD}API Metrics:${NC}"
  collect_api_stats | while read line; do echo "  $line"; done
  echo ""
  draw_box_bottom 70 "$GREEN"
}

# ============================================================================
# USER-FRIENDLY PROMPTS
# ============================================================================

show_welcome_message() {
  echo ""
  echo -e "  ${CYAN}${BOLD}Welcome to the {{PROJECT_NAME}}ID Test Suite!${NC}"
  echo ""
  echo -e "  This tool helps you verify that your authentication system"
  echo -e "  is working correctly. Each test checks a specific feature."
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

  if [ -n "$default" ]; then
    echo -ne "${CYAN}${BOLD}> ${NC}$prompt_text ${DIM}[$default]${NC}: "
  else
    echo -ne "${CYAN}${BOLD}> ${NC}$prompt_text: "
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
  local url="${1:-$API_BASE/metrics}"
  local max_wait="${2:-10}"

  echo -e "${CYAN}Checking server status...${NC}"

  for i in $(seq 1 $max_wait); do
    if curl -s "$url" > /dev/null 2>&1; then
      echo -e "${GREEN}Server is ready!${NC}"
      return 0
    fi
    echo -ne "\r  Waiting... ($i/$max_wait)"
    sleep 1
  done

  echo ""
  echo -e "${RED}Server not responding at $url${NC}"
  echo -e "${YELLOW}Please start the server with: npm run start:dev${NC}"
  return 1
}

check_database_status() {
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
export -f query_db query_db_verbose assert_sql count_rows
export -f http_get http_post extract_http_code extract_http_body assert_http
export -f generate_summary_report
export -f show_welcome_message show_help prompt_user confirm_action wait_for_key
export -f check_server_status check_database_status
export -f push_menu pop_menu clear_screen
export -f collect_database_stats collect_api_stats