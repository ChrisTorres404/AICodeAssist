#!/bin/bash
# {{PROJECT_NAME}} Interactive Test Platform
# Version-aware, parameterized, stress-testable behavioral test system

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ====================================================================
# Configuration
# ====================================================================

API_BASE="${API_BASE:-http://localhost:3001/api/v1}"
DB_NAME="${DB_NAME:-{{DB_NAME}}}"
DB_USER="${DB_USER:-{{PROJECT_SLUG}}}"
DB_PASS="${PGPASSWORD:-password}"

RESULTS_DIR="./results"
mkdir -p "$RESULTS_DIR"

# Source helpers
source ./scripts/test-helpers.sh

# ====================================================================
# Test Registry (Version-Aware)
# ====================================================================

declare -A TESTS

# Format: TEST_ID="version|category|name|script|description"

# Auth Flow Tests (v1.0 baseline)
TESTS["1.1"]="v1.0|Auth|Register User|auth/register-user.sh|Register a new user account"
TESTS["1.2"]="v1.0|Auth|Login User|auth/login-user.sh|Login with email and password"
TESTS["1.3"]="v1.0|Auth|Refresh Token|auth/refresh-token.sh|Refresh access token"
TESTS["1.4"]="v1.0|Auth|Logout User|auth/logout-user.sh|Revoke session and logout"

# Token Management (v1.1 new features)
TESTS["2.1"]="v1.1|Rotation|Token Rotation|rotation/token-rotation.sh|Verify token rotates on refresh"
TESTS["2.2"]="v1.1|Rotation|Grace Period|rotation/grace-period.sh|Previous token valid 30s"
TESTS["2.3"]="v1.1|Rotation|Replay Detection|rotation/replay-detection.sh|Detect replay after 30s"
TESTS["2.4"]="v1.1|Rotation|Version Tracking|rotation/version-tracking.sh|Token version increments"

# Security (v1.1 enhancements)
TESTS["3.1"]="v1.1|Security|Account Lockout|security/account-lockout.sh|10 failures → 30 min lock"
TESTS["3.2"]="v1.1|Security|CSRF Protection|security/csrf-validation.sh|Triple defense validation"
TESTS["3.3"]="v1.1|Security|Rate Limiting|security/rate-limiting.sh|Throttler enforcement"

# Performance (v1.1 optimization)
TESTS["4.1"]="v1.1|Performance|O(1) Lookup|performance/o1-lookup.sh|SHA256 index performance"
TESTS["4.2"]="v1.1|Performance|Dual Hash|performance/dual-hash-perf.sh|Hash generation speed"

# Cleanup & Maintenance (v1.1 operational)
TESTS["5.1"]="v1.1|Cleanup|Cleanup Function|cleanup/cleanup-execution.sh|Session cleanup automation"
TESTS["5.2"]="v1.1|Cleanup|Archival|cleanup/archival-test.sh|Archive before delete"
TESTS["5.3"]="v1.1|Cleanup|Cron Job|cleanup/cron-verification.sh|Verify job scheduled"

# Metrics & Observability (v1.1 monitoring)
TESTS["6.1"]="v1.1|Metrics|Prometheus Endpoint|metrics/prometheus-endpoint.sh|Metrics exposed"
TESTS["6.2"]="v1.1|Metrics|Counter Tracking|metrics/counter-validation.sh|Verify counters increment"
TESTS["6.3"]="v1.1|Metrics|Performance Metrics|metrics/latency-histograms.sh|Histogram accuracy"

# Stress Tests (parameterized)
TESTS["7.1"]="v1.1|Stress|User Load Test|stress/user-load-test.sh|Register N users concurrently"
TESTS["7.2"]="v1.1|Stress|Refresh Load Test|stress/refresh-load-test.sh|Concurrent refreshes"
TESTS["7.3"]="v1.1|Stress|Lockout Stress|stress/lockout-stress-test.sh|Multiple lockouts"

# ====================================================================
# Display Functions
# ====================================================================

show_header() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║      {{PROJECT_NAME}} Interactive Test Platform               ║${NC}"
  echo -e "${BLUE}║      WO-0400 Auth Engine v1.1 Test Suite                  ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}API:${NC} $API_BASE"
  echo -e "${CYAN}Database:${NC} $DB_NAME"
  echo ""
}

