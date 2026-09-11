#!/usr/bin/env python3
"""
rule-hook — evaluate markdown-defined hook rules against a tool call.

Rules are small files with YAML-ish frontmatter and a message body:

    ---
    name: block-force-push-main
    enabled: true
    event: bash            # bash | file | all
    pattern: git push .*--force.*(main|master)
    action: block          # warn (default) | block
    ---
    Force-pushing a shared branch rewrites history for everyone.

Rule files are read from <pipeline>/core/hooks/rules/ and from the project's
.claude/hook-rules/. Add a project rule by dropping a file in the latter; no
JSON, no code. Called as a PreToolUse hook for Bash and Edit/Write.
"""
import json, os, re, sys

def find_up(start, name):
    d = start
    while True:
        if os.path.isfile(os.path.join(d, name)): return d
        nd = os.path.dirname(d)
        if nd == d: return None
        d = nd

def load_rules():
    here = os.path.dirname(os.path.abspath(__file__))
    dirs = [os.path.join(here, "rules")]
    proj = find_up(os.getcwd(), "pipeline.config.sh") or find_up(os.getcwd(), ".claude")
    if proj: dirs.append(os.path.join(proj, ".claude", "hook-rules"))
    rules = []
    for d in dirs:
        if not os.path.isdir(d): continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".md"): continue
            try: text = open(os.path.join(d, fn)).read()
            except OSError: continue
            m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
            if not m: continue
            fm = {}
            for line in m.group(1).splitlines():
                if ":" in line:
                    k, v = line.split(":", 1); fm[k.strip()] = v.strip().strip('"').strip("'")
            if fm.get("enabled", "true").lower() not in ("true", "yes", "1"): continue
            if not fm.get("pattern"): continue
            try: rx = re.compile(fm["pattern"], re.I)
            except re.error: continue
            rules.append({"name": fm.get("name", fn[:-3]), "event": fm.get("event", "all"),
                          "rx": rx, "action": fm.get("action", "warn").lower(), "msg": m.group(2).strip()})
    return rules

def main():
    try: payload = json.load(sys.stdin)
    except Exception: return 0
    tool = payload.get("tool_name", ""); ti = payload.get("tool_input") or {}
    if tool == "Bash":
        event, subject = "bash", ti.get("command", "")
    elif tool in ("Edit", "Write", "MultiEdit"):
        event = "file"
        subject = "\n".join(str(ti.get(k, "")) for k in ("file_path", "content", "new_string"))
    else:
        return 0
    if not subject: return 0
    block, msgs = False, []
    for r in load_rules():
        if r["event"] not in ("all", event): continue
        if r["rx"].search(subject):
            msgs.append(f"[{r['name']}] {r['msg']}")
            block = block or r["action"] == "block"
    if not msgs: return 0
    print("\n".join(msgs), file=sys.stderr)
    return 2 if block else 0

if __name__ == "__main__": sys.exit(main())
