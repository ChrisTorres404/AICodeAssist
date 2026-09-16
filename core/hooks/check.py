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
  check.py --types                   also type-check (slow; off by default)

Exit 2 when something blocks, 0 otherwise. Findings go to stderr.

Strict is --strict, ACP_STRICT=1, or ACP_HOOK_PROFILE=strict. The last is there
because the git hooks are shims that exec this directly and never pass through
run-hook.sh, so without it a project running the strict profile would be strict
in a Claude Code session and merely advisory at commit time.

What blocks under every profile: credential-like values, a lint/format/type
configuration that was weakened, and a closeout resting on verification that is
not an executed pass. Debug logging, stubs, oversized UI files, untraceable
documentation claims, generic-UI drift, and files the project's own formatter
would rewrite warn, and block under --strict. Type errors are asked for
(--types, or ACP_CHECK_TYPES=1) and then warn, and block under --strict: a
whole-project type-check is too slow to put on every commit unasked.
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
design = load("design-quality")
formatting = load("post-edit-format")
typecheck = load("post-edit-typecheck")

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


# --- the rules the session hooks ran alone ------------------------------------
# Three rules below existed only as PostToolUse hooks, which means they only ever
# ran inside Claude Code. An agent that is not Claude Code, or a person at a
# terminal, saw none of them. They run here too now, over the same file set and
# with the same exclusions as every other rule, so git and CI enforce them under
# any agent. Their tables and their decisions are imported from those hooks
# rather than restated, for the reason stated at the top of this file.

FORMAT_TIMEOUT = 60      # a formatter on a changed set; long enough for a cold start
TYPES_TIMEOUT = 120      # a whole-project tsc, the same bound the post-edit hook uses


class _Ask:
    """Stands in for `subprocess` inside a post-edit hook while the hook is asked
    which command it would run for a file. Those hooks decide, then act; check
    time needs the decision without the action — nothing on disk may change while
    someone is part-way through a commit — so calls are recorded and none are
    executed. `git rev-parse` is answered instead of recorded: it is the hook's
    own containment guard, not the command being asked about, and an empty answer
    switches that guard off for a path we have already resolved ourselves."""

    def __init__(self): self.calls = []

    def run(self, args, **kw):
        args = list(args)
        if args[:2] != ["git", "rev-parse"]: self.calls.append((args, kw))
        return subprocess.CompletedProcess(args, 0, "", "")


def hook_command(mod, path):
    """The command `mod` would run for `path`, without running it.

    Asking the hook beats copying its table here: the formatter a project has
    configured, and the tsconfig nearest a file, are decisions with real detail
    in them, and a second copy of that detail is a copy that goes stale. The
    module's own `subprocess` and `json` names are swapped for the duration and
    put back, so nothing outside this call is affected."""
    ask = _Ask()
    payload = {"tool_name": "Edit", "tool_input": {"file_path": path}}
    saved = mod.subprocess, mod.json
    mod.subprocess = ask
    mod.json = type("_payload", (), {"load": staticmethod(lambda _stream: payload)})
    try:
        mod.main()
    except Exception:
        return None
    finally:
        mod.subprocess, mod.json = saved
    return ask.calls[0] if ask.calls else None


def check_ui_drift(root, files, warnings):
    """design-quality's signals over the changed frontend files. The hook sees one
    edit as it happens; this sees the set that is about to be committed. Advisory
    under every profile, blocking under strict — the signals are judgement calls
    (a rendered list may legitimately have no empty state), and a rule that is
    right most of the time belongs in front of a person, not across a gate."""
    for p in sorted(files):
        if not design.FRONTEND.search(p): continue
        try: text = open(os.path.join(root, p), encoding="utf-8", errors="ignore").read()
        except OSError: continue
        for rx, msg in design.SIGNALS:
            m = rx.search(text)          # one report per signal per file, as the hook does
            if not m: continue
            line = text.count("\n", 0, m.start()) + 1
            warnings.append(f"{p}:{line}: `{m.group(0)[:40].strip()}` — {msg}")


def read_only_form(prefix):
    """A formatter's write invocation turned into the one that only reports.

    `prefix` is the command the post-edit hook would run with the file name
    removed. Everything the pipeline knows about *which* formatter a project uses
    comes from that hook; what is known here, and only here, is how each formatter
    is asked the question instead of told to act. Returns None when a formatter
    has no read-only form, which is reported as a note and never as a finding."""
    if not prefix: return None
    prog = os.path.basename(prefix[0])
    if prog == "prettier": return [prefix[0], "--check"]
    if prog == "biome":    return [prefix[0], "format"]            # without --write it only reports
    if prog == "ruff":     return [prefix[0], "format", "--check"] # no -q: the names are the answer
    if prog == "black":    return [prefix[0], "--check"]
    if prog == "gofmt":    return [prefix[0], "-l"]
    if prog == "rustfmt":  return list(prefix) + ["--check"]
    return None


