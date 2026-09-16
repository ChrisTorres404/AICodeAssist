#!/bin/bash
# ============================================================================
# {{PROJECT_NAME}} Interactive Test Runner
# ============================================================================
# The by-hand runner: a menu over the same inventory the canonical regression
# runner uses (../runners/run-all-critical-tests.sh), for picking one suite,
# one tier, or hunting a flake by repeating a suite. It holds no tests of its
# own — everything it offers is a suite file on disk, listed in the manifest.
#
#   ./test-runner.sh                   interactive menu
#   ./test-runner.sh --list            print the inventory and exit
#   ./test-runner.sh --suite <file>    run one suite and keep its evidence
#   ./test-runner.sh --suite <file> --repeat 20
#                                      run it repeatedly, to catch a flake
#
# --suite takes a path relative to the suites directory, an absolute path, or a
# suite number from --list. It is the single-file form: one run, one timestamped
# log under TEST_RESULTS_DIR, and the suite's own exit code passed back, so it
# can stand in a script or a CI step. (`wo verify <n> --run <file>` is the same
# run recorded against a work order.)
#
# Every log it keeps goes under TEST_RESULTS_DIR — the same directory every
# other runner writes to. See ../lib/paths.sh.
#
# Environment: ACTIVE_ENV, SUITES_DIR, SUITES_MANIFEST, TEST_RESULTS_DIR.
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"

# shellcheck source=../lib/paths.sh
. "$SCRIPT_DIR/../lib/paths.sh"
MANIFEST="$SUITES_MANIFEST"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

mkdir -p "$TEST_RESULTS_DIR"

COVERAGE_SCRIPT="$SCRIPT_DIR/../scripts/calculate-coverage.js"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# The rendered default lives in a variable: `${API_BASE:-{{...}}}` would
# append the extra braces to an API_BASE that is already set.
_default_api_base='{{API_BASE_URL}}'
API_BASE="${API_BASE:-$_default_api_base}"
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


# ====================================================================
# Inventory — loaded from the manifest, in file order
# ====================================================================

SUITE_TIERS=()
SUITE_TYPES=()
SUITE_FILES=()
SUITE_LABELS=()

load_manifest() {
  if [ ! -f "$MANIFEST" ]; then
    echo "No suite manifest at $MANIFEST — add tier|type|file|label lines." >&2
    return 0
  fi
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    parse_manifest_line "$line" || continue
    SUITE_TIERS+=("$MF_TIER")
    SUITE_TYPES+=("$MF_TYPE")
    SUITE_FILES+=("$MF_FILE")
    SUITE_LABELS+=("$MF_LABEL")
  done < "$MANIFEST"
}

# Suite files present on disk but absent from the manifest — worth surfacing,
# because an unlisted suite never runs in a regression. Answered by the shared
# resolver in ../lib/paths.sh.
unlisted_suites() {
  unlisted_suite_files "$MANIFEST"
}

suite_count() { echo "${#SUITE_FILES[@]}"; }

# ====================================================================
# Display
# ====================================================================

show_header() {
  clear 2>/dev/null || true
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║      {{PROJECT_NAME}} Interactive Test Runner${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}API:${NC}      $API_BASE"
  echo -e "${CYAN}Env:${NC}      ${ACTIVE_ENV:-LOCAL_DEV}"
  echo -e "${CYAN}Suites:${NC}   $SUITES_DIR ($(suite_count) listed)"
  echo ""
}

show_menu() {
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Main Menu${NC}"
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "  1. List suites (by tier)"
  echo "  2. Run one suite"
  echo "  3. Run a tier"
  echo "  4. Run every listed suite"
  echo "  5. Repeat one suite N times (flake hunt)"
  echo "  6. Coverage report from a verification document"
  echo "  7. Check the service under test"
  echo "  8. Exit"
  echo ""
}

list_suites() {
  local filter_tier="${1:-}"

  if [ "$(suite_count)" -eq 0 ]; then
    echo -e "${YELLOW}No suites listed in $(basename "$MANIFEST").${NC}"
    return
  fi

  printf "%-5s %-16s %-10s %-10s %s\n" "#" "TIER" "TYPE" "STATUS" "SUITE"
  echo "────────────────────────────────────────────────────────────────"

  local i status
  for i in "${!SUITE_FILES[@]}"; do
    [ -n "$filter_tier" ] && [ "${SUITE_TIERS[$i]}" != "$filter_tier" ] && continue
    if [ -f "$SUITES_DIR/${SUITE_FILES[$i]}" ]; then
      status="present"
    else
      status="MISSING"
    fi
    printf "%-5s %-16s %-10s %-10s %s\n" "$((i + 1))" "${SUITE_TIERS[$i]}" "${SUITE_TYPES[$i]:-untyped}" "$status" "${SUITE_LABELS[$i]}"
  done

  local extra
  extra="$(unlisted_suites)"
  if [ -n "$extra" ]; then
    echo ""
    echo -e "${YELLOW}Present but not in the manifest (never runs in a regression):${NC}"
    echo "$extra" | sed 's/^/  /'
  fi
  echo ""
}

