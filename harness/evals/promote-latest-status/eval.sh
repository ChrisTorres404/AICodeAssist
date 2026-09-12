#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
W=./.aicodepipeline/bin/wo; B=./.aicodepipeline/bin/bug
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; printf '#!/usr/bin/env bash\nexit 1\n' > bad.sh
b="$($B new "Plan only" --category api | grep -o 'BUG-[0-9]*' | head -1)"; b="${b#BUG-}"
$B verify "$b" >/dev/null
rc=0; $B promote "$b" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "plan-only bug was promoted"; exit 1; }
n="$($W new "Pass then fail" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
$W verify "$n" --run ./ok.sh >/dev/null; $W verify "$n" --run ./bad.sh >/dev/null 2>&1 || true
rc=0; $W promote "$n" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "work order promoted after PASS then FAIL"; exit 1; }
rc=0; $W close "$n" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "work order closed after PASS then FAIL"; exit 1; }
$B verify "$b" --run ./ok.sh >/dev/null; $B verify "$b" --run ./bad.sh >/dev/null 2>&1 || true
rc=0; $B promote "$b" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "bug promoted after PASS then FAIL"; exit 1; }
$W verify "$n" --run ./ok.sh >/dev/null; $W close "$n" >/dev/null || { echo "close refused after a fresh PASS"; exit 1; }
exit 0
