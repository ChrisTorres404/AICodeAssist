#!/usr/bin/env python3
"""
wo-reference — traceability check, in two forms.

  * PreToolUse hook for Bash: reads the tool payload on stdin, looks at the
    command about to run, and reports before the commit happens.
  * git commit-msg hook: invoked by git as `wo-reference.py <file> [source]`,
    it reads the message file git is about to record, no matter how the author
    supplied it: -m, -F, an editor, or a here-document. Cleanup modes vary and
    are set from a command line the hook cannot see, so it reads the authored
    text as written, comment lines included.

Two different rules, deliberately:

  A commit that names no work order may be perfectly correct — tooling, docs,
  a chore — so that stays advisory. A commit that names a work order or bug
  which does not exist is a plain factual error: it reads as traceable and
  leads nowhere. That one is refused, in both forms, under every profile.
  ACP_WO_REFERENCE=warn downgrades it for people who need the escape hatch.
"""
import json, os, re, subprocess, sys

REF = re.compile(r"\b(WO-\d{3,}|BUG-\d{3,})\b")


def git_root():
    try:
        return subprocess.run(["git", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def dirs_from_config(root):
    wod, bugd = "Workspace/Docs/WorkOrders", "Workspace/Docs/Bugs"
    cfg = os.path.join(root, "pipeline.config.sh")
    if os.path.isfile(cfg):
        for line in open(cfg, errors="ignore"):
            if line.startswith("export WORKORDERS_DIR="): wod = line.split("=", 1)[1].strip().strip('"')
            elif line.startswith("export BUGS_DIR="): bugd = line.split("=", 1)[1].strip().strip('"')
    return wod, bugd


def existing_ids(root, subdir, prefix):
    """The identifiers that actually have a folder. A commit may reference work
    that was never opened; that is how a trail of four commits can cite three
    work orders none of which exist."""
    out = set()
    d = os.path.join(root, subdir)
    if os.path.isdir(d):
        for name in os.listdir(d):
            m = re.match(prefix + r"-(\d{3,})", name)
            if m: out.add(f"{prefix}-{m.group(1)}")
    return out


def phantom_refs(text):
    """Which of the identifiers this text cites have no folder. Empty when the
    text cites nothing, when there is no repository, or when all of them exist."""
    refs = set(REF.findall(text))
    if not refs: return []
    root = git_root()
    if not root: return []
    wod, bugd = dirs_from_config(root)
    known = existing_ids(root, wod, "WO") | existing_ids(root, bugd, "BUG")
    return sorted(r for r in refs if r not in known)


def report_phantoms(missing):
    print(f"Traceability — this commit cites {', '.join(missing)}, which does not exist.\n"
          f"  A reference to a work order nobody opened is worse than no reference: it\n"
          f"  reads as traceable and leads nowhere. Open it ('wo new'), cite the one that\n"
          f"  really covers this change, or drop the reference.", file=sys.stderr)


def warn_only():
    return os.environ.get("ACP_WO_REFERENCE") == "warn"


def commit_msg_mode(path, source):
    # Git composes merge and squash messages itself; the author did not write them.
    if source in ("merge", "squash"): return 0
    try:
        text = open(path, errors="ignore").read()
    except Exception:
        return 0
    # Only the scissors section is dropped: git generates it and never records it,
    # and with --verbose it holds a diff that could mention any identifier.
    #
    # Comment lines are kept. Whether git strips them depends on the cleanup mode,
    # which `git commit --cleanup=verbatim` sets from a command line this hook never
    # sees, and under verbatim a commented-out citation is recorded verbatim. Rather
    # than guess at the mode and be wrong in the direction that lets a phantom
    # through, a citation anywhere in the authored message counts as a citation.
    marker = "------------------------ >8 ------------------------"
    for line in text.splitlines():
        if marker in line:
            text = text.split(line)[0]
            break
    missing = phantom_refs(text)
    if not missing: return 0
    report_phantoms(missing)
    return 0 if warn_only() else 1


def tool_hook_mode():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if "git commit" not in cmd:
        return 0
    # The message may not be in the command at all: -F, --file and an editor all
    # put it elsewhere. The commit-msg hook is what covers those; here we only
    # speak up about what is visible, and stay quiet rather than guess.
    if REF.search(cmd):
        missing = phantom_refs(cmd)
        if missing:
            report_phantoms(missing)
            return 0 if warn_only() else 2
        return 0
    if re.search(r"-F\b|--file\b|--template\b|-c\s|-C\s|--amend|--no-edit|--fixup|--squash\b", cmd):
        return 0
    print(
        "Traceability — this commit message names no WO-#### or BUG-####.\n"
        "  If this change belongs to a work order or bug, reference it so the\n"
        "  change can be traced back to its specification. If it is genuinely\n"
        "  standalone (tooling, docs, chore), proceed.",
        file=sys.stderr)
    return 0


def main():
    if len(sys.argv) > 1:
        return commit_msg_mode(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
    return tool_hook_mode()


if __name__ == "__main__":
    sys.exit(main())
