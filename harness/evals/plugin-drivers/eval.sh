#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
"$PIPELINE_ROOT/bin/build-plugin" >/dev/null 2>&1 || { echo "build-plugin failed"; exit 1; }
P="$PIPELINE_ROOT/dist/plugin"
cd "$EVAL_TMP"; mkdir p && cd p && git init -q && git -c user.email=e@x -c user.name=e commit -q --allow-empty -m init
W="$P/bin/wo"; B="$P/bin/bug"
n="$($W new "Plugin consumer feature" --size small --area backend 2>&1 | grep -o 'WO-[0-9]*' | head -1)" || true
[ -n "$n" ] || { echo "packaged wo new failed:"; $W new "Plugin consumer feature" --size small 2>&1 | tail -3; exit 1; }
n="${n#WO-}"; printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh
$W verify "$n" --run ./ok.sh >/dev/null || { echo "packaged wo verify --run failed"; exit 1; }
fill_wo "$n"; $W close "$n" >/dev/null || { echo "packaged wo close failed"; exit 1; }
b="$($B new "Plugin bug" --category api 2>&1 | grep -o 'BUG-[0-9]*' | head -1)"; [ -n "$b" ] || { echo "packaged bug new failed"; exit 1; }
$B verify "${b#BUG-}" --run ./ok.sh >/dev/null || { echo "packaged bug verify failed"; exit 1; }
fill_bug "${b#BUG-}"; $B close "${b#BUG-}" >/dev/null || { echo "packaged bug close failed"; exit 1; }
exit 0
