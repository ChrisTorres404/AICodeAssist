#!/usr/bin/env python3
"""
evidence-gate — Stop hook. Deterministic checks only, no inference.

1. Any work order or bug folder touched in this working tree that has a
   CLOSEOUT must also have a VERIFICATION document containing an EXECUTED
   status line. A closeout resting on "NOT EXECUTED — PLAN ONLY" is a claim
   without evidence.
2. Modified source files must not contain debug logging.

Advisory in the standard profile. Blocking (exit 2) in strict, or when
ACP_EVIDENCE_GATE=block.
"""
import os, re, subprocess, sys

SRC_EXT = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".py", ".go", ".rb", ".java", ".kt", ".rs", ".php", ".cs", ".swift"}
DEBUG = re.compile(r"\bconsole\.log\s*\(|\bdebugger\b|\bprint\s*\(.*\bDEBUG\b")

def sh(cmd):
    try: return subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
    except Exception: return ""

def latest_status(path):
    """PASS | FAIL | RUNNING | PLAN | none, read exactly the way the drivers read it.

    The '**Overall status:**' line is the authoritative answer; the run records
    below it are history. A document whose latest run failed still contains the
    word PASS further up, which is why this cannot be a search of the whole text.
    """
    try:
        text = open(path, errors="ignore").read()
    except OSError:
        return "none"
    m = re.search(r"^\*\*Overall status:\*\*(.*)$", text, re.M)
    if not m: return "none"
    line = m.group(1)
    if "RUNNING" in line: return "RUNNING"
    if re.search(r"EXECUTED\s*[—–-]+\s*PASS", line): return "PASS"
    if re.search(r"EXECUTED\s*[—–-]+\s*FAIL", line): return "FAIL"
    if "PRECONDITION" in line: return "PRECOND"
    if "NOT EXECUTED" in line: return "PLAN"
    return "none"


def main():
    root = sh(["git", "rev-parse", "--show-toplevel"]).strip()
    if not root: return 0
    changed = [l[3:].strip() for l in sh(["git", "-C", root, "status", "--porcelain", "-uall"]).splitlines() if l.strip()]
    changed = [c for c in changed if "/packs/" not in f"/{c}"]   # promoted copies are archives, not work in progress
    changed = [c.split(" -> ")[-1] for c in changed]
    problems, warnings = [], []

    # 1. closeout without executed evidence
    folders = set()
    for c in changed:
        m = re.search(r"(^|/)((WO|BUG)-\d{3,}-[^/]+)(/|$)", c)
        if m:
            folders.add(os.path.join(root, c[: m.end(2)]))
    for d in sorted(folders):
        if not os.path.isdir(d): continue
        names = os.listdir(d)
        has_close = any("CLOSEOUT" in n.upper() for n in names)
        if not has_close: continue
        ver = [n for n in names if "VERIFICATION" in n.upper()]
        if not ver:
            problems.append(f"{os.path.relpath(d, root)}: CLOSEOUT present, no VERIFICATION document"); continue
        # The drivers read one authoritative line and so does this. Searching the
        # whole document for any PASS-or-FAIL accepted a closeout whose latest run
        # had failed, because an older passing run was still in the history.
        rel = os.path.relpath(d, root)
        statuses = [latest_status(os.path.join(d, v)) for v in sorted(ver)]
        st = next((x for x in statuses if x != "none"), "none")
        if st == "PASS":
            pass
        elif st == "FAIL":
            problems.append(f"{rel}: the latest verification run is EXECUTED — FAIL")
        elif st == "RUNNING":
            problems.append(f"{rel}: the last verification never finished; an interrupted run is not a result")
        elif st == "PRECOND":
            problems.append(f"{rel}: the last verification could not run (a precondition failed); nothing was asserted")
        elif st == "PLAN":
            problems.append(f"{rel}: VERIFICATION is NOT EXECUTED — PLAN ONLY")
        else:
            problems.append(f"{rel}: VERIFICATION has no authoritative '**Overall status:**' line")

    # 2. debug logging in modified source
    for c in changed:
        p = os.path.join(root, c)
        if os.path.splitext(c)[1] not in SRC_EXT or not os.path.isfile(p): continue
        if re.search(r"(^|/)(test|tests|__tests__|spec|scripts)/|\.(test|spec)\.", c): continue
        try:
            for n, line in enumerate(open(p, errors="ignore"), 1):
                if DEBUG.search(line) and not line.lstrip().startswith(("//", "#", "*")):
                    warnings.append(f"{c}:{n}: debug logging"); break
        except OSError: pass

    if not problems and not warnings: return 0
    out = []
    if problems:
        out.append("Evidence gate — a closeout is resting on verification that does not support it:")
        out += [f"  {p}" for p in problems]
        out.append("  Run the tests, record EXECUTED — PASS/FAIL with output, then close.")
    if warnings:
        out.append("Debug logging left in modified source:")
        out += [f"  {w}" for w in warnings[:10]]
    print("\n".join(out), file=sys.stderr)
    block = problems and (os.environ.get("ACP_STRICT") == "1" or os.environ.get("ACP_EVIDENCE_GATE") == "block")
    return 2 if block else 0

if __name__ == "__main__": sys.exit(main())
