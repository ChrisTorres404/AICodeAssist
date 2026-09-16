#!/usr/bin/env python3
"""
inventory — what a repository already is, read before anything is installed.

Projects arrive in different shapes. Some already keep work-order folders. Some
keep numbered documents (docs/work-orders/NN-type-slug.md, docs/bugs/NNN-slug.md),
or architecture decision records, or nothing but scattered markdown. The intake
step has to find out which, catalogue what is there, and say how it would be
brought in — without touching any of it. Adoption is a decision a person makes;
this only supplies the facts to make it with.

Usage (normally through the intake step):

  inventory.py --root <dir> [--workorders-dir <rel>] [--bugs-dir <rel>]
               [--testing-dir <rel>] [--pipeline-dir <rel>]
               [--out <file>] [--json]

  --json          a machine-readable summary on stdout
  --out <file>    a human-readable INDEX.md written to that path

Exit 0 on success, 1 with a message when the root is not a directory. The tree
is read once; nothing under it is written, ever.
"""
import re, argparse, importlib.util, json, os, re, subprocess, sys
from datetime import datetime, timezone

# An inventory that leaves .pyc files behind has written to the project it was
# told not to touch.
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
# <pipeline>/core/hooks/inventory.py — two directories up is the installed pipeline,
# derived the way check.py derives it so the two agree on what to skip.
PIPELINE_DIR = os.path.realpath(os.path.join(HERE, "..", ".."))


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# The rules and this tool must agree on what is not the project's own work —
# vendored dependencies, build output, the pipeline's own installed copy. Borrowing
# check.py's walk, and with it its SKIP_DIRS, rather than restating the list means
# the two cannot drift apart.
check = _load("acp_check", os.path.join(HERE, "check.py"))
walk = check.walk

MD_EXT = (".md", ".mdx", ".markdown")
# A work-order or bug folder the pipeline itself would recognise, anywhere in the tree.
RECORD_FOLDER = re.compile(r"^(WO|BUG)-(\d{3,})-")
# A numbered document: 12-feat-search.md, 003-fixed-crash.md, 0001-use-postgres.md.
NUMBERED_FILE = re.compile(r"^(\d{2,4})[-_]")
H1 = re.compile(r"(?m)^#[ \t]+(.+?)[ \t]*#*[ \t]*$")
STATUS_LINE = re.compile(r"(?mi)^[ \t>*_]*(?:\*\*)?status(?:\*\*)?[ \t]*:[ \t]*(.+?)[ \t*_]*$")

ADR_DIRS = {"adr", "adrs"}
DECISION_DIRS = {"decisions", "decision-records"}
WO_DIRS = {"work-orders", "workorders", "work_orders", "wo", "workorder"}
BUG_DIRS = {"bugs", "bug", "issues", "defects"}

INSTRUCTION_FILES = ["AGENTS.md", "CLAUDE.md", ".cursorrules",
                     ".github/copilot-instructions.md", "GEMINI.md"]
INSTRUCTION_DIRS = [".cursor/rules"]
CI_FILES = [".gitlab-ci.yml", "Jenkinsfile", "azure-pipelines.yml", "bitbucket-pipelines.yml"]
CI_DIRS = [".github/workflows", ".circleci"]

# The markers the installer writes into the git hooks it owns. Their presence is how
# an already-installed project is told from one that has its own hooks.
HOOK_MARKERS = {"commit-msg": "acp:commit-msg:wo-reference", "pre-commit": "acp:pre-commit:check"}

