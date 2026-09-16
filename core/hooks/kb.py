#!/usr/bin/env python3
"""
kb — knowledge-base freshness, bound to source.

A repository analysis produces documents that are true on the day they are
written and quietly stop being true afterwards. Nothing in the documents
themselves records that: a Feature Profile describing a login flow reads
exactly the same whether the flow still works that way or was rewritten last
month. This tool removes the guess. Every claim in a profile already carries a
`<!-- SOURCE: path:L12 -->` comment naming the file and line that proves it
(the convention doc-claims-check.py enforces on write); `bind` records the
content hash of every cited file, and `status` re-hashes them and reports which
profiles still rest on the source they were written from.

The knowledge base is a directory (default Workspace/Docs/KnowledgeBase)
holding the analysis document, `profiles/` with one Feature Profile per
feature, a status matrix, and `source-index.tsv` — the machine-readable
binding this tool writes and reads.

  kb.py bind   --root <dir> --kb <dir>            record a hash per cited file
  kb.py status --root <dir> --kb <dir> [--json]   current / stale / broken, and
                                                  which source nothing describes
  kb.py impact --root <dir> --kb <dir> --files …  which profiles describe this change

Exit codes — status: 0 every profile current, 1 something is stale, 2 something
is broken (broken outranks stale), 3 there is no knowledge base to report on.
impact: 0 nothing affected, 1 at least one profile describes the change. bind:
0, or 1 when the directory holds no profiles.

`wo close` and `acp check` call `impact` to say "this change touched files these
profiles describe". Re-writing the profile is agent work and always was; this
tool only knows, and says, when it is due.

The rules it shares with the hooks — the SOURCE comment's spelling, the source
extensions, the directories no rule reads, the hash — are imported from them,
so the engine and the hooks cannot drift apart.
"""
import argparse, hashlib, importlib.util, json, os, re, sys

# Reading a project must not leave bytecode behind in the installed pipeline.
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))


def load(name):
    """Import a sibling hook script as a module. Their names carry hyphens, so
    the ordinary import statement cannot reach them (check.py does the same)."""
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


docs = load("doc-claims-check")
quality = load("quality-gate")
check = load("check")

SOURCE_RX = docs.SOURCE_RX            # <!-- SOURCE: path:L12 --> / :L12-L20 / :12 / no line
PLACEHOLDER = docs.PLACEHOLDER        # the templates' own example citation is not a claim
file_hash = check.file_hash           # sha256[:16], the same digest the manifest uses
SKIP_DIRS = check.SKIP_DIRS
# SOURCE_RX captures only the first line of a range. A profile citing L12-L20 is
# making a claim about line 20 too, so the end of the range is read back out of
# the matched text and checked as well.
RANGE_END = re.compile(r":L?\d+\s*-\s*L?(\d+)")
# The hooks' source extensions plus the two single-file component formats: a
# profile describes a UI feature as readily as a service, and a .vue or .svelte
# file nobody describes is exactly the gap this reports.
SOURCE_EXT = set(quality.SOURCE_EXT) | {".vue", ".svelte"}

INDEX_NAME = "source-index.tsv"
DEFAULT_KB = os.path.join("Workspace", "Docs", "KnowledgeBase")
HEADER_PREFIX = "# acp kb source-index"


# --- reading the knowledge base ---------------------------------------------

def slash(p):
    """One spelling for a path in output and in the index, on every platform."""
    return p.replace(os.sep, "/")


def rel_to(base, path):
    return slash(os.path.relpath(path, base))


def read(path):
    try:
        return open(path, encoding="utf-8", errors="ignore").read()
    except OSError:
        return ""


def md_docs(kb):
    """Every markdown document under the knowledge base, in a stable order."""
    for d, dirs, files in os.walk(kb):
        dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
        for f in sorted(files):
            if f.endswith((".md", ".mdx")):
                yield os.path.join(d, f)


def resolve(ref, doc_path, root):
    """A cited path resolves against the repository root or against the document's
    own directory — the two spellings doc-claims-check accepts, so a citation a
    hook passed is a citation this engine can find."""
    if os.path.isabs(ref):
        cands = [ref]
    else:
        cands = [os.path.join(root, ref), os.path.join(os.path.dirname(doc_path), ref)]
    return next((c for c in cands if os.path.isfile(c)), None)


