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
#   NOT EXECUTED        the suite file is listed but absent, or the run stopped
#
# Nothing is stamped PASS that was not executed. The report is the artefact you
# attach to a work order or bug closeout, so it carries the whole transcript of
# every suite — the request each check made and the response it got — not a
# tail of it. A truncated transcript is not evidence: the check that matters is
# always the one that scrolled off.
#
# Usage:
#   ./run-behavioral-tests.sh [--quick|--standard|--full] [--tier <tier>]
#                             [--type <type>] [--out <dir>] [OPTIONS]
#
#   --quick      essential tier only
#   --standard   essential + core + extended (default)
#   --full       every tier
#   --tier X     one tier only; overrides the mode
#   --type X     only suites of that type; composes with the mode and --tier
#   --out DIR    write the report somewhere other than the results directory
#
# Options, the same vocabulary the canonical runner speaks:
#   --verbose            also stream each suite's output to the terminal
#                        (env VERBOSE=true)
#   --no-prep            skip the health check and the known-state reset
#   --stop-fail          stop after the first failing suite; the rest are
#                        recorded NOT EXECUTED, never as passes
#                        (env STOP_ON_FAIL=true)
#   --show-config        print the loaded configuration first
#                        (env SHOW_CONFIG=true)
#   --include-unlisted   also run the suite files no manifest row names, as a
#                        final "unlisted" tier
#   --list               list the inventory and exit — delegated verbatim to the
#                        canonical runner, so the two can never list differently
#   -h, --help           print this header and exit
#
# The health check is recorded, not fatal. A run that refuses to write anything
# because the service is down leaves a work order with no evidence at all, and
# a static or unit suite needs no service; so the outage goes in the report and
# the suites that need the service fail, or exit 77, on their own terms.
#
# Environment: ACTIVE_ENV, SUITES_DIR, SUITES_MANIFEST, TEST_RESULTS_DIR, and
# anything the suites themselves read from config/test-config.env.
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${TEST_CONFIG:-$SCRIPT_DIR/../config/test-config.env}"
RUNNER="$SCRIPT_DIR/../runners/run-all-critical-tests.sh"

# Suites, manifest and results directory come from one shared resolver, which
# also settles the order: the manifest cannot be resolved before the suites
# directory it sits beside is known.
# shellcheck source=../lib/paths.sh
. "$SCRIPT_DIR/../lib/paths.sh"
MANIFEST="$SUITES_MANIFEST"

FILTER_TIER=""
FILTER_TYPE=""
MODE="standard"
OUTPUT_DIR="$TEST_RESULTS_DIR"
LIST_ONLY=false
SKIP_PREP=false
INCLUDE_UNLISTED=false
case "${VERBOSE:-}" in true|1|yes) VERBOSE=true;; *) VERBOSE=false;; esac
case "${STOP_ON_FAIL:-}" in true|1|yes) STOP_ON_FAIL=true;; *) STOP_ON_FAIL=false;; esac
case "${SHOW_CONFIG:-}" in true|1|yes) SHOW_CONFIG=true;; *) SHOW_CONFIG=false;; esac

# Forwarded verbatim when --list delegates to the canonical runner.
RUNNER_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --quick)     MODE="quick"; RUNNER_ARGS+=("$1"); shift;;
    --standard)  MODE="standard"; RUNNER_ARGS+=("$1"); shift;;
    --full)      MODE="full"; RUNNER_ARGS+=("$1"); shift;;
    --tier) FILTER_TIER="$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"; RUNNER_ARGS+=("$1" "${2:-}"); shift 2;;
    --type) FILTER_TYPE="$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"; RUNNER_ARGS+=("$1" "${2:-}"); shift 2;;
    --out)  OUTPUT_DIR="${2:?--out needs a directory}"; shift 2;;
    --verbose)   VERBOSE=true; shift;;
    --no-prep)   SKIP_PREP=true; shift;;
    --stop-fail) STOP_ON_FAIL=true; shift;;
    --show-config) SHOW_CONFIG=true; shift;;
    --include-unlisted) INCLUDE_UNLISTED=true; RUNNER_ARGS+=("$1"); shift;;
    --list)      LIST_ONLY=true; shift;;
    -h|--help) awk 'NR>1 && /^#/ {sub(/^#[ ]?/,""); print; next} NR>1 {exit}' "$0"; exit 0;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
export VERBOSE STOP_ON_FAIL SHOW_CONFIG

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# health_url, db_configured, recover_db_pool, reset_test_environment and
# prepare_test_environment — the same implementations the canonical runner uses.
# shellcheck source=../lib/test-env.sh
. "$SCRIPT_DIR/../lib/test-env.sh"

# --list is the canonical runner's answer, verbatim: two scripts over one
# manifest must not have two ideas of what is in it.
if [ "$LIST_ONLY" = true ]; then
  exec bash "$RUNNER" --list ${RUNNER_ARGS[@]+"${RUNNER_ARGS[@]}"}
fi

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

