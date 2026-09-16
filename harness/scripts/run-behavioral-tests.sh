#!/usr/bin/env bash
# ============================================================================
# Behavioral test run → markdown evidence report
# ============================================================================
# The manifest-driven run whose output is a document rather than a terminal
# report. Same suites, same manifest and the same flags as the canonical runner
# (../runners/run-all-critical-tests.sh); what differs is the artefact: a dated
# markdown file in which every suite is stamped with what actually happened:
#
#   EXECUTED — PASS     the suite ran and exited 0
#   EXECUTED — FAIL     the suite ran and exited non-zero (output included)
#   NOT EXECUTED        the suite file is listed but absent
#
# Nothing is stamped PASS that was not executed. The report is the artefact you
# attach to a work order or bug closeout.
#
# Usage:
#   ./run-behavioral-tests.sh [--quick|--standard|--full] [--tier <tier>]
#                             [--type <type>] [--out <dir>]
#
#   --quick      essential tier only
#   --standard   essential + core + extended (default)
#   --full       every tier
#   --tier X     one tier only; overrides the mode
#   --type X     only suites of that type; composes with the mode and --tier
#   --out DIR    write the report somewhere other than the results directory
#
# Environment: ACTIVE_ENV, SUITES_DIR, SUITES_MANIFEST, TEST_RESULTS_DIR, and
# anything the suites themselves read from config/test-config.env.
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"

# Suites, manifest and results directory come from one shared resolver, which
# also settles the order: the manifest cannot be resolved before the suites
# directory it sits beside is known.
# shellcheck source=../lib/paths.sh
. "$SCRIPT_DIR/../lib/paths.sh"
MANIFEST="$SUITES_MANIFEST"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

FILTER_TIER=""
FILTER_TYPE=""
MODE="standard"
OUTPUT_DIR="$TEST_RESULTS_DIR"

while [ $# -gt 0 ]; do
  case "$1" in
    --quick)     MODE="quick"; shift;;
    --standard)  MODE="standard"; shift;;
    --full)      MODE="full"; shift;;
    --tier) FILTER_TIER="$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"; shift 2;;
    --type) FILTER_TYPE="$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"; shift 2;;
    --out)  OUTPUT_DIR="${2:?--out needs a directory}"; shift 2;;
    -h|--help) sed -n '2,30p' "$0"; exit 0;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done

# Which tiers a mode covers. --tier overrides it with a single tier.
case "$MODE" in
  quick)    MODE_TIERS="essential";;
  full)     MODE_TIERS="essential core extended security integration performance infrastructure recent";;
  *)        MODE_TIERS="essential core extended";;
esac
[ -n "$FILTER_TIER" ] && MODE_TIERS="$FILTER_TIER"

tier_selected() {
  local want="$1" t
  for t in $MODE_TIERS; do [ "$t" = "$want" ] && return 0; done
  return 1
}

mkdir -p "$OUTPUT_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$OUTPUT_DIR/behavioral-test-report_$TIMESTAMP.md"
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
NOT_EXECUTED=0

{
  echo "# Behavioral Test Report"
  echo ""
  echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S %Z')  "
  echo "**Environment:** ${ACTIVE_ENV:-LOCAL_DEV} (${ENV_LABEL:-unlabelled})  "
  echo "**API:** ${API_BASE:-unset}  "
  [ -n "${DB_NAME:-}" ] && echo "**Database:** ${DB_USER:-}@${DB_HOST:-}:${DB_PORT:-}/${DB_NAME}  "
  echo "**Manifest:** $(basename "$MANIFEST")  "
  echo "**Mode:** $MODE (tiers: $MODE_TIERS)  "
  [ -n "$FILTER_TYPE" ] && echo "**Type filter:** $FILTER_TYPE  "
  echo ""
  echo "---"
  echo ""
  echo "## Suite Execution"
} > "$REPORT_FILE"

echo "Behavioral test run — $(date '+%Y-%m-%d %H:%M:%S')"
echo "Suites: $SUITES_DIR"
echo ""

if [ ! -f "$MANIFEST" ]; then
  echo "No suite manifest at $MANIFEST — add tier|type|file|label lines." >&2
  exit 2
fi

