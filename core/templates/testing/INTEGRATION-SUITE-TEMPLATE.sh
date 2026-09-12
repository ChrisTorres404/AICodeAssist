#!/usr/bin/env bash
# WO-XXXX: [Title] — integration suite.
#
# Parallel work orders each verify their own module in isolation, so each one
# can pass while the modules do not compose: a record created through one is
# missing from another's output. This suite is what catches that. It runs
# every covered suite first, then walks one entity across every module.
#
# `wo verify <n> --run <this file>` records the result from this script's exit
# code, so it must exit non-zero when any part fails.
set -uo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../.." && pwd; })"
HARNESS="$ROOT/{{PIPELINE_ROOT}}/harness"
source "$HARNESS/config/test-config.env"
source "$HARNESS/lib/test-helpers.sh"

BASE="${API_BASE%/}"
pass=0; fail=0
code() { curl -s -o /dev/null -w '%{http_code}' -A "$TEST_USER_AGENT" "$@"; }
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "  PASS $3"; else fail=$((fail+1)); echo "  FAIL $3 (expected $2, got $1)"; fi; }
contains() { # haystack needle label — the composition assertion: what one module wrote, another must surface
  case "$1" in *"$2"*) pass=$((pass+1)); echo "  PASS $3";; *) fail=$((fail+1)); echo "  FAIL $3 (did not find '$2')";; esac; }

# --- start the service once for every suite below --------------------------
HOST="$(printf '%s' "$API_BASE" | sed -E 's|^(https?://[^/]+).*|\1|')"
STARTED=""
if ! curl -s -o /dev/null --max-time 2 "$HOST/"; then
  START="${SUITE_START_CMD:-}"
  [ -z "$START" ] && [ -f "$ROOT/package.json" ] && START="npm start"
  [ -n "$START" ] || { echo "  FAIL nothing is listening at $HOST and SUITE_START_CMD is not set"; exit 1; }
  set -m
  ( cd "$ROOT" && eval "$START" ) >"/tmp/integration-service.$$.log" 2>&1 &
  STARTED=$!
  set +m
  stop_service() { [ -n "${STARTED:-}" ] || return 0; kill -- -"$STARTED" 2>/dev/null || kill "$STARTED" 2>/dev/null; wait "$STARTED" 2>/dev/null; }
  trap 'stop_service' EXIT INT TERM
  for _ in $(seq 1 20); do curl -s -o /dev/null --max-time 1 "$HOST/" && break; sleep 0.5; done
fi
HEALTH="$(health_url || true)"
[ "$(code "$HEALTH")" = 200 ] || { echo "  FAIL no healthy endpoint (tried $HEALTH)"; exit 1; }

# --- 1. every covered work order's own suite still passes -------------------
# COVERED_SUITES is filled in by `wo integrate`; add or remove as the batch changes.
COVERED_SUITES="{{COVERED_SUITES}}"
echo "== covered suites"
for s in $COVERED_SUITES; do
  f="$ROOT/{{TESTING_DIR}}/suites/$s"
  [ -f "$f" ] || { echo "  FAIL $s is listed but does not exist"; fail=$((fail+1)); continue; }
  if API_BASE="$API_BASE" bash "$f" >"/tmp/covered.$$.log" 2>&1; then pass=$((pass+1)); echo "  PASS $s"
  else fail=$((fail+1)); echo "  FAIL $s"; sed 's/^/        /' "/tmp/covered.$$.log" | tail -6; fi
done

# --- 2. composition: one entity walked across every module ------------------
# Each module passing alone proves nothing about the whole. Create a record in
# one module and assert that every other module surfaces it.
echo "== composition"
# id="$(curl -s -X POST -H 'content-type: application/json' -d '{"name":"Integration"}' "$BASE/things" | jq -r .id)"
# [ -n "$id" ] && [ "$id" != null ] || { echo "  FAIL could not create the fixture"; fail=$((fail+1)); }
# curl -s -X POST -H 'content-type: application/json' -d '{"note":"from module A"}' "$BASE/things/$id/notes" >/dev/null
# contains "$(curl -s "$BASE/things/$id/summary")"  "from module A"  "module B's summary includes what module A wrote"
# contains "$(curl -s "$BASE/things/$id/export.md")" "from module A"  "module C's export includes what module A wrote"
# curl -s -o /dev/null -X DELETE "$BASE/things/$id"

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
