#!/bin/bash
# ============================================================================
# Behavioral Test Suite - Master Test Runner
# ============================================================================
# Runs ALL behavioral tests in the suite with centralized configuration
#
# Usage:
#   ./run-all-tests.sh                    # Run against LOCAL_DEV (default)
#   ACTIVE_ENV=LOCAL_TEST ./run-all-tests.sh    # Run against fresh test db
#   ACTIVE_ENV=DOCKER ./run-all-tests.sh        # Run against Docker
#
# Options:
#   STOP_ON_FAIL=true   # Stop on first failure
#   VERBOSE=true        # Show detailed output
#   SHOW_CONFIG=true    # Display configuration before running
# ============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="${SCRIPT_DIR}/suites"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Load master configuration
echo "Loading test configuration..."
source "${CONFIG_DIR}/test-config.env"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Behavioral Test Suite - Master Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Environment: ${ENV_LABEL}"
echo "  Target Database: ${DB_NAME}"
echo "  Total Tests: $(ls -1 "${SUITE_DIR}"/*.sh | grep -v test-helpers | wc -l | tr -d ' ')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Counters
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
SKIPPED_SUITES=0

# Results array
declare -a FAILED_TESTS

# Get all test files (exclude test-helpers.sh)
TEST_FILES=$(ls -1 "${SUITE_DIR}"/*.sh | grep -v "test-helpers.sh" | sort)

for test_file in $TEST_FILES; do
  test_name=$(basename "$test_file")
  TOTAL_SUITES=$((TOTAL_SUITES + 1))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Running: ${test_name} (${TOTAL_SUITES}/$(echo "$TEST_FILES" | wc -l | tr -d ' '))"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Run test
  if bash "$test_file"; then
    echo ""
    echo "✅ PASSED: ${test_name}"
    PASSED_SUITES=$((PASSED_SUITES + 1))
  else
    echo ""
    echo "❌ FAILED: ${test_name}"
    FAILED_SUITES=$((FAILED_SUITES + 1))
    FAILED_TESTS+=("$test_name")

    if [ "${STOP_ON_FAIL}" = "true" ]; then
      echo ""
      echo "STOP_ON_FAIL=true - Stopping test execution"
      break
    fi
  fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Suite Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Total Suites: ${TOTAL_SUITES}"
echo "  Passed: ${PASSED_SUITES}"
echo "  Failed: ${FAILED_SUITES}"
echo "  Skipped: ${SKIPPED_SUITES}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${FAILED_SUITES} -gt 0 ]; then
  echo ""
  echo "Failed Tests:"
  for failed_test in "${FAILED_TESTS[@]}"; do
    echo "  - ${failed_test}"
  done
fi

echo ""

# Exit with failure if any tests failed
if [ ${FAILED_SUITES} -gt 0 ]; then
  exit 1
fi

exit 0