def check_format(root, files, warnings, notes):
    """Files the project's own formatter would rewrite. Never rewrites them: at
    check time the working tree belongs to whoever is committing. Advisory,
    blocking under strict. A formatter that is not installed, or fails, is a note
    and never a failure — the pipeline does not own the project's toolchain, and
    a missing dependency is not a finding about the code."""
    groups = {}
    here = os.getcwd()
    try:
        # The hook detects the project's formatter by relative path (a prettier
        # config, node_modules/.bin/prettier), so the question has to be asked
        # from the project root for the answer to be about this project.
        os.chdir(root)
        for p in sorted(files):
            if not is_source(p): continue
            got = hook_command(formatting, os.path.join(root, p))
            if not got: continue
            args = got[0]
            mode = read_only_form(args[:-1])      # the hook always puts the file last
            if mode is None:
                notes.append(f"{os.path.basename(args[0])} has no read-only form here; formatting not checked")
                continue
            groups.setdefault(tuple(mode), []).append(p)
        for mode, paths in sorted(groups.items()):
            prog = os.path.basename(mode[0])
            try:
                r = subprocess.run(list(mode) + paths, cwd=root, capture_output=True, text=True, timeout=FORMAT_TIMEOUT)
            except Exception:
                notes.append(f"{prog} is configured but could not be run here; formatting not checked")
                continue
            out = (r.stdout or "") + (r.stderr or "")
            # Every one of these names the files it would change; gofmt -l names them
            # and still exits 0, so the names are read rather than the status.
            hit = [p for p in paths if p in out or os.path.join(root, p) in out]
            for p in hit:
                warnings.append(f"{p}: {prog} would reformat this file; run the project's formatter, then stage it")
            if not hit and r.returncode != 0:
                notes.append(f"{prog} reported a problem it did not attribute to a file; formatting not checked")
    finally:
        os.chdir(here)


DIAGNOSTIC = re.compile(r"^(.+?)\((\d+),\d+\): (error TS\d+: .*)$")


def check_types(root, files, warnings, notes):
    """The nearest-tsconfig `tsc --noEmit` the post-edit hook runs, reporting only
    the errors in the changed files. Asked for rather than always on: a whole
    project type-check costs seconds to minutes, and a commit hook that does that
    unbidden is a commit hook people remove. Once asked for it is advisory, and
    blocking under strict."""
    runs = {}
    for p in sorted(files):
        if not p.endswith((".ts", ".tsx")): continue
        got = hook_command(typecheck, os.path.join(root, p))
        if not got: continue
        args, kw = got
        # The command is per-tsconfig, not per-file, so files sharing one project
        # share one run. -p names the project; the file itself is not an argument.
        runs.setdefault((tuple(args), kw.get("cwd") or root), []).append(p)
    for (args, cwd), _paths in sorted(runs.items()):
        try:
            r = subprocess.run(list(args), cwd=cwd, capture_output=True, text=True, timeout=TYPES_TIMEOUT)
        except Exception:
            notes.append("tsc is not available here; type errors not checked"); continue
        seen = 0
        for line in (r.stdout or "").splitlines():
            m = DIAGNOSTIC.match(line)
            if not m: continue
            seen += 1
            rel = os.path.relpath(os.path.join(cwd, m.group(1)), root)
            if rel in files: warnings.append(f"{rel}:{m.group(2)}: {m.group(3)}")
        if not seen and r.returncode != 0:
            notes.append("tsc could not run (is TypeScript installed?); type errors not checked")


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
    ap.add_argument("--types", action="store_true", help="also run the project's tsc over the changed TypeScript (slow; ACP_CHECK_TYPES=1 does the same)")
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

    blockers, warnings, notes = [], [], []
    check_secrets(root, files, blockers)
    check_config(root, files, blockers)
    check_evidence(root, evidence_files, blockers)
    check_quality(root, files, warnings)
    check_ui_size(root, files, warnings)
    check_docs(root, files, warnings)
    check_ui_drift(root, files, warnings)
    check_format(root, files, warnings, notes)
    if a.types or os.environ.get("ACP_CHECK_TYPES") == "1": check_types(root, files, warnings, notes)
    if not a.no_kb: check_kb(root, files, warnings, a.kb)

    # The git hooks are shims that exec this directly; run-hook.sh, which is what
    # turns the strict profile into ACP_STRICT, is only in the Claude Code path.
    # Reading the profile here is what makes strict mean the same thing at a
    # commit, in CI, and in a session.
    strict = (a.strict or os.environ.get("ACP_STRICT") == "1"
              or os.environ.get("ACP_HOOK_PROFILE", "").strip().lower() == "strict")
    notes = list(dict.fromkeys(notes))       # one line per reason, however many files hit it
    if not blockers and not warnings:
        if not a.quiet:
            print(f"check: {len(evidence_files)} file(s) in {how}, nothing found")
            for n in notes: print(f"  note: {n}")
        return 0
    out = [f"check — {how}, {len(files)} file(s):"]
    if blockers:
        out.append("  blocking:")
        out += [f"    {b}" for b in blockers[:20]]
    if warnings:
        out.append("  advisory:" if not strict else "  blocking under strict:")
        out += [f"    {w}" for w in warnings[:30]]
    if notes:
        out.append("  note:")
        out += [f"    {n}" for n in notes]
    print("\n".join(out), file=sys.stderr)
    return 2 if blockers or (strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