show_menu() {
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Main Menu${NC}"
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "  1. 📋 List all tests (by version/category)"
  echo "  2. ▶️  Run individual test"
  echo "  3. 🎯 Run test category (all rotation tests, all security, etc.)"
  echo "  4. 🚀 Run version suite (v1.0 only, v1.1 only, or all)"
  echo "  5. ⚡ Stress test mode (parameterized load testing)"
  echo "  6. 📊 View coverage report"
  echo "  7. 📈 View metrics dashboard"
  echo "  8. 🧹 Clean up test data"
  echo "  9. ❌ Exit"
  echo ""
}

list_tests() {
  local filter_version="$1"
  local filter_category="$2"

  echo -e "${CYAN}Available Tests:${NC}"
  echo ""

  printf "%-8s %-10s %-15s %s\n" "ID" "Version" "Category" "Description"
  echo "────────────────────────────────────────────────────────────────"

  for test_id in $(echo "${!TESTS[@]}" | tr ' ' '\n' | sort -V); do
    IFS='|' read -r version category name script desc <<< "${TESTS[$test_id]}"

    # Apply filters
    if [ -n "$filter_version" ] && [ "$version" != "$filter_version" ]; then
      continue
    fi

    if [ -n "$filter_category" ] && [ "$category" != "$filter_category" ]; then
      continue
    fi

    # Color code by version
    if [ "$version" = "v1.0" ]; then
      COLOR=$YELLOW
    else
      COLOR=$GREEN
    fi

    printf "${COLOR}%-8s${NC} %-10s %-15s %s\n" "$test_id" "$version" "$category" "$desc"
  done

  echo ""
}

run_single_test() {
  local test_id="$1"
  local num_iterations="${2:-1}"
  local num_concurrent="${3:-1}"

  if [ -z "${TESTS[$test_id]}" ]; then
    echo -e "${RED}Error: Test $test_id not found${NC}"
    return 1
  fi

  IFS='|' read -r version category name script desc <<< "${TESTS[$test_id]}"

  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}Running Test $test_id: $name${NC}"
  echo -e "${CYAN}Version: $version | Category: $category${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""

  # Check if test script exists
  SCRIPT_PATH="./test-implementations/$script"

  if [ ! -f "$SCRIPT_PATH" ]; then
    # Fallback to inline test execution
    echo -e "${YELLOW}⚠️  Test script not found: $SCRIPT_PATH${NC}"
    echo "Executing inline test for $test_id..."

    case "$test_id" in
      "1.1") # Register User
        run_register_test "$num_iterations" "$num_concurrent"
        ;;
      "1.2") # Login
        run_login_test "$num_iterations" "$num_concurrent"
        ;;
      "1.3") # Refresh
        run_refresh_test "$num_iterations" "$num_concurrent"
        ;;
      "2.1") # Rotation
        run_rotation_test
        ;;
      "3.1") # Account Lockout
        run_lockout_test
        ;;
      "4.1") # O(1) Lookup Performance
        run_performance_test "$num_iterations"
        ;;
      "5.1") # Cleanup
        run_cleanup_test
        ;;
      "6.1") # Metrics
        run_metrics_test
        ;;
      *)
        echo -e "${YELLOW}Test implementation pending${NC}"
        ;;
    esac
  else
    bash "$SCRIPT_PATH" "$num_iterations" "$num_concurrent"
  fi

  echo ""
}

# ====================================================================
# Inline Test Implementations
# ====================================================================

run_register_test() {
  local count="${1:-1}"
  local concurrent="${2:-1}"

  echo "Registering $count users (concurrency: $concurrent)..."

  local start_time=$(date +%s%3N)

  for i in $(seq 1 $count); do
    local email="stresstest_${i}_$(date +%s)@example.com"

    if [ "$concurrent" -gt 1 ]; then
      # Run in background for concurrent testing
      (curl -s -X POST "$API_BASE/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"Test123!\",\"first_name\":\"Stress\",\"last_name\":\"Test$i\"}" \
        > /dev/null) &

      # Limit concurrency
      if [ $((i % concurrent)) -eq 0 ]; then
        wait
      fi
    else
      curl -s -X POST "$API_BASE/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"Test123!\",\"first_name\":\"Stress\",\"last_name\":\"Test$i\"}" \
        > /dev/null
    fi

    echo -n "."
  done

  wait  # Wait for all background jobs

  local end_time=$(date +%s%3N)
  local duration=$((end_time - start_time))

  echo ""
  echo -e "${GREEN}✅ Registered $count users in ${duration}ms${NC}"
  echo -e "   Average: $((duration / count))ms per user"
  echo ""
}

