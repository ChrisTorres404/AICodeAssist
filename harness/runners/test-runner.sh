#!/bin/bash
# ============================================================================
# {{PROJECT_NAME}} Interactive Test Runner
# ============================================================================
# A menu over the same inventory the regression runner uses: the suites listed
# in harness/config/suites.manifest, found in the suites directory. It holds no
# tests of its own — everything it offers is a suite file on disk.
#
#   ./test-runner.sh              interactive menu
#   ./test-runner.sh --list       print the inventory and exit
#
# Environment: ACTIVE_ENV, SUITES_DIR, SUITES_MANIFEST, RESULTS_DIR.
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"
# resolved after SUITES_DIR below: the project-owned manifest beside the suites wins

if [ -z "${SUITES_DIR:-}" ]; then
  for candidate in \
      "$SCRIPT_DIR/../../../{{TESTING_DIR}}/suites" \
      "$SCRIPT_DIR/../../{{TESTING_DIR}}/suites" \
      "$SCRIPT_DIR/../suites"; do
    [ -d "$candidate" ] && { SUITES_DIR="$candidate"; break; }
  done
  SUITES_DIR="${SUITES_DIR:-$SCRIPT_DIR/../suites}"
if [ -n "${SUITES_MANIFEST:-}" ]; then MANIFEST="$SUITES_MANIFEST"
elif [ -f "$SUITES_DIR/../suites.manifest" ]; then MANIFEST="$SUITES_DIR/../suites.manifest"
else MANIFEST="$SCRIPT_DIR/../config/suites.manifest"; fi
fi

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

RESULTS_DIR="${RESULTS_DIR:-$(dirname "$SUITES_DIR")/results}"
mkdir -p "$RESULTS_DIR"

COVERAGE_SCRIPT="$SCRIPT_DIR/../scripts/calculate-coverage.js"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

API_BASE="${API_BASE:-{{API_BASE_URL}}}"
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
SUITE_FILES=()
SUITE_LABELS=()

load_manifest() {
  if [ ! -f "$MANIFEST" ]; then
    echo "No suite manifest at $MANIFEST — add tier|file|label lines." >&2
    return 0
  fi
  local tier file label
  while IFS='|' read -r tier file label; do
    case "$tier" in ''|\#*) continue;; esac
    tier="$(printf '%s' "$tier" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    [ -n "$file" ] || continue
    SUITE_TIERS+=("$tier")
    SUITE_FILES+=("$file")
    SUITE_LABELS+=("${label:-$file}")
  done < "$MANIFEST"
}

# Suite files present on disk but absent from the manifest — worth surfacing,
# because an unlisted suite never runs in a regression.
unlisted_suites() {
  [ -d "$SUITES_DIR" ] || return 0
  local path rel listed f
  for path in "$SUITES_DIR"/*.sh "$SUITES_DIR"/*/*.sh; do
    [ -f "$path" ] || continue
    rel="${path#"$SUITES_DIR"/}"
    listed=false
    for f in "${SUITE_FILES[@]:-}"; do
      [ "$f" = "$rel" ] && { listed=true; break; }
    done
    [ "$listed" = false ] && echo "$rel"
  done
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

  printf "%-5s %-16s %-12s %s\n" "#" "TIER" "STATUS" "SUITE"
  echo "────────────────────────────────────────────────────────────────"

  local i status
  for i in "${!SUITE_FILES[@]}"; do
    [ -n "$filter_tier" ] && [ "${SUITE_TIERS[$i]}" != "$filter_tier" ] && continue
    if [ -f "$SUITES_DIR/${SUITE_FILES[$i]}" ]; then
      status="present"
    else
      status="MISSING"
    fi
    printf "%-5s %-16s %-12s %s\n" "$((i + 1))" "${SUITE_TIERS[$i]}" "$status" "${SUITE_LABELS[$i]}"
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
  result_file="$RESULTS_DIR/$(basename "$file" .sh)_${stamp}.log"

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
    -A "${TEST_USER_AGENT:-harness}" "$(health_url)" 2>/dev/null || echo "000")
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
  node "$COVERAGE_SCRIPT" "$doc"
}

# ====================================================================
# Entry
# ====================================================================

load_manifest

if [ "${1:-}" = "--list" ]; then
  list_suites
  exit 0
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
