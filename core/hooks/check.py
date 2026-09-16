#!/usr/bin/env python3
"""
check — the pipeline's rules, run over a set of files, from anywhere.

The session hooks in this directory see one tool call at a time and only run
inside Claude Code. This runs the same rules over a list of paths and runs
under any agent, or none: `wo close` calls it on the work order's changes, a
git pre-commit hook calls it on the staged set, CI calls it on the pull
request, and the session hooks remain the early warning in Claude Code. One
implementation, several moments. The rule tables are imported from the hook
scripts so the two cannot drift apart.

Usage (normally through `acp check`):

  check.py --staged                  the git index
  check.py --since <ref>             git changes since a ref, plus untracked
  check.py --manifest <file>         files changed since a manifest was taken
  check.py --paths <p> [<p>...]      an explicit list
  check.py --root <dir>              project root (default: cwd)
  check.py --strict                  advisory findings block too

Exit 2 when something blocks, 0 otherwise. Findings go to stderr.

What blocks under every profile: credential-like values, a lint/format/type
configuration that was weakened, and a closeout resting on verification that is
not an executed pass. Debug logging, stubs, oversized UI files and untraceable
documentation claims warn, and block under --strict.
"""
import argparse, hashlib, importlib.util, os, re, subprocess, sys

# Loading the hook modules must not leave bytecode behind in an installed project.
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))


def load(name):
    """Import a sibling hook script as a module. Their names carry hyphens, so
    the ordinary import statement cannot reach them."""
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


quality = load("quality-gate")
commit = load("commit-quality")
config = load("config-protection")
uisize = load("ui-size-check")
docs = load("doc-claims-check")
evidence = load("evidence-gate")

SECRET_LINE = re.compile(commit.SECRET.pattern.replace(r"^\+.*(", "(", 1))
# The per-line fixture exemption comes from the hook too, so a line the commit hook
# lets through is not refused here, and a change to either spelling moves both.
ALLOW_SECRET = commit.ALLOW_SECRET
SECRET_EXT = set(quality.SOURCE_EXT) | {".env", ".json", ".yml", ".yaml", ".toml", ".ini", ".cfg", ".properties", ".sh"}
TEST = commit.TEST
# .claude holds the installed copies of the pipeline's agents, skills and workflows.
# They are the pipeline's own source, vendored into the project, exactly like the
# pipeline root the session hooks skip; the project did not write them.
SKIP_DIRS = {"node_modules", ".git", "__pycache__", ".venv", "venv", "dist", "build", ".next", ".turbo", "coverage", ".claude"}
# <pipeline>/core/hooks/check.py — two directories up is the installed pipeline.
PIPELINE_DIR = os.path.realpath(os.path.join(HERE, "..", ".."))


# --- the file set -----------------------------------------------------------

def sh(args, cwd):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=60).stdout
    except Exception:
        return ""


def from_git_status_lines(text):
    out = {}
    for line in text.splitlines():
        if not line.strip(): continue
        parts = line.split("\t")
        st = parts[0][:1]
        path = parts[-1]
        if st == "D": continue
        out[path] = "A" if st == "A" else "M"
    return out


def staged(root):
    return from_git_status_lines(sh(["git", "diff", "--cached", "--name-status"], root))


def since(root, ref):
    files = from_git_status_lines(sh(["git", "diff", "--name-status", ref], root))
    for line in sh(["git", "ls-files", "-o", "--exclude-standard"], root).splitlines():
        if line.strip(): files[line.strip()] = "A"
    return files


def file_hash(path):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(65536), b""):
                h.update(chunk)
    except OSError:
        return ""
    return h.hexdigest()[:16]


def walk(root, exclude):
    """Every regular file under root, minus the pipeline's own state and the
    directories no rule should read. Mirrors the driver's fingerprint walk."""
    ex = [os.path.normpath(e) for e in exclude if e]
    for d, dirs, files in os.walk(root):
        rel = os.path.relpath(d, root)
        rel = "" if rel == "." else rel
        dirs[:] = [x for x in dirs if x not in SKIP_DIRS and os.path.normpath(os.path.join(rel, x)) not in ex]
        for f in files:
            p = os.path.join(rel, f) if rel else f
            if os.path.normpath(p) in ex: continue
            yield p


def read_manifest(path):
    out = {}
    try:
        for line in open(path, encoding="utf-8", errors="ignore"):
            line = line.rstrip("\n")
            if not line or line.startswith("#"): continue
            h, _, p = line.partition("\t")
            out[p] = h
    except OSError:
        pass
    return out


def write_manifest(root, path, exclude, only=None):
    """Snapshot the tree: one line per file, hash then path. Taken when a work
    order opens, so its changes can be named later with or without git."""
    with open(path, "w", encoding="utf-8") as f:
        f.write("# acp manifest: sha256[:16]\\tpath — files as they were when the work order opened\n")
        for p in sorted(walk(root, exclude)):
            if only and not any(p == o or p.startswith(o.rstrip("/") + "/") for o in only): continue
            f.write(f"{file_hash(os.path.join(root, p))}\t{p}\n")