# A suite colours its output for a terminal. The report is not a terminal, and
# the escape codes both make it unreadable and hide the word the check counter
# is looking for — "STATUS: PASS" ends with a reset sequence, not with PASS.
# Strip them once, with a literal escape character rather than \x1b, which only
# GNU sed understands.
ESC="$(printf '\033')"
strip_ansi() { sed "s/${ESC}\[[0-9;]*m//g"; }

TOTAL=0
PASSED=0
FAILED=0
NOT_EXECUTED=0
CHECKS_PASSED=0
CHECKS_FAILED=0
STOPPED=false

echo "Behavioral test run — $(date '+%Y-%m-%d %H:%M:%S')"
echo "Suites: $SUITES_DIR"
echo ""

if [ ! -f "$MANIFEST" ]; then
  echo "No suite manifest at $MANIFEST — add tier|type|file|label lines." >&2
  exit 2
fi

# ----------------------------------------------------------------------------
# Preparation — recorded in the report, whichever way it goes
# ----------------------------------------------------------------------------
PREP_NOTE="skipped (--no-prep)"
if [ "$SKIP_PREP" = false ]; then
  PREP_OUTPUT="$(prepare_test_environment 2>&1)"
  PREP_RC=$?
  echo "$PREP_OUTPUT"
  if [ "$PREP_RC" -eq 0 ]; then
    PREP_NOTE="health check passed; known state applied"
  else
    PREP_NOTE="SERVICE NOT ANSWERING — suites needing it will fail or report a precondition"
    echo -e "${YELLOW}$PREP_NOTE${NC}" >&2
  fi
  echo ""
else
  PREP_OUTPUT="environment preparation skipped (--no-prep)"
fi

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
  [ "$INCLUDE_UNLISTED" = true ] && echo "**Unlisted suites:** included  "
  [ "$STOP_ON_FAIL" = true ] && echo "**Stop on failure:** yes  "
  echo "**Preparation:** $PREP_NOTE  "
  echo ""
  echo "<details><summary>Preparation output</summary>"
  echo ""
  echo '```'
  echo "$PREP_OUTPUT"
  echo '```'
  echo ""
  echo "</details>"
  echo ""
  echo "---"
  echo ""
  echo "## Suite Execution"
} > "$REPORT_FILE"

if [ "$SHOW_CONFIG" = true ]; then
  echo "API:   ${API_BASE:-unset}"
  echo "Env:   ${ACTIVE_ENV:-LOCAL_DEV} (${ENV_LABEL:-unlabelled})"
  echo "DB:    ${DB_USER:-}@${DB_HOST:-}:${DB_PORT:-}/${DB_NAME:-none}"
  echo "Tiers: $MODE_TIERS"
  echo ""
fi

# ----------------------------------------------------------------------------
# One suite: run it, and write down everything it did
# ----------------------------------------------------------------------------
# The per-check evidence is the suite's own output, complete. A suite written
# to the methodology prints, for each check, the request it made and the
# response it got; keeping all of it is what makes the report reproducible by
# someone who was not there.
record_suite() {
  local tier="$1" type="$2" file="$3" label="$4"
  local path="$SUITES_DIR/$file"
  local start elapsed rc output status checks pass_n fail_n

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
    return 0
  fi

  chmod +x "$path" 2>/dev/null || true
  start=$(date +%s)
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- $label ---"
    output="$(bash "$path" 2>&1 | tee /dev/stderr)"
    rc=${PIPESTATUS[0]}
  else
    output="$(bash "$path" 2>&1)"
    rc=$?
  fi
  elapsed=$(( $(date +%s) - start ))
  output="$(printf '%s\n' "$output" | strip_ansi)"

  if [ "$rc" -eq 0 ]; then
    status="EXECUTED — PASS"
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}PASS${NC} $label ${DIM}(${elapsed}s)${NC}"
  else
    status="EXECUTED — FAIL"
    FAILED=$((FAILED + 1))
    echo -e "${RED}FAIL${NC} $label ${DIM}(exit $rc, ${elapsed}s)${NC}"
  fi

  # The individual checks the suite reported, pulled out of its transcript so
  # a reader sees which behaviour failed without reading the whole log. Both
  # shapes the harness prints are recognised — "  PASS <label>" and the
  # "RESULT: <label>" / "STATUS: PASS" pair — and the descriptions are kept,
  # because a list of bare verdicts says nothing about what was checked.
  checks="$(printf '%s\n' "$output" | grep -E 'RESULT:|^[[:space:]]*(STATUS:[[:space:]]*)?(PASS|FAIL|SKIP)([[:space:]]|$)' || true)"
  # Counted from the verdict lines alone: a description is free text and may
  # well contain the word "fail".
  pass_n="$(printf '%s\n' "$output" | grep -cE '^[[:space:]]*(STATUS:[[:space:]]*)?PASS([[:space:]]|$)' || true)"
  fail_n="$(printf '%s\n' "$output" | grep -cE '^[[:space:]]*(STATUS:[[:space:]]*)?FAIL([[:space:]]|$)' || true)"
  pass_n="$(printf '%s' "${pass_n:-0}" | tr -d '[:space:]')"
  fail_n="$(printf '%s' "${fail_n:-0}" | tr -d '[:space:]')"
  CHECKS_PASSED=$((CHECKS_PASSED + pass_n))
  CHECKS_FAILED=$((CHECKS_FAILED + fail_n))

  {
    echo ""
    echo "### $label"
    echo ""
    echo "**Tier:** $tier  "
    echo "**Type:** ${type:-untyped}  "
    echo "**Suite:** \`$file\`  "
    echo "**Status:** $status  "
    echo "**Exit code:** $rc  "
    echo "**Duration:** ${elapsed}s  "
    echo "**Checks reported:** $pass_n passed, $fail_n failed"
    echo ""
    echo "**Command:**"
    echo ""
    echo '```bash'
    echo "bash $path"
    echo '```'
    echo ""
    if [ -n "$checks" ]; then
      echo "**Checks:**"
      echo ""
      echo '```'
      printf '%s\n' "$checks"
      echo '```'
      echo ""
    fi
    echo "**Transcript (complete):**"
    echo ""
    echo '```'
    printf '%s\n' "$output"
    echo '```'
    echo ""
    echo "---"
  } >> "$REPORT_FILE"

  if [ "$rc" -ne 0 ] && [ "$STOP_ON_FAIL" = true ]; then
    STOPPED=true
    return 1
  fi
  return 0
}

