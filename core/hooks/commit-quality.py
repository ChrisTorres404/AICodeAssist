#!/usr/bin/env python3
"""
commit-quality — PreToolUse hook for Bash, on `git commit`.

Before a commit lands: scans the staged content for debug logging, stubs, and
credentials, and runs the project's linter on staged files when one exists.
Credentials block; the rest warns (blocks in strict).
"""
import json, os, re, shutil, subprocess, sys

DEBUG = re.compile(r"^\+.*(\bconsole\.log\s*\(|\bdebugger\b|\bTODO:?\s*implement\b|Not implemented|\bbinding\.pry\b|\bpdb\.set_trace\(\)|\bbreakpoint\(\))")
SECRET = re.compile(r"^\+.*("
                    r"AKIA[0-9A-Z]{16}|[sr]k_(live|test)_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z\-_]{35}"
                    r"|\b(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp|mssql)://[^:\s'\"]+:[^@\s'\"]{4,}@"
                    r"|(?i:[a-z0-9_]*(secret|api[_-]?key|access[_-]?key|private[_-]?key|auth[_-]?token|password|passwd)[a-z0-9_]*\s*[:=]\s*['\"][A-Za-z0-9+/=_\-]{16,}['\"])"
                    r")")
SRC = re.compile(r"\.(ts|tsx|js|jsx|mjs|py|go|rb|java|kt|rs|php|cs|swift)$")
TEST = re.compile(r"(^|/)(test|tests|__tests__|spec)/|\.(test|spec)\.")

def sh(*a):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=20).stdout
    except Exception: return ""

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if not re.search(r"\bgit\s+commit\b", cmd) or "--amend" in cmd and "-m" not in cmd: return 0
    staged = [f for f in sh("git", "diff", "--cached", "--name-only").splitlines() if f]
    if not staged: return 0
    diff = sh("git", "diff", "--cached", "--unified=0")
    debug, secrets, cur = [], [], ""
    for line in diff.splitlines():
        if line.startswith("+++ b/"): cur = line[6:]; continue
        if not cur or not SRC.search(cur): continue
        if SECRET.search(line): secrets.append(f"{cur}: {line[1:80].strip()}…")
        elif DEBUG.search(line) and not TEST.search(cur): debug.append(f"{cur}: {line[1:80].strip()}")
    lint_out = ""
    if any(f.endswith((".ts", ".tsx", ".js", ".jsx")) for f in staged) and os.path.exists("node_modules/.bin/eslint"):
        files = [f for f in staged if f.endswith((".ts", ".tsx", ".js", ".jsx")) and os.path.exists(f)]
        if files: lint_out = subprocess.run(["node_modules/.bin/eslint", "--max-warnings", "0", *files], capture_output=True, text=True).stdout.strip()
    elif any(f.endswith(".py") for f in staged):
        files = [f for f in staged if f.endswith(".py") and os.path.exists(f)]
        if files and shutil.which("ruff") and (os.path.exists(".ruff.toml") or os.path.exists("ruff.toml") or os.path.exists("pyproject.toml")):
            try:
                r = subprocess.run(["ruff", "check", *files], capture_output=True, text=True, timeout=60); lint_out = r.stdout.strip() if r.returncode else ""
            except Exception: lint_out = ""
    if not (debug or secrets or lint_out): return 0
    out = []
    if secrets: out += ["Commit blocked — credential-like values in staged changes:"] + [f"  {s}" for s in secrets[:5]]
    if debug: out += ["Debug logging or stubs in staged source:"] + [f"  {d}" for d in debug[:10]]
    if lint_out: out += ["Linter findings on staged files:"] + [f"  {l}" for l in lint_out.splitlines()[:15]]
    print("\n".join(out), file=sys.stderr)
    return 2 if secrets or (debug and os.environ.get("ACP_STRICT") == "1") else 0

if __name__ == "__main__": sys.exit(main())