# Category guesses for `bug adopt --category`. A wrong guess is cheap — the flag is
# in the command for a person to correct — and no guess at all is not, because the
# flag is required and the command would not run.
BUG_CATEGORIES = [
    ("auth", ("auth", "login", "logout", "session", "token", "jwt", "oauth", "sso", "password", "mfa", "signin")),
    ("security", ("security", "xss", "csrf", "injection", "vuln", "secret", "leak-credential", "escalation")),
    ("database", ("database", "db", "sql", "postgres", "mysql", "migration", "schema", "query", "orm")),
    ("api", ("api", "endpoint", "rest", "graphql", "route", "controller", "request")),
    ("ui", ("ui", "frontend", "css", "layout", "button", "modal", "render", "page", "component", "style")),
    ("performance", ("perf", "performance", "slow", "latency", "timeout", "memory", "leak")),
    ("observability", ("log", "logging", "metric", "trace", "monitor", "alert", "telemetry")),
    ("integration", ("integration", "webhook", "sync", "import", "export", "third-party")),
    ("config", ("config", "deploy", "deployment", "docker", "build", "ci", "pipeline", "env")),
    ("docs", ("docs", "documentation", "readme", "typo")),
]

SHAPE_SENTENCE = {
    "workorders": "The record is already work-order shaped: folders named WO-NNNN, with their documents inside.",
    "numbered": "The record is numbered documents: files named NN-slug.md, kept together in a directory.",
    "adr": "The record is architecture decision records: numbered decisions in their own directory.",
    "loose": "The record is loose documentation: markdown exists, but it follows no numbering scheme.",
    "none": "No record was found: there is no markdown outside the pipeline's own files.",
}


# --- git ---------------------------------------------------------------------