def changed_since_manifest(root, manifest, exclude, only=None):
    before = read_manifest(manifest)
    out = {}
    for p in walk(root, exclude):
        if only and not any(p == o or p.startswith(o.rstrip("/") + "/") for o in only): continue
        h = file_hash(os.path.join(root, p))
        if p not in before: out[p] = "A"
        elif before[p] != h: out[p] = "M"
    return out


# --- the rules ---------------------------------------------------------------

def is_source(path):
    return os.path.splitext(path)[1] in quality.SOURCE_EXT


def check_secrets(root, files, blockers):
    for p, st in files.items():
        if os.path.splitext(p)[1] not in SECRET_EXT and not os.path.basename(p).startswith(".env"): continue
        try:
            for n, line in enumerate(open(os.path.join(root, p), encoding="utf-8", errors="ignore"), 1):
                if SECRET_LINE.search(line) and not ALLOW_SECRET.search(line):
                    blockers.append(f"{p}:{n}: credential-like value — rotate it, or if the line is a "
                                    f"fixture that must carry one, mark it 'acp:allow-secret' with a reason")
                    break
        except OSError:
            continue


def check_quality(root, files, warnings):
    for p, st in files.items():
        if not is_source(p) or TEST.search(p): continue
        try:
            lines = open(os.path.join(root, p), encoding="utf-8", errors="ignore").read().splitlines()
        except OSError:
            continue
        for n, line in enumerate(lines, 1):
            if line.lstrip().startswith(("//", "#", "*")) and "TODO" not in line and "FIXME" not in line: continue
            for rx, msg in quality.RULES:
                if rx.search(line):
                    warnings.append(f"{p}:{n}: {msg}")
                    break


def check_config(root, files, blockers):
    if os.environ.get("ACP_ALLOW_CONFIG_EDIT") == "1": return
    for p, st in files.items():
        if st != "M": continue          # creating a configuration is allowed; weakening one is not
        if config.PROTECTED.search(p):
            blockers.append(f"{p}: lint, format, or strictness configuration changed (ACP_ALLOW_CONFIG_EDIT=1 in its own commit, with a reason)")


def check_ui_size(root, files, warnings):
    for p in files:
        if not p.endswith(uisize.UI_EXT): continue
        if re.search(r"(^|/)(test|tests|__tests__|spec|stories)/|\.(test|spec|stories)\.", p): continue
        try: n = sum(1 for _ in open(os.path.join(root, p), encoding="utf-8", errors="ignore"))
        except OSError: continue
        for rx, limit, label in uisize.LIMITS:
            if rx.search(p):
                if n > limit: warnings.append(f"{p}: {n} lines; the UI rules cap a {label} at {limit}")
                break


def check_docs(root, files, warnings):
    for p in files:
        if not p.endswith((".md", ".mdx")): continue
        full = os.path.join(root, p)
        try: text = open(full, encoding="utf-8", errors="ignore").read()
        except OSError: continue
        if not (re.search(r"(?m)^(wo|status):", text[:600]) or "<!-- SOURCE:" in text): continue
        seen = set()
        for m in docs.SOURCE_RX.finditer(text):
            ref, line_no = m.group(1), m.group(2)
            if docs.PLACEHOLDER.search(ref) or (ref, line_no) in seen: continue
            seen.add((ref, line_no))
            cands = [ref] if os.path.isabs(ref) else [os.path.join(root, ref), os.path.join(os.path.dirname(full), ref)]
            found = next((c for c in cands if os.path.isfile(c)), None)
            if not found:
                warnings.append(f"{p}: SOURCE points at a file that does not exist: {ref}")


def check_evidence(root, files, blockers):
    """A closeout in the changed set must rest on an executed pass, read the way
    the drivers read it."""
    folders = set()
    for p in files:
        m = re.search(r"(^|/)((WO|BUG)-\d{3,}-[^/]+)(/|$)", p)
        if m: folders.add(p[: m.end(2)])
    for d in sorted(folders):
        full = os.path.join(root, d)
        if not os.path.isdir(full): continue
        names = os.listdir(full)
        if not any("CLOSEOUT" in n.upper() for n in names): continue
        ver = sorted(n for n in names if "VERIFICATION" in n.upper() and n.endswith(".md"))
        if not ver:
            blockers.append(f"{d}: CLOSEOUT present, no VERIFICATION document"); continue
        st = next((s for s in (evidence.latest_status(os.path.join(full, v)) for v in ver) if s != "none"), "none")
        if st == "PASS": continue
        why = {"FAIL": "the latest verification run failed", "RUNNING": "the last verification never finished",
               "PRECOND": "the last verification could not run (a precondition failed); nothing was asserted",
               "PLAN": "verification is NOT EXECUTED — PLAN ONLY"}.get(st, "VERIFICATION has no authoritative status line")
        blockers.append(f"{d}: CLOSEOUT present but {why}")


