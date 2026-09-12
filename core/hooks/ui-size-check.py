#!/usr/bin/env python3
"""
ui-size-check — PostToolUse hook for Edit/Write on UI files. Enforces the
line limits the UI rules declare as mechanical: page 150, component 200,
modal or dialog 50, form 80, table 100. Advisory in the standard profile;
blocking in strict (or ACP_UI_SIZE=block).
"""
import json, os, re, sys
UI_EXT = (".tsx", ".jsx", ".vue", ".svelte")
LIMITS = [  # (path/name pattern, limit, label) — first match wins
    (re.compile(r"(^|/)(dialogs?|modals?)/|(Dialog|Modal)\.(tsx|jsx|vue|svelte)$"), 50, "modal/dialog"),
    (re.compile(r"(^|/)forms?/|Form\.(tsx|jsx|vue|svelte)$"), 80, "form"),
    (re.compile(r"(^|/)tables?/|Table\.(tsx|jsx|vue|svelte)$"), 100, "table"),
    (re.compile(r"(^|/)(pages?|app|routes?|views?)/|Page\.(tsx|jsx|vue|svelte)$|(^|/)page\.(tsx|jsx)$"), 150, "page"),
    (re.compile(r"(^|/)components?/|\.(tsx|jsx|vue|svelte)$"), 200, "component"),
]

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    f = (payload.get("tool_input") or {}).get("file_path", "")
    if not f.endswith(UI_EXT) or not os.path.isfile(f): return 0
    if re.search(r"(^|/)(test|tests|__tests__|spec|stories)/|\.(test|spec|stories)\.", f): return 0
    try: n = sum(1 for _ in open(f, encoding="utf-8", errors="ignore"))
    except OSError: return 0
    for rx, limit, label in LIMITS:
        if rx.search(f):
            if n <= limit: return 0
            print(f"{os.path.basename(f)} is {n} lines; the UI rules cap a {label} at {limit}.\n"
                  f"  Split it: extract sub-components or hooks into the feature's components/ and hooks/ directories.", file=sys.stderr)
            strict = os.environ.get("ACP_STRICT") == "1" or os.environ.get("ACP_UI_SIZE") == "block"
            return 2 if strict else 0
    return 0

if __name__ == "__main__": sys.exit(main())
