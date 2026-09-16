#!/usr/bin/env bash
# Example behavioural suite: create, read, update, delete — against the running
# service, asserting on the actual response values and then on the actual row.
#
# This is the shape every behavioural suite has. Nothing is mocked. Every check
# is a real request or a real query, and the thing asserted is the value that
# came back, compared with the value that was sent. A test that asserts a call
# "succeeded" without reading what it returned is not behavioural.
#
# Configure with the harness config (API_BASE, DB_*), or override:
#   RESOURCE=/things TABLE=things ./crud-with-state-verification.sh
set -uo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../../../.." && pwd -P; })"
HARNESS="${HARNESS:-$ROOT/{{PIPELINE_ROOT}}/harness}"
[ -f "$HARNESS/config/test-config.env" ] && source "$HARNESS/config/test-config.env"
[ -f "$HARNESS/lib/test-helpers.sh" ] && source "$HARNESS/lib/test-helpers.sh"

BASE="${API_BASE:-}"; BASE="${BASE%/}"
RESOURCE="${RESOURCE:-/things}"          # the collection endpoint under test
TABLE="${TABLE:-things}"                 # the table the endpoint writes to
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "  PASS $3"; else fail=$((fail+1)); echo "  FAIL $3 (expected '$2', got '$1')"; fi; }
precondition() { echo "  precondition: $*" >&2; exit 77; }
json() { curl -s -H 'content-type: application/json' "$@"; }
code() { curl -s -o /dev/null -w '%{http_code}' -H 'content-type: application/json' "$@"; }
field() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get(sys.argv[1], ""))' "$2" 2>/dev/null; }

# --- preconditions: exit 77 when they are not met; nothing below means anything without them ---
[ -n "$BASE" ] || precondition "API_BASE is not set"
curl -s -o /dev/null --max-time 3 "$BASE/" || precondition "nothing is answering at $BASE"

echo "== CRUD with state verification against $BASE$RESOURCE"
title="suite-$(date +%s)-$$"

# create: assert on the values that came back, not on the fact of a response
created="$(json -X POST -d "{\"title\":\"$title\"}" "$BASE$RESOURCE")"
id="$(field "$created" id)"
check "$([ -n "$id" ] && echo present || echo missing)" present "create returns an id"
check "$(field "$created" title)" "$title" "create echoes the title that was sent"

# the row exists with those values, verified in the database, not inferred from the API
if db_configured 2>/dev/null; then
  check "$(run_sql "select count(*) from $TABLE where id = '$id' and title = '$title'" | tr -d ' ')" 1 "the row is in $TABLE with the sent title"
else
  echo "  SKIP database not configured; state verified through the API only"
fi

# read: the same values come back
check "$(code "$BASE$RESOURCE/$id")" 200 "GET the record"
check "$(field "$(json "$BASE$RESOURCE/$id")" title)" "$title" "GET returns the stored title"

# update: the new value is stored, and the untouched fields are untouched
updated="$(json -X PATCH -d '{"title":"'"$title"'-renamed"}' "$BASE$RESOURCE/$id")"
check "$(field "$updated" title)" "$title-renamed" "PATCH returns the new title"
check "$(field "$updated" id)" "$id" "PATCH keeps the id"
if db_configured 2>/dev/null; then
  check "$(run_sql "select title from $TABLE where id = '$id'" | tr -d ' ')" "$title-renamed" "the row carries the new title"
fi

# a request that must be refused, refused with the right status and no side effect
check "$(code -X POST -d '{}' "$BASE$RESOURCE")" 400 "POST without a title is refused with 400"

# delete: gone from the API and gone from the table
check "$(code -X DELETE "$BASE$RESOURCE/$id")" 204 "DELETE the record"
check "$(code "$BASE$RESOURCE/$id")" 404 "GET after delete is 404"
if db_configured 2>/dev/null; then
  check "$(run_sql "select count(*) from $TABLE where id = '$id'" | tr -d ' ')" 0 "the row is gone from $TABLE"
fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
