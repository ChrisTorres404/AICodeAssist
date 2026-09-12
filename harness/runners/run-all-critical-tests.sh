#!/bin/bash
# ============================================================================
# MASTER TEST RUNNER — behavioral regression
# ============================================================================
# Runs the suites listed in harness/config/suites.manifest, tier by tier, and
# prints one report. The runner carries no suite list of its own: everything it
# knows comes from the manifest and the suites directory.
#
# Usage: ./run-all-critical-tests.sh [OPTIONS]
#
# Modes:
#   --quick       essential tier only
#   --standard    essential + core + extended (default)
#   --full        every tier
#
# Options:
#   --verbose     Show full output from each suite
#   --no-prep     Skip environment preparation
#   --stop-fail   Stop on the first suite failure
#   --list        List the suites that would run, and exit
#   --tier X      Run only tier X (e.g. --tier security)
#
# Environment:
#   ACTIVE_ENV        LOCAL_DEV (default) | LOCAL_TEST | DOCKER
#   SUITES_DIR        where the suite scripts live
#   SUITES_MANIFEST   path to the manifest
#   See config/test-config.env for the rest.
# ============================================================================

set +e  # a failing suite must not abort the run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"
# resolved after SUITES_DIR below: the project-owned manifest beside the suites wins

# Suites live in the project's testing directory; the harness sits beside it
# under the pipeline root. Override with SUITES_DIR when your layout differs.
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

# Source configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Defaults (config file normally supplies these)
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

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$USER}"
DB_NAME="${DB_NAME:-}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"

# A browser User-Agent: services that score clients for risk, or block unknown
# agents, treat curl-like agents as suspicious.
export TEST_USER_AGENT="${TEST_USER_AGENT:-Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36}"

# Parse arguments
MODE="standard"
VERBOSE=false
SKIP_PREP=false
STOP_ON_FAIL=false
LIST_ONLY=false
FILTER_TIER=""
NEXT_IS_TIER=false

for arg in "$@"; do
    case $arg in
        --quick)      MODE="quick" ;;
        --standard)   MODE="standard" ;;
        --full)       MODE="full" ;;
        --verbose)    VERBOSE=true ;;
        --no-prep)    SKIP_PREP=true ;;
        --stop-fail)  STOP_ON_FAIL=true ;;
        --list)       LIST_ONLY=true ;;
        --tier)       NEXT_IS_TIER=true ;;
        *)
            if [ "$NEXT_IS_TIER" = true ]; then
                FILTER_TIER="$arg"
                NEXT_IS_TIER=false
            fi
            ;;
    esac
done

# Results tracking
declare -a PASSED_SUITES
declare -a FAILED_SUITES
declare -a SKIPPED_SUITES
START_TIME=$(date +%s)

# ============================================================================
# SUITE INVENTORY — from harness/config/suites.manifest (tier|file|label)
# ============================================================================
ESSENTIAL_TESTS=()
CORE_TESTS=()
EXTENDED_TESTS=()
SECURITY_TESTS=()
INTEGRATION_TESTS=()
PERFORMANCE_TESTS=()
INFRASTRUCTURE_TESTS=()
RECENT_TESTS=()

load_manifest() {
    [ -f "$MANIFEST" ] || { echo "No suite manifest at $MANIFEST — add tier|file|label lines."; return 0; }
    local tier file label
    while IFS='|' read -r tier file label; do
        case "$tier" in ''|\#*) continue;; esac
        tier="$(printf '%s' "$tier" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"
        [ -n "$file" ] || continue
        case "$tier" in
            ESSENTIAL)      ESSENTIAL_TESTS+=("$file:$label");;
            CORE)           CORE_TESTS+=("$file:$label");;
            EXTENDED)       EXTENDED_TESTS+=("$file:$label");;
            SECURITY)       SECURITY_TESTS+=("$file:$label");;
            INTEGRATION)    INTEGRATION_TESTS+=("$file:$label");;
            PERFORMANCE)    PERFORMANCE_TESTS+=("$file:$label");;
            INFRASTRUCTURE) INFRASTRUCTURE_TESTS+=("$file:$label");;
            RECENT)         RECENT_TESTS+=("$file:$label");;
            *) echo "unknown tier '$tier' in manifest (line: $file)";;
        esac
    done < "$MANIFEST"
}
load_manifest

