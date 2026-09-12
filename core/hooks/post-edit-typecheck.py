#!/usr/bin/env python3
"""
post-edit-typecheck — PostToolUse hook for Edit/Write on TypeScript files.
Finds the nearest tsconfig, runs the project's own tsc, and reports only the
errors in the edited file. Advisory; the build-error-resolver fixes them.
"""
import json, os, subprocess, sys

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    f = (payload.get("tool_input") or {}).get("file_path", "")
    if not f.endswith((".ts", ".tsx")) or not os.path.isfile(f): return 0
    d = os.path.dirname(os.path.abspath(f)); cfg = None
    for _ in range(20):
        if os.path.exists(os.path.join(d, "tsconfig.json")): cfg = d; break
        nd = os.path.dirname(d)
        if nd == d: break
        d = nd
    if not cfg: return 0
    tsc = os.path.join(cfg, "node_modules", ".bin", "tsc")
    if not os.path.exists(tsc): tsc = "npx"; args = ["--no-install", "tsc"]
    else: args = []
    try: r = subprocess.run([tsc, *args, "--noEmit", "--pretty", "false", "-p", os.path.join(cfg, "tsconfig.json")], capture_output=True, text=True, timeout=120, cwd=cfg)
    except Exception: return 0
    rel = os.path.relpath(os.path.abspath(f), cfg)
    mine = [l for l in r.stdout.splitlines() if l.startswith(rel) or l.startswith("./" + rel)]
    if not mine: return 0
    print(f"Type errors in {rel} after this edit:\n" + "\n".join("  " + l for l in mine[:12]) + "\n  Fix them now, minimally; do not suppress.", file=sys.stderr)
    return 0

if __name__ == "__main__": sys.exit(main())
