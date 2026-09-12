#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
git init -q >/dev/null 2>&1 || true; mkdir -p src; echo "v1" > src/app.txt; git add -A >/dev/null 2>&1; git -c user.email=e@x -c user.name=e commit -q -m init >/dev/null 2>&1 || true
W=./.aicodepipeline/bin/wo; printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh
n="$($W new "Freshness" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
$W verify "$n" --run ./ok.sh >/dev/null
echo "v2" > src/app.txt
rc=0; $W close "$n" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "closed although the source changed after the PASS"; exit 1; }
$W verify "$n" --run ./ok.sh >/dev/null; $W close "$n" >/dev/null || { echo "close refused after re-running on the current tree"; exit 1; }
exit 0