# ============================================================================
# FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

db_configured() {
    [ -n "${DB_NAME:-}" ] && command -v psql > /dev/null 2>&1
}

# Terminate idle connections left behind by a suite, so the next one is not
# blocked by an exhausted pool. No-op when no database is configured.
release_idle_db_connections() {
    db_configured || return 0
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -t -A -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle' AND pid <> pg_backend_pid();" \
        > /dev/null 2>&1 || true
}

run_suite() {
    local file="$1"
    local name="$2"
    local full_path="$SUITES_DIR/$file"

    if [ ! -f "$full_path" ]; then
        echo -e "  ${YELLOW}SKIP${NC} $name ${DIM}(file not found)${NC}"
        SKIPPED_SUITES+=("$name")
        return 0
    fi

    chmod +x "$full_path" 2>/dev/null || true

    local suite_start elapsed
    suite_start=$(date +%s)
    echo -ne "  ${BLUE}RUN ${NC} $name..."

    if [ "$VERBOSE" = true ]; then
        echo ""
        if "$full_path" 2>&1; then
            elapsed=$(( $(date +%s) - suite_start ))
            echo -e "  ${GREEN}PASS${NC} $name ${DIM}(${elapsed}s)${NC}"
            PASSED_SUITES+=("$name")
        else
            elapsed=$(( $(date +%s) - suite_start ))
            echo -e "  ${RED}FAIL${NC} $name ${DIM}(${elapsed}s)${NC}"
            FAILED_SUITES+=("$name")
            if [ "$STOP_ON_FAIL" = true ]; then
                echo -e "\n  ${RED}--stop-fail: aborting remaining suites${NC}"
                return 1
            fi
        fi
    else
        local log_file
        # an explicit template: BSD mktemp treats -t as a prefix, GNU mktemp
        # requires the XXXXXX and rejects a bare prefix.
        log_file="$(mktemp "${TMPDIR:-/tmp}/harness-suite.XXXXXX")"
        if "$full_path" > "$log_file" 2>&1; then
            elapsed=$(( $(date +%s) - suite_start ))
            echo -e "\r  ${GREEN}PASS${NC} $name ${DIM}(${elapsed}s)${NC}                    "
            PASSED_SUITES+=("$name")
        else
            elapsed=$(( $(date +%s) - suite_start ))
            echo -e "\r  ${RED}FAIL${NC} $name ${DIM}(${elapsed}s)${NC}                    "
            FAILED_SUITES+=("$name")
            echo -e "    ${YELLOW}Last output:${NC}"
            tail -5 "$log_file" 2>/dev/null | sed 's/^/    /'
            if [ "$STOP_ON_FAIL" = true ]; then
                rm -f "$log_file"
                echo -e "\n  ${RED}--stop-fail: aborting remaining suites${NC}"
                return 1
            fi
        fi
        rm -f "$log_file"
    fi

    release_idle_db_connections
    return 0
}