# ====================================================================
# Execution
# ====================================================================

run_suite_file() {
  local file="$1"
  local label="$2"
  local path="$SUITES_DIR/$file"

  if [ ! -f "$path" ]; then
    echo -e "${RED}Not found: $path${NC}"
    return 1
  fi

  local stamp result_file
  stamp="$(date +%Y%m%d_%H%M%S)"
  result_file="$TEST_RESULTS_DIR/$(basename "$file" .sh)_${stamp}.log"

  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}Running: $label${NC}  ${DIM}($file)${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""

  chmod +x "$path" 2>/dev/null || true
  local start end rc
  start=$(date +%s)
  bash "$path" 2>&1 | tee "$result_file"
  rc=${PIPESTATUS[0]}
  end=$(date +%s)

  echo ""
  if [ "$rc" -eq 0 ]; then
    echo -e "${GREEN}EXECUTED — PASS${NC}  $label  ${DIM}($((end - start))s)${NC}"
  else
    echo -e "${RED}EXECUTED — FAIL${NC}  $label  ${DIM}(exit $rc, $((end - start))s)${NC}"
  fi
  echo -e "${DIM}Output: $result_file${NC}"
  echo ""
  return "$rc"
}

run_indexed_suite() {
  local n="$1"
  local i=$((n - 1))
  if [ "$i" -lt 0 ] || [ "$i" -ge "$(suite_count)" ]; then
    echo -e "${RED}No suite #$n${NC}"
    return 1
  fi
  run_suite_file "${SUITE_FILES[$i]}" "${SUITE_LABELS[$i]}"
}

run_tier() {
  local tier="$1"
  local passed=0 failed=0 i

  for i in "${!SUITE_FILES[@]}"; do
    [ "${SUITE_TIERS[$i]}" = "$tier" ] || continue
    if run_suite_file "${SUITE_FILES[$i]}" "${SUITE_LABELS[$i]}"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo -e "${BOLD}Tier '$tier': ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
}

run_all() {
  local passed=0 failed=0 i
  for i in "${!SUITE_FILES[@]}"; do
    if run_suite_file "${SUITE_FILES[$i]}" "${SUITE_LABELS[$i]}"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done
  echo -e "${BOLD}All suites: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
}

repeat_suite() {
  local n="$1"
  local times="$2"
  local i=$((n - 1)) run passed=0 failed=0

  if [ "$i" -lt 0 ] || [ "$i" -ge "$(suite_count)" ]; then
    echo -e "${RED}No suite #$n${NC}"
    return 1
  fi

  for run in $(seq 1 "$times"); do
    echo -e "${DIM}--- run $run of $times ---${NC}"
    if run_suite_file "${SUITE_FILES[$i]}" "${SUITE_LABELS[$i]}" > /dev/null 2>&1; then
      passed=$((passed + 1))
      echo -e "  ${GREEN}PASS${NC}"
    else
      failed=$((failed + 1))
      echo -e "  ${RED}FAIL${NC}"
    fi
  done

  echo ""
  echo -e "${BOLD}${SUITE_LABELS[$i]}: $passed/$times passed${NC}"
  [ "$failed" -gt 0 ] && echo -e "${YELLOW}Flaky or broken — a suite that does not pass every time is not evidence.${NC}"
}

check_service() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -A "${TEST_USER_AGENT:-harness}" "$(health_url)" 2>/dev/null || true)
  code="${code:-000}"
  if [ "$code" = "200" ]; then
    echo -e "${GREEN}Service healthy${NC} at $(health_url) (HTTP $code)"
  else
    echo -e "${RED}Service not answering${NC} at ${API_BASE}${HEALTH_PATH} (HTTP $code)"
  fi
}

coverage_report() {
  local doc="$1"
  if [ ! -f "$doc" ]; then
    echo -e "${RED}Not found: $doc${NC}"
    return 1
  fi
  if ! command -v node > /dev/null 2>&1; then
    echo -e "${RED}node is required for the coverage report${NC}"
    return 1
  fi
  TEST_RESULTS_DIR="$TEST_RESULTS_DIR" node "$COVERAGE_SCRIPT" "$doc"
}

# ====================================================================
# Entry
# ====================================================================

load_manifest