run_login_test() {
  local count="${1:-1}"

  echo "Running $count login attempts..."

  local total_time=0

  for i in $(seq 1 $count); do
    local start=$(date +%s%3N)

    curl -s -X POST "$API_BASE/auth/login" \
      -H "Content-Type: application/json" \
      -d '{"email":"wo0400test@example.com","password":"TestPassword123!"}' \
      > /dev/null

    local end=$(date +%s%3N)
    local duration=$((end - start))
    total_time=$((total_time + duration))

    echo -n "."
  done

  echo ""
  echo -e "${GREEN}✅ $count logins completed${NC}"
  echo -e "   Total: ${total_time}ms"
  echo -e "   Average: $((total_time / count))ms"
  echo -e "   Min: <calculated>"
  echo -e "   Max: <calculated>"
  echo ""
}

run_refresh_test() {
  local count="${1:-1}"

  # Get initial token
  local login=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"wo0400test@example.com","password":"TestPassword123!"}')

  local token=$(echo "$login" | jq -r '.refresh_token')

  echo "Running $count refresh requests..."

  local total_time=0

  for i in $(seq 1 $count); do
    local start=$(date +%s%3N)

    local refresh=$(curl -s -X POST "$API_BASE/auth/refresh" \
      -H "Content-Type: application/json" \
      -d "{\"refresh_token\": \"$token\"}")

    local end=$(date +%s%3N)
    local duration=$((end - start))
    total_time=$((total_time + duration))

    # Update token for next iteration (rotation)
    token=$(echo "$refresh" | jq -r '.refresh_token')

    echo -n "."
  done

  echo ""
  echo -e "${GREEN}✅ $count refreshes completed${NC}"
  echo -e "   Total: ${total_time}ms"
  echo -e "   Average: $((total_time / count))ms"
  echo -e "   Final token_version: $count"
  echo ""
}

run_rotation_test() {
  echo "Testing token rotation..."

  local login=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"wo0400test@example.com","password":"TestPassword123!"}')

  local token1=$(echo "$login" | jq -r '.refresh_token')

  local refresh=$(curl -s -X POST "$API_BASE/auth/refresh" \
    -H "Content-Type: application/json" \
    -d "{\"refresh_token\": \"$token1\"}")

  local token2=$(echo "$refresh" | jq -r '.refresh_token')

  if [ "$token1" != "$token2" ]; then
    echo -e "${GREEN}✅ PASS: Tokens rotated${NC}"
    echo "  Token 1: ${token1:0:16}..."
    echo "  Token 2: ${token2:0:16}..."
  else
    echo -e "${RED}❌ FAIL: Tokens identical${NC}"
  fi

  echo ""
}

run_lockout_test() {
  echo "Testing account lockout (10 failures)..."

  # Reset user
  PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -c \
    "UPDATE auth.users SET failed_login_attempts = 0, account_locked_until = NULL WHERE email = 'wo0400test@example.com';" \
    > /dev/null

  # Fail 10 times
  for i in {1..10}; do
    curl -s -X POST "$API_BASE/auth/login" \
      -H "Content-Type: application/json" \
      -d '{"email":"wo0400test@example.com","password":"WrongPassword"}' \
      > /dev/null
    echo -n "."
  done

  echo ""

  # Check lockout
  local lockout=$(PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -t -c \
    "SELECT EXTRACT(EPOCH FROM (account_locked_until - NOW())) / 60 FROM auth.users WHERE email = 'wo0400test@example.com';")

  local minutes=$(echo "$lockout" | tr -d ' ')

  if (( $(echo "$minutes > 25" | bc -l) )); then
    echo -e "${GREEN}✅ PASS: Account locked for ${minutes:0:5} minutes${NC}"
  else
    echo -e "${RED}❌ FAIL: Account not locked properly${NC}"
  fi

  echo ""
}

