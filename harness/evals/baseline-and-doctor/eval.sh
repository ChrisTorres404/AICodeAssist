#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git config user.email e@x; git config user.name e
A=./.aicodepipeline/bin/acp
doc() { $A doctor . 2>&1 || true; }

# counts are validated, not counted
doc | grep -q 'every definition parses' || { echo "doctor did not validate what it counts"; doc | grep -i 'agents:'; exit 1; }
printf -- '---\nname: broken\ndescription: one\n  two: [unbalanced\n---\n# x\n' > .claude/skills/broken.md
doc | grep -q 'do not parse\|lint reports [1-9]' || { echo "doctor passed a skill whose frontmatter does not parse"; doc | grep -i 'agents:'; exit 1; }
rm -f .claude/skills/broken.md

# a baseline is asked for, then recorded, then bound to the tree
doc | grep -q 'no baseline' || { echo "doctor did not ask for a baseline"; exit 1; }
rc=0; $A baseline >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "baseline succeeded with no test command"; exit 1; }
printf '#!/usr/bin/env bash\necho "9 passed, 0 failed"\n' > t.sh; chmod +x t.sh
$A baseline --command ./t.sh >/dev/null 2>&1 || { echo "baseline failed with a passing command"; $A baseline --command ./t.sh; exit 1; }
bl=Workspace/Testing/results/BASELINE.md
[ -f "$bl" ] || { echo "no baseline document written"; exit 1; }
grep -q 'PASS, 9 passed, 0 failed' "$bl" || { echo "the baseline did not record the count"; cat "$bl" | head -8; exit 1; }
grep -q 'tree [0-9a-f]\{16\}' "$bl" || { echo "the baseline is not bound to a tree"; exit 1; }
git add -A >/dev/null 2>&1; git commit -q -m "chore: baseline" >/dev/null 2>&1
doc | grep -q 'baseline recorded against this exact tree' || { echo "doctor does not recognise a baseline for the current tree"; doc | grep -i baseline; exit 1; }
echo change > src.txt
doc | grep -q 'the tree has changed since' || { echo "doctor did not notice the tree moved past the baseline"; doc | grep -i baseline; exit 1; }
printf '#!/usr/bin/env bash\necho "8 passed, 1 failed"\nexit 1\n' > t.sh
rc=0; $A baseline --command ./t.sh >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "a failing baseline reported success"; exit 1; }
grep -q 'FAIL (exit 1), 8 passed, 1 failed' "$bl" || { echo "a failing baseline was not recorded as such"; grep Result "$bl"; exit 1; }

# a repository with no commits is not a source state
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" q --name Q --no-git >/dev/null 2>&1; cd q; git init -q
out="$(./.aicodepipeline/bin/acp doctor . 2>&1 || true)"; case "$out" in *"no commits yet"*) ;; *) echo "doctor passed a repository with no commits as a git repository"; exit 1;; esac
rc=0; ./.aicodepipeline/bin/acp baseline --command true >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "baseline ran against a repository with no commits"; exit 1; }

# a moved workspace is named, and stale instructions are noticed
cd "$EVAL_TMP/p"
perl -pi -e 's|^export WORKORDERS_DIR=.*|export WORKORDERS_DIR="docs/orders"|' pipeline.config.sh
out="$("$PIPELINE_ROOT/bin/install.sh" . 2>&1)"
case "$out" in *"workspace moved: WORKORDERS_DIR"*) ;; *) echo "the installer did not say the workspace moved"; exit 1;; esac
case "$out" in *"still exists and is no longer read"*) ;; *) echo "the installer did not name the orphaned folder"; exit 1;; esac
[ -d Workspace/Docs/WorkOrders ] || { echo "the installer deleted the previous workspace"; exit 1; }
doc | grep -q 'never mentions the configured work-order directory' || { echo "doctor did not notice instructions pointing at the old layout"; exit 1; }
# and the install itself ends with lint, out loud
case "$out" in *"lint: 0 error(s)"*) ;; *) echo "install did not report lint at the end"; exit 1;; esac
exit 0