# --- non-interactive forms --------------------------------------------------
# Resolve what --suite was given: a suite number from the listing, a path
# relative to the suites directory, or a path anywhere on disk. Three lines
# come back — file, label, and the directory the file is relative to — because
# a function called in a command substitution cannot set a variable for its
# caller, and the directory has to travel with the answer.
resolve_suite() {
  local want="$1" i dir base

  case "$want" in
    ''|*[!0-9]*) ;;
    *)  i=$((want - 1))
        if [ "$i" -ge 0 ] && [ "$i" -lt "$(suite_count)" ]; then
          printf '%s\n%s\n%s' "${SUITE_FILES[$i]}" "${SUITE_LABELS[$i]}" "$SUITES_DIR"
          return 0
        fi
        echo "no suite #$want in the manifest" >&2
        return 1
        ;;
  esac

  if [ -f "$SUITES_DIR/$want" ]; then
    printf '%s\n%s\n%s' "$want" "$(basename "$want" .sh)" "$SUITES_DIR"
    return 0
  fi
  if [ -f "$want" ]; then
    # A suite kept outside the suites directory still runs: run_suite_file
    # joins the file to a directory, so hand back the one it belongs to.
    dir="$(cd "$(dirname "$want")" && pwd)"
    base="$(basename "$want")"
    printf '%s\n%s\n%s' "$base" "$(basename "$base" .sh)" "$dir"
    return 0
  fi
  echo "no such suite: $want" >&2
  return 1
}

SUITE_ARG=""
REPEAT_N=""
while [ $# -gt 0 ]; do
  case "$1" in
    --list)   list_suites; exit 0;;
    --suite)  SUITE_ARG="${2:?--suite needs a suite file or number}"; shift 2;;
    --repeat) REPEAT_N="${2:?--repeat needs a count}"; shift 2;;
    -h|--help) awk 'NR>1 && /^#/ {sub(/^#[ ]?/,""); print; next} NR>1 {exit}' "$0"; exit 0;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done

if [ -n "$SUITE_ARG" ]; then
  resolved="$(resolve_suite "$SUITE_ARG")" || exit 2
  suite_file="$(printf '%s' "$resolved" | sed -n '1p')"
  suite_label="$(printf '%s' "$resolved" | sed -n '2p')"
  SUITES_DIR="$(printf '%s' "$resolved" | sed -n '3p')"
  mkdir -p "$TEST_RESULTS_DIR"
  if [ -n "$REPEAT_N" ]; then
    passed=0; failed=0
    for run in $(seq 1 "$REPEAT_N"); do
      echo -e "${DIM}--- run $run of $REPEAT_N ---${NC}"
      if run_suite_file "$suite_file" "$suite_label" > /dev/null 2>&1; then
        passed=$((passed + 1)); echo -e "  ${GREEN}PASS${NC}"
      else
        failed=$((failed + 1)); echo -e "  ${RED}FAIL${NC}"
      fi
    done
    echo ""
    echo -e "${BOLD}$suite_label: $passed/$REPEAT_N passed${NC}"
    [ "$failed" -gt 0 ] && echo -e "${YELLOW}Flaky or broken — a suite that does not pass every time is not evidence.${NC}"
    [ "$failed" -eq 0 ]
    exit $?
  fi
  run_suite_file "$suite_file" "$suite_label"
  exit $?
fi

while true; do
  show_header
  show_menu

  read -r -p "Select option: " choice

  case "$choice" in
    1)
      echo ""
      read -r -p "Filter by tier (blank for all): " tier
      list_suites "$(printf '%s' "$tier" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
      read -r -p "Press enter to continue..." _
      ;;
    2)
      list_suites
      read -r -p "Suite number: " n
      [ -n "$n" ] && run_indexed_suite "$n"
      read -r -p "Press enter to continue..." _
      ;;
    3)
      echo ""
      read -r -p "Tier: " tier
      [ -n "$tier" ] && run_tier "$(printf '%s' "$tier" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
      read -r -p "Press enter to continue..." _
      ;;
    4)
      run_all
      read -r -p "Press enter to continue..." _
      ;;
    5)
      list_suites
      read -r -p "Suite number: " n
      read -r -p "How many runs? (default 5): " times
      times="${times:-5}"
      [ -n "$n" ] && repeat_suite "$n" "$times"
      read -r -p "Press enter to continue..." _
      ;;
    6)
      echo ""
      read -r -p "Path to a verification document: " doc
      [ -n "$doc" ] && coverage_report "$doc"
      read -r -p "Press enter to continue..." _
      ;;
    7)
      echo ""
      check_service
      read -r -p "Press enter to continue..." _
      ;;
    8)
      echo ""
      echo "Bye."
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option${NC}"
      sleep 1
      ;;
  esac
done