def citations(doc_path, root):
    """[(ref as written, highest line cited or None, resolved absolute path or None)]
    for one document, deduplicated, in document order."""
    out, seen = [], set()
    for m in SOURCE_RX.finditer(read(doc_path)):
        ref, start = m.group(1), m.group(2)
        if PLACEHOLDER.search(ref): continue
        end = RANGE_END.search(m.group(0))
        hi = max(int(start), int(end.group(1))) if start and end else (int(start) if start else None)
        if (ref, hi) in seen: continue
        seen.add((ref, hi))
        out.append((ref, hi, resolve(ref, doc_path, root)))
    return out


def profiles_of(kb, root):
    """{document path relative to the kb: [citations]} for every document that
    carries at least one. A document with no citation makes no claim this tool
    can check — an index page or a matrix — and is not a profile."""
    out = {}
    for p in sorted(md_docs(kb)):
        cits = citations(p, root)
        if cits: out[rel_to(kb, p)] = (p, cits)
    return out


_hashes, _lines = {}, {}


def hash_of(path):
    """Each cited file is hashed once per run, however many profiles cite it."""
    if path not in _hashes: _hashes[path] = file_hash(path)
    return _hashes[path]


def line_count(path):
    if path not in _lines:
        try: _lines[path] = sum(1 for _ in open(path, encoding="utf-8", errors="ignore"))
        except OSError: _lines[path] = 0
    return _lines[path]


# --- the index ---------------------------------------------------------------

def index_path(kb):
    return os.path.join(kb, INDEX_NAME)


def read_index(kb):
    """{path relative to root: hash}. An unreadable or absent index is an empty
    one: every citation then reads as never bound, which is the truth."""
    out = {}
    try:
        for line in open(index_path(kb), encoding="utf-8", errors="ignore"):
            line = line.rstrip("\n")
            if not line or line.startswith("#"): continue
            parts = line.split("\t")
            if len(parts) >= 2: out[parts[0]] = parts[1]
    except OSError:
        pass
    return out


def write_index(kb, rows):
    """rows: {path relative to root: (hash, {profiles})}. Sorted, no timestamp —
    the same tree binds to the same bytes, so an index in version control only
    changes when the binding changes."""
    body = "".join(f"{p}\t{h}\t{','.join(sorted(profs))}\n" for p, (h, profs) in sorted(rows.items()))
    bound_tree = hashlib.sha256(body.encode("utf-8")).hexdigest()[:16]
    n_profiles = len({x for _, profs in rows.values() for x in profs})
    header = (f"{HEADER_PREFIX} — columns: path, sha256[:16], citing profiles (tab-separated; "
              f"paths relative to the project root, profiles relative to this directory); "
              f"files={len(rows)}; profiles={n_profiles}; bound_tree={bound_tree}\n")
    with open(index_path(kb), "w", encoding="utf-8") as f:
        f.write(header)
        f.write(body)
    return bound_tree


def bound_tree_of(kb):
    head = ""
    try:
        with open(index_path(kb), encoding="utf-8", errors="ignore") as f:
            head = f.readline()
    except OSError:
        return ""
    m = re.search(r"bound_tree=([0-9a-f]+)", head)
    return m.group(1) if m else ""


# --- what nothing describes ---------------------------------------------------

def is_pipeline_dir(path):
    """The installed pipeline is the project's tooling, not its code: nobody is
    expected to write a Feature Profile about it. Detected by what it contains
    rather than by its name, because the install directory is configurable."""
    return os.path.isfile(os.path.join(path, "bin", "wo")) and os.path.isdir(os.path.join(path, "core", "hooks"))


def source_files(root, kb, exts):
    """Every source file under the root, minus the directories no rule reads, the
    knowledge base itself, and any installed pipeline."""
    out = []
    for d, dirs, files in os.walk(root):
        keep = []
        for x in sorted(dirs):
            full = os.path.join(d, x)
            if x in SKIP_DIRS or os.path.realpath(full) == kb or is_pipeline_dir(full): continue
            keep.append(x)
        dirs[:] = keep
        for f in sorted(files):
            if os.path.splitext(f)[1] in exts:
                out.append(rel_to(root, os.path.join(d, f)))
    return sorted(out)


def cluster(paths, limit=10):
    """Uncovered files are reported by the directory they sit in: a count alone
    says how much is undescribed, the directories say which part of the system."""
    by_dir = {}
    for p in paths:
        by_dir.setdefault(slash(os.path.dirname(p)) or ".", []).append(p)
    ordered = sorted(by_dir.items(), key=lambda kv: (-len(kv[1]), kv[0]))[:limit]
    return [{"dir": d, "count": len(fs), "examples": sorted(fs)[:3]} for d, fs in ordered]


