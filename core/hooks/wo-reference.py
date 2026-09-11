#!/usr/bin/env python3
"""
wo-reference — PreToolUse hook for Bash.

Traceability rule: a commit that changes code should name the work order or bug
it belongs to. This does not block the commit; it surfaces the omission while
the message can still be amended.
"""
import json, re, sys

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if "git commit" not in cmd:
        return 0
    if re.search(r"\b(WO-\d{3,}|BUG-\d{3,})\b", cmd):
        return 0
    if re.search(r"--amend|-C\s|--no-edit|--fixup", cmd):
        return 0
    print(
        "Traceability — this commit message names no WO-#### or BUG-####.\n"
        "  If this change belongs to a work order or bug, reference it so the\n"
        "  change can be traced back to its specification. If it is genuinely\n"
        "  standalone (tooling, docs, chore), proceed.",
        file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())
