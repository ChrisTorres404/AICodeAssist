#!/usr/bin/env bash
set -uo pipefail
H="$PIPELINE_ROOT/core/hooks/wo-reference.py"
# The hook resolves citations against the repository it is invoked in, so this
# builds that repository directly rather than through the installer: the check
# has to hold in an installed project as much as in the pipeline itself.
cd "$EVAL_TMP"; mkdir -p p && cd p
git init -q >/dev/null 2>&1; git -c user.email=e@x -c user.name=e commit -q --allow-empty -m init >/dev/null 2>&1
mkdir -p Workspace/Docs/WorkOrders Workspace/Docs/Bugs

hook() { printf '%s' "{\"tool_input\":{\"command\":\"git commit -m \\\"$1\\\"\"}}" | python3 "$H" >/dev/null 2>&1; }

# nothing has been opened yet: both citations are phantoms, and both are refused
rc=0; hook "WO-0999: never opened" || rc=$?
[ "$rc" -eq 2 ] || { echo "a commit citing WO-0999 was accepted (exit $rc); no such work order exists"; exit 1; }
rc=0; hook "BUG-0404: never filed" || rc=$?
[ "$rc" -eq 2 ] || { echo "a commit citing BUG-0404 was accepted (exit $rc)"; exit 1; }

# open them for real; the same messages are then fine
mkdir -p Workspace/Docs/WorkOrders/WO-0999-real Workspace/Docs/Bugs/BUG-0404-real
rc=0; hook "WO-0999: the work this commit belongs to" || rc=$?
[ "$rc" -eq 0 ] || { echo "a commit citing the real WO-0999 was refused (exit $rc)"; exit 1; }
rc=0; hook "BUG-0404: the fix this commit carries" || rc=$?
[ "$rc" -eq 0 ] || { echo "a commit citing the real BUG-0404 was refused (exit $rc)"; exit 1; }

# a directory relocated by configuration is still found
rm -rf Workspace/Docs/WorkOrders; mkdir -p Ops/Orders/WO-0777-moved
printf 'export WORKORDERS_DIR="Ops/Orders"\n' > pipeline.config.sh
rc=0; hook "WO-0777: opened under a configured directory" || rc=$?
[ "$rc" -eq 0 ] || { echo "the configured work-order directory was not consulted (exit $rc)"; exit 1; }
rm -f pipeline.config.sh

# the documented downgrade
rc=0; ACP_WO_REFERENCE=warn hook "WO-0111: never opened" || rc=$?
[ "$rc" -eq 0 ] || { echo "ACP_WO_REFERENCE=warn did not downgrade the refusal (exit $rc)"; exit 1; }

# no reference at all stays advisory: that judgement belongs to the author
rc=0; hook "chore: tidy the build script" || rc=$?
[ "$rc" -eq 0 ] || { echo "an unreferenced commit was blocked (exit $rc)"; exit 1; }
exit 0
