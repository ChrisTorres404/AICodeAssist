#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# agent-normalize.sh — bring the agent fleet in line with how Claude Code
# actually dispatches subagents.
#
# The fleet was written for an earlier tool that matched agents on declared
# file patterns and contexts. Claude Code does not read those; it selects an
# agent from its `description`. This script:
#
#   1. removes the dead "## Activation Triggers" section
#   2. folds its trigger content into the description when the description
#      does not already say when to use the agent
#   3. pins a model tier (dated ids rot; `sonnet` tracks the current release)
#   4. marks "## Project-Specific Rules" as the overlay zone
#
# Re-runnable and idempotent.
# ---------------------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
files = sorted((root/"core/agents/base").glob("*.md")) + sorted((root/"core/agents/roles").glob("*.md"))
files = [f for f in files if f.name != "README.md"]
stripped = folded = remodeled = marked = 0

for f in files:
    s = f.read_text()

    # --- capture the trigger block before removing it -------------------
    m = re.search(r"^## Activation Triggers\n(.*?)(?=^## )", s, re.S | re.M)
    triggers = ""
    if m:
        body = m.group(1)
        ctx = re.search(r"\*\*(?:Triggers|Contexts):\*\*\s*(.+)", body)
        if ctx:
            triggers = re.sub(r"[`*]", "", ctx.group(1)).strip().rstrip(".")
        s = s[:m.start()] + s[m.end():]
        stripped += 1

    # --- description must say when to use the agent ---------------------
    dm = re.search(r"^description:\s*(.+)$", s, re.M)
    if dm and triggers:
        desc = dm.group(1).strip()
        if not re.search(r"\b(use |when |for any|proactive)", desc, re.I):
            desc = desc.rstrip(".") + f". Use for {triggers}."
            s = s[:dm.start(1)] + desc + s[dm.end(1):]
            folded += 1

    # --- pin a model tier instead of a dated id -------------------------
    s2 = re.sub(r"^model:\s*claude-sonnet-[\d-]+$", "model: sonnet", s, flags=re.M)
    if s2 != s:
        remodeled += 1; s = s2

    # --- flag the overlay zone -----------------------------------------
    if "## Project-Specific Rules" in s and "PROJECT OVERLAY" not in s:
        s = s.replace("## Project-Specific Rules",
            "## Project-Specific Rules\n\n> **PROJECT OVERLAY** — this section is replaced per project.\n"
            "> Put your own rules in `core/agents/overlays/`, not here: this file is\n"
            "> overwritten wholesale on the next `bin/install.sh`.", 1)
        marked += 1

    f.write_text(s)

print(f"  agents processed  : {len(files)}")
print(f"  dead sections gone: {stripped}")
print(f"  descriptions fixed: {folded}")
print(f"  model ids pinned  : {remodeled}")
print(f"  overlay zones kept: {marked}")
PY
