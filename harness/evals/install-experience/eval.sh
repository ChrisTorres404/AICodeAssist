#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null || exit 1
cd p; W=./.aicodepipeline/bin/wo; A=./.aicodepipeline/bin/acp
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh

# 1. the installed copy's self-test skips what needs the source repo, and does not fail on it
out="$(./.aicodepipeline/bin/eval run 2>&1)"
case "$out" in *"skipped"*) ;; *) echo "an installed copy did not skip the installer evaluations:"; echo "$out" | tail -3; exit 1;; esac
echo "$out" | grep -qE "^  [0-9]+ passed, 0 failed" || { echo "the installed copy reported failures for source-only evaluations:"; echo "$out" | tail -4; exit 1; }

# 2. doctor proves a lifecycle in this layout instead of trusting it
dout="$($A doctor . 2>&1)"
case "$dout" in *"lifecycle probe"*) ;; *) echo "doctor did not exercise a lifecycle probe"; exit 1;; esac
case "$dout" in *FAIL*) echo "doctor reported FAIL on a healthy install:"; echo "$dout" | grep FAIL; exit 1;; esac
[ "$(ls -d Workspace/Docs/WorkOrders/WO-* 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ] || { echo "the doctor probe left a work order behind"; exit 1; }

# 3. a commit citing a work order that was never opened is reported, and blocked in strict
H=.aicodepipeline/core/hooks/wo-reference.py
n="$($W new "Real work" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"
real="$(printf '{"tool_input":{"command":"git commit -m \\"%s: real\\""}}' "$n" | python3 "$H" 2>&1)"
[ -z "$real" ] || { echo "a commit citing a real work order was flagged: $real"; exit 1; }
phantom="$(printf '%s' '{"tool_input":{"command":"git commit -m \"WO-0999: never opened\""}}' | python3 "$H" 2>&1)"
case "$phantom" in *"does not exist"*) ;; *) echo "a commit citing a nonexistent work order was accepted: $phantom"; exit 1;; esac
rc=0; printf '%s' '{"tool_input":{"command":"git commit -m \"WO-0999: never opened\""}}' | python3 "$H" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || { echo "a phantom work-order reference was not blocked under the default profile (rc=$rc)"; exit 1; }

# 4. a verification still full of template placeholders is not evidence
n="${n#WO-}"; $W verify "$n" --run ./ok.sh >/dev/null
rc=0; $W close "$n" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "closed on a verification document that was never filled in"; exit 1; }
ALLOW_PLACEHOLDERS=1 $W close "$n" >/dev/null 2>&1 || { echo "the documented override did not work"; exit 1; }
exit 0
