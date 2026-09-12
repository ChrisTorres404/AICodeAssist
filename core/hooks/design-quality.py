#!/usr/bin/env python3
"""
design-quality — PostToolUse hook for Edit/Write on frontend files. Flags the
generic-UI drift the UI rules and production lessons warn about: hard-coded
colours instead of design-system tokens, transition-all, inline styles, icon
buttons with no accessible name, missing empty states on data components.
Advisory only.
"""
import json, os, re, sys
FRONTEND = re.compile(r"\.(tsx|jsx|vue|svelte|astro|css|scss|html)$")
SIGNALS = [
    (re.compile(r"\b(bg|text|border)-(white|black|gray|slate|zinc|neutral|stone|red|blue|green|yellow)-\d{2,3}\b"), "hard-coded colour class; use the design system's semantic tokens (bg-card, text-foreground, border-border) so dark mode works"),
    (re.compile(r"\btransition-all\b"), "transition-all animates properties you did not intend; name the properties"),
    (re.compile(r"style=\{\{|style=\"[^\"]*(color|background|margin|padding)"), "inline style; use the design system or a class"),
    (re.compile(r"<button[^>]*>\s*<(svg|Icon|[A-Z]\w*Icon)\b(?![^<]*aria-)"), "icon-only button with no accessible name; add aria-label"),
    (re.compile(r"\.map\(\s*\(?\w+\)?\s*=>\s*<"), "a rendered list; confirm the empty state is designed (what if there is no data?)"),
    (re.compile(r"toLocale(Date|Time)?String\("), "ad-hoc date formatting; use the shared date utility with the project's timezone policy"),
]


def edited_text(ti):
    """The text this tool call writes: Write content, Edit new_string, or every MultiEdit new_string."""
    if ti.get("content"): return ti["content"]
    if ti.get("new_string"): return ti["new_string"]
    edits = ti.get("edits") or []
    return "\n".join(e.get("new_string", "") for e in edits if isinstance(e, dict))

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    ti = payload.get("tool_input") or {}; f = ti.get("file_path", "")
    if not FRONTEND.search(f): return 0
    text = edited_text(ti)
    if not text: return 0
    hits = []
    for rx, msg in SIGNALS:
        m = rx.search(text)
        if m: hits.append(f"  `{m.group(0)[:40]}` — {msg}")
    if not hits: return 0
    print(f"Design check on {os.path.basename(f)}:\n" + "\n".join(hits[:6]) + "\n  See the installed UI rules for the standards these come from.", file=sys.stderr)
    return 0

if __name__ == "__main__": sys.exit(main())
