#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
[ -x .git/hooks/commit-msg ] || { echo "new-project left no commit-msg hook; the check cannot be complete without it"; exit 1; }
git config user.email e@x; git config user.name e

base="$(git rev-parse HEAD)"
recorded() { [ "$(git rev-parse HEAD)" != "$base" ]; }
reset_to_base() { git reset -q --hard "$base"; }

# 1. a message supplied by file — the route that walked around the tool hook
printf 'WO-9999: never opened\n' > msg.txt; echo one > a.txt; git add a.txt
git commit -q -F msg.txt >/dev/null 2>&1
recorded && { echo "a commit citing WO-9999 was recorded when the message came from a file"; exit 1; }

# 2. a message supplied on stdin
echo two > b.txt; git add b.txt
printf 'BUG-0404: never filed\n' | git commit -q -F - >/dev/null 2>&1
recorded && { echo "a commit citing BUG-0404 was recorded when the message came from stdin"; exit 1; }

# 3. a message written by an editor
echo three > c.txt; git add c.txt
GIT_EDITOR='printf "WO-0777: never opened\n" >' git commit -q >/dev/null 2>&1
recorded && { echo "a commit citing WO-0777 was recorded when the message came from an editor"; exit 1; }

# 4. the same, inline: blocked at the tool hook and by git alike
echo four > d.txt; git add d.txt
git commit -q -m "WO-9999: never opened" >/dev/null 2>&1
recorded && { echo "a commit citing WO-9999 was recorded from an inline message"; exit 1; }

# 5. open it for real; the file route now goes through
n="$(./.aicodepipeline/bin/wo new "Real order" --size trivial --area docs | grep -o 'WO-[0-9]*' | head -1)"
[ -n "$n" ] || { echo "could not open a work order"; exit 1; }
git add -A; printf '%s: the work this commit belongs to\n' "$n" > msg.txt
git commit -q -F msg.txt >/dev/null 2>&1
recorded || { echo "a commit citing the real $n was refused"; git log --oneline -1; exit 1; }
base="$(git rev-parse HEAD)"

# 6. an unreferenced commit is the author's call, not the hook's
echo five > e.txt; git add e.txt; git commit -q -m "chore: tidy the build script" >/dev/null 2>&1
recorded || { echo "an unreferenced commit was refused"; exit 1; }
base="$(git rev-parse HEAD)"

# 7. the documented downgrade
echo six > f.txt; git add f.txt
printf 'WO-0111: never opened\n' > msg.txt
ACP_WO_REFERENCE=warn git commit -q -F msg.txt >/dev/null 2>&1
recorded || { echo "ACP_WO_REFERENCE=warn did not let the commit through"; exit 1; }
base="$(git rev-parse HEAD)"

# 9. cleanup modes: the hook must read the authored message, not a guess at what
#    git will keep. --cleanup=verbatim preserves comment lines verbatim.
reset_to_base() { git reset -q --hard "$base"; }
base="$(git rev-parse HEAD)"
git commit -q --allow-empty --cleanup=verbatim -m '# WO-9999: phantom in comment form' >/dev/null 2>&1
recorded && { echo "a phantom citation was recorded through --cleanup=verbatim"; exit 1; }
# a verbose commit carries a diff below the scissors line; that is git's text, not the author's
echo seven > g.txt; git add g.txt
git commit -q --verbose -m "chore: a commit whose diff is attached" >/dev/null 2>&1
recorded || { echo "a verbose commit with no citation was refused"; exit 1; }
base="$(git rev-parse HEAD)"

# 10. a hook git cannot execute is not protection, and doctor must not call it one
hookpath="$(git rev-parse --git-path hooks/commit-msg)"
chmod -x "$hookpath"
out="$(./.aicodepipeline/bin/acp doctor . 2>&1 | grep -i 'commit-msg' || true)"
case "$out" in *FAIL*|*"not executable"*) ;; *) echo "doctor called a non-executable hook protection: $out"; exit 1;; esac
chmod +x "$hookpath"

# 11. minimal means no hooks, and that has to include this one
"$PIPELINE_ROOT/bin/install.sh" . --profile minimal >/dev/null 2>&1 || { echo "minimal reinstall failed"; exit 1; }
[ -f "$hookpath" ] && { echo "the minimal profile left a blocking git hook installed"; exit 1; }
echo eight > h.txt; git add h.txt
git commit -q -m "WO-9999: phantom under minimal" >/dev/null 2>&1
recorded || { echo "the minimal profile still blocked a commit"; exit 1; }
base="$(git rev-parse HEAD)"
"$PIPELINE_ROOT/bin/install.sh" . --profile standard >/dev/null 2>&1 || { echo "standard reinstall failed"; exit 1; }
echo nine > i.txt; git add i.txt
git commit -q -m "WO-9999: phantom again" >/dev/null 2>&1
recorded && { echo "reinstalling the standard profile did not restore the hook"; exit 1; }

# 8. installing over a repository must not silently replace someone else's hook
printf '#!/bin/sh\nexit 0\n' > .git/hooks/commit-msg; chmod +x .git/hooks/commit-msg
out="$("$PIPELINE_ROOT/bin/install.sh" . 2>&1)"
grep -q 'acp:commit-msg' .git/hooks/commit-msg && { echo "install overwrote an existing commit-msg hook"; exit 1; }
case "$out" in *"left your existing hook alone"*) ;; *) echo "install replaced or ignored the existing hook without saying so"; exit 1;; esac