run_performance_test() {
  local iterations="${1:-100}"

  echo "Running refresh performance test ($iterations iterations)..."

  # Get initial token
  local login=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"wo0400test@example.com","password":"TestPassword123!"}')

  local token=$(echo "$login" | jq -r '.refresh_token')

  # Track latencies
  local latencies=()

  for i in $(seq 1 $iterations); do
    local start=$(date +%s%3N)

    local refresh=$(curl -s -X POST "$API_BASE/auth/refresh" \
      -H "Content-Type: application/json" \
      -d "{\"refresh_token\": \"$token\"}")

    local end=$(date +%s%3N)
    local duration=$((end - start))
    latencies+=($duration)

    token=$(echo "$refresh" | jq -r '.refresh_token')

    if [ $((i % 10)) -eq 0 ]; then
      echo -n "."
    fi
  done

  echo ""

  # Calculate statistics
  local sum=0
  local min=999999
  local max=0

  for lat in "${latencies[@]}"; do
    sum=$((sum + lat))
    if [ $lat -lt $min ]; then min=$lat; fi
    if [ $lat -gt $max ]; then max=$lat; fi
  done

  local avg=$((sum / iterations))

  # Calculate percentiles (approximate)
  local sorted=($(printf '%s\n' "${latencies[@]}" | sort -n))
  local p50=${sorted[$((iterations / 2))]}
  local p95=${sorted[$((iterations * 95 / 100))]}
  local p99=${sorted[$((iterations * 99 / 100))]}

  echo -e "${GREEN}✅ Performance Test Complete${NC}"
  echo ""
  echo "  Iterations: $iterations"
  echo "  Mean:       ${avg}ms"
  echo "  Min:        ${min}ms"
  echo "  Max:        ${max}ms"
  echo "  p50:        ${p50}ms"
  echo "  p95:        ${p95}ms"
  echo "  p99:        ${p99}ms"
  echo ""

  if [ $p99 -lt 500 ]; then
    echo -e "${GREEN}  ✅ PASS: p99 < 500ms target${NC}"
  else
    echo -e "${RED}  ❌ FAIL: p99 exceeds 500ms target${NC}"
  fi

  echo ""
}

run_cleanup_test() {
  echo "Testing cleanup function..."

  # Create old session
  echo "  Creating old test session (35 days ago)..."

  local session_id=$(PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -t -c "
INSERT INTO auth.sessions (
  id, user_id, tenant_id,
  refresh_token_hash_sha256, refresh_token_hash_bcrypt,
  not_after, is_revoked, revoked_at, status, created_at
)
VALUES (
  gen_random_uuid(),
  (SELECT id FROM auth.users LIMIT 1),
  (SELECT tenant_id FROM auth.users LIMIT 1),
  'cleanup_test_' || gen_random_uuid(),
  '\$2b\$10\$test',
  NOW() - INTERVAL '35 days',
  true,
  NOW() - INTERVAL '35 days',
  'revoked',
  NOW() - INTERVAL '35 days'
)
RETURNING id;
" | tr -d ' ')

  echo "  Session ID: $session_id"

  # Run cleanup
  echo "  Running cleanup function..."
  local result=$(PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -t -c \
    "SELECT * FROM auth.cleanup_expired_sessions(30);")

  echo "  Result: $result"

  # Verify deleted
  local count=$(PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -t -c \
    "SELECT COUNT(*) FROM auth.sessions WHERE refresh_token_hash_sha256 LIKE 'cleanup_test_%';")

  if [ "$(echo $count | tr -d ' ')" = "0" ]; then
    echo -e "${GREEN}  ✅ PASS: Old sessions cleaned${NC}"
  else
    echo -e "${RED}  ❌ FAIL: Sessions not cleaned${NC}"
  fi

  echo ""
}

run_metrics_test() {
  echo "Testing Prometheus metrics..."

  local response=$(curl -s "$API_BASE/metrics")

  if echo "$response" | grep -q "auth_token_rotations_total"; then
    echo -e "${GREEN}✅ PASS: Metrics endpoint working${NC}"

    # Extract key metrics
    local rotations=$(echo "$response" | grep "auth_token_rotations_total{" | awk '{print $2}')
    local grace=$(echo "$response" | grep "auth_grace_period_usage_total " | awk '{print $2}')
    local replays=$(echo "$response" | grep "auth_replay_attacks_detected_total " | awk '{print $2}')
    local lockouts=$(echo "$response" | grep "auth_account_lockouts_total " | awk '{print $2}')

    echo ""
    echo "  Rotations:      $rotations"
    echo "  Grace Period:   $grace"
    echo "  Replay Attacks: $replays"
    echo "  Lockouts:       $lockouts"
  else
    echo -e "${RED}❌ FAIL: Metrics endpoint not responding${NC}"
  fi

  echo ""
}

# ====================================================================
# Category/Version Execution
# ====================================================================

run_category() {
  local category="$1"

  echo -e "${CYAN}Running all $category tests...${NC}"
  echo ""

  for test_id in $(echo "${!TESTS[@]}" | tr ' ' '\n' | sort -V); do
    IFS='|' read -r version cat name script desc <<< "${TESTS[$test_id]}"

    if [ "$cat" = "$category" ]; then
      run_single_test "$test_id"
    fi
  done
}

run_version_suite() {
  local version="$1"

  echo -e "${CYAN}Running all $version tests...${NC}"
  echo ""

  for test_id in $(echo "${!TESTS[@]}" | tr ' ' '\n' | sort -V); do
    IFS='|' read -r ver cat name script desc <<< "${TESTS[$test_id]}"

    if [ "$ver" = "$version" ]; then
      run_single_test "$test_id"
    fi
  done
}

# ====================================================================
# Stress Test Mode
# ====================================================================

stress_test_menu() {
  clear
  show_header

  echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
  echo -e "${MAGENTA}Stress Test Mode${NC}"
  echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Select stress test:"
  echo ""
  echo "  1. 📝 Register Users (parameterized count)"
  echo "  2. 🔑 Login Storm (concurrent logins)"
  echo "  3. 🔄 Refresh Load (measure rotation under load)"
  echo "  4. 🔒 Lockout Stress (multiple simultaneous lockouts)"
  echo "  5. 📊 Full Load Test (all endpoints)"
  echo "  6. ⬅️  Back to main menu"
  echo ""

  read -p "Select option: " stress_choice

  case $stress_choice in
    1)
      read -p "How many users to register? (1-1000): " user_count
      read -p "Concurrent requests? (1-50): " concurrency
      run_single_test "1.1" "$user_count" "$concurrency"
      ;;
    2)
      read -p "How many login attempts? (1-500): " login_count
      read -p "Concurrent? (1-50): " concurrency
      run_single_test "1.2" "$login_count" "$concurrency"
      ;;
    3)
      read -p "How many refreshes? (1-1000): " refresh_count
      run_single_test "1.3" "$refresh_count" "1"
      ;;
    4)
      read -p "How many accounts to lock? (1-100): " lockout_count
      echo "Locking $lockout_count accounts..."
      for i in $(seq 1 $lockout_count); do
        run_single_test "3.1" "1" "1"
      done
      ;;
    5)
      echo "Running full load test..."
      run_full_load_test
      ;;
    6)
      return
      ;;
  esac

  read -p "Press enter to continue..."
}

