#!/usr/bin/env bash
# Example behavioural suite: an authentication flow, end to end, with real
# tokens. Register, sign in, use the token, refuse a bad one, sign out, and
# confirm the token no longer works. Every assertion is on a value the running
# system produced; the session row is checked in the database when one exists.
#
# Configure with the harness config (API_BASE, DB_*, AUTH_*), or override:
#   AUTH_PREFIX=/auth ME=/me SESSIONS_TABLE=sessions ./auth-flow.sh
set -uo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../../../.." && pwd -P; })"
HARNESS="${HARNESS:-$ROOT/{{PIPELINE_ROOT}}/harness}"
[ -f "$HARNESS/config/test-config.env" ] && source "$HARNESS/config/test-config.env"
[ -f "$HARNESS/lib/test-helpers.sh" ] && source "$HARNESS/lib/test-helpers.sh"

BASE="${API_BASE:-}"; BASE="${BASE%/}"
AUTH_PREFIX="${AUTH_PREFIX:-/auth}"; ME="${ME:-/me}"; SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "  PASS $3"; else fail=$((fail+1)); echo "  FAIL $3 (expected '$2', got '$1')"; fi; }
precondition() { echo "  precondition: $*" >&2; exit 77; }
json() { curl -s -H 'content-type: application/json' "$@"; }
code() { curl -s -o /dev/null -w '%{http_code}' -H 'content-type: application/json' "$@"; }
field() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get(sys.argv[1], ""))' "$2" 2>/dev/null; }

[ -n "$BASE" ] || precondition "API_BASE is not set"
curl -s -o /dev/null --max-time 3 "$BASE/" || precondition "nothing is answering at $BASE"

echo "== auth flow against $BASE$AUTH_PREFIX"
email="suite-$(date +%s)-$$@example.com"; password="example-pass-$$"

# register: a real account, created by this suite, removed by this suite
check "$(code -X POST -d "{\"email\":\"$email\",\"password\":\"$password\"}" "$BASE$AUTH_PREFIX/register")" 201 "register creates the account"

# sign in: the token that comes back is the one asserted on from here
login="$(json -X POST -d "{\"email\":\"$email\",\"password\":\"$password\"}" "$BASE$AUTH_PREFIX/login")"
token="$(field "$login" token)"
check "$([ -n "$token" ] && echo present || echo missing)" present "login returns a token"
check "$(field "$(json -H "authorization: Bearer $token" "$BASE$ME")" email)" "$email" "the token identifies the account that signed in"

# the session exists as a row, not only as a token that happens to work
if db_configured 2>/dev/null; then
  check "$(run_sql "select count(*) from $SESSIONS_TABLE s join users u on u.id = s.user_id where u.email = '$email' and s.revoked_at is null" | tr -d ' ')" 1 "one live session row for the account"
fi

# refusals, with the right status and nothing leaked
check "$(code -X POST -d "{\"email\":\"$email\",\"password\":\"wrong\"}" "$BASE$AUTH_PREFIX/login")" 401 "wrong password is 401"
check "$(code -H 'authorization: Bearer not-a-token' "$BASE$ME")" 401 "a forged token is 401"
check "$(code "$BASE$ME")" 401 "no token is 401"

# sign out: the token stops working, and the row says why
check "$(code -X POST -H "authorization: Bearer $token" "$BASE$AUTH_PREFIX/logout")" 204 "logout"
check "$(code -H "authorization: Bearer $token" "$BASE$ME")" 401 "the token no longer works after logout"
if db_configured 2>/dev/null; then
  check "$(run_sql "select count(*) from $SESSIONS_TABLE s join users u on u.id = s.user_id where u.email = '$email' and s.revoked_at is not null" | tr -d ' ')" 1 "the session row is marked revoked, not deleted"
fi

# clean up what this suite created
if db_configured 2>/dev/null; then run_sql "delete from users where email = '$email'" >/dev/null 2>&1 || true; fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
