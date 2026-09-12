#!/usr/bin/env python3
"""
pre-compact — PreCompact hook. Before context is compacted, writes a
deterministic orientation note so the continuation starts knowing what was in
flight: modified files, in-flight work orders, last commits. No model call.
"""
import datetime, json, os, subprocess, sys

def sh(*a):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception: return ""

def main():
    root = sh("git", "rev-parse", "--show-toplevel") or os.getcwd()
    sessions = None
    for cand in ("Workspace/Sessions/active", ".workspace/sessions/active"):
        if os.path.isdir(os.path.join(root, cand)): sessions = os.path.join(root, cand); break
    if not sessions:
        cfg = os.path.join(root, "pipeline.config.sh")
        if os.path.exists(cfg):
            for line in open(cfg):
                if line.startswith("export SESSIONS_DIR="):
                    sessions = os.path.join(root, line.split("=", 1)[1].strip().strip('"'), "active")
    if not sessions: return 0
    os.makedirs(sessions, exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y-%m-%d--%H%M")
    wo = ""
    for cand in (os.path.join(root, ".aicodepipeline", "bin", "wo"),):
        if os.path.exists(cand): wo = subprocess.run([cand, "list", "--active"], capture_output=True, text=True, cwd=root).stdout.strip()
    note = "\n".join([
        f"# Compaction note — {ts}", "",
        "Written automatically before context compaction. Read this first after resuming.", "",
        "## Modified files (uncommitted)", "```", sh("git", "-C", root, "status", "--short") or "(clean)", "```", "",
        "## In-flight work orders", "```", wo or "(none or driver not installed)", "```", "",
        "## Recent commits", "```", sh("git", "-C", root, "log", "--oneline", "-8") or "(none)", "```", "",
        "Next: run `wo status <n>` on the active work order and continue from its CHECKLIST.", ""])
    with open(os.path.join(sessions, f"compaction--{ts}.md"), "w") as f: f.write(note)
    print(f"Compaction note written to {os.path.relpath(sessions, root)}/compaction--{ts}.md", file=sys.stderr)
    return 0

if __name__ == "__main__": sys.exit(main())
