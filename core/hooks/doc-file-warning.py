#!/usr/bin/env python3
"""
doc-file-warning — PreToolUse hook for Write. Warns when an ad-hoc scratch
document (NOTES.md, TODO.md, SCRATCH.txt…) is about to be created outside a
documentation directory. Work belongs in a work order, not a loose file.
"""
import json, os, re, sys
ADHOC = re.compile(r"^(NOTES|TODO|SCRATCH|TEMP|DRAFT|BRAINSTORM|SPIKE|DEBUG|WIP|SUMMARY|PLAN|IDEAS)\.(md|txt)$", re.I)
STRUCTURED = re.compile(r"(^|/)(docs|Workspace|\.claude|\.aicodepipeline|\.github|templates|memory)/")

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    f = (payload.get("tool_input") or {}).get("file_path", "")
    if not f or not ADHOC.search(os.path.basename(f)) or STRUCTURED.search(f) or os.path.exists(f): return 0
    print(f"{os.path.basename(f)} looks like a scratch file. Notes belong on the work order (`wo note`), plans in its SPEC, and handoffs in the sessions directory. Loose files at the root get lost.", file=sys.stderr)
    return 0

if __name__ == "__main__": sys.exit(main())