# A suite listed but never reached, because the run stopped at a failure. It is
# not a pass and it is not a failure: it is a suite nobody has an answer for.
record_not_reached() {
  local tier="$1" type="$2" file="$3" label="$4"
  TOTAL=$((TOTAL + 1))
  NOT_EXECUTED=$((NOT_EXECUTED + 1))
  {
    echo ""
    echo "### $label"
    echo ""
    echo "**Tier:** $tier  "
    echo "**Type:** ${type:-untyped}  "
    echo "**Suite:** \`$file\`  "
    echo "**Status:** NOT EXECUTED — the run stopped at an earlier failure (--stop-fail)"
    echo ""
    echo "---"
  } >> "$REPORT_FILE"
}

# ----------------------------------------------------------------------------
# The manifest, in order
# ----------------------------------------------------------------------------
PREV_TIER=""

while IFS= read -r line || [ -n "$line" ]; do
  parse_manifest_line "$line" || continue
  tier="$MF_TIER"; type="$MF_TYPE"; file="$MF_FILE"; label="$MF_LABEL"
  tier_selected "$tier" || continue
  # An untyped manifest row is never selected by --type: nothing says what
  # kind of test it is.
  [ -n "$FILTER_TYPE" ] && [ "$type" != "$FILTER_TYPE" ] && continue

  if [ "$STOPPED" = true ]; then
    record_not_reached "$tier" "$type" "$file" "$label"
    continue
  fi

  # Between tiers, put the system back into the state the next tier expects:
  # the suites that just ran are what built the state that would otherwise
  # fail the next ones. Inert unless the project configured a reset.
  if [ -n "$PREV_TIER" ] && [ "$tier" != "$PREV_TIER" ] && [ "$SKIP_PREP" = false ]; then
    recover_db_pool
    reset_test_environment
  fi
  PREV_TIER="$tier"

  record_suite "$tier" "$type" "$file" "$label" || true
done < "$MANIFEST"

# ----------------------------------------------------------------------------
# The suite files no manifest row names, when asked for
# ----------------------------------------------------------------------------
if [ "$INCLUDE_UNLISTED" = true ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    if [ "$STOPPED" = true ]; then
      record_not_reached "unlisted" "" "$rel" "$rel"
      continue
    fi
    record_suite "unlisted" "" "$rel" "$rel" || true
  done <<EOF
$(unlisted_suite_files "$MANIFEST")
EOF
fi

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
  echo "| Checks passed | $CHECKS_PASSED |"
  echo "| Checks failed | $CHECKS_FAILED |"
  echo "| Passing share of listed | ${COVERAGE_PCT}% |"
  echo ""
  echo "**Verdict:** $VERDICT"
  echo ""
  echo "_Generated $(date '+%Y-%m-%d %H:%M:%S %Z')_"
} >> "$REPORT_FILE"

{
  echo "Behavioral tests: ${COVERAGE_PCT}% of listed suites passing"
  echo "Listed: $TOTAL | Executed: $EXECUTED | Passed: $PASSED | Failed: $FAILED | Not executed: $NOT_EXECUTED"
  echo "Checks: $CHECKS_PASSED passed, $CHECKS_FAILED failed"
  echo "Verdict: $VERDICT"
} > "$SUMMARY_FILE"

echo ""
echo "Listed:       $TOTAL"
echo "Executed:     $EXECUTED"
echo "Passed:       $PASSED"
echo "Failed:       $FAILED"
echo "Not executed: $NOT_EXECUTED"
echo "Checks:       $CHECKS_PASSED passed, $CHECKS_FAILED failed"
echo ""
echo "Report:  $REPORT_FILE"
echo "Summary: $SUMMARY_FILE"
echo ""

[ "$FAILED" -gt 0 ] && exit 1
exit 0