# --- subcommands ----------------------------------------------------------------

def cmd_bind(a, root, kb):
    profs = profiles_of(kb, root) if os.path.isdir(kb) else {}
    if not profs:
        print(f"kb bind: no profiles under {slash(os.path.relpath(kb, root))} — a profile is a markdown "
              f"document carrying <!-- SOURCE: path:L12 --> citations", file=sys.stderr)
        return 1
    rows, unresolved = {}, []
    for name, (path, cits) in profs.items():
        for ref, _hi, found in cits:
            if not found:
                unresolved.append(f"{name}: {ref}")
                continue
            key = rel_to(root, os.path.realpath(found))
            entry = rows.setdefault(key, [hash_of(found), set()])
            entry[1].add(name)
    rows = {p: (h, profs_set) for p, (h, profs_set) in rows.items()}
    bound_tree = write_index(kb, rows)
    print(f"kb bind: {len(rows)} source file(s) cited by {len(profs)} profile(s) — "
          f"{slash(os.path.relpath(index_path(kb), root))}, bound_tree={bound_tree}")
    if unresolved:
        # Not a failure here: these citations are reported as broken by `status`,
        # which is where a profile's state belongs.
        print(f"kb bind: {len(unresolved)} citation(s) point at nothing and are not in the index:", file=sys.stderr)
        for u in unresolved[:10]: print(f"  {u}", file=sys.stderr)
    return 0


def classify(profs, root, index):
    """Per profile: broken if a citation points at a file or a line that is not
    there; else stale if a cited file's content no longer matches the binding (or
    was never bound); else current."""
    out = []
    for name, (path, cits) in profs.items():
        broken, stale = [], []
        for ref, hi, found in cits:
            if not found:
                broken.append(f"{ref} — cited file does not exist")
                continue
            rp = rel_to(root, os.path.realpath(found))
            n = line_count(found)
            if hi is not None and hi > n:
                broken.append(f"{rp}:L{hi} — past the end of the file ({n} lines)")
                continue
            if rp not in index:
                stale.append(f"{rp} — not in the index; bind has not run since this citation was written")
            elif index[rp] != hash_of(found):
                stale.append(f"{rp} — changed since bind")
        state = "broken" if broken else ("stale" if stale else "current")
        out.append({"profile": name, "state": state, "citations": len(cits),
                    "reason": (broken + stale)[0] if (broken or stale) else None,
                    "broken": broken, "stale": stale})
    return out


def cmd_status(a, root, kb):
    profs = profiles_of(kb, root) if os.path.isdir(kb) else {}
    if not profs:
        print(f"no knowledge base at {slash(os.path.relpath(kb, root))}")
        return 3
    index = read_index(kb)
    bound = os.path.isfile(index_path(kb))
    rows = classify(profs, root, index)
    counts = {s: sum(1 for r in rows if r["state"] == s) for s in ("current", "stale", "broken")}

    exts = {("." + e.lstrip(".")).lower() for e in a.source_ext.split(",") if e.strip()} if a.source_ext else SOURCE_EXT
    cited = {rel_to(root, os.path.realpath(f)) for _n, (_p, cits) in profs.items() for _r, _h, f in cits if f}
    uncovered = [p for p in source_files(root, kb, exts) if p not in cited]

    rc = 2 if counts["broken"] else (1 if counts["stale"] else 0)
    summary = (f"kb: {len(rows)} profiles — {counts['current']} current, {counts['stale']} stale, "
               f"{counts['broken']} broken; {len(uncovered)} uncovered source files")

    if a.json:
        print(json.dumps({
            "kb": slash(os.path.relpath(kb, root)),
            "bound": bound,
            "bound_tree": bound_tree_of(kb),
            "profiles": rows,
            "counts": {"profiles": len(rows), **counts},
            "uncovered": {"count": len(uncovered), "clusters": cluster(uncovered),
                          "files": uncovered[:100], "files_truncated": len(uncovered) > 100},
            "summary": summary,
            "exit": rc,
        }, indent=2, sort_keys=True))
        return rc

    print(f"index: bound, {len(index)} file(s), bound_tree={bound_tree_of(kb)}" if bound
          else "index: not bound — no source-index.tsv; run `kb.py bind` (every profile reads as stale until then)")
    w = max([len(r["profile"]) for r in rows] + [7])
    print(f"{'profile'.ljust(w)}  state    first problem")
    for r in sorted(rows, key=lambda r: ({"broken": 0, "stale": 1, "current": 2}[r["state"]], r["profile"])):
        print(f"{r['profile'].ljust(w)}  {r['state'].ljust(7)}  {r['reason'] or '-'}")
    if uncovered:
        print(f"\nuncovered: {len(uncovered)} source file(s) no profile cites")
        for c in cluster(uncovered):
            print(f"  {c['dir'].ljust(w)}  {str(c['count']).rjust(5)}  {', '.join(c['examples'])}")
    else:
        print("\nuncovered: none — every source file is cited by a profile")
    print(f"\n{summary}")
    return rc