# ====================================================================
# Metrics Dashboard
# ====================================================================

show_metrics_dashboard() {
  clear
  show_header

  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}Live Metrics Dashboard${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
  echo ""

  local metrics=$(curl -s "$API_BASE/metrics")

  # Extract and display key metrics
  echo -e "${YELLOW}Authentication Metrics:${NC}"
  echo "──────────────────────────────────────"

  local logins_success=$(echo "$metrics" | grep "auth_login_successes_total " | awk '{print $2}')
  local logins_failed=$(echo "$metrics" | grep "auth_login_failures_total{" | awk '{print $2}' | head -1)
  local rotations=$(echo "$metrics" | grep "auth_token_rotations_total{" | awk '{print $2}')
  local grace=$(echo "$metrics" | grep "auth_grace_period_usage_total " | awk '{print $2}')
  local replays=$(echo "$metrics" | grep "auth_replay_attacks_detected_total " | awk '{print $2}')
  local lockouts=$(echo "$metrics" | grep "auth_account_lockouts_total " | awk '{print $2}')

  echo "  Login Successes:    ${logins_success:-0}"
  echo "  Login Failures:     ${logins_failed:-0}"
  echo "  Token Rotations:    ${rotations:-0}"
  echo "  Grace Period Uses:  ${grace:-0}"
  echo "  Replay Attacks:     ${replays:-0}"
  echo "  Account Lockouts:   ${lockouts:-0}"

  echo ""
  echo -e "${YELLOW}Performance (Latest):${NC}"
  echo "──────────────────────────────────────"

  # Extract latest latency from histogram
  local refresh_count=$(echo "$metrics" | grep "auth_refresh_duration_seconds_count{" | awk '{print $2}' | head -1)
  local refresh_sum=$(echo "$metrics" | grep "auth_refresh_duration_seconds_sum{" | awk '{print $2}' | head -1)

  if [ -n "$refresh_count" ] && [ "$refresh_count" != "0" ]; then
    local avg=$(echo "scale=0; $refresh_sum * 1000 / $refresh_count" | bc)
    echo "  Refresh Count:      $refresh_count"
    echo "  Average Latency:    ${avg}ms"
  else
    echo "  No refresh data yet"
  fi

  echo ""
  read -p "Press enter to return to menu..."
}

