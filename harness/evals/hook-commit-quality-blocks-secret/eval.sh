#!/usr/bin/env bash
set -euo pipefail
cd "$EVAL_TMP"; git init -q r; cd r; git config user.email e@x; git config user.name e
# key assembled at runtime so the fixture itself never contains a credential-shaped string
printf 'export const k = "%s%s";\n' 'AKIA' 'ABCDEFGHIJKLMNOP' > a.ts; git add a.ts
rc=0; printf '%s' '{"tool_input":{"command":"git commit -m x"}}' | python3 "$PIPELINE_ROOT/core/hooks/commit-quality.py" 2>/dev/null || rc=$?
[ "$rc" -eq 2 ] || { echo "secret not blocked (rc=$rc)"; exit 1; }
printf 'export const k = 1;\n' > a.ts; git add a.ts
printf '%s' '{"tool_input":{"command":"git commit -m x"}}' | python3 "$PIPELINE_ROOT/core/hooks/commit-quality.py" || { echo "clean commit blocked"; exit 1; }
