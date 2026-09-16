#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
A=./.aicodepipeline/bin/acp
mkdir -p src Workspace/Docs/WorkOrders/WO-0007-thing
echo 'const k = "AKIA'ABCDEFGHIJKLMNOP'";' > src/leak.ts
printf 'console.log("x");\n' > src/dbg.ts
echo '{}' > tsconfig.json
printf '# Closeout\n' > Workspace/Docs/WorkOrders/WO-0007-thing/WO-0007-CLOSEOUT.md
printf '**Overall status:** EXECUTED — FAIL (x)\n' > Workspace/Docs/WorkOrders/WO-0007-thing/WO-0007-VERIFICATION.md

# named paths, no git anywhere
out="$($A check --paths src/leak.ts src/dbg.ts tsconfig.json Workspace/Docs/WorkOrders/WO-0007-thing/WO-0007-CLOSEOUT.md 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "a credential, a changed config and a failed closeout did not block (exit $rc)"; echo "$out"; exit 1; }
for want in "credential-like" "strictness configuration changed" "latest verification run failed" "console.log"; do
  case "$out" in *"$want"*) ;; *) echo "report lacks: $want"; echo "$out"; exit 1;; esac
done
# advisory alone does not block, and does under strict
rc=0; $A check --paths src/dbg.ts >/dev/null 2>&1 || rc=$?; [ "$rc" -eq 0 ] || { echo "advisory findings blocked without strict (exit $rc)"; exit 1; }
rc=0; $A check --paths src/dbg.ts --strict >/dev/null 2>&1 || rc=$?; [ "$rc" -eq 2 ] || { echo "advisory findings did not block under strict (exit $rc)"; exit 1; }
# no git and no file set is an honest error, not a silent pass
rc=0; $A check >/dev/null 2>&1 || rc=$?; [ "$rc" -eq 1 ] || { echo "check with nothing to compare against exited $rc instead of refusing"; exit 1; }

# a manifest names the change without git; creating a config is fine, changing one is not
python3 .aicodepipeline/core/hooks/check.py --root . --write-manifest "$EVAL_TMP/m" --exclude Workspace/Docs/WorkOrders
echo '{"strict": false}' > tsconfig.json          # modified since the manifest
echo '{}' > .prettierrc                            # created since the manifest
rm -f src/leak.ts
out="$(python3 .aicodepipeline/core/hooks/check.py --root . --manifest "$EVAL_TMP/m" --exclude Workspace/Docs/WorkOrders 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "a config changed since the manifest did not block (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *"tsconfig.json"*) ;; *) echo "the changed config was not named"; echo "$out"; exit 1;; esac
case "$out" in *".prettierrc"*) echo "a newly created config was treated as a weakened one"; exit 1;; *) ;; esac

# the same rules over the git index, when there is git
git init -q && git -c user.email=e@x -c user.name=e add -A >/dev/null 2>&1
out="$($A check --staged 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "staged mode did not block on the failed closeout (exit $rc)"; echo "$out"; exit 1; }
exit 0
