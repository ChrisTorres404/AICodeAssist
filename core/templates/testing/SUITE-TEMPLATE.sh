#!/usr/bin/env bash
# WO-XXXX: [Title] — behavioural suite. Runs real requests against the running
# service and asserts on the responses. `wo verify <n> --run <this file>` records
# EXECUTED — PASS or FAIL from this script's exit code, so it must exit non-zero
# on any failure. Do not print PASS for anything that did not run.
set -uo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../.." && pwd; })"
HARNESS="$ROOT/{{PIPELINE_ROOT}}/harness"
source "$HARNESS/config/test-config.env"      # API_BASE, ORIGIN, DB_*, AUTH_* (exported values win)
source "$HARNESS/lib/test-helpers.sh"          # assert_http_status, wait_for_server, auth helpers, SQL helpers

BASE="${API_BASE%/}"
pass=0; fail=0
check() { # actual expected label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "  PASS $3"; else fail=$((fail+1)); echo "  FAIL $3 (expected $2, got $1)"; fi
}
code() { curl -s -o /dev/null -w '%{http_code}' -A "$TEST_USER_AGENT" "$@"; }

echo "== WO-XXXX against $BASE"
HEALTH="$(health_url || true)"
wait_for_server "$HEALTH" 10 >/dev/null 2>&1 || { echo "  FAIL service is not up at $BASE"; exit 1; }

# --- checks: one behaviour per line; create what you need and clean it up after ---
check "$(code "$HEALTH")" 200 "health answers 200"
# id="$(curl -s -X POST -H 'content-type: application/json' -d '{"title":"x"}' "$BASE/things" | jq -r .id)"
# check "$(code "$BASE/things/$id")" 200 "GET the record we created"
# curl -s -o /dev/null -X DELETE "$BASE/things/$id"   # clean up

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
