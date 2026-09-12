#!/usr/bin/env python3
"""
doc-claims-check — PostToolUse hook for Edit/Write on markdown documents.

Generated documentation has two failure modes the pipeline refuses to take on
faith: claims that trace to nothing, and claims stated more strongly than the
source supports. This hook checks both mechanically:

  1. every `<!-- SOURCE: path:L12 -->` traceability comment must point at a
     file that exists (paths are absolute or relative to the git root);
  2. over-claim language outside code blocks (never, always, impossible,
     guarantees, "there is no way", "100%") is reported with the safer form.

Only documents that carry the pipeline's frontmatter (`wo:` or `status:`) or a
SOURCE comment are checked, so ordinary READMEs are left alone. Advisory in the
standard profile; blocking in strict (or ACP_DOC_CLAIMS=block).
"""
import json, os, re, subprocess, sys

SOURCE_RX = re.compile(r"<!--\s*SOURCE:\s*([^\s:>]+)(?::L?(\d+)(?:-L?\d+)?)?[^>]*-->")
OVERCLAIM = [
    (re.compile(r"\b(never|always|impossible|cannot be|can't be)\b", re.I), "state the mechanism: \"by design, X prevents...\" / \"under normal operation...\""),
    (re.compile(r"\bguarantee[sd]?\b", re.I), "say \"enforces\", \"validates\", or \"ensures\""),
    (re.compile(r"\bthere is no way\b|\b100%\b|\bfully secure\b|\bcompletely secure\b", re.I), "name what the architecture prevents and what it does not"),
]

def git_root(path):
    try:
        return subprocess.run(["git", "-C", os.path.dirname(os.path.abspath(path)) or ".", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""

def strip_code(text):
    return re.sub(r"```.*?```", "", text, flags=re.S)


def edited_text(ti):
    """The text this tool call writes: Write content, Edit new_string, or every MultiEdit new_string."""
    if ti.get("content"): return ti["content"]
    if ti.get("new_string"): return ti["new_string"]
    edits = ti.get("edits") or []
    return "\n".join(e.get("new_string", "") for e in edits if isinstance(e, dict))

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    ti = payload.get("tool_input") or {}
    path = ti.get("file_path") or ""
    if not path.endswith((".md", ".mdx")): return 0
    text = edited_text(ti)
    if not text: return 0
    head = text[:600]
    is_doc = bool(re.search(r"(?m)^(wo|status):", head)) or "<!-- SOURCE:" in text
    if not is_doc: return 0
    root = git_root(path)
    problems, warnings = [], []
    seen = set()
    for m in SOURCE_RX.finditer(text):
        ref, line_no = m.group(1), m.group(2)
        key = (ref, line_no)
        if key in seen: continue
        seen.add(key)
        candidates = [ref] if os.path.isabs(ref) else [os.path.join(root, ref) if root else ref, os.path.join(os.path.dirname(os.path.abspath(path)), ref)]
        found = next((c for c in candidates if os.path.isfile(c)), None)
        if not found:
            problems.append(f"SOURCE points at a file that does not exist: {ref}"); continue
        if line_no:
            try: n_lines = sum(1 for _ in open(found, encoding="utf-8", errors="ignore"))
            except OSError: n_lines = None
            if n_lines is not None and int(line_no) > n_lines:
                problems.append(f"SOURCE line does not exist: {ref}:L{line_no} (file has {n_lines} lines)")
    body = strip_code(text)
    for n, line in enumerate(body.splitlines(), 1):
        if line.lstrip().startswith(("<!--", "|", "#")) and "SOURCE" in line: continue
        for rx, fix in OVERCLAIM:
            mm = rx.search(line)
            if mm:
                warnings.append(f"line {n}: \"{mm.group(0)}\" — {fix}")
                break
    if not problems and not warnings: return 0
    out = [f"Documentation claims check — {os.path.basename(path)}:"]
    out += [f"  {p}" for p in problems[:10]]
    out += [f"  over-claim {w}" for w in warnings[:8]]
    if problems: out.append("  A claim that traces to nothing is omitted, not invented (core/rules/common/documentation.md).")
    print("\n".join(out), file=sys.stderr)
    strict = os.environ.get("ACP_STRICT") == "1" or os.environ.get("ACP_DOC_CLAIMS") == "block"
    return 2 if (problems and strict) else 0

if __name__ == "__main__": sys.exit(main())
