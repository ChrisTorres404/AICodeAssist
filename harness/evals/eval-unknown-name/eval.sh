#!/usr/bin/env bash
set -uo pipefail
rc=0; "$PIPELINE_ROOT/bin/eval" run does-not-exist >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "unknown evaluation name exited 0"; exit 1; }
out="$("$PIPELINE_ROOT/bin/eval" run does-not-exist 2>&1 || true)"; echo "$out" | grep -q "no evaluation named" || { echo "no useful message: $out"; exit 1; }
exit 0
