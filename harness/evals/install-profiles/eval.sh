#!/usr/bin/env bash
set -euo pipefail
cd "$EVAL_TMP"
for p in minimal standard full; do "$PIPELINE_ROOT/bin/new-project" "$p" --name "$p" --no-git --profile "$p" >/dev/null; done
[ "$(ls minimal/.claude/skills | wc -l)" -le 6 ] || { echo "minimal has too many skills"; exit 1; }
grep -q '"hooks"' minimal/.claude/settings.json && { echo "minimal installed hooks"; exit 1; }
grep -q '"hooks"' standard/.claude/settings.json || { echo "standard missing hooks"; exit 1; }
[ "$(ls standard/.claude/skills | wc -l)" -gt 60 ] || { echo "standard missing skills"; exit 1; }
[ "$(ls full/.claude/agents | wc -l)" -gt "$(ls standard/.claude/agents | wc -l)" ] || { echo "full did not add the agent sets"; exit 1; }
[ -d full/.claude/skills/hipaa-compliance ] || { echo "full did not install the skill sets"; exit 1; }
[ -d standard/.claude/skills/hipaa-compliance ] && { echo "standard installed a skill set unasked"; exit 1; }
"$PIPELINE_ROOT/bin/new-project" oneset --name oneset --no-git --skill-set network >/dev/null
[ -d oneset/.claude/skills/homelab-wireguard-vpn ] || { echo "--skill-set network did not install"; exit 1; }
[ -d oneset/.claude/skills/hipaa-compliance ] && { echo "--skill-set network installed another set"; exit 1; }
exit 0
