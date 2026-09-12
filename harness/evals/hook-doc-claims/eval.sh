#!/usr/bin/env bash
set -uo pipefail
H="$PIPELINE_ROOT/core/hooks/doc-claims-check.py"
cd "$EVAL_TMP"; git init -q d; cd d; mkdir -p src; echo "x" > src/real.ts
bad='{"tool_input":{"file_path":"'"$PWD"'/doc.md","content":"---\nwo: WO-0001\nstatus: DRAFT\n---\nIt never fails. <!-- SOURCE: src/missing.ts:L4 -->\n"}}'
good='{"tool_input":{"file_path":"'"$PWD"'/doc.md","content":"---\nwo: WO-0001\n---\nThe guard enforces it. <!-- SOURCE: src/real.ts:L1 -->\n"}}'
plain='{"tool_input":{"file_path":"'"$PWD"'/README.md","content":"This never happens and always works."}}'
out="$(printf '%s' "$bad" | python3 "$H" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "standard profile should warn, not block (rc=$rc)"; exit 1; }
echo "$out" | grep -q "does not exist: src/missing.ts" || { echo "missing SOURCE path not reported:"; echo "$out"; exit 1; }
echo "$out" | grep -qi "over-claim" || { echo "over-claim not reported"; exit 1; }
out="$(printf '%s' "$bad" | ACP_STRICT=1 python3 "$H" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "strict should block on a missing SOURCE (rc=$rc)"; exit 1; }
out="$(printf '%s' "$good" | python3 "$H" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || { echo "traced claim should be silent: $out"; exit 1; }
out="$(printf '%s' "$plain" | python3 "$H" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || { echo "plain README should be ignored: $out"; exit 1; }
badline='{"tool_input":{"file_path":"'"$PWD"'/doc.md","content":"---\nwo: WO-0001\n---\nThe guard enforces it. <!-- SOURCE: src/real.ts:L99999 -->\n"}}'
out="$(printf '%s' "$badline" | python3 "$H" 2>&1)"; echo "$out" | grep -q "line does not exist" || { echo "bad line number not reported: $out"; exit 1; }
exit 0
