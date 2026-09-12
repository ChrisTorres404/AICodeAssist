#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
W=./.aicodepipeline/bin/wo
n="$($W new "Started work" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; $W start "${n#WO-}" >/dev/null; $W note "${n#WO-}" "continue from step 3" >/dev/null
out="$(bash .aicodepipeline/core/hooks/session-orient.sh </dev/null 2>&1)"
echo "$out" | grep -q "$n" || { echo "orientation omitted the in-progress work order:"; echo "$out"; exit 1; }
m="$($W new "Blocked work" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; $W block "${m#WO-}" "waiting on API key" >/dev/null
out="$(bash .aicodepipeline/core/hooks/session-orient.sh </dev/null 2>&1)"; echo "$out" | grep -q "$m" || { echo "orientation omitted the blocked work order:"; echo "$out"; exit 1; }
exit 0
