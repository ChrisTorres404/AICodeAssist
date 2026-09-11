#!/bin/bash
# WO-0400 Automated Behavioral Test Runner
# Executes all tests from harness, captures evidence, generates report

set -e

# ====================================================================
# Configuration
# ====================================================================

API_BASE="${API_BASE:-http://localhost:3001/api/v1}"
DB_NAME="${DB_NAME:-{{DB_NAME}}}"
DB_USER="${DB_USER:-{{PROJECT_SLUG}}}"
DB_PASS="${PGPASSWORD:-password}"

OUTPUT_DIR="./test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$OUTPUT_DIR/behavioral-test-report_$TIMESTAMP.md"
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"

mkdir -p "$OUTPUT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ====================================================================
# Test Execution Framework
# ====================================================================

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_http() {
  local test_id="$1"
  local test_name="$2"
  local method="$3"
  local endpoint="$4"
  local data="$5"
  local expected_status="$6"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -e "${YELLOW}Running Test $test_id: $test_name${NC}"

  # Execute request
  RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$API_BASE$endpoint" \
    -H "Content-Type: application/json" \
    -d "$data" 2>&1)

  HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed '$d')

  # Verify status code
  if [ "$HTTP_CODE" = "$expected_status" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    STATUS="PASS"
  else
    echo -e "  ${RED}❌ FAIL (expected $expected_status, got $HTTP_CODE)${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    STATUS="FAIL"
  fi

  # Append to report
  cat >> "$REPORT_FILE" <<EOF

## Test $test_id: $test_name

**Status:** EXECUTED — $STATUS

**HTTP Request:**
\`\`\`bash
curl -X $method $API_BASE$endpoint \\
  -H "Content-Type: application/json" \\
  -d '$data'
\`\`\`

**HTTP Response (Status: $HTTP_CODE):**
\`\`\`
$BODY
\`\`\`

**Expected Status:** $expected_status
**Actual Status:** $HTTP_CODE
**Result:** ✅ $STATUS

---
EOF
}

test_sql() {
  local test_id="$1"
  local test_name="$2"
  local query="$3"
  local expected_pattern="$4"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -e "${YELLOW}Running SQL Test $test_id: $test_name${NC}"

  # Execute query
  RESULT=$(PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h localhost -d "$DB_NAME" -t -c "$query" 2>&1)

  # Check if result contains expected pattern
  if echo "$RESULT" | grep -q "$expected_pattern"; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    STATUS="PASS"
  else
    echo -e "  ${RED}❌ FAIL (expected pattern: $expected_pattern)${NC}"
    echo -e "  ${RED}Got: $RESULT${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    STATUS="FAIL"
  fi

  # Append to report
  cat >> "$REPORT_FILE" <<EOF

## SQL Test $test_id: $test_name

**Status:** EXECUTED — $STATUS

**Query:**
\`\`\`sql
$query
\`\`\`

**Result:**
\`\`\`
$RESULT
\`\`\`

**Expected Pattern:** \`$expected_pattern\`
**Result:** ✅ $STATUS

---
EOF
}

# ====================================================================
# Initialize Report
# ====================================================================

cat > "$REPORT_FILE" <<EOF
# WO-0400 Behavioral Test Report (Automated)

**Date:** $(date)
**API:** $API_BASE
**Database:** $DB_NAME
**Execution:** AUTOMATED

---

## Test Execution
EOF

echo -e "${GREEN}========================================"
echo "WO-0400 Automated Behavioral Test Suite"
echo -e "========================================${NC}"
echo ""

# ====================================================================
# Test Suite Execution
# ====================================================================

# Test 1: Dual Hash Generation
test_sql "1.1" "Dual Hash in Database" \
  "SELECT COUNT(*) FROM auth.sessions WHERE refresh_token_hash_sha256 IS NOT NULL AND refresh_token_hash_bcrypt IS NOT NULL AND user_id = (SELECT id FROM auth.users WHERE email = 'wo0400test@example.com') LIMIT 1;" \
  "1"

# Test 2: Token Rotation
echo ""
echo "Executing token rotation test..."
REFRESH_RESPONSE=$(curl -s -X POST "$API_BASE/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"${TEST_REFRESH_TOKEN:?export a refresh token captured from a prior login}"}' 2>&1)

if echo "$REFRESH_RESPONSE" | grep -q "refresh_token"; then
  echo -e "${GREEN}✅ Token rotation working${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "${RED}❌ Token rotation failed${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test 3: Metrics Endpoint
test_http "3.1" "Prometheus Metrics Endpoint" \
  "GET" "/metrics" \
  "" \
  "200"

# Test 4: Cleanup Function
test_sql "4.1" "Cleanup Function Exists" \
  "SELECT COUNT(*) FROM pg_proc WHERE proname = 'cleanup_expired_sessions' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');" \
  "1"

# Test 5: Account Lockout Verification
test_sql "5.1" "Account Lockout State" \
  "SELECT failed_login_attempts FROM auth.users WHERE email = 'wo0400test@example.com';" \
  "10"

# ====================================================================
# Generate Summary
# ====================================================================

COVERAGE_PCT=$((PASSED_TESTS * 100 / TOTAL_TESTS))

cat >> "$REPORT_FILE" <<EOF

---

## Final Summary

**Total Tests:** $TOTAL_TESTS
**Passed:** $PASSED_TESTS
**Failed:** $FAILED_TESTS
**Coverage:** $COVERAGE_PCT%

**Verdict:** $([ $FAILED_TESTS -eq 0 ] && echo "✅ ALL TESTS PASSED" || echo "❌ $FAILED_TESTS TEST(S) FAILED")

---

**Report generated:** $(date)
**Report location:** $REPORT_FILE
EOF

# Generate summary file
cat > "$SUMMARY_FILE" <<EOF
WO-0400 Behavioral Tests: $COVERAGE_PCT% Coverage
Total: $TOTAL_TESTS | Passed: $PASSED_TESTS | Failed: $FAILED_TESTS
Status: $([ $FAILED_TESTS -eq 0 ] && echo "✅ ALL PASS" || echo "❌ FAILURES")
EOF

echo ""
echo -e "${GREEN}========================================"
echo "Test Execution Complete"
echo -e "========================================${NC}"
echo "Total:    $TOTAL_TESTS"
echo "Passed:   $PASSED_TESTS"
echo "Failed:   $FAILED_TESTS"
echo "Coverage: $COVERAGE_PCT%"
echo ""
echo "Report: $REPORT_FILE"
echo ""

# Exit code = number of failures (0 = success for CI/CD)
exit $FAILED_TESTS