def check_kb(root, files, warnings, kb):
    """A change to a file a Feature Profile cites makes that profile a claim about
    code that no longer exists. The engine lives beside this script; when it is
    absent, or there is no knowledge base, there is nothing to say."""
    kb = kb or os.path.join(root, "Workspace", "Docs", "KnowledgeBase")
    engine = os.path.join(HERE, "kb.py")
    if not os.path.isdir(kb) or not os.path.isfile(engine) or not files: return
    try:
        r = subprocess.run([sys.executable, engine, "impact", "--root", root, "--kb", kb, "--stdin"],
                           input="\n".join(sorted(files)) + "\n", capture_output=True, text=True, timeout=60)
    except Exception:
        return
    if r.returncode == 1:
        for line in r.stdout.splitlines():
            if line.strip() and not line.startswith(("uncovered:", "impact:")) and "\t" in line:
                prof, cited = line.split("\t", 1)
                warnings.append(f"{prof}: describes changed code ({cited}); update it, then run acp kb bind")


# --- main ----------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(add_help=True)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--staged", action="store_true")
    g.add_argument("--since")
    g.add_argument("--manifest")
    g.add_argument("--paths", nargs="+")
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--exclude", nargs="*", default=[])
    ap.add_argument("--only", nargs="*", default=None, help="scope for manifest mode: paths the work order declared")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--kb", default=None, help="knowledge-base directory (default: Workspace/Docs/KnowledgeBase under root)")
    ap.add_argument("--no-kb", action="store_true", help="skip the knowledge-base rule (the drivers run their own at close)")
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument("--write-manifest", help="take a snapshot of the tree to this file and exit")
    ap.add_argument("--list", action="store_true", help="print the file set one path per line and exit; no rules run")
    a = ap.parse_args()
    # realpath, not abspath: on macOS the temp directory is a symlink, and a root
    # spelled one way with paths spelled the other resolves to nothing.
    root = os.path.realpath(a.root)

    if a.write_manifest:
        write_manifest(root, a.write_manifest, a.exclude, a.only)
        return 0

    if a.staged:
        files = staged(root); how = "the staged changes"
    elif a.since:
        files = since(root, a.since); how = f"changes since {a.since}"
    elif a.manifest:
        if not os.path.isfile(a.manifest):
            print(f"check: no manifest at {a.manifest}; nothing to compare against", file=sys.stderr); return 1
        files = changed_since_manifest(root, a.manifest, a.exclude, a.only); how = "changes since the work order opened"
    elif a.paths:
        files = {os.path.relpath(os.path.realpath(p), root): "M" for p in a.paths}; how = f"{len(a.paths)} named path(s)"
    else:
        if sh(["git", "rev-parse", "--show-toplevel"], root).strip():
            files = since(root, "HEAD"); how = "changes since HEAD"
        else:
            print("check: not a git repository; give --paths, --manifest, or --staged", file=sys.stderr); return 1

    files = {p: s for p, s in files.items() if os.path.isfile(os.path.join(root, p))}
    if a.list:
        for p in sorted(files): print(p)
        return 0
    # The excluded directories are excluded in every mode. The installed pipeline
    # carries example credentials and template configurations by design, and the
    # work-order folders are the pipeline's own state; a staged set that includes
    # them is not evidence of anything about the project.
    ex = [os.path.normpath(e) for e in a.exclude if e]
    # acp check names the pipeline root; a direct invocation does not, so derive it
    # the way the session hooks do and agree with them either way. Only when it sits
    # inside the project: a checkout of the pipeline itself is the project.
    if PIPELINE_DIR.startswith(root + os.sep):
        ex.append(os.path.normpath(os.path.relpath(PIPELINE_DIR, root)))
    def excluded(p):
        q = os.path.normpath(p)
        return any(q == e or q.startswith(e + os.sep) for e in ex) or any(part in SKIP_DIRS for part in q.split(os.sep))
    # The evidence rule is the exception: it is about the work-order folders, which
    # the other rules are told to skip. It sees everything that was named.
    evidence_files = dict(files)
    files = {p: s for p, s in files.items() if not excluded(p)}
    if not files and not evidence_files:
        if not a.quiet: print(f"check: nothing to check in {how}")
        return 0

    blockers, warnings = [], []
    check_secrets(root, files, blockers)
    check_config(root, files, blockers)
    check_evidence(root, evidence_files, blockers)
    check_quality(root, files, warnings)
    check_ui_size(root, files, warnings)
    check_docs(root, files, warnings)
    if not a.no_kb: check_kb(root, files, warnings, a.kb)

    strict = a.strict or os.environ.get("ACP_STRICT") == "1"
    if not blockers and not warnings:
        if not a.quiet: print(f"check: {len(evidence_files)} file(s) in {how}, nothing found")
        return 0
    out = [f"check — {how}, {len(files)} file(s):"]
    if blockers:
        out.append("  blocking:")
        out += [f"    {b}" for b in blockers[:20]]
    if warnings:
        out.append("  advisory:" if not strict else "  blocking under strict:")
        out += [f"    {w}" for w in warnings[:30]]
    print("\n".join(out), file=sys.stderr)
    return 2 if blockers or (strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
