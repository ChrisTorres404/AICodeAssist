#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git config user.email e@x; git config user.name e
W=./.aicodepipeline/bin/wo

# 1. the fingerprint is the same untracked, staged, and committed
mkdir -p src; echo hello > src/a.txt
f0="$($W fingerprint)"; git add src/a.txt; f1="$($W fingerprint)"; git commit -q -m "chore: add a" >/dev/null 2>&1; f2="$($W fingerprint)"
[ "$f0" = "$f1" ] || { echo "git add changed the fingerprint of an unchanged file ($f0 -> $f1)"; exit 1; }
[ "$f1" = "$f2" ] || { echo "git commit changed the fingerprint of an unchanged file ($f1 -> $f2)"; exit 1; }
echo changed > src/a.txt; f3="$($W fingerprint)"
[ "$f3" != "$f2" ] || { echo "a real edit did not change the fingerprint"; exit 1; }
git checkout -q src/a.txt

# 2. verify, commit, close: the natural order works
n="$($W new "Bound" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
$W suite "$n" >/dev/null; s1="$(ls Workspace/Testing/suites/wo-"$n"-*.sh)"
printf '#!/usr/bin/env bash\necho "3 passed, 0 failed"\nexit 0\n' > "$s1"
$W verify "$n" --run "$s1" >/dev/null 2>&1; fill_wo "$n"
git add -A >/dev/null 2>&1; git commit -q -m "chore: verified" >/dev/null 2>&1
$W close "$n" >/dev/null 2>&1 || { echo "committing between verify and close staled the evidence"; $W close "$n" 2>&1 | head -2; exit 1; }
rm -f Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-CLOSEOUT.md

# 3. a new, unrelated suite does not stale the pass; a change to the suite that ran does
printf '#!/usr/bin/env bash\nexit 0\n' > Workspace/Testing/suites/unrelated.sh
$W close "$n" >/dev/null 2>&1 || { echo "writing an unrelated suite staled the pass"; exit 1; }
rm -f Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-CLOSEOUT.md
printf '#!/usr/bin/env bash\necho "3 passed, 0 failed"\nexit 0 # edited\n' > "$s1"
out="$($W close "$n" 2>&1)" && { echo "the suite that produced the pass changed and close still went through"; exit 1; }
case "$out" in *"suite that produced the PASS has changed"*) ;; *) echo "refused for the wrong reason:"; echo "$out" | head -2; exit 1;; esac
exit 0
