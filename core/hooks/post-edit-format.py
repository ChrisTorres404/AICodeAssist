#!/usr/bin/env python3
"""
post-edit-format — PostToolUse hook for Edit/Write. Formats the edited file
with the project's own formatter when one is configured. Silent otherwise.
Never installs anything; never formats files outside the repository.
"""
import json, os, subprocess, sys

def exists(*names): return any(os.path.exists(n) for n in names)

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    f = (payload.get("tool_input") or {}).get("file_path", "")
    if not f or not os.path.isfile(f): return 0
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
    if root and not os.path.abspath(f).startswith(root): return 0
    ext = os.path.splitext(f)[1]
    cmd = None
    if ext in (".ts", ".tsx", ".js", ".jsx", ".mjs", ".json", ".css", ".md"):
        if exists("biome.json", "biome.jsonc") and os.path.exists("node_modules/.bin/biome"): cmd = ["node_modules/.bin/biome", "format", "--write", f]
        elif exists(".prettierrc", ".prettierrc.json", ".prettierrc.js", ".prettierrc.cjs", "prettier.config.js", "prettier.config.mjs") and os.path.exists("node_modules/.bin/prettier"): cmd = ["node_modules/.bin/prettier", "--write", "--log-level", "silent", f]
    elif ext == ".py" and exists("ruff.toml", ".ruff.toml", "pyproject.toml"): cmd = ["ruff", "format", "-q", f]
    elif ext == ".go": cmd = ["gofmt", "-w", f]
    elif ext == ".rs" and exists("Cargo.toml"): cmd = ["rustfmt", "--edition", "2021", f]
    if not cmd: return 0
    try: subprocess.run(cmd, capture_output=True, timeout=30)
    except Exception: pass
    return 0

if __name__ == "__main__": sys.exit(main())