while IFS= read -r line || [ -n "$line" ]; do
  parse_manifest_line "$line" || continue
  tier="$MF_TIER"; type="$MF_TYPE"; file="$MF_FILE"; label="$MF_LABEL"
  tier_selected "$tier" || continue
  # An untyped manifest row is never selected by --type: nothing says what
  # kind of test it is.
  [ -n "$FILTER_TYPE" ] && [ "$type" != "$FILTER_TYPE" ] && continue

  path="$SUITES_DIR/$file"
  TOTAL=$((TOTAL + 1))

  if [ ! -f "$path" ]; then
    NOT_EXECUTED=$((NOT_EXECUTED + 1))
    echo -e "${YELLOW}NOT EXECUTED${NC} $label ${DIM}(missing $file)${NC}"
    {
      echo ""
      echo "### $label"
      echo ""
      echo "**Tier:** $tier  "
      echo "**Type:** ${type:-untyped}  "
      echo "**Suite:** \`$file\`  "
      echo "**Status:** NOT EXECUTED — suite file not found"
      echo ""
      echo "---"
    } >> "$REPORT_FILE"
    continue
  fi

  chmod +x "$path" 2>/dev/null || true
  start=$(date +%s)
  output="$(bash "$path" 2>&1)"
  rc=$?
  elapsed=$(( $(date +%s) - start ))

  if [ "$rc" -eq 0 ]; then
    status="EXECUTED — PASS"
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}PASS${NC} $label ${DIM}(${elapsed}s)${NC}"
  else
    status="EXECUTED — FAIL"
    FAILED=$((FAILED + 1))
    echo -e "${RED}FAIL${NC} $label ${DIM}(exit $rc, ${elapsed}s)${NC}"
  fi

  {
    echo ""
    echo "### $label"
    echo ""
    echo "**Tier:** $tier  "
    echo "**Type:** ${type:-untyped}  "
    echo "**Suite:** \`$file\`  "
    echo "**Status:** $status  "
    echo "**Exit code:** $rc  "
    echo "**Duration:** ${elapsed}s"
    echo ""
    echo "**Command:**"
    echo ""
    echo '```bash'
    echo "$path"
    echo '```'
    echo ""
    echo "**Output (last 60 lines):**"
    echo ""
    echo '```'
    echo "$output" | tail -60
    echo '```'
    echo ""
    echo "---"
  } >> "$REPORT_FILE"
done < "$MANIFEST"

EXECUTED=$((PASSED + FAILED))
if [ "$TOTAL" -gt 0 ]; then
  COVERAGE_PCT=$((PASSED * 100 / TOTAL))
else
  COVERAGE_PCT=0
fi

if [ "$FAILED" -eq 0 ] && [ "$EXECUTED" -gt 0 ] && [ "$NOT_EXECUTED" -eq 0 ]; then
  VERDICT="ALL SUITES PASSED"
elif [ "$EXECUTED" -eq 0 ]; then
  VERDICT="NOTHING EXECUTED"
elif [ "$FAILED" -eq 0 ]; then
  VERDICT="PASSED, $NOT_EXECUTED NOT EXECUTED"
else
  VERDICT="$FAILED SUITE(S) FAILED"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Suites listed | $TOTAL |"
  echo "| Executed | $EXECUTED |"
  echo "| Passed | $PASSED |"
  echo "| Failed | $FAILED |"
  echo "| Not executed | $NOT_EXECUTED |"
  echo "| Passing share of listed | ${COVERAGE_PCT}% |"
  echo ""
  echo "**Verdict:** $VERDICT"
  echo ""
  echo "_Generated $(date '+%Y-%m-%d %H:%M:%S %Z')_"
} >> "$REPORT_FILE"

{
  echo "Behavioral tests: ${COVERAGE_PCT}% of listed suites passing"
  echo "Listed: $TOTAL | Executed: $EXECUTED | Passed: $PASSED | Failed: $FAILED | Not executed: $NOT_EXECUTED"
  echo "Verdict: $VERDICT"
} > "$SUMMARY_FILE"

echo ""
echo "Listed:       $TOTAL"
echo "Executed:     $EXECUTED"
echo "Passed:       $PASSED"
echo "Failed:       $FAILED"
echo "Not executed: $NOT_EXECUTED"
echo ""
echo "Report:  $REPORT_FILE"
echo "Summary: $SUMMARY_FILE"
echo ""

[ "$FAILED" -gt 0 ] && exit 1
exit 0
