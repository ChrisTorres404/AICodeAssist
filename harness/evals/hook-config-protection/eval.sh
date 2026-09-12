#!/usr/bin/env bash
set -euo pipefail
cd "$EVAL_TMP"; echo '{}' > tsconfig.json
rc=0; printf '{"tool_input":{"file_path":"%s/tsconfig.json"}}' "$EVAL_TMP" | python3 "$PIPELINE_ROOT/core/hooks/config-protection.py" 2>/dev/null || rc=$?
[ "$rc" -eq 2 ] || { echo "edit not blocked"; exit 1; }
printf '{"tool_input":{"file_path":"%s/other/tsconfig.json"}}' "$EVAL_TMP" | python3 "$PIPELINE_ROOT/core/hooks/config-protection.py" || { echo "create blocked"; exit 1; }
printf '{"tool_input":{"file_path":"%s/tsconfig.json"}}' "$EVAL_TMP" | ACP_ALLOW_CONFIG_EDIT=1 python3 "$PIPELINE_ROOT/core/hooks/config-protection.py" || { echo "override ignored"; exit 1; }
