#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git add -A >/dev/null 2>&1; git -c user.email=e@x -c user.name=e commit -q -m base >/dev/null 2>&1
W=./.aicodepipeline/bin/wo
mkdir -p src; echo good > src/app.txt
status_of() { grep -m1 'Overall status' Workspace/Docs/WorkOrders/WO-"$1"-*/WO-"$1"-VERIFICATION.md; }

# 1. the source moves while the suite runs: the suite read one thing, the tree says another
n="$($W new "Drift" --size trivial --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
cat > drift.sh <<'SUITE'
#!/usr/bin/env bash
cat src/app.txt > "$EVAL_TMP/what-the-suite-read"
touch "$EVAL_TMP/suite-started"
while [ ! -f "$EVAL_TMP/release" ]; do sleep 0.1; done
exit 0
SUITE
chmod +x drift.sh; rm -f "$EVAL_TMP/suite-started" "$EVAL_TMP/release"
( $W verify "$n" --run ./drift.sh >/dev/null 2>&1 ) &
while [ ! -f "$EVAL_TMP/suite-started" ]; do sleep 0.1; done
echo broken > src/app.txt; touch "$EVAL_TMP/release"; wait
[ "$(cat "$EVAL_TMP/what-the-suite-read")" = good ] || { echo "the fixture did not reproduce: the suite did not read the original contents"; exit 1; }
case "$(status_of "$n")" in *"EXECUTED — FAIL"*) ;; *) echo "a suite that exited 0 against source that changed underneath it was recorded as: $(status_of "$n")"; exit 1;; esac
fill_wo "$n"; $W close "$n" >/dev/null 2>&1 && { echo "closeout was accepted on a run whose source changed underneath it"; exit 1; }

# the documented override, for suites that write into the tree by design
ALLOW_TREE_DRIFT=1 $W verify "$n" --run ./drift.sh >/dev/null 2>&1 || true

# 2. an interrupted rerun must not leave the previous pass authoritative
m="$($W new "Interrupted" --size trivial --area docs | grep -o 'WO-[0-9]*' | head -1)"; m="${m#WO-}"
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; chmod +x ok.sh
printf '#!/usr/bin/env bash\ntouch "$EVAL_TMP/slow-started"\nsleep 60\nexit 1\n' > slow.sh; chmod +x slow.sh
$W verify "$m" --run ./ok.sh >/dev/null 2>&1
case "$(status_of "$m")" in *"EXECUTED — PASS"*) ;; *) echo "the fixture did not reproduce: the first run did not pass"; exit 1;; esac
rm -f "$EVAL_TMP/slow-started"
set -m
$W verify "$m" --run ./slow.sh >/dev/null 2>&1 & 
vp=$!
while [ ! -f "$EVAL_TMP/slow-started" ]; do sleep 0.1; done
kill -9 -"$vp" 2>/dev/null || kill -9 "$vp" 2>/dev/null
sleep 1; wait 2>/dev/null
set +m
case "$(status_of "$m")" in *RUNNING*) ;; *) echo "a killed verification left the status as: $(status_of "$m")"; exit 1;; esac
fill_wo "$m"; $W close "$m" >/dev/null 2>&1 && { echo "closeout was accepted while the last verification had not finished"; exit 1; }
$W verify "$m" --run ./ok.sh >/dev/null 2>&1    # finishing a real run clears it
fill_wo "$m"; $W close "$m" >/dev/null 2>&1 || { echo "closeout was refused after a completed passing rerun"; exit 1; }

# 3. the Stop hook reads the document the way the drivers do
k="$($W new "Stop hook" --size trivial --area docs | grep -o 'WO-[0-9]*' | head -1)"; k="${k#WO-}"
printf '#!/usr/bin/env bash\nexit 1\n' > bad.sh; chmod +x bad.sh
$W verify "$k" --run ./ok.sh >/dev/null 2>&1     # a pass earlier in the history
$W verify "$k" --run ./bad.sh >/dev/null 2>&1    # the latest run fails
d="$(ls -d Workspace/Docs/WorkOrders/WO-"$k"-*)"
printf '# Closeout\n\nWritten directly.\n' > "$d/WO-$k-CLOSEOUT.md"
git add -A >/dev/null 2>&1
rc=0; echo '{}' | ACP_EVIDENCE_GATE=block python3 .aicodepipeline/core/hooks/evidence-gate.py >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || { echo "the blocking Stop hook accepted a closeout whose latest verification failed (exit $rc)"; exit 1; }
exit 0
