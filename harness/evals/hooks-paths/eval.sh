#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" "Project With Spaces" --name "Spaces" --no-git >/dev/null || { echo "scaffold failed"; exit 1; }
run_hooks() { # runs every command string from settings.json with cwd = project, empty stdin; fails on exit 127 or 126
  local proj="$1"; ( cd "$proj" && python3 -c "import json; d=json.load(open('.claude/settings.json')); [print(h['command']) for v in d['hooks'].values() for g in v for h in g['hooks']]" ) | while IFS= read -r cmd; do
    ( cd "$proj" && bash -c "$cmd" </dev/null >/dev/null 2>&1 ); rc=$?
    [ "$rc" -eq 127 ] || [ "$rc" -eq 126 ] && { echo "command not found/executable (rc=$rc) in $proj: $cmd"; return 1; }
  done; return 0; }
run_hooks "$EVAL_TMP/Project With Spaces" || exit 1
mv "$EVAL_TMP/Project With Spaces" "$EVAL_TMP/Moved Elsewhere"
run_hooks "$EVAL_TMP/Moved Elsewhere" || { echo "(after moving the project)"; exit 1; }
exit 0