def git(root, *args):
    """One git call. Absent git, a directory that is not a repository, and a
    repository with no commits all have to read as 'no answer', not as a crash."""
    try:
        r = subprocess.run(("git",) + args, cwd=root, capture_output=True, text=True, timeout=20)
    except (OSError, subprocess.SubprocessError):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def git_state(root):
    if git(root, "rev-parse", "--is-inside-work-tree") != "true":
        return {"present": False, "commits": 0, "head": None, "remote": None,
                "upstream": None, "ahead": 0, "behind": 0, "dirty": 0}
    commits = git(root, "rev-list", "--count", "HEAD")
    remotes = (git(root, "remote") or "").split()
    # origin when it exists, otherwise whichever remote is first; a repository with
    # several remotes still has one the project is usually pushed to.
    remote = "origin" if "origin" in remotes else (remotes[0] if remotes else None)
    upstream = git(root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
    ahead = behind = 0
    if upstream:
        counts = git(root, "rev-list", "--left-right", "--count", f"{upstream}...HEAD")
        if counts and len(counts.split()) == 2:
            behind, ahead = (int(x) for x in counts.split())
    status = git(root, "status", "--porcelain")
    return {"present": True,
            "commits": int(commits) if commits and commits.isdigit() else 0,
            "head": git(root, "rev-parse", "--short", "HEAD"),
            "remote": remote, "upstream": upstream, "ahead": ahead, "behind": behind,
            "dirty": len([l for l in (status or "").splitlines() if l.strip()])}


def git_hooks(root, present):
    """Whether the pipeline's own hooks are already wired in. --git-path resolves
    core.hooksPath and linked worktrees, which a plain .git/hooks guess does not."""
    out = {"commit_msg": False, "pre_commit": False}
    if not present:
        return out
    for name, key in (("commit-msg", "commit_msg"), ("pre-commit", "pre_commit")):
        hook = git(root, "rev-parse", "--git-path", f"hooks/{name}")
        if not hook:
            continue
        full = hook if os.path.isabs(hook) else os.path.join(root, hook)
        try:
            out[key] = HOOK_MARKERS[name] in open(full, encoding="utf-8", errors="ignore").read()
        except OSError:
            pass
    return out


# --- reading the tree ---------------------------------------------------------

def read_head(full, limit=8192):
    try:
        with open(full, encoding="utf-8", errors="ignore") as f:
            return f.read(limit)
    except OSError:
        return ""


def title_of(head, path):
    """The first H1, or the filename. A document's own heading is what a person
    would call it; the filename is the fallback, not the preference."""
    m = H1.search(head)
    if m and m.group(1).strip():
        return m.group(1).strip()[:120]
    return os.path.splitext(os.path.basename(path))[0]


def parts_of(path):
    return [p.lower() for p in os.path.normpath(path).split(os.sep)]


def under(path, directory):
    if not directory:
        return False
    d = os.path.normpath(directory)
    target = os.path.normpath(path)
    return target == d or target.startswith(d + os.sep)


def item_kind(path, wo_dir, bug_dir):
    """What a record item is, guessed from where it sits and what it is called.
    The directory wins over the filename: a document called 13-fix-login.md inside
    a work-orders directory is a work order about a fix, not a bug report."""
    base = os.path.basename(path)
    dirs = parts_of(os.path.dirname(path))
    m = RECORD_FOLDER.match(base) or next((RECORD_FOLDER.match(d.upper()) for d in
                                           os.path.normpath(path).split(os.sep)
                                           if RECORD_FOLDER.match(d.upper())), None)
    if m:
        return "bug" if m.group(1) == "BUG" else "work-order"
    if under(path, bug_dir) or any(d in BUG_DIRS for d in dirs):
        return "bug"
    if under(path, wo_dir) or any(d in WO_DIRS for d in dirs):
        return "work-order"
    if any(d in ADR_DIRS for d in dirs) or base.lower().startswith("adr"):
        return "adr"
    if any(d in DECISION_DIRS for d in dirs):
        return "decision"
    if re.search(r"(^|[-_])bugs?([-_]|\.)", base.lower()):
        return "bug"
    return "unknown"


def status_hint(path, head):
    """fixed, open, or nothing. A name token is the stronger signal: a scheme that
    encodes the state in the filename means it, where a Status: line in a document
    may be a template heading nobody updated."""
    tokens = re.split(r"[-_.]", os.path.basename(path).lower())
    if "fixed" in tokens:
        return "fixed"
    if "open" in tokens:
        return "open"
    m = STATUS_LINE.search(head)
    if m:
        v = m.group(1).strip().lower()
        if re.search(r"\b(fixed|closed|done|complete|completed|resolved|shipped)\b", v):
            return "fixed"
        if re.search(r"\b(open|todo|in.progress|active|new)\b", v):
            return "open"
    return None


# Directory names that say where a document is filed, not what it is about. Left in,
# every bug under docs/ would be guessed as a documentation bug.
GENERIC_DIRS = {"docs", "doc", "documentation", "bugs", "bug", "issues", "defects",
                "work-orders", "workorders", "work_orders", "wo", "notes", "src", "adr", "adrs"}


def bug_category(path, title):
    words = [d for d in parts_of(os.path.dirname(path)) if d not in GENERIC_DIRS]
    hay = " ".join(words + [os.path.basename(path), title]).lower()
    for name, vocabulary in BUG_CATEGORIES:
        if any(re.search(r"(^|[^a-z])" + re.escape(w) + r"([^a-z]|$)", hay) for w in vocabulary):
            return name
    return "other"


DOC_NAME_KINDS = [("readme", "readme"), ("changelog", "changelog"), ("changes", "changelog"),
                  ("history", "changelog"), ("contributing", "contributing"), ("license", "license"),
                  ("licence", "license"), ("copying", "license")]
DOC_TOKEN_KINDS = [("runbook", "runbook"), ("playbook", "runbook"), ("guide", "guide"),
                   ("tutorial", "guide"), ("howto", "guide"), ("spec", "spec"),
                   ("specification", "spec"), ("rfc", "spec"), ("design", "design"),
                   ("architecture", "design"), ("meeting", "meeting-notes"), ("minutes", "meeting-notes"),
                   ("standup", "meeting-notes"), ("retro", "meeting-notes")]


def doc_kind(path, title, head):
    """What a document is. Path first, because a directory is a deliberate choice;
    then the filename; then the heading, for the documents filed nowhere in
    particular. Every one of these is a guess, and the table says so."""
    base = os.path.basename(path).lower()
    stem = os.path.splitext(base)[0]
    dirs = parts_of(os.path.dirname(path))
    for name, kind in DOC_NAME_KINDS:
        if stem == name or stem.startswith(name + "."):
            return kind
    if any(d in ADR_DIRS for d in dirs) or stem.startswith("adr"):
        return "adr"
    if any(d in DECISION_DIRS for d in dirs):
        return "adr"
    if any(d in WO_DIRS for d in dirs) or RECORD_FOLDER.match(base.upper()) or "wo-" in base:
        return "work-order"
    if any(d in BUG_DIRS for d in dirs) or base.upper().startswith("BUG-"):
        return "bug"
    if any(d in ("notes", "meetings", "meeting-notes") for d in dirs):
        return "meeting-notes"
    tokens = set(re.split(r"[-_.\s]", stem)) | set(dirs)
    for word, kind in DOC_TOKEN_KINDS:
        if word in tokens:
            return kind
    head_l = (title + "\n" + head[:400]).lower()
    for word, kind in DOC_TOKEN_KINDS:
        if re.search(r"(^|[^a-z])" + re.escape(word) + r"([^a-z]|$)", head_l):
            return kind
    return "unknown"


# --- the record ---------------------------------------------------------------

def record_folder_items(md_files, meta, wo_dir, bug_dir):
    """Work-order and bug folders: one item per folder, not per file. The folder is
    the item; the document adopted is its specification, or its only document."""
    folders = {}
    for rel in md_files:
        parts = os.path.normpath(rel).split(os.sep)
        for i, part in enumerate(parts[:-1]):
            m = RECORD_FOLDER.match(part.upper())
            if m:
                folders.setdefault(os.sep.join(parts[:i + 1]), []).append(rel)
                break
    items = []
    for folder in sorted(folders):
        docs = sorted(folders[folder])
        # A SPEC is the document the record is about; a closeout or a checklist is
        # about the work, and adopting it would carry the wrong text across.
        doc = next((d for d in docs if "SPEC" in os.path.basename(d).upper()), docs[0])
        m = RECORD_FOLDER.match(os.path.basename(folder).upper())
        items.append(make_item(doc, int(m.group(2)), meta, wo_dir, bug_dir, folder=folder))
    return items, set(folders)


def numbered_items(md_files, meta, wo_dir, bug_dir, inside_folders):
    items = []
    for rel in sorted(md_files):
        if any(under(rel, f) for f in inside_folders):
            continue
        m = NUMBERED_FILE.match(os.path.basename(rel))
        if m:
            items.append(make_item(rel, int(m.group(1)), meta, wo_dir, bug_dir))
    return items


def make_item(rel, number, meta, wo_dir, bug_dir, folder=None):
    title, head = meta[rel]
    item = {"path": rel, "number": number, "title": title,
            "kind": item_kind(folder or rel, wo_dir, bug_dir),
            "status_hint": status_hint(rel, head)}
    if folder:
        item["folder"] = folder
    return item


def classify(md_files, meta, wo_dir, bug_dir):
    """The shape of the record, and everything in it.

    Precedence is strict: a repository that already has WO folders has answered the
    question, whatever else it also keeps; then a directory of numbered documents;
    then decision records; then markdown with no scheme; then nothing. The shape
    names the dominant scheme, and the items list everything found either way, so a
    stray ADR beside three numbered work orders is still catalogued."""
    folder_items, folders = record_folder_items(md_files, meta, wo_dir, bug_dir)
    loose_items = numbered_items(md_files, meta, wo_dir, bug_dir, folders)
    items = folder_items + loose_items

    # Where the numbered documents cluster: a directory needs three of them before it
    # counts as a scheme, because two is a coincidence.
    by_dir = {}
    for it in loose_items:
        by_dir.setdefault(os.path.dirname(it["path"]), []).append(it)
    dense = sorted((d for d, v in by_dir.items() if len(v) >= 3), key=lambda d: (-len(by_dir[d]), d))
    adr_dirs = sorted(d for d in by_dir
                      if os.path.basename(d).lower() in (ADR_DIRS | DECISION_DIRS))
    # A dense directory called adr is decision records that happen to be numbered, not a
    # numbering scheme for work; it is the directory's name that says which.
    dense = [d for d in dense if d not in adr_dirs]

    if folders:
        # Where the work orders are, not where the bug folders are: a repository with
        # both is described by the scheme its work is filed under.
        ordered = sorted(folders, key=lambda f: (not os.path.basename(f).upper().startswith("WO-"), f))
        shape, where = "workorders", os.path.dirname(ordered[0])
    elif dense:
        shape, where = "numbered", dense[0]
    elif adr_dirs:
        shape, where = "adr", adr_dirs[0]
    elif md_files:
        shape, where = "loose", None
    else:
        shape, where = "none", None

    if shape in ("loose", "none"):
        items = []
    return {"shape": shape, "where": where or None,
            "items": [i for i in items if i["kind"] != "bug"],
            "bugs": [i for i in items if i["kind"] == "bug"]}


# --- what to run next -----------------------------------------------------------

def shq(s):
    """A double-quoted shell word. Titles come out of documents this tool did not
    write, and the commands are meant to be pasted as they are."""
    return '"' + re.sub(r'([\\"$`])', r"\\\1", str(s)) + '"'


def adopt_commands(record):
    """One ready-to-run command per item, and a note where two items claim the same
    number. Inventing a number to break a tie would put a record under an identifier
    nothing else cites, which is worse than stopping and saying so."""
    commands, collisions = [], []
    for ns, items, verb in (("work order", record["items"], "wo"), ("bug", record["bugs"], "bug")):
        by_number = {}
        for it in items:
            by_number.setdefault(it["number"], []).append(it)
        for number in sorted(by_number):
            group = sorted(by_number[number], key=lambda i: i["path"])
            if len(group) > 1:
                collisions.append({"kind": ns, "number": number, "paths": [i["path"] for i in group]})
                continue
            it = group[0]
            if verb == "wo":
                status = "open" if it["status_hint"] == "open" else "migrated"
                commands.append(f"wo adopt {shq(it['path'])} --number {number} "
                                f"--title {shq(it['title'])} --status {status}")
            else:
                status = it["status_hint"] if it["status_hint"] in ("fixed", "open") else "migrated"
                commands.append(f"bug adopt {shq(it['path'])} --number {number} "
                                f"--category {bug_category(it['path'], it['title'])} --status {status}")
    return commands, collisions


def stack_of(root, pipeline_dir):
    """detect-stack already knows how to read a project; asking it keeps one answer
    to 'what is this built with'. It may be absent (the pipeline is not installed
    here yet), so its absence is a null, not a failure."""
    candidates = [os.path.join(root, pipeline_dir, "bin", "detect-stack"),
                  os.path.join(PIPELINE_DIR, "bin", "detect-stack")]
    for exe in candidates:
        if not os.path.isfile(exe):
            continue
        try:
            r = subprocess.run([sys.executable, exe, root, "--json"],
                               capture_output=True, text=True, timeout=60)
            if r.returncode == 0:
                return json.loads(r.stdout)
        except (OSError, ValueError, subprocess.SubprocessError):
            continue
    return {}


# --- the document ----------------------------------------------------------------

def human_bytes(n):
    return f"{n:,} B" if n < 1024 else f"{n / 1024:.1f} kB"


def plural(n, word):
    return f"{n} {word}" + ("" if n == 1 else "s")


def md_cell(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def git_sentence(g):
    if not g["present"]:
        return ("This directory is not under version control. Nothing here can be bound to a "
                "source state until it is a repository with at least one commit.")
    if g["commits"] == 0:
        return "This is a git repository with no commits yet."
    bits = [f"{plural(g['commits'], 'commit')}, at {g['head']}"]
    if g["upstream"]:
        rel = []
        if g["ahead"]:
            rel.append(f"{g['ahead']} ahead")
        if g["behind"]:
            rel.append(f"{g['behind']} behind")
        bits.append(f"tracking {g['upstream']} ({', '.join(rel) or 'in step'})")
    elif g["remote"]:
        bits.append(f"remote {g['remote']}, no tracking branch")
    else:
        bits.append("no remote")
    bits.append("a clean tree" if not g["dirty"] else plural(g["dirty"], "uncommitted change"))
    return "This is a git repository: " + ", ".join(bits) + "."


def render(data, root_name):
    g, rec = data["git"], data["record"]
    out = [f"# Repository inventory — {root_name}", ""]
    against = f"commit {g['head']}" if g.get("head") else "an uncommitted tree"
    out += [f"Taken {data['taken']} against {against}.", ""]

    out += ["## What this repository is", "", git_sentence(g), ""]
    st = data["stack"]
    stack = ", ".join(st.get("languages", []) + st.get("frameworks", [])) or "no recognised stack"
    if st.get("package_manager"):
        stack += f" ({st['package_manager']})"
    out.append(f"- **Stack:** {stack}")
    t = data["tests"]
    out.append(f"- **Tests:** " + (f"`{t['command']}`" if t["command"] else "no test command was detected"))
    if t["suites_manifest"]:
        out.append("- **Suite manifest:** present, " + plural(t["manifest_entries"], "entry").replace("entrys", "entries"))
    instr = ", ".join(f"`{i['path']}` ({human_bytes(i['bytes'])})" for i in data["instructions"])
    out.append("- **Instruction files:** " + (instr or "none"))
    if data["claude_imports_agents"]:
        out.append("  - `CLAUDE.md` imports `AGENTS.md`, so both agents read one set of instructions.")
    h = data["hooks"]
    wired = [n for n, on in (("commit-msg", h["commit_msg"]), ("pre-commit", h["pre_commit"])) if on]
    out.append("- **Git hooks:** " + (", ".join(wired) + " already wired to this pipeline" if wired
                                      else "none of this pipeline's hooks are installed"))
    out.append("- **CI:** " + (", ".join(f"`{c}`" for c in data["ci"]) or "none found"))
    out.append("")

    out += ["## The record", "", SHAPE_SENTENCE[rec["shape"]], ""]
    ip = rec.get("in_pipeline") or {}
    if ip.get("work_orders") or ip.get("bugs"):
        out += [f"Already inside the pipeline, and not proposed again: {ip.get('work_orders', 0)} work order(s), {ip.get('bugs', 0)} bug(s).", ""]
    if rec["where"]:
        out += [f"Found under `{rec['where']}`.", ""]
    rows = rec["items"] + rec["bugs"]
    if rows:
        out += ["| Number | Kind | Title | Status hint | Path |", "|---|---|---|---|---|"]
        for it in sorted(rows, key=lambda i: (i["kind"], i["number"], i["path"])):
            out.append(f"| {it['number']} | {it['kind']} | {md_cell(it['title'])} | "
                       f"{it['status_hint'] or '—'} | `{it['path']}` |")
        out.append("")

    out += ["## Suggested adoption", ""]
    if rec["shape"] == "loose":
        out += ["The record is loose documentation; nothing is adopted unless you choose it", ""]
    elif rec["shape"] == "none":
        out += ["No record was found", ""]
    elif data["suggested_adopt"]:
        out += ["Run from the project root, through the installed pipeline's drivers. Each command "
                "keeps the number the document already cites, and writes no verification: adopted "
                "work is recorded, not verified.", "", "```bash"]
        out += data["suggested_adopt"]
        out += ["```", ""]
    else:
        out += ["Items were found, but none could be proposed without inventing a number.", ""]
    for c in data["collisions"]:
        out.append(f"- Two or more {c['kind']} records claim number {c['number']}: "
                   + ", ".join(f"`{p}`" for p in c["paths"])
                   + ". No command is proposed; pick the numbers yourself.")
    if data["collisions"]:
        out.append("")

    out += ["## Every document", ""]
    if data["docs"]:
        out += ["| Path | Kind | Size | Modified |", "|---|---|---|---|"]
        for d in sorted(data["docs"], key=lambda x: x["path"]):
            out.append(f"| `{d['path']}` | {d['kind']} | {human_bytes(d['bytes'])} | {d['modified']} |")
        out.append("")
        if data["docs_capped"]:
            out += [f"Listing capped at {len(data['docs'])} of {data['docs_total']} documents.", ""]
    else:
        out += ["No markdown was found outside the skipped directories.", ""]

    out += ["---", "",
            "This inventory is read-only. Nothing in the repository was changed, moved, or "
            "renamed to produce it, and nothing was adopted. Whatever is proposed above happens "
            "only when a person runs it."]
    return "\n".join(out) + "\n"


# --- main -------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--workorders-dir", default="Workspace/Docs/WorkOrders")
    ap.add_argument("--bugs-dir", default="Workspace/Docs/Bugs")
    ap.add_argument("--testing-dir", default="Workspace/Testing")
    ap.add_argument("--pipeline-dir", default=".aicodepipeline")
    ap.add_argument("--knowledge-dir", default="Workspace/Docs/KnowledgeBase")
    ap.add_argument("--out", help="write the human-readable INDEX.md here")
    ap.add_argument("--json", action="store_true", help="print the summary as JSON")
    a = ap.parse_args()

    # realpath, not abspath: on macOS the temp directory is a symlink, and a root
    # spelled one way with paths spelled the other resolves to nothing.
    root = os.path.realpath(os.path.expanduser(a.root))
    if not os.path.isdir(root):
        print(f"inventory: {a.root} is not a directory", file=sys.stderr)
        return 1

    wo_dir = os.path.normpath(a.workorders_dir) if a.workorders_dir else ""
    bug_dir = os.path.normpath(a.bugs_dir) if a.bugs_dir else ""
    # The pipeline's own installed copy is not the project's documentation, exactly as
    # the rules skip it; .git and the vendored directories come from SKIP_DIRS.
    exclude = [os.path.normpath(a.pipeline_dir)] if a.pipeline_dir else []
    if PIPELINE_DIR.startswith(root + os.sep):
        exclude.append(os.path.normpath(os.path.relpath(PIPELINE_DIR, root)))

    # One walk. Everything below reads from what it collected, so a repository with a
    # few thousand files costs one traversal and one open per markdown file.
    # What is already inside the pipeline's own directories is not an external
    # record to bring in: it is in. It is counted, not proposed for adoption, and
    # the knowledge base is generated description, not documentation to catalogue.
    kb_dir = os.path.normpath(a.knowledge_dir) if a.knowledge_dir else ""
    in_pipeline = {"work_orders": 0, "bugs": 0}
    seen_folders = set()
    md_files, meta, docs = [], {}, []
    for rel in walk(root, exclude + ([kb_dir] if kb_dir else [])):
        if not rel.lower().endswith(MD_EXT):
            continue
        # A folder that carries the driver's metadata is the pipeline's own record,
        # wherever it lives; a work-order-shaped folder without it is history that
        # has not been brought in yet, even when it already sits in the right place.
        owned = None
        parts = rel.split(os.sep)
        for i, part in enumerate(parts[:-1]):
            if re.match(r"^(WO|BUG)-\d{3,}-", part):
                folder = os.path.join(root, *parts[:i + 1])
                if os.path.isfile(os.path.join(folder, ".wo-meta")): owned = ("work_orders", os.path.join(*parts[:i + 1]))
                elif os.path.isfile(os.path.join(folder, ".bug-meta")): owned = ("bugs", os.path.join(*parts[:i + 1]))
                break
        if owned:
            if owned not in seen_folders:
                seen_folders.add(owned); in_pipeline[owned[0]] += 1
            continue
        full = os.path.join(root, rel)
        head = read_head(full)
        title = title_of(head, rel)
        meta[rel] = (title, head)
        md_files.append(rel)
        try:
            stat = os.stat(full)
        except OSError:
            continue
        docs.append({"path": rel, "title": title, "bytes": stat.st_size,
                     "modified": datetime.fromtimestamp(stat.st_mtime, timezone.utc).date().isoformat(),
                     "kind": doc_kind(rel, title, head)})

    docs.sort(key=lambda d: d["path"])
    docs_total = len(docs)
    docs_capped = docs_total > 2000
    docs = docs[:2000]

    g = git_state(root)
    record = classify(md_files, meta, wo_dir, bug_dir)
    record["in_pipeline"] = in_pipeline
    commands, collisions = adopt_commands(record)

    instructions = []
    for name in INSTRUCTION_FILES:
        full = os.path.join(root, name)
        if os.path.isfile(full):
            instructions.append({"path": name, "bytes": os.path.getsize(full)})
    for d in INSTRUCTION_DIRS:
        full = os.path.join(root, d)
        if os.path.isdir(full):
            for f in sorted(os.listdir(full)):
                if os.path.isfile(os.path.join(full, f)):
                    instructions.append({"path": f"{d}/{f}", "bytes": os.path.getsize(os.path.join(full, f))})
    claude = os.path.join(root, "CLAUDE.md")
    # The installer writes CLAUDE.md as a one-line import of AGENTS.md so both agents
    # read the same instructions; whether that link exists is the useful fact.
    imports = os.path.isfile(claude) and "@AGENTS.md" in read_head(claude, 65536)

    ci = []
    for d in CI_DIRS:
        full = os.path.join(root, d)
        if os.path.isdir(full):
            ci += [f"{d}/{f}" for f in sorted(os.listdir(full)) if os.path.isfile(os.path.join(full, f))]
    ci += [f for f in CI_FILES if os.path.isfile(os.path.join(root, f))]

    manifest = os.path.join(root, a.testing_dir, "suites.manifest") if a.testing_dir else ""
    entries = 0
    if manifest and os.path.isfile(manifest):
        entries = len([l for l in open(manifest, encoding="utf-8", errors="ignore")
                       if l.strip() and not l.lstrip().startswith("#")])
    stack = stack_of(root, a.pipeline_dir)

    data = {
        "root": os.path.basename(root),
        "taken": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "git": g,
        "instructions": instructions,
        "claude_imports_agents": bool(imports),
        "hooks": git_hooks(root, g["present"]),
        "ci": ci,
        "stack": {k: stack.get(k) for k in ("languages", "frameworks", "package_manager")} if stack else
                 {"languages": [], "frameworks": [], "package_manager": ""},
        "tests": {"command": (stack.get("commands") or {}).get("test") or None,
                  "suites_manifest": bool(manifest and os.path.isfile(manifest)),
                  "manifest_entries": entries},
        "record": record,
        "docs": docs,
        "docs_total": docs_total,
        "docs_capped": docs_capped,
        "suggested_adopt": commands,
        "collisions": collisions,
    }

    if a.out:
        parent = os.path.dirname(os.path.abspath(a.out))
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(render(data, data["root"]))

    if a.json:
        print(json.dumps(data, indent=2))
    else:
        rec = data["record"]
        print(f"inventory: {data['root']} — {SHAPE_SENTENCE[rec['shape']]}")
        print(f"  record   : {plural(len(rec['items']), 'item')}, {plural(len(rec['bugs']), 'bug')}, "
              f"{plural(len(commands), 'adoption command')}")
        print(f"  documents: {plural(docs_total, 'markdown file')}"
              + (f" (listing capped at {len(docs)})" if docs_capped else ""))
        print("  git      : " + ("absent" if not g["present"]
                                 else f"{plural(g['commits'], 'commit')}, {g['dirty']} dirty"))
        if a.out:
            print(f"  written  : {os.path.basename(a.out)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
