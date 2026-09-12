#!/bin/bash
# Run one behavioral suite and keep its output as evidence.
#
#   ./run-test-suite.sh <path-to-suite.sh> [results-dir]
#
# The exit code is the suite's own: 0 means EXECUTED — PASS, anything else
# EXECUTED — FAIL. Nothing is summarised that was not run.

set -uo pipefail

SUITE_FILE="${1:-}"
RESULTS_DIR="${2:-${RESULTS_DIR:-./results}}"

if [ -z "$SUITE_FILE" ]; then
  echo "Usage: ./run-test-suite.sh <suite-file> [results-dir]"
  echo ""
  echo "Example:"
  echo "  ./run-test-suite.sh {{TESTING_DIR}}/suites/health-and-readiness.sh"
  exit 2
fi

if [ ! -f "$SUITE_FILE" ]; then
  echo "Error: suite file not found: $SUITE_FILE"
  exit 2
fi

mkdir -p "$RESULTS_DIR"

SUITE_NAME="$(basename "$SUITE_FILE" .sh)"
RESULT_FILE="$RESULTS_DIR/${SUITE_NAME}_$(date +%Y%m%d_%H%M%S).log"

echo "========================================"
echo "Running suite: $SUITE_NAME"
echo "========================================"
echo ""

bash "$SUITE_FILE" > "$RESULT_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "EXECUTED — PASS"
else
  echo "EXECUTED — FAIL (exit code: $EXIT_CODE)"
  echo ""
  tail -20 "$RESULT_FILE" | sed 's/^/  /'
fi

echo ""
echo "Output saved to: $RESULT_FILE"
echo ""

exit $EXIT_CODE
