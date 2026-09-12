#!/usr/bin/env python3
"""
config-protection — PreToolUse hook for Edit/Write. Blocks changes to linter,
formatter, and compiler-strictness configuration that already exists. Agents
weaken these to make checks pass instead of fixing the code. Creating a new
config file is allowed; changing one is not, unless ACP_ALLOW_CONFIG_EDIT=1.
"""
import json, os, re, sys

PROTECTED = re.compile(r"(^|/)(\.eslintrc(\.[a-z]+)?|eslint\.config\.[cm]?js|\.prettierrc(\.[a-z]+)?|prettier\.config\.[cm]?js|biome\.jsonc?|ruff\.toml|\.ruff\.toml|mypy\.ini|\.flake8|pyrightconfig\.json|tsconfig(\.[a-z]+)?\.json|\.golangci\.ya?ml|rustfmt\.toml|clippy\.toml|\.rubocop\.yml|phpstan\.neon|\.editorconfig)$")

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    ti = payload.get("tool_input") or {}
    f = ti.get("file_path", "")
    if not f or not os.path.exists(f): return 0
    if f.endswith(("pyproject.toml", "setup.cfg", "package.json")):
        # shared files: protect only the lint/format/strictness sections inside them
        touched = "\n".join([ti.get("old_string", ""), ti.get("new_string", ""), ti.get("content", "")] + [e.get("old_string", "") + e.get("new_string", "") for e in (ti.get("edits") or []) if isinstance(e, dict)])
        if not re.search(r"\[tool\.(ruff|mypy|black|pyright|pytest|flake8|isort|pylint)|\"(eslintConfig|prettier|jest)\"\s*:", touched): return 0
    elif not PROTECTED.search(f): return 0
    if os.environ.get("ACP_ALLOW_CONFIG_EDIT") == "1": return 0
    print(f"Blocked: {os.path.basename(f)} is a lint, format, or strictness configuration.\n"
          "  Fix the code the check is complaining about instead of the check.\n"
          "  If the config genuinely needs to change, do it in its own commit with ACP_ALLOW_CONFIG_EDIT=1 and say why.", file=sys.stderr)
    return 2

if __name__ == "__main__": sys.exit(main())
