#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git config user.email e@x; git config user.name e
A=./.aicodepipeline/bin/acp; W=./.aicodepipeline/bin/wo

# installing opened six work orders, each with its suite and the compact verification template
[ "$($W list 2>/dev/null | grep -c 'WO-000[1-6]' || true)" -eq 6 ] || { echo "install did not open six intake work orders"; $W list; exit 1; }
[ "$(ls Workspace/Testing/suites/intake-0*.sh 2>/dev/null | wc -l | tr -d ' ')" -eq 6 ] || { echo "the six intake suites were not copied"; ls Workspace/Testing/suites; exit 1; }
grep -q '^intake=01' Workspace/Docs/WorkOrders/WO-0001-*/.wo-meta || { echo "step metadata missing"; exit 1; }
[ "$(grep -c '\[[A-Za-z][^]]*\]' Workspace/Docs/WorkOrders/WO-0002-*/WO-0002-SPEC.md || true)" = 0 ] || { echo "an intake spec shipped with placeholders"; exit 1; }
st="$($A intake status 2>&1 || true)"; case "$st" in *"not yet operational: 0 of 6"*) ;; *) echo "intake status wrong at the start"; echo "$st"; exit 1;; esac
# a second install keeps them rather than opening twelve
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1
[ "$($W list 2>/dev/null | grep -c 'WO-' || true)" -eq 6 ] || { echo "reinstalling opened the intake work orders again"; $W list; exit 1; }

# once the project has source, a step that is not done fails its suite and names the fix
mkdir -p src; printf 'module.exports = 1;\n' > src/index.js
rc=0; $W verify 3 --run Workspace/Testing/suites/intake-03-*.sh >/tmp/v3.out 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "the baseline step passed before a baseline existed"; exit 1; }
grep -q 'acp baseline' Workspace/Docs/WorkOrders/WO-0003-*/WO-0003-VERIFICATION-*.log || { echo "the failing baseline step did not name acp baseline"; exit 1; }
fill_wo 3; $W close 3 >/dev/null 2>&1 && { echo "an intake step closed on a failed suite"; exit 1; }

# do the steps, in the order the guide gives
printf '{"name":"p","scripts":{"test":"echo 4 passed, 0 failed"}}\n' > package.json
./.aicodepipeline/bin/detect-stack . --write >/dev/null 2>&1
printf 'export SUITE_COMMAND="npm test"\n' >> pipeline.config.sh
git add -A >/dev/null 2>&1; git commit -q -m "chore: stack and suite command" >/dev/null 2>&1
$A baseline >/dev/null 2>&1 || { echo "baseline failed"; exit 1; }
$A intake inventory >/dev/null 2>&1 || { echo "inventory failed"; exit 1; }
for n in 1 2 3 4 5; do
  $W verify "$n" --run Workspace/Testing/suites/intake-0$n-*.sh >/dev/null 2>&1 || { echo "intake step $n failed after being done:"; tail -5 Workspace/Docs/WorkOrders/WO-000$n-*/WO-000$n-VERIFICATION-*.log; exit 1; }
  fill_wo "$n"; $W close "$n" >/dev/null 2>&1 || { echo "intake step $n did not close after passing"; $W close "$n"; exit 1; }
done
# the verification the driver wrote for an intake step is the compact one, not fifty prompts
[ "$(grep -c '\[[A-Za-z][^]]*\]' Workspace/Docs/WorkOrders/WO-0001-*/WO-0001-VERIFICATION.md)" -le 3 ] || { echo "an intake step got the feature-work verification template"; exit 1; }
st="$($A intake status 2>&1 || true)"; case "$st" in *"not yet operational: 5 of 6"*) ;; *) echo "intake status wrong after five"; echo "$st"; exit 1;; esac
doc="$($A doctor . 2>&1 || true)"; case "$doc" in *"5 of 6 intake steps"*) ;; *) echo "doctor does not report intake progress"; printf '%s\n' "$doc" | grep -i intake; exit 1;; esac

# the knowledge base step: the lite level was scaffolded at install, so it passes on day one
[ -f Workspace/Docs/KnowledgeBase/level ] || { echo "install did not scaffold the knowledge base"; ls Workspace/Docs/KnowledgeBase; exit 1; }
$W verify 6 --run Workspace/Testing/suites/intake-06-*.sh >/dev/null 2>&1 || { echo "the knowledge-base step failed on the scaffolded lite knowledge base:"; tail -8 Workspace/Docs/WorkOrders/WO-0006-*/WO-0006-VERIFICATION-*.log; exit 1; }
# source added since install gets a profile stub when a work order closes (grow), and the index still binds
[ "$(ls Workspace/Docs/KnowledgeBase/profiles/*.md 2>/dev/null | wc -l | tr -d ' ')" -ge 1 ] || { echo "no profile stub after source was added and work orders closed"; ls -R Workspace/Docs/KnowledgeBase; exit 1; }
# at a higher level the same knowledge base is short, and the step says so
perl -pi -e 's/^export KNOWLEDGE_LEVEL=.*/export KNOWLEDGE_LEVEL="standard"/' pipeline.config.sh
rc=0; $W verify 6 --run Workspace/Testing/suites/intake-06-*.sh >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "the knowledge-base step passed at the standard level with no narrative written"; exit 1; }
grep -q 'short of the standard level' Workspace/Docs/WorkOrders/WO-0006-*/WO-0006-VERIFICATION-*.log || { echo "the failing step did not say the profiles are short of the level"; tail -6 Workspace/Docs/WorkOrders/WO-0006-*/WO-0006-VERIFICATION-*.log; exit 1; }
perl -pi -e 's/^export KNOWLEDGE_LEVEL=.*/export KNOWLEDGE_LEVEL="lite"/' pipeline.config.sh
$W verify 6 --run Workspace/Testing/suites/intake-06-*.sh >/dev/null 2>&1 || { echo "the knowledge-base step failed again at lite"; exit 1; }
fill_wo 6; $W close 6 >/dev/null 2>&1 || { echo "step six did not close"; exit 1; }
st="$($A intake status 2>&1 || true)"; case "$st" in *"operational: every intake step"*) ;; *) echo "all six closed but not operational"; echo "$st"; exit 1;; esac
doc="$($A doctor . 2>&1 || true)"; case "$doc" in *"intake: operational"*) ;; *) echo "doctor does not report operational"; exit 1;; esac
exit 0
