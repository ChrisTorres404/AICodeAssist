#!/bin/bash
# ============================================================================
# MASTER TEST RUNNER - Full Regression Suite
# ============================================================================
# Runs behavioral tests across all tiers and provides a comprehensive report.
#
# Usage: ./run-all-critical-tests.sh [OPTIONS]
#
# Modes:
#   --quick       Essential auth tests only (~30s, 5 suites)
#   --standard    Essential + Comprehensive + Core WO suites (default, ~3min)
#   --full        Everything including all workable WO suites (~10min)
#
# Options:
#   --verbose     Show full output from each test
#   --no-prep     Skip environment preparation (risk state, Redis flush)
#   --stop-fail   Stop on first suite failure
#   --list        List all suites and exit (no execution)
#   --category X  Run only category X (e.g., --category comprehensive)
#
# Environment:
#   ACTIVE_ENV    LOCAL_DEV (default) | DOCKER | LOCAL_TEST
#   See config/test-config.env for full configuration
# ============================================================================

set +e  # Don't exit on individual test failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITES_DIR="$SCRIPT_DIR/suites"
COMPREHENSIVE_DIR="$SUITES_DIR/comprehensive"
CONFIG_FILE="$SCRIPT_DIR/config/test-config.env"

# Source configuration
if [ -f "$CONFIG_FILE" ]; then
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

# Defaults
API_BASE="${API_BASE:-http://localhost:8601/api/v1}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$USER}"
DB_NAME="${DB_NAME:-{{DB_NAME}}}"
REDIS_PORT="${REDIS_PORT:-6379}"

# Browser UA for risk scoring bypass
export TEST_USER_AGENT="${TEST_USER_AGENT:-Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36}"

# Parse arguments
MODE="standard"
VERBOSE=false
SKIP_PREP=false
STOP_ON_FAIL=false
LIST_ONLY=false
FILTER_CATEGORY=""

for arg in "$@"; do
    case $arg in
        --quick)      MODE="quick" ;;
        --standard)   MODE="standard" ;;
        --full)       MODE="full" ;;
        --verbose)    VERBOSE=true ;;
        --no-prep)    SKIP_PREP=true ;;
        --stop-fail)  STOP_ON_FAIL=true ;;
        --list)       LIST_ONLY=true ;;
        --category)   NEXT_IS_CATEGORY=true ;;
        *)
            if [ "$NEXT_IS_CATEGORY" = true ]; then
                FILTER_CATEGORY="$arg"
                NEXT_IS_CATEGORY=false
            fi
            ;;
    esac
done

# Results tracking
declare -a PASSED_SUITES
declare -a FAILED_SUITES
declare -a SKIPPED_SUITES
SUITE_TIMES=()
START_TIME=$(date +%s)

# ============================================================================
# TEST SUITE DEFINITIONS
# ============================================================================
# Format: "relative/path/to/script.sh:Display Name"
# Paths are relative to $SUITES_DIR

