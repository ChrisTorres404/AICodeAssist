#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
[ -d .git ] && { echo "the fixture has git; this evaluation needs none"; exit 1; }
W=./.aicodepipeline/bin/wo
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; chmod +x ok.sh
n="$($W new "No git" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
d="$(ls -d Workspace/Docs/WorkOrders/WO-"$n"-*)"
[ -s "$d/.wo-manifest" ] || { echo "no manifest was taken when the work order opened"; exit 1; }

# work done during the order: one file with a credential
mkdir -p src; echo 'const k = "AKIA'ABCDEFGHIJKLMNOP'";' > src/cfg.ts
$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
out="$($W close "$n" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || { echo "a credential added during the work order did not block the close"; exit 1; }
case "$out" in *"credential-like"*) ;; *) echo "close refused for the wrong reason:"; echo "$out"; exit 1;; esac

# fix it; the tree moved, so evidence must be re-run, then close goes through
echo 'const k = process.env.KEY;' > src/cfg.ts
out="$($W close "$n" 2>&1)"; case "$out" in *"source changed after the last PASS"*) ;; *) echo "editing after the pass was not caught without git:"; echo "$out"; exit 1;; esac
$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
$W close "$n" >/dev/null 2>&1 || { echo "close was refused after a clean re-run"; $W close "$n"; exit 1; }
[ -f "$d/WO-$n-CLOSEOUT.md" ] || { echo "no closeout was drafted"; exit 1; }
exit 0