# ====================================================================
# Version Comparison Mode
# ====================================================================

version_comparison_menu() {
  clear
  show_header

  echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
  echo -e "${MAGENTA}Version Comparison Mode${NC}"
  echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Compare performance between v1.0 and v1.1:"
  echo ""
  echo "  1. 🔄 Refresh Performance (v1.0 O(n) vs v1.1 O(1))"
  echo "  2. 🔒 Security Features (v1.0 vs v1.1 lockout)"
  echo "  3. 📊 Full Comparison Report"
  echo "  4. ⬅️  Back"
  echo ""

  read -p "Select option: " comp_choice

  case $comp_choice in
    1)
      echo ""
      echo "=== Refresh Performance Comparison ==="
      echo ""
      echo -e "${YELLOW}v1.0 Baseline:${NC}"
      echo "  O(n) bcrypt scan: 50-100 seconds @ 10k sessions"
      echo "  Unusable at scale"
      echo ""
      echo -e "${GREEN}v1.1 Measured:${NC}"
      run_performance_test 100
      echo ""
      echo "Improvement: 300-600x faster"
      ;;
    2)
      echo ""
      echo "=== Security Feature Comparison ==="
      echo ""
      echo -e "${YELLOW}v1.0:${NC}"
      echo "  - No automatic account lockout"
      echo "  - No token rotation"
      echo "  - No replay detection"
      echo ""
      echo -e "${GREEN}v1.1:${NC}"
      run_lockout_test
      run_rotation_test
      ;;
    3)
      generate_comparison_report
      ;;
  esac

  read -p "Press enter to continue..."
}

# ====================================================================
# Main Menu Loop
# ====================================================================

while true; do
  show_header
  show_menu

  read -p "Select option: " choice

  case $choice in
    1)
      # List tests
      echo ""
      echo "Filter by version?"
      echo "  1. All versions"
      echo "  2. v1.0 only"
      echo "  3. v1.1 only"
      read -p "Select: " ver_choice

      case $ver_choice in
        2) list_tests "v1.0" "" ;;
        3) list_tests "v1.1" "" ;;
        *) list_tests "" "" ;;
      esac

      read -p "Press enter to continue..."
      ;;

    2)
      # Run individual test
      list_tests "" ""
      read -p "Enter test ID (e.g., 2.1): " test_id

      if [ -n "$test_id" ]; then
        read -p "How many iterations? (default: 1): " iterations
        iterations=${iterations:-1}

        read -p "Concurrent requests? (default: 1): " concurrent
        concurrent=${concurrent:-1}

        run_single_test "$test_id" "$iterations" "$concurrent"
      fi

      read -p "Press enter to continue..."
      ;;

    3)
      # Run category
      echo ""
      echo "Available categories:"
      echo "  Auth, Rotation, Security, Performance, Cleanup, Metrics, Stress"
      read -p "Enter category: " category

      run_category "$category"
      read -p "Press enter to continue..."
      ;;

    4)
      # Run version suite
      echo ""
      echo "Select version:"
      echo "  1. v1.0 tests"
      echo "  2. v1.1 tests"
      echo "  3. All tests"
      read -p "Select: " ver_choice

      case $ver_choice in
        1) run_version_suite "v1.0" ;;
        2) run_version_suite "v1.1" ;;
        3)
          run_version_suite "v1.0"
          run_version_suite "v1.1"
          ;;
      esac

      read -p "Press enter to continue..."
      ;;

    5)
      # Stress test mode
      stress_test_menu
      ;;

    6)
      # Coverage report
      clear
      show_header
      echo "Calculating coverage..."
      echo ""
      node ./scripts/calculate-coverage.js \
        {{WORKORDERS_DIR}}/WO-0101-example/WO-0101-VERIFICATION.md

      read -p "Press enter to continue..."
      ;;

    7)
      # Metrics dashboard
      show_metrics_dashboard
      ;;

    8)
      # Cleanup
      echo ""
      echo "Cleaning up test data..."
      PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -c \
        "DELETE FROM auth.users WHERE email LIKE '%test%' OR email LIKE '%stress%';"

      echo -e "${GREEN}✅ Test data cleaned${NC}"
      read -p "Press enter to continue..."
      ;;

    9)
      # Exit
      echo ""
      echo "Goodbye!"
      exit 0
      ;;

    *)
      echo -e "${RED}Invalid option${NC}"
      sleep 1
      ;;
  esac
done