# --- TIER 1: ESSENTIAL (--quick) ---
# Core auth flow — if these fail, nothing else matters
# Suite inventory comes from harness/config/suites.manifest (tier|file|label).
# Arrays below are filled from it so the runner carries no project-specific list.
MANIFEST="${SUITES_MANIFEST:-$SCRIPT_DIR/../config/suites.manifest}"
ESSENTIAL_TESTS=()
COMPREHENSIVE_TESTS_A=()
COMPREHENSIVE_TESTS_B=()
AUTH_EXTENDED_TESTS=()
ADMIN_TESTS=()
PLATFORM_TESTS=()
SECURITY_TESTS=()
ADVANCED_AUTH_TESTS=()
OBSERVABILITY_TESTS=()
ENTERPRISE_TESTS=()
OAUTH_TESTS=()
INFRASTRUCTURE_TESTS=()
load_manifest() {
    [ -f "$MANIFEST" ] || { echo "No suite manifest at $MANIFEST — add tier|file|label lines."; return 0; }
    while IFS='|' read -r tier file label; do
        case "$tier" in ''|\#*) continue;; esac
        tier="$(printf '%s' "$tier" | tr '[:lower:]' '[:upper:]' | tr -d ' ')"
        case "$tier" in
            ESSENTIAL) ESSENTIAL_TESTS+=("$file:$label");;
            COMPREHENSIVE_A) COMPREHENSIVE_TESTS_A+=("$file:$label");;
            COMPREHENSIVE_B) COMPREHENSIVE_TESTS_B+=("$file:$label");;
            AUTH_EXTENDED) AUTH_EXTENDED_TESTS+=("$file:$label");;
            ADMIN) ADMIN_TESTS+=("$file:$label");;
            PLATFORM) PLATFORM_TESTS+=("$file:$label");;
            SECURITY) SECURITY_TESTS+=("$file:$label");;
            ADVANCED_AUTH) ADVANCED_AUTH_TESTS+=("$file:$label");;
            OBSERVABILITY) OBSERVABILITY_TESTS+=("$file:$label");;
            ENTERPRISE) ENTERPRISE_TESTS+=("$file:$label");;
            OAUTH) OAUTH_TESTS+=("$file:$label");;
            INFRASTRUCTURE) INFRASTRUCTURE_TESTS+=("$file:$label");;
            *) echo "unknown tier '$tier' in manifest (line: $file)";;
        esac
    done < "$MANIFEST"
}
load_manifest

# --- TIER 3: RECENT WOs (--full) ---
RECENT_WO_TESTS=()  # filled from the manifest

# ============================================================================
# FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

    local suite_start=$(date +%s)
    echo -ne "  ${BLUE}RUN ${NC} $name..."

    if [ "$VERBOSE" = true ]; then
        echo ""
        if "$full_path" 2>&1; then
            local suite_end=$(date +%s)
            local elapsed=$((suite_end - suite_start))
            echo -e "  ${GREEN}PASS${NC} $name ${DIM}(${elapsed}s)${NC}"
            PASSED_SUITES+=("$name")
        else
            local suite_end=$(date +%s)
            local elapsed=$((suite_end - suite_start))
            echo -e "  ${RED}FAIL${NC} $name ${DIM}(${elapsed}s)${NC}"
            FAILED_SUITES+=("$name")
            if [ "$STOP_ON_FAIL" = true ]; then
                echo -e "\n  ${RED}--stop-fail: Aborting remaining tests${NC}"
                return 1
            fi
        fi
    else
        local log_file="/tmp/{{PROJECT_SLUG}}_test_output_$$.log"
        if "$full_path" > "$log_file" 2>&1; then
            local suite_end=$(date +%s)
            local elapsed=$((suite_end - suite_start))
            echo -e "\r  ${GREEN}PASS${NC} $name ${DIM}(${elapsed}s)${NC}                    "
            PASSED_SUITES+=("$name")
        else
            local suite_end=$(date +%s)
            local elapsed=$((suite_end - suite_start))
            echo -e "\r  ${RED}FAIL${NC} $name ${DIM}(${elapsed}s)${NC}                    "
            FAILED_SUITES+=("$name")
            # Show last few lines of error
            echo -e "    ${YELLOW}Last output:${NC}"
            tail -5 "$log_file" 2>/dev/null | sed 's/^/    /'
            if [ "$STOP_ON_FAIL" = true ]; then
                rm -f "$log_file"
                echo -e "\n  ${RED}--stop-fail: Aborting remaining tests${NC}"
                return 1
            fi
        fi
        rm -f "$log_file"
    fi

    # Cleanup idle DB connections after each suite to prevent pool exhaustion
    PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d postgres -t -A -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle' AND pid <> pg_backend_pid();" \
        > /dev/null 2>&1 || true

    return 0
}

