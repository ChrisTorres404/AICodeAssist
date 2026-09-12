#!/usr/bin/env bash
set -uo pipefail
cd "$PIPELINE_ROOT"
out="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP DATABASE prod\""}}' | ACP_HOOK_RULES_DIR="$PIPELINE_ROOT/core/hooks/rules" python3 core/hooks/rule-hook.py 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "expected exit 2, got $rc: $out"; exit 1; }
