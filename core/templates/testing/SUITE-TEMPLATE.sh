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
# Self-starting: a suite must run for anyone, not only for whoever wrote it.
# If the service is not already up, start it with SUITE_START_CMD (default: the
# project's run command) and stop it on exit. Fixtures the suite needs are
# created by the suite itself, never passed in through the environment.
HOST="$(printf '%s' "$API_BASE" | sed -E 's|^(https?://[^/]+).*|\1|')"
STARTED=""
if ! curl -s -o /dev/null --max-time 2 "$HOST/"; then
  START="${SUITE_START_CMD:-}"
  [ -z "$START" ] && [ -f "$ROOT/package.json" ] && START="npm start"
  [ -n "$START" ] || { echo "  FAIL nothing is listening at $HOST and SUITE_START_CMD is not set"; exit 1; }
  set -m                                   # own process group, so the whole service tree can be stopped
  ( cd "$ROOT" && eval "$START" ) >"/tmp/suite-service.$$.log" 2>&1 &
  STARTED=$!
  set +m
  stop_service() { [ -n "${STARTED:-}" ] || return 0; kill -- -"$STARTED" 2>/dev/null || kill "$STARTED" 2>/dev/null; wait "$STARTED" 2>/dev/null; }
  trap 'stop_service' EXIT INT TERM
  for _ in $(seq 1 20); do curl -s -o /dev/null --max-time 1 "$HOST/" && break; sleep 0.5; done
fi
HEALTH="$(health_url || true)"          # resolved now that the service answers
[ "$(code "$HEALTH")" = 200 ] || { echo "  FAIL no healthy endpoint (tried $HEALTH)"; [ -n "$STARTED" ] && tail -5 "/tmp/suite-service.$$.log"; exit 1; }

# --- checks: one behaviour per line; create what you need and clean it up after ---
check "$(code "$HEALTH")" 200 "health answers 200"
# id="$(curl -s -X POST -H 'content-type: application/json' -d '{"title":"x"}' "$BASE/things" | jq -r .id)"
# check "$(code "$BASE/things/$id")" 200 "GET the record we created"
# curl -s -o /dev/null -X DELETE "$BASE/things/$id"   # clean up

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
