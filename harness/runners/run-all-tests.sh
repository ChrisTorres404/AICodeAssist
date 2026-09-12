#!/bin/bash
# ============================================================================
# Run every suite on disk
# ============================================================================
# The manifest-driven runner (run-all-critical-tests.sh) runs what is listed.
# This one runs every suite file in the suites directory, listed or not — use
# it to catch suites that were written but never added to the manifest.
#
# Usage:
#   ./run-all-tests.sh                        # against LOCAL_DEV (default)
#   ACTIVE_ENV=DOCKER ./run-all-tests.sh      # against containers
#
# Options (environment):
#   STOP_ON_FAIL=true   stop at the first failure
#   SUITES_DIR=...      where the suites live
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"

if [ -z "${SUITES_DIR:-}" ]; then
  for candidate in \
      "$SCRIPT_DIR/../../../{{TESTING_DIR}}/suites" \
      "$SCRIPT_DIR/../../{{TESTING_DIR}}/suites" \
      "$SCRIPT_DIR/../suites"; do
    [ -d "$candidate" ] && { SUITES_DIR="$candidate"; break; }
  done
  SUITES_DIR="${SUITES_DIR:-$SCRIPT_DIR/../suites}"
fi

echo "Loading test configuration..."
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# Every executable suite, minus anything that is a shared library rather than a
# suite (files whose name starts with an underscore or contains "helpers").
TEST_FILES=()
while IFS= read -r found; do
  [ -n "$found" ] && TEST_FILES+=("$found")
done < <(find "$SUITES_DIR" -name '*.sh' -type f 2>/dev/null \
  | grep -v -e '/_' -e 'helpers' | sort)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Behavioral Test Suite — every suite on disk"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Environment: ${ENV_LABEL:-${ACTIVE_ENV:-LOCAL_DEV}}"
echo "  Suites dir:  ${SUITES_DIR}"
echo "  Found:       ${#TEST_FILES[@]}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "${#TEST_FILES[@]}" -eq 0 ]; then
  echo "No suites found in $SUITES_DIR"
  exit 0
fi

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
declare -a FAILED_NAMES

for test_file in "${TEST_FILES[@]}"; do
  test_name=$(basename "$test_file")
  TOTAL_SUITES=$((TOTAL_SUITES + 1))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Running: ${test_name} (${TOTAL_SUITES}/${#TEST_FILES[@]})"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if bash "$test_file"; then
    echo ""
    echo "EXECUTED — PASS: ${test_name}"
    PASSED_SUITES=$((PASSED_SUITES + 1))
  else
    echo ""
    echo "EXECUTED — FAIL: ${test_name}"
    FAILED_SUITES=$((FAILED_SUITES + 1))
    FAILED_NAMES+=("$test_name")

    if [ "${STOP_ON_FAIL:-false}" = "true" ]; then
      echo ""
      echo "STOP_ON_FAIL=true — stopping"
      break
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Suite Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Total Suites: ${TOTAL_SUITES}"
echo "  Passed: ${PASSED_SUITES}"
echo "  Failed: ${FAILED_SUITES}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${FAILED_SUITES} -gt 0 ]; then
  echo ""
  echo "Failed:"
  for failed_test in "${FAILED_NAMES[@]}"; do
    echo "  - ${failed_test}"
  done
  echo ""
  exit 1
fi

echo ""
exit 0
