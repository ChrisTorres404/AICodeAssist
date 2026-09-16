#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git --agent-set identity --skill-set network >/dev/null; cd p
mkdir -p .claude/skills/my-own-skill && printf -- '---\nname: my-own-skill\ndescription: mine\n---\n# mine\n' > .claude/skills/my-own-skill/SKILL.md
[ "$(ls .claude/skills | wc -l)" -gt 100 ] || { echo "standard install did not install the skills"; exit 1; }
ls .claude/agents | grep -q "clerk-architect" || { echo "identity agent set not installed"; exit 1; }
"$PIPELINE_ROOT/bin/install.sh" "$PWD" --profile minimal >/dev/null || { echo "minimal reinstall failed"; exit 1; }
[ -d .claude/skills/react-patterns ] && { echo "minimal reinstall left a standard-profile skill (react-patterns)"; exit 1; }
[ -d .claude/skills/work-order ] || { echo "minimal reinstall removed a lifecycle skill"; exit 1; }
[ -d .claude/skills/homelab-wireguard-vpn ] || { echo "minimal reinstall removed a skill set that is still selected in the config"; exit 1; }
[ -d .claude/skills/my-own-skill ] || { echo "user skill removed"; exit 1; }
python3 -c "import json,sys; d=json.load(open('.claude/settings.json')); sys.exit(1 if any('acp:' in h['command'] for v in d.get('hooks',{}).values() for g in v for h in g['hooks']) else 0)" || { echo "minimal reinstall left pipeline hooks"; exit 1; }
perl -pi -e 's/^export AGENT_SETS=.*/export AGENT_SETS=""/; s/^export SKILL_SETS=.*/export SKILL_SETS=""/' pipeline.config.sh
"$PIPELINE_ROOT/bin/install.sh" "$PWD" >/dev/null
ls .claude/agents | grep -q "clerk-architect" && { echo "identity agents not removed after deselecting the set"; exit 1; }
[ -d .claude/skills/homelab-wireguard-vpn ] && { echo "network skills not removed after deselecting the set"; exit 1; }
exit 0
