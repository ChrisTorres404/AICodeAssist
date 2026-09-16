#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo; A=./.aicodepipeline/bin/acp
n="$($W new "Carried" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
$W suite "$n" >/dev/null; s="$(ls Workspace/Testing/suites/wo-"$n"-*.sh)"; printf '#!/usr/bin/env bash\necho "2 passed, 0 failed"\n' > "$s"
$W verify "$n" --run "$s" >/dev/null 2>&1; fill_wo "$n"; $W close "$n" >/dev/null 2>&1
c="$(ls Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-CLOSEOUT.md)"
perl -pi -e 's/\[What was delivered\]/w/; s/\[Root cause\]/r/' "$c"
$A pack lint >/dev/null 2>&1; true
# with the lessons still the template, promote only goes through when told to, and pack lint reports it
$W promote "$n" --allow-placeholders >/dev/null 2>&1 || { echo "promote failed"; $W promote "$n" --allow-placeholders; exit 1; }
[ -f ".aicodepipeline/packs/p/workorders/WO-$n-carried/suite/$(basename "$s")" ] || { echo "the suite did not travel with the work order"; find .aicodepipeline/packs -type f | head; exit 1; }
grep -q "suite/$(basename "$s")" .aicodepipeline/packs/p/catalog/WO-$n.md || { echo "the catalog does not point at the carried suite"; cat .aicodepipeline/packs/p/catalog/WO-$n.md; exit 1; }
grep -q '\\`' .aicodepipeline/packs/p/catalog/WO-$n.md && { echo "the catalog carries escaped backticks"; exit 1; }
rc=0; $A pack lint >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "pack lint passed an entry whose pitfalls are the placeholder"; exit 1; }
perl -pi -e 's/\[Lesson [0-9]\]/Do not trust the first green run./g; s/_\(none recorded.*\)_/Do not trust the first green run./' .aicodepipeline/packs/p/catalog/WO-$n.md
$A pack lint >/dev/null 2>&1 || { echo "pack lint failed an entry with pitfalls filled in"; $A pack lint; exit 1; }
exit 0
