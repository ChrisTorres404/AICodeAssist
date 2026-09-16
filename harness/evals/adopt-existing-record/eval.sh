#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo; B=./.aicodepipeline/bin/bug
printf '# Old feature\n\nShipped in 2025 after a manual harness run.\n' > old.md
printf '# Old bug\n\nFixed by hand.\n' > oldbug.md

$W adopt old.md --number 42 --opened 2025-06-01 --dry-run > "$EVAL_TMP/dry.out" 2>&1; grep -q 'would adopt' "$EVAL_TMP/dry.out" || { echo "dry run did not describe the plan"; exit 1; }
[ -d Workspace/Docs/WorkOrders/WO-0042-old-feature ] && { echo "dry run created the folder"; exit 1; }
$W adopt old.md --number 42 --opened 2025-06-01 >/dev/null || { echo "adopt failed"; exit 1; }
d=Workspace/Docs/WorkOrders/WO-0042-old-feature
cmp -s old.md "$d/WO-0042-SPEC.md" || { echo "the adopted document is not byte-identical to the original"; exit 1; }
ls "$d" | grep -qi VERIFICATION && { echo "adopt wrote a verification for work it never ran"; exit 1; }
grep -q '^status=migrated' "$d/.wo-meta" || { echo "adopted state not recorded"; exit 1; }
grep -q '^adopted=' "$d/.wo-meta" || { echo "adoption date not recorded"; exit 1; }
rc=0; $W adopt old.md --number 42 >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "a second record took the same number"; exit 1; }

# one definition of state across list, filters and stats
$W list > "$EVAL_TMP/list.out" 2>&1; grep -q 'WO-0042.*migrated' "$EVAL_TMP/list.out" || { echo "wo list does not show migrated"; cat "$EVAL_TMP/list.out"; exit 1; }
$W list --active > "$EVAL_TMP/active.out" 2>&1; grep -q 'WO-0042' "$EVAL_TMP/active.out" && { echo "an adopted item counts as active"; exit 1; }
$W list --open > "$EVAL_TMP/open.out" 2>&1; grep -q 'WO-0042' "$EVAL_TMP/open.out" && { echo "an adopted item counts as open"; exit 1; }
$W list --adopted > "$EVAL_TMP/adopted.out" 2>&1; grep -q 'WO-0042' "$EVAL_TMP/adopted.out" || { echo "--adopted does not list it"; exit 1; }
$W stats > "$EVAL_TMP/stats.out" 2>&1; grep -q 'adopted, not verified *1' "$EVAL_TMP/stats.out" || { echo "wo stats folds adopted work into open"; cat "$EVAL_TMP/stats.out"; exit 1; }
grep -q 'mean open-to-closeout' "$EVAL_TMP/stats.out" && { echo "cycle time reported from adopted items"; exit 1; }

# bugs: the category is the metadata, the number is what the record cites
out="$($B adopt oldbug.md --number 7 --category ui 2>&1)" || { echo "bug adopt failed: $out"; exit 1; }
case "$out" in *"outside the ui series"*) ;; *) echo "a number outside its category's series was not noted"; exit 1;; esac
grep -q '^category=ui' Workspace/Docs/Bugs/BUG-0007-*/.bug-meta || { echo "category not recorded in metadata"; exit 1; }
$B list | grep -q 'BUG-0007 *migrated *ui' || { echo "bug list does not read state and category from the metadata"; $B list; exit 1; }
# a bug opened normally records its category too, and a closeout still means fixed
b="$($B new "New bug" --category api | grep -o 'BUG-[0-9]*' | head -1)"; b="${b#BUG-}"
grep -q '^category=api' Workspace/Docs/Bugs/BUG-"$b"-*/.bug-meta || { echo "bug new did not record its category"; exit 1; }
printf '# Closeout\n' > "$(ls -d Workspace/Docs/Bugs/BUG-"$b"-*)/BUG-$b-CLOSEOUT.md"
$B list | grep -q "BUG-$b *fixed" || { echo "a closeout does not read as fixed"; $B list; exit 1; }
exit 0