run_category() {
    local category_name="$1"
    shift
    local tests=("$@")

    if [ ${#tests[@]} -eq 0 ]; then
        return 0
    fi

    # If category filter is active, skip non-matching categories
    if [ -n "$FILTER_CATEGORY" ]; then
        local cat_lower=$(echo "$category_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        local filter_lower=$(echo "$FILTER_CATEGORY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        if [[ "$cat_lower" != *"$filter_lower"* ]]; then
            return 0
        fi
    fi

    print_header "$category_name"

    for test in "${tests[@]}"; do
        IFS=':' read -r file name <<< "$test"
        run_suite "$file" "$name" || return 1
    done
    return 0
}

list_suites() {
    local category="$1"
    shift
    local tests=("$@")

    if [ ${#tests[@]} -eq 0 ]; then
        return
    fi

    echo -e "\n${CYAN}$category${NC} (${#tests[@]} suites):"
    for test in "${tests[@]}"; do
        IFS=':' read -r file name <<< "$test"
        local full_path="$SUITES_DIR/$file"
        if [ -f "$full_path" ]; then
            echo -e "  ${GREEN}OK${NC}   $file  ${DIM}→ $name${NC}"
        else
            echo -e "  ${YELLOW}MISS${NC} $file  ${DIM}→ $name${NC}"
        fi
    done
}

# ============================================================================
# ENVIRONMENT PREPARATION
# ============================================================================

prepare_environment() {
    echo -e "${MAGENTA}  Preparing test environment...${NC}"

    # 1. Check API health
    local health=$(curl -s -o /dev/null -w "%{http_code}" \
        -A "$TEST_USER_AGENT" \
        "${API_BASE}/health" 2>/dev/null || echo "000")
    if [ "$health" != "200" ]; then
        echo -e "  ${RED}API not responding (HTTP $health)${NC}"
        echo -e "  ${RED}Start the API first: npm run start:dev --workspace=apps/{{API_APP}}${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}API healthy${NC} (HTTP $health)"

    # 2. Clean risk scoring state
    echo -ne "  ${DIM}Cleaning risk scoring state...${NC}"
    PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c \
        "DELETE FROM audit.events WHERE action IN ('auth.login_failed','auth.session_blocked_high_risk') AND (metadata->>'ip_address' IN ('::1','127.0.0.1','::ffff:127.0.0.1') OR metadata->>'ip_address' IS NULL) AND created_at > NOW() - INTERVAL '2 hours';" \
        > /dev/null 2>&1 || true
    echo -e "\r  ${GREEN}Risk state cleaned${NC}                          "

    # 3. Flush Redis rate limiter
    echo -ne "  ${DIM}Flushing Redis rate limits...${NC}"
    redis-cli -p "$REDIS_PORT" FLUSHDB > /dev/null 2>&1 || \
    redis-cli -p 4239 FLUSHDB > /dev/null 2>&1 || \
    redis-cli FLUSHDB > /dev/null 2>&1 || true
    echo -e "\r  ${GREEN}Redis flushed${NC}                               "

    # 4. Check DB pool health and recover if needed
    echo -ne "  ${DIM}Checking DB connection pool...${NC}"
    local idle_count=$(PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c \
        "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle';" 2>/dev/null || echo "0")
    idle_count=$(echo "$idle_count" | tr -d '[:space:]')
    if [ "${idle_count:-0}" -gt 8 ] 2>/dev/null; then
        echo -e "\r  ${YELLOW}DB pool: $idle_count idle connections — recovering...${NC}"
        PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c \
            "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle' AND pid != pg_backend_pid();" \
            > /dev/null 2>&1 || true
        sleep 5
        echo -e "  ${GREEN}Pool recovered${NC} (terminated $idle_count idle connections)"
    else
        echo -e "\r  ${GREEN}DB pool healthy${NC} ($idle_count idle connections)"
    fi

    echo ""
}

# Recovery function: terminates idle DB connections and waits for pool to reset
# Connects via 'postgres' DB to avoid contention when {{DB_NAME}} pool is exhausted
recover_db_pool() {
    # Use postgres DB for the recovery query — more reliable when target pool is exhausted
    local recovery_db="postgres"
    local idle_count=$(PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$recovery_db" -t -A -c \
        "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle';" 2>/dev/null || echo "0")
    idle_count=$(echo "$idle_count" | tr -d '[:space:]')

    if [ "${idle_count:-0}" -gt 5 ] 2>/dev/null; then
        echo -e "  ${YELLOW}Pool recovery: $idle_count idle connections, terminating...${NC}"
        PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$recovery_db" -t -A -c \
            "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND state = 'idle' AND pid != pg_backend_pid();" \
            > /dev/null 2>&1 || true
        sleep 5
        echo -e "  ${GREEN}Pool recovered${NC}"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# List mode
if [ "$LIST_ONLY" = true ]; then
    echo -e "${BOLD}Available Test Suites${NC}"
    echo -e "${DIM}Environment: ${ACTIVE_ENV:-LOCAL_DEV}${NC}"

    list_suites "TIER 1: ESSENTIAL (--quick)" "${ESSENTIAL_TESTS[@]}"

    list_suites "TIER 2: COMPREHENSIVE A (--standard)" "${COMPREHENSIVE_TESTS_A[@]}"
    list_suites "TIER 2: COMPREHENSIVE B (--standard)" "${COMPREHENSIVE_TESTS_B[@]}"
    list_suites "TIER 2: EXTENDED AUTH (--standard)" "${AUTH_EXTENDED_TESTS[@]}"
    list_suites "TIER 2: ADMIN & RBAC (--standard)" "${ADMIN_TESTS[@]}"
    list_suites "TIER 2: PLATFORM (--standard)" "${PLATFORM_TESTS[@]}"

    list_suites "TIER 3: SECURITY HARDENING (--full)" "${SECURITY_TESTS[@]}"
    list_suites "TIER 3: ADVANCED AUTH (--full)" "${ADVANCED_AUTH_TESTS[@]}"
    list_suites "TIER 3: OBSERVABILITY (--full)" "${OBSERVABILITY_TESTS[@]}"
    list_suites "TIER 3: ENTERPRISE FEATURES (--full)" "${ENTERPRISE_TESTS[@]}"
    list_suites "TIER 3: OAUTH & JWT (--full)" "${OAUTH_TESTS[@]}"
    list_suites "TIER 3: INFRASTRUCTURE (--full)" "${INFRASTRUCTURE_TESTS[@]}"
    list_suites "TIER 3: RECENT WOs (--full)" "${RECENT_WO_TESTS[@]}"

    # Count totals
    TOTAL_QUICK=${#ESSENTIAL_TESTS[@]}
    TOTAL_STANDARD=$((TOTAL_QUICK + ${#COMPREHENSIVE_TESTS_A[@]} + ${#COMPREHENSIVE_TESTS_B[@]} + ${#AUTH_EXTENDED_TESTS[@]} + ${#ADMIN_TESTS[@]} + ${#PLATFORM_TESTS[@]}))
    TOTAL_FULL=$((TOTAL_STANDARD + ${#SECURITY_TESTS[@]} + ${#ADVANCED_AUTH_TESTS[@]} + ${#OBSERVABILITY_TESTS[@]} + ${#ENTERPRISE_TESTS[@]} + ${#OAUTH_TESTS[@]} + ${#INFRASTRUCTURE_TESTS[@]} + ${#RECENT_WO_TESTS[@]}))
    echo -e "\n${BOLD}Totals:${NC} --quick=$TOTAL_QUICK  --standard=$TOTAL_STANDARD  --full=$TOTAL_FULL"
    exit 0
fi

# Banner
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}{{PROJECT_NAME}} - REGRESSION TEST SUITE${NC}"
echo -e "${CYAN}║${NC}  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "${CYAN}║${NC}  Mode: ${BOLD}$(echo "$MODE" | tr '[:lower:]' '[:upper:]')${NC}  Env: ${BOLD}${ACTIVE_ENV:-LOCAL_DEV}${NC}"
echo -e "${CYAN}║${NC}  DB: ${DIM}${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"

# Environment preparation
if [ "$SKIP_PREP" = false ]; then
    prepare_environment
fi

# ============================================================================
# TIER 1: ESSENTIAL (all modes)
# ============================================================================
run_category "TIER 1: ESSENTIAL AUTHENTICATION" "${ESSENTIAL_TESTS[@]}" || true

# ============================================================================
# TIER 2: STANDARD (--standard and --full)
# ============================================================================
if [ "$MODE" = "standard" ] || [ "$MODE" = "full" ]; then

    # Pool recovery + risk state cleaning between tier 1 and tier 2
    # Essential tests create many logins, exhausting pool and accumulating risk events
    recover_db_pool
    redis-cli -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || true
    PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c \
        "DELETE FROM audit.events WHERE action IN ('auth.login_failed','auth.session_blocked_high_risk') AND created_at > NOW() - INTERVAL '2 hours';" \
        > /dev/null 2>&1 || true

    run_category "TIER 2: COMPREHENSIVE (Auth & Data)" "${COMPREHENSIVE_TESTS_A[@]}" || true

    # Pool recovery between comprehensive batches — API Keys & Webhooks need clean pool
    recover_db_pool
    redis-cli -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || true

    run_category "TIER 2: COMPREHENSIVE (Admin APIs)" "${COMPREHENSIVE_TESTS_B[@]}" || true

    # Pool recovery after all comprehensive tests
    recover_db_pool
    redis-cli -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || true

    run_category "TIER 2: EXTENDED AUTHENTICATION" "${AUTH_EXTENDED_TESTS[@]}" || true
    run_category "TIER 2: ADMIN & RBAC" "${ADMIN_TESTS[@]}" || true
    run_category "TIER 2: PLATFORM" "${PLATFORM_TESTS[@]}" || true
fi

# ============================================================================
# TIER 3: FULL (--full only)
# ============================================================================
if [ "$MODE" = "full" ]; then

    # Mid-run risk state cleanup to prevent cascading failures
    redis-cli -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || true
    PGPASSWORD="$PGPASSWORD" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c \
        "DELETE FROM audit.events WHERE action IN ('auth.login_failed','auth.session_blocked_high_risk') AND created_at > NOW() - INTERVAL '2 hours';" \
        > /dev/null 2>&1 || true

    run_category "TIER 3: SECURITY HARDENING" "${SECURITY_TESTS[@]}" || true

    recover_db_pool

    run_category "TIER 3: ADVANCED AUTH" "${ADVANCED_AUTH_TESTS[@]}" || true
    run_category "TIER 3: OBSERVABILITY" "${OBSERVABILITY_TESTS[@]}" || true

    # Recovery before enterprise tests
    recover_db_pool
    redis-cli -p "${REDIS_PORT:-6379}" FLUSHDB > /dev/null 2>&1 || true

    run_category "TIER 3: ENTERPRISE FEATURES" "${ENTERPRISE_TESTS[@]}" || true
    run_category "TIER 3: OAUTH & JWT" "${OAUTH_TESTS[@]}" || true

    recover_db_pool

    run_category "TIER 3: INFRASTRUCTURE" "${INFRASTRUCTURE_TESTS[@]}" || true
    run_category "TIER 3: RECENT WOs" "${RECENT_WO_TESTS[@]}" || true
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

# Calculate pass rate
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

if [ "$TOTAL_FAILED" -eq 0 ] && [ "$TOTAL_SKIPPED" -eq 0 ]; then
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}ALL SYSTEMS GO - PRODUCTION READY${NC}"
elif [ "$TOTAL_FAILED" -eq 0 ]; then
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}PASS${NC} ${YELLOW}(${TOTAL_SKIPPED} skipped — missing files)${NC}"
else
    echo -e "${CYAN}║${NC}  ${RED}${BOLD}FAILURES DETECTED — DO NOT DEPLOY${NC}"
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

# Exit with failure code if any tests failed
if [ "$TOTAL_FAILED" -gt 0 ]; then
    exit 1
fi

exit 0
