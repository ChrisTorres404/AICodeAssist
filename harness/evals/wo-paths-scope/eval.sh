#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo
mkdir -p packages/api packages/web; echo a > packages/api/a.txt; echo w > packages/web/w.txt
git add -A >/dev/null 2>&1; git -c user.email=e@x -c user.name=e commit -q -m base >/dev/null 2>&1
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; chmod +x ok.sh

n="$($W new "Scoped" --size small --area docs --paths packages/api | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
d="$(ls -d Workspace/Docs/WorkOrders/WO-"$n"-*)"
grep -q '^paths=packages/api' "$d/.wo-meta" || { echo "the declared scope was not recorded"; exit 1; }
grep -q 'packages/web' "$d/.wo-manifest" && { echo "the manifest includes files outside the declared scope"; exit 1; }

$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
# someone else's change, outside the scope: evidence still stands
echo w2 > packages/web/w.txt
out="$($W close "$n" 2>&1)"; rc=$?
case "$out" in *"source changed after the last PASS"*) echo "a change outside the declared scope invalidated the evidence"; exit 1;; esac
[ "$rc" -eq 0 ] || { echo "close failed for another reason:"; echo "$out"; exit 1; }
rm -f "$d/WO-$n-CLOSEOUT.md"

# a change inside the scope: evidence is stale, as it should be
echo a2 > packages/api/a.txt
out="$($W close "$n" 2>&1)"; case "$out" in *"source changed after the last PASS"*) ;; *) echo "a change inside the declared scope was not caught:"; echo "$out"; exit 1;; esac

# and the close-time checks look only inside the scope
echo 'const k = "AKIA'ABCDEFGHIJKLMNOP'";' > packages/web/leak.ts     # outside
$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
$W close "$n" >/dev/null 2>&1 || { echo "a credential outside the declared scope blocked the close"; $W close "$n"; exit 1; }
exit 0
