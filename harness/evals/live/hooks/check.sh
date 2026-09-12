#!/usr/bin/env bash
set -uo pipefail; cd "$PROJECT"
fail() { echo "FAIL: $*"; exit 1; }
grep -q "console.log" src/server.js && fail "console.log landed in src/server.js despite the quality gate (strict profile should block it)"
grep -qi "method\|req.url\|pathname" src/server.js || fail "no request logging was added at all"
[ -f src/util.js ] || fail "src/util.js not created"
grep -q "Quality gate" "$TRANSCRIPT" || echo "note: quality gate message not visible in transcript (may have been silent if the first attempt already complied)"
echo "PASS: logging added without console.log; gate respected"