def cmd_impact(a, root, kb):
    changed = list(a.files or [])
    if a.stdin:
        changed += [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    # The caller names paths relative to the root; an absolute path is accepted and
    # brought back to the same spelling, so git output and driver output both work.
    norm = []
    for p in changed:
        full = p if os.path.isabs(p) else os.path.join(root, p)
        rp = rel_to(root, os.path.realpath(full))
        if rp not in norm: norm.append(rp)

    profs = profiles_of(kb, root) if os.path.isdir(kb) else {}
    if not profs:
        # No knowledge base is not an error for a driver mid-change: there is
        # simply nothing that describes this yet.
        print(f"no knowledge base at {slash(os.path.relpath(kb, root))}")
        return 0

    changed_set = set(norm)
    # A profile is affected by a change only while the change is unaccounted for:
    # once the profile has been updated and re-bound, the index hash matches the
    # file again and the same change is no longer a reason to name it.
    index = read_index(kb) if os.path.isfile(os.path.join(kb, INDEX_NAME)) else {}
    def indexed_hash(rp):
        v = index.get(rp)
        if v is None: return None
        if isinstance(v, dict): return v.get("hash") or v.get("sha")
        if isinstance(v, (tuple, list)): return v[0]
        return v
    def unaccounted(rp):
        full = os.path.join(root, rp)
        if not os.path.isfile(full): return True
        h = indexed_hash(rp)
        return h is None or h != file_hash(full)
    affected, cited_all = {}, set()
    for name, (_path, cits) in profs.items():
        cited = {rel_to(root, os.path.realpath(f)) for _r, _h, f in cits if f}
        cited_all |= cited
        hit = sorted(p for p in (cited & changed_set) if unaccounted(p))
        if hit: affected[name] = hit

    for name in sorted(affected):
        print(f"{name}\t{','.join(affected[name])}")
    print(f"kb impact: {len(affected)} profile(s) describe {len(changed_set & cited_all)} of {len(norm)} changed file(s)")

    uncovered = [p for p in norm if p not in cited_all and os.path.splitext(p)[1] in SOURCE_EXT]
    print("uncovered:")
    for p in uncovered: print(f"  {p}")
    if not uncovered: print("  none")
    return 1 if affected else 0


def main():
    ap = argparse.ArgumentParser(prog="kb.py", description="knowledge-base freshness, bound to source")
    sub = ap.add_subparsers(dest="cmd")
    for name, help_text in (("bind", "record a content hash per cited source file"),
                            ("status", "report which profiles are current, stale, or broken"),
                            ("impact", "report which profiles describe a set of changed files")):
        p = sub.add_parser(name, help=help_text)
        p.add_argument("--root", default=os.getcwd())
        p.add_argument("--kb", default=None)
        if name == "status":
            p.add_argument("--json", action="store_true")
            p.add_argument("--source-ext", default=None, help="comma-separated extensions to count as source")
        if name == "impact":
            p.add_argument("--files", nargs="*", default=[])
            p.add_argument("--stdin", action="store_true", help="read changed paths from stdin, one per line")
    a = ap.parse_args()
    if not a.cmd:
        ap.print_help()
        return 2
    # realpath, not abspath: on macOS the temp directory is a symlink, and a root
    # spelled one way with paths spelled the other resolves to nothing.
    root = os.path.realpath(a.root)
    kb = os.path.realpath(a.kb) if a.kb else os.path.join(root, DEFAULT_KB)
    return {"bind": cmd_bind, "status": cmd_status, "impact": cmd_impact}[a.cmd](a, root, kb)


if __name__ == "__main__":
    sys.exit(main())
