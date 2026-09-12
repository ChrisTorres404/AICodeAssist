#!/usr/bin/env python3
"""
quality-gate — PostToolUse hook for Edit/Write.

The methodology forbids debug logging, placeholder implementations, and
not-implemented stubs in committed code. Historically that was enforced by
asking the model to remember. This checks.

Non-blocking by design: it reports findings back into the transcript so they
get fixed in the same turn, rather than failing the edit. Set
ACP_QUALITY_GATE=block, or the strict hook profile, to make violations blocking.
"""
import json, os, re, sys

SOURCE_EXT = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".py", ".go",
              ".rb", ".java", ".kt", ".rs", ".php", ".cs", ".swift"}

RULES = [
    # debug output, per language — the project logger is always the answer
    (re.compile(r"\bconsole\.(log|debug)\s*\("),                         "console.log — use the project logger"),
    (re.compile(r"\bprint\s*\(.*\b(debug|here|xxx|test)\b", re.I),      "debug print — use the project logger"),
    (re.compile(r"\bfmt\.Print(ln|f)?\s*\("),                             "fmt.Print — use the project logger"),
    (re.compile(r"\b(println!|dbg!)\s*\("),                                "println!/dbg! — use tracing or log"),
    (re.compile(r"\bSystem\.(out|err)\.print(ln)?\s*\("),                 "System.out — use the project logger"),
    (re.compile(r"\bConsole\.Write(Line)?\s*\("),                          "Console.Write — use the project logger"),
    (re.compile(r"^\s*(puts|pp?)\s+"),                                       "puts/p — use the project logger"),
    (re.compile(r"\b(var_dump|print_r)\s*\("),                              "var_dump/print_r — use the project logger"),
    (re.compile(r"\bdebugPrint\s*\(|^\s*print\s*\(.*\);\s*$"),           "debug print — use the project logger"),
    # stubs and deferred work
    (re.compile(r"(//|#)\s*TODO:?\s*implement", re.I),                       "TODO: implement — finish it or do not ship it"),
    (re.compile(r"throw new (Error|NotImplementedException)\s*\(\s*['\"]not implemented", re.I), "not-implemented stub"),
    (re.compile(r"raise NotImplementedError|\btodo!\s*\(|\bunimplemented!\s*\(|panic\(\s*\"(not implemented|todo)|throw new NotImplementedException\(\)|UnsupportedOperationException\(\s*\"not implemented", re.I), "not-implemented stub"),
    (re.compile(r"\bFIXME\b"),                                               "FIXME left in source"),
]


def edited_text(ti):
    """The text this tool call writes: Write content, Edit new_string, or every MultiEdit new_string."""
    if ti.get("content"): return ti["content"]
    if ti.get("new_string"): return ti["new_string"]
    edits = ti.get("edits") or []
    return "\n".join(e.get("new_string", "") for e in edits if isinstance(e, dict))

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    ti = payload.get("tool_input") or {}
    path = ti.get("file_path") or ti.get("path") or ""
    if not path or os.path.splitext(path)[1] not in SOURCE_EXT:
        return 0
    if re.search(r"(^|/)(test|tests|__tests__|spec)/|\.(test|spec)\.", path):
        return 0          # test files may legitimately log and stub

    text = edited_text(ti)
    if not text:
        return 0

    found = []
    for n, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith(("//", "#", "*")) and "TODO" not in line and "FIXME" not in line:
            continue
        for rx, msg in RULES:
            if rx.search(line):
                found.append(f"  {os.path.basename(path)}:{n}  {msg}")
                break

    if not found:
        return 0

    head = f"Quality gate — {len(found)} issue(s) just written into {path}:"
    body = "\n".join(found[:12])
    tail = "\nThese violate the project's code-quality rules. Fix them now, in this turn."
    print(f"{head}\n{body}{tail}", file=sys.stderr)
    strict = os.environ.get("ACP_STRICT") == "1" or os.environ.get("ACP_QUALITY_GATE") == "block" \
        or os.environ.get("AICODEPIPELINE_QUALITY_GATE") == "block"
    return 2 if strict else 0

if __name__ == "__main__":
    sys.exit(main())
