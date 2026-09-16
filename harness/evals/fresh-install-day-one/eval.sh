#!/usr/bin/env bash
set -euo pipefail
cd "$EVAL_TMP"
out="$("$PIPELINE_ROOT/bin/new-project" day1 --name "Day One" --skill-pack business-ops 2>&1)"
echo "$out" | grep -qi "unresolved" && { echo "install warned about unresolved variables:"; echo "$out" | grep -i -A3 unresolved; exit 1; }
cd day1
./.aicodepipeline/bin/acp doctor . | grep -q "FAIL" && { echo "doctor reported FAIL on a fresh install"; ./.aicodepipeline/bin/acp doctor .; exit 1; }
# doctor proves the lifecycle by running one; a diagnostic must leave no trace of it,
# in this project or in the pipeline it was run from
[ "$(non_intake_wos | grep -c . || true)" -eq 0 ] || { echo "doctor left its probe work order behind:"; ls Workspace/Docs/WorkOrders; exit 1; }
ls -a | grep -q 'acp-doctor-probe' && { echo "doctor left its probe suite behind"; exit 1; }
[ "$(ls "$PIPELINE_ROOT/Workspace/Docs/WorkOrders" 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ] || { echo "doctor wrote into the pipeline repository instead of the project it was pointed at:"; ls "$PIPELINE_ROOT/Workspace/Docs/WorkOrders"; exit 1; }
# and the same when it is pointed at a project from outside it
( cd "$EVAL_TMP" && "$PIPELINE_ROOT/bin/acp" doctor day1 >/dev/null 2>&1 )
[ "$(ls "$PIPELINE_ROOT/Workspace/Docs/WorkOrders" 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ] || { echo "doctor run from the pipeline repository wrote its probe there:"; ls "$PIPELINE_ROOT/Workspace/Docs/WorkOrders"; exit 1; }
[ "$(non_intake_wos | grep -c . || true)" -eq 0 ] || { echo "doctor left its probe behind when run from outside the project"; exit 1; }
./.aicodepipeline/bin/pack search "anything" >/dev/null || { echo "pack search errored on a fresh install"; exit 1; }
./.aicodepipeline/bin/pack list >/dev/null || { echo "pack list errored"; exit 1; }
grep -q "{{" AGENTS.md && { echo "AGENTS.md has unrendered variables"; grep -n "{{" AGENTS.md | head -3; exit 1; }
grep -q "@AGENTS.md" CLAUDE.md || { echo "CLAUDE.md does not import AGENTS.md"; exit 1; }
# The installer renders these three placeholders inside this very line, so an
# installed copy of this file carries the rendered project path — which is a
# home directory for most people. The rule is exempted here, on this line only.
grep -rq "{{PIPELINE_ROOT}}\|{{PROJECT_ROOT}}\|{{API_BASE_URL}}" .aicodepipeline/core .aicodepipeline/harness --exclude-dir=project && { echo "pipeline variables left unrendered"; exit 1; }  # acp:lint-ignore personal-path
n="$(./.aicodepipeline/bin/wo new "First order" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"
[ -n "$n" ] || { echo "wo new produced no number"; exit 1; }
./.aicodepipeline/bin/wo status "${n#WO-}" >/dev/null
b="$(./.aicodepipeline/bin/bug new "First bug" --category api | grep -o 'BUG-[0-9]*' | head -1)"
[ "${b#BUG-}" = "0100" ] || { echo "bug new --category api did not start the 0100 series (got $b)"; exit 1; }
exit 0
