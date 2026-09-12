#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; mkdir p && cd p && git init -q
cp "$PIPELINE_ROOT/pipeline.config.example.sh" pipeline.config.sh
mkdir -p .claude; cat > .claude/settings.json <<'J'
{ "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "echo my-own-hook" } ] } ] } }
J
count_acp() { python3 -c "import json; d=json.load(open('.claude/settings.json')); print(sum(1 for v in d.get('hooks',{}).values() for g in v for h in g['hooks'] if 'acp:' in h['command']))"; }
has_own() { grep -q "my-own-hook" .claude/settings.json; }
"$PIPELINE_ROOT/bin/install.sh" "$PWD" >/dev/null || { echo "install failed"; exit 1; }
has_own || { echo "user hook lost on install"; exit 1; }
[ "$(count_acp)" -ge 15 ] || { echo "pipeline hooks not added beside the user hook ($(count_acp))"; exit 1; }
first="$(count_acp)"
"$PIPELINE_ROOT/bin/install.sh" "$PWD" >/dev/null; [ "$(count_acp)" -eq "$first" ] || { echo "reinstall duplicated hooks ($first -> $(count_acp))"; exit 1; }
python3 - <<'PY'
import json; p='.claude/settings.json'; d=json.load(open(p))
for v in d['hooks'].values():
    for g in v:
        for h in g['hooks']:
            if 'acp:pre:rules' in h['command']: h['command']='echo tampered acp:pre:rules'
json.dump(d, open(p,'w'), indent=2)
PY
"$PIPELINE_ROOT/bin/install.sh" "$PWD" >/dev/null; grep -q "echo tampered" .claude/settings.json && { echo "tampered pipeline hook not restored"; exit 1; }
has_own || { echo "user hook lost on upgrade"; exit 1; }
"$PIPELINE_ROOT/bin/install.sh" "$PWD" --profile minimal >/dev/null
[ "$(count_acp)" -eq 0 ] || { echo "minimal profile left $(count_acp) pipeline hooks"; exit 1; }
has_own || { echo "user hook lost on minimal reinstall"; exit 1; }
exit 0
