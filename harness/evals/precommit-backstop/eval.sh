#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git config user.email e@x; git config user.name e
hook="$(git rev-parse --git-path hooks/pre-commit)"
[ -x "$hook" ] || { echo "no executable pre-commit hook after scaffolding"; exit 1; }
git rev-parse HEAD >/dev/null 2>&1 || { echo "the scaffold's first commit never landed; the pre-commit hook blocked the install itself"; exit 1; }
base="$(git rev-parse HEAD)"; recorded() { [ "$(git rev-parse HEAD)" != "$base" ]; }

# a closeout resting on a failed verification, written by hand and committed directly
mkdir -p Workspace/Docs/WorkOrders/WO-0042-by-hand
printf '**Overall status:** EXECUTED — FAIL (x)\n' > Workspace/Docs/WorkOrders/WO-0042-by-hand/WO-0042-VERIFICATION.md
printf '# Closeout\n' > Workspace/Docs/WorkOrders/WO-0042-by-hand/WO-0042-CLOSEOUT.md
git add -A; git commit -q -m "chore: closeout" >/dev/null 2>&1
recorded && { echo "a hand-written closeout on failed verification was committed"; exit 1; }
git reset -q; rm -rf Workspace/Docs/WorkOrders/WO-0042-by-hand

# a credential in staged source
mkdir -p src; echo 'const k = "AKIA'ABCDEFGHIJKLMNOP'";' > src/k.ts
git add -A; git commit -q -m "chore: key" >/dev/null 2>&1
recorded && { echo "a credential was committed past the pre-commit hook"; exit 1; }
git reset -q; rm -rf src

# an ordinary commit is untouched
echo note > note.txt; git add note.txt; git commit -q -m "chore: note" >/dev/null 2>&1
recorded || { echo "a clean commit was refused"; exit 1; }
base="$(git rev-parse HEAD)"

# minimal installs no hooks, and removes the pipeline's
"$PIPELINE_ROOT/bin/install.sh" . --profile minimal >/dev/null 2>&1 || { echo "minimal reinstall failed"; exit 1; }
[ -f "$hook" ] && { echo "the minimal profile left the pipeline's pre-commit hook in place"; exit 1; }
"$PIPELINE_ROOT/bin/install.sh" . --profile standard >/dev/null 2>&1 || { echo "standard reinstall failed"; exit 1; }
[ -x "$hook" ] || { echo "reinstalling standard did not restore the pre-commit hook"; exit 1; }

# someone else's hook is theirs
printf '#!/bin/sh\nexit 0\n' > "$hook"; chmod +x "$hook"
out="$("$PIPELINE_ROOT/bin/install.sh" . 2>&1)"
grep -q 'acp:pre-commit' "$hook" && { echo "install overwrote an existing pre-commit hook"; exit 1; }
case "$out" in *"pre-commit: left your existing hook alone"*) ;; *) echo "install replaced or ignored an existing pre-commit hook without saying so"; exit 1;; esac
exit 0
