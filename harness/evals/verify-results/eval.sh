#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo; B=./.aicodepipeline/bin/bug
status_of() { grep -m1 'Overall status' Workspace/Docs/WorkOrders/WO-"$1"-*/WO-"$1"-VERIFICATION.md; }

# a precondition failure is its own state, and close refuses on it as such
n="$($W new "Precond" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
printf '#!/usr/bin/env bash\necho "precondition: service down"\nexit 77\n' > pre.sh; chmod +x pre.sh
$W verify "$n" --run ./pre.sh >/dev/null 2>&1
case "$(status_of "$n")" in *"PRECONDITION FAILED"*) ;; *"EXECUTED — FAIL"*) echo "exit 77 was recorded as a failure"; exit 1;; *) echo "exit 77 recorded as: $(status_of "$n")"; exit 1;; esac
fill_wo "$n"; out="$($W close "$n" 2>&1)" && { echo "close went through on a run that never ran"; exit 1; }
case "$out" in *"could not run"*) ;; *) echo "close refused for the wrong reason:"; echo "$out" | head -1; exit 1;; esac
$W list | grep -q "WO-$n.*PRECOND" || { echo "wo list does not show the precondition state"; $W list; exit 1; }
# the Stop hook agrees
d="$(ls -d Workspace/Docs/WorkOrders/WO-"$n"-*)"; printf '# Closeout\n' > "$d/WO-$n-CLOSEOUT.md"; git add -A >/dev/null 2>&1
rc=0; echo '{}' | ACP_EVIDENCE_GATE=block python3 .aicodepipeline/core/hooks/evidence-gate.py >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || { echo "the Stop hook accepted a closeout on a run that never ran (exit $rc)"; exit 1; }
rm -f "$d/WO-$n-CLOSEOUT.md"; git reset -q

# counts travel with the verdict, for every common runner shape
m="$($W new "Counts" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; m="${m#WO-}"
for shape in "42 passed, 1 failed" "Tests: 1 failed, 42 passed, 43 total" "1 failing" ; do
  printf '#!/usr/bin/env bash\necho "%s"\nexit 1\n' "$shape" > c.sh; chmod +x c.sh
  $W verify "$m" --run ./c.sh >/dev/null 2>&1
  case "$shape" in "1 failing") want="checks 0/1";; *) want="checks 42/43";; esac
  case "$(status_of "$m")" in *"$want"*) ;; *) echo "count not recorded for '$shape': $(status_of "$m")"; exit 1;; esac
done
$W list | grep -q "WO-$m.*FAIL 42/43\|WO-$m.*FAIL 0/1" || { echo "wo list does not show the ratio"; $W list; exit 1; }
printf '#!/usr/bin/env bash\necho "43 passed, 0 failed"\nexit 0\n' > c.sh; $W verify "$m" --run ./c.sh >/dev/null 2>&1
$W list | grep -q "WO-$m.*PASS 43/43" || { echo "a passing ratio is not shown"; $W list; exit 1; }

# the bug driver behaves the same
b="$($B new "Precond bug" --category api | grep -o 'BUG-[0-9]*' | head -1)"; b="${b#BUG-}"
$B verify "$b" --run ./pre.sh >/dev/null 2>&1
grep -m1 'Overall status' Workspace/Docs/Bugs/BUG-"$b"-*/BUG-"$b"-VERIFICATION.md | grep -q PRECONDITION || { echo "bug verify did not record the precondition state"; exit 1; }
exit 0