run_tier() {
    local tier_name="$1"
    shift
    local tests=("$@")

    [ ${#tests[@]} -eq 0 ] && return 0

    if [ -n "$FILTER_TIER" ]; then
        local tier_lower filter_lower
        tier_lower=$(echo "$tier_name" | tr '[:upper:]' '[:lower:]')
        filter_lower=$(echo "$FILTER_TIER" | tr '[:upper:]' '[:lower:]')
        [ "$tier_lower" = "$filter_lower" ] || return 0
    fi

    print_header "TIER: $(echo "$tier_name" | tr '[:lower:]' '[:upper:]')"

    local test file name
    for test in "${tests[@]}"; do
        IFS=':' read -r file name <<< "$test"
        run_suite "$file" "$name" || return 1
    done
    return 0
}

list_suites() {
    local tier="$1"
    shift
    local tests=("$@")

    [ ${#tests[@]} -eq 0 ] && return

    echo -e "\n${CYAN}$tier${NC} (${#tests[@]} suites):"
    local test file name
    for test in "${tests[@]}"; do
        IFS=':' read -r file name <<< "$test"
        if [ -f "$SUITES_DIR/$file" ]; then
            echo -e "  ${GREEN}OK${NC}   $file  ${DIM}-> $name${NC}"
        else
            echo -e "  ${YELLOW}MISS${NC} $file  ${DIM}-> $name${NC}"
        fi
    done
}

# ============================================================================
# ENVIRONMENT PREPARATION
# ============================================================================

prepare_environment() {
    echo -e "${MAGENTA}  Preparing test environment...${NC}"

    # 1. The service under test must answer before anything is claimed about it
    local health
    health=$(curl -s -o /dev/null -w "%{http_code}" -A "$TEST_USER_AGENT" \
        "$(health_url)" 2>/dev/null || echo "000")
    if [ "$health" != "200" ]; then
        echo -e "  ${RED}Service not responding at ${API_BASE}${HEALTH_PATH} or the host root (HTTP $health)${NC}"
        echo -e "  ${RED}Start the service under test, then run this again.${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}Service healthy${NC} (HTTP $health)"

    # 2. Optional: flush the cache/rate limiter so limits do not leak between runs
    if [ "${REDIS_FLUSH:-0}" = "1" ] && command -v redis-cli > /dev/null 2>&1; then
        echo -ne "  ${DIM}Flushing Redis...${NC}"
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" FLUSHDB > /dev/null 2>&1 || true
        echo -e "\r  ${GREEN}Redis flushed${NC}                               "
    fi

    # 3. Optional: project-supplied SQL that resets state before a run
    if [ -n "${TEST_PREP_SQL:-}" ] && db_configured; then
        echo -ne "  ${DIM}Running TEST_PREP_SQL...${NC}"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$TEST_PREP_SQL" \
            > /dev/null 2>&1 || echo -e "  ${YELLOW}TEST_PREP_SQL failed${NC}"
        echo -e "\r  ${GREEN}Prep SQL applied${NC}                            "
    fi

    # 4. Connection pool health
    if db_configured; then
        local idle_count
        idle_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c \
            "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle';" 2>/dev/null || echo "0")
        idle_count=$(echo "$idle_count" | tr -d '[:space:]')
        if [ "${idle_count:-0}" -gt 8 ] 2>/dev/null; then
            echo -e "  ${YELLOW}DB pool: $idle_count idle connections — releasing...${NC}"
            release_idle_db_connections
            sleep 2
            echo -e "  ${GREEN}Pool released${NC}"
        else
            echo -e "  ${GREEN}DB pool healthy${NC} ($idle_count idle connections)"
        fi
    fi

    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if [ "$LIST_ONLY" = true ]; then
    echo -e "${BOLD}Available Test Suites${NC}"
    echo -e "${DIM}Environment: ${ACTIVE_ENV:-LOCAL_DEV}  Suites: $SUITES_DIR${NC}"

    list_suites "ESSENTIAL (--quick)"          "${ESSENTIAL_TESTS[@]}"
    list_suites "CORE (--standard)"            "${CORE_TESTS[@]}"
    list_suites "EXTENDED (--standard)"        "${EXTENDED_TESTS[@]}"
    list_suites "SECURITY (--full)"            "${SECURITY_TESTS[@]}"
    list_suites "INTEGRATION (--full)"         "${INTEGRATION_TESTS[@]}"
    list_suites "PERFORMANCE (--full)"         "${PERFORMANCE_TESTS[@]}"
    list_suites "INFRASTRUCTURE (--full)"      "${INFRASTRUCTURE_TESTS[@]}"
    list_suites "RECENT (--full)"              "${RECENT_TESTS[@]}"

    TOTAL_QUICK=${#ESSENTIAL_TESTS[@]}
    TOTAL_STANDARD=$((TOTAL_QUICK + ${#CORE_TESTS[@]} + ${#EXTENDED_TESTS[@]}))
    TOTAL_FULL=$((TOTAL_STANDARD + ${#SECURITY_TESTS[@]} + ${#INTEGRATION_TESTS[@]} + ${#PERFORMANCE_TESTS[@]} + ${#INFRASTRUCTURE_TESTS[@]} + ${#RECENT_TESTS[@]}))
    echo -e "\n${BOLD}Totals:${NC} --quick=$TOTAL_QUICK  --standard=$TOTAL_STANDARD  --full=$TOTAL_FULL"
    exit 0
fi

# Banner
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}{{PROJECT_NAME}} — BEHAVIORAL REGRESSION SUITE${NC}"
echo -e "${CYAN}║${NC}  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "${CYAN}║${NC}  Mode: ${BOLD}$(echo "$MODE" | tr '[:lower:]' '[:upper:]')${NC}  Env: ${BOLD}${ACTIVE_ENV:-LOCAL_DEV}${NC}"
echo -e "${CYAN}║${NC}  API: ${DIM}${API_BASE}${NC}"
if db_configured; then
    echo -e "${CYAN}║${NC}  DB: ${DIM}${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}${NC}"
fi
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"

if [ "$SKIP_PREP" = false ]; then
    prepare_environment
fi

# --- essential: every mode --------------------------------------------------
run_tier "essential" "${ESSENTIAL_TESTS[@]}" || true

# --- standard: core + extended ---------------------------------------------
if [ "$MODE" = "standard" ] || [ "$MODE" = "full" ]; then
    release_idle_db_connections
    run_tier "core" "${CORE_TESTS[@]}" || true
    release_idle_db_connections
    run_tier "extended" "${EXTENDED_TESTS[@]}" || true
fi

# --- full: everything else --------------------------------------------------
if [ "$MODE" = "full" ]; then
    release_idle_db_connections
    run_tier "security" "${SECURITY_TESTS[@]}" || true
    run_tier "integration" "${INTEGRATION_TESTS[@]}" || true
    release_idle_db_connections
    run_tier "performance" "${PERFORMANCE_TESTS[@]}" || true
    run_tier "infrastructure" "${INFRASTRUCTURE_TESTS[@]}" || true
    run_tier "recent" "${RECENT_TESTS[@]}" || true
fi

# ============================================================================
# SUMMARY
# ============================================================================

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_PASSED=${#PASSED_SUITES[@]}
TOTAL_FAILED=${#FAILED_SUITES[@]}
TOTAL_SKIPPED=${#SKIPPED_SUITES[@]}
TOTAL=$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))

if [ "$TOTAL" -gt 0 ]; then
    PASS_RATE=$(( (TOTAL_PASSED * 100) / TOTAL ))
else
    PASS_RATE=0
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}FINAL RESULTS${NC}"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
printf "${CYAN}║${NC}  %-20s %s\n" "Mode:" "$(echo "$MODE" | tr '[:lower:]' '[:upper:]')"
printf "${CYAN}║${NC}  %-20s %s\n" "Duration:" "${TOTAL_TIME}s"
printf "${CYAN}║${NC}  %-20s %s\n" "Total Suites:" "$TOTAL"
printf "${CYAN}║${NC}  %-20s ${GREEN}%s${NC}\n" "Passed:" "$TOTAL_PASSED"
printf "${CYAN}║${NC}  %-20s ${RED}%s${NC}\n" "Failed:" "$TOTAL_FAILED"
printf "${CYAN}║${NC}  %-20s ${YELLOW}%s${NC}\n" "Skipped:" "$TOTAL_SKIPPED"
printf "${CYAN}║${NC}  %-20s %s%%\n" "Pass Rate:" "$PASS_RATE"
echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${CYAN}║${NC}  ${YELLOW}${BOLD}NO SUITES RAN${NC} — add rows to $(basename "$MANIFEST")"
elif [ "$TOTAL_FAILED" -eq 0 ] && [ "$TOTAL_SKIPPED" -eq 0 ]; then
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}ALL SUITES PASSED${NC}"
elif [ "$TOTAL_FAILED" -eq 0 ]; then
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}PASS${NC} ${YELLOW}(${TOTAL_SKIPPED} skipped — missing files)${NC}"
else
    echo -e "${CYAN}║${NC}  ${RED}${BOLD}FAILURES DETECTED${NC}"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${RED}Failed Suites:${NC}"
    for suite in "${FAILED_SUITES[@]}"; do
        echo -e "${CYAN}║${NC}    ${RED}x $suite${NC}"
    done
fi

if [ "$TOTAL_SKIPPED" -gt 0 ]; then
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Skipped:${NC}"
    for suite in "${SKIPPED_SUITES[@]}"; do
        echo -e "${CYAN}║${NC}    ${YELLOW}- $suite${NC}"
    done
fi

echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

[ "$TOTAL_FAILED" -gt 0 ] && exit 1
exit 0
