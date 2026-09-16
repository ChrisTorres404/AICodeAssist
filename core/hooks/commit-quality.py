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

# A fixture has to be able to carry a credential-shaped string: a test that asserts
# the value is never rendered, a parser's sample input. Exempting test files
# wholesale would not do — a fixture is where a real credential hides best — so the
# exemption is per line, visible to every reader and to review.
ALLOW_SECRET = re.compile(r"acp:allow-secret")

# The installed pipeline is vendored into the project it serves, with this script at
# <pipeline>/core/hooks/. Its own rule tables quote the literals these rules look
# for, and its shipped scripts log to the console for real, so a scan that reads the
# pipeline reports the pipeline instead of the project — under strict, on every
# commit, forever. Same for the agent and skill copies under .claude/.
PIPELINE_DIR = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CLAUDE_DIR = re.compile(r"(^|/)\.claude/")


def vendored(path, base):
    """True when this path is the pipeline's own installed source rather than the
    project's code. Kept in step with the same rule in quality-gate.py and with the
    --exclude check.py derives; a change here belongs in all three.

    The pipeline root is skipped only when it sits inside the project. A checkout of
    the pipeline itself is the project, and skipping it there would switch the rule
    off in the one repository that must keep it on."""
    if CLAUDE_DIR.search(path): return True
    base = os.path.realpath(base)
    if base == PIPELINE_DIR: return False
    full = os.path.realpath(os.path.join(base, path))
    return full == PIPELINE_DIR or full.startswith(PIPELINE_DIR + os.sep)

def sh(*a):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=20).stdout
    except Exception: return ""

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if not re.search(r"\bgit\s+commit\b", cmd) or "--amend" in cmd and "-m" not in cmd: return 0
    # git names staged paths from the top level, so that is what they resolve against.
    base = os.path.realpath(sh("git", "rev-parse", "--show-toplevel").strip() or os.getcwd())
    staged = [f for f in sh("git", "diff", "--cached", "--name-only").splitlines() if f and not vendored(f, base)]
    if not staged: return 0
    diff = sh("git", "diff", "--cached", "--unified=0")
    debug, secrets, cur, skip = [], [], "", True
    for line in diff.splitlines():
        # decided once per file rather than once per line: a large diff would pay
        # for resolving the same path thousands of times
        if line.startswith("+++ b/"): cur = line[6:]; skip = not SRC.search(cur) or vendored(cur, base); continue
        if not cur or skip: continue
        if SECRET.search(line) and not ALLOW_SECRET.search(line): secrets.append(f"{cur}: {line[1:80].strip()}…")
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
    if secrets: out += ["Commit blocked — credential-like values in staged changes:"] + [f"  {s}" for s in secrets[:5]] + [
        "  Rotate the value and take it out of the change. If the line is a fixture that",
        "  has to carry a credential-shaped string, mark that line and say why:",
        "    // acp:allow-secret — fixture, asserted never to be emitted"]
    if debug: out += ["Debug logging or stubs in staged source:"] + [f"  {d}" for d in debug[:10]]
    if lint_out: out += ["Linter findings on staged files:"] + [f"  {l}" for l in lint_out.splitlines()[:15]]
    print("\n".join(out), file=sys.stderr)
    return 2 if secrets or (debug and os.environ.get("ACP_STRICT") == "1") else 0

if __name__ == "__main__": sys.exit(main())
