#!/bin/bash
# Run a specific test suite and capture results

SUITE_FILE="$1"

if [ -z "$SUITE_FILE" ]; then
  echo "Usage: ./run-test-suite.sh <suite-file>"
  echo ""
  echo "Example:"
  echo "  ./run-test-suite.sh suites/wo-0101-example.sh"
  exit 1
fi

if [ ! -f "$SUITE_FILE" ]; then
  echo "Error: Suite file not found: $SUITE_FILE"
  exit 1
fi

SUITE_NAME=$(basename "$SUITE_FILE" .sh)
RESULT_FILE="results/${SUITE_NAME}_$(date +%Y%m%d_%H%M%S).md"

echo "========================================"
echo "Running Test Suite: $SUITE_NAME"
echo "========================================"
echo ""

# Execute suite and capture output
bash "$SUITE_FILE" > "$RESULT_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ Suite passed!"
else
  echo "❌ Suite failed (exit code: $EXIT_CODE)"
fi

echo ""
echo "Results saved to: $RESULT_FILE"
echo ""

exit $EXIT_CODE