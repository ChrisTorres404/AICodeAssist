#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install.sh — render the pipeline into a target project
#
#   bin/install.sh /path/to/project [--dry-run] [--profile minimal|standard|full]
#
#   minimal   rules, agents, commands, the six lifecycle skills; no hooks
#   standard  everything above plus all skills and hooks           (default)
#   full      standard plus every domain agent pack
#
# Reads <project>/pipeline.config.sh, copies core/ and harness/ into
# <project>/$PIPELINE_ROOT with every {{VAR}} resolved, wires the agents and
# slash commands into <project>/.claude/, and creates the workspace folders.
#
# Writes ONLY inside the target project. The pipeline repo is never modified.
# Re-runnable: existing rendered files are overwritten, authored work is not.
# ---------------------------------------------------------------------------
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "${1:-}" in -h|--help|"") sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:+0}";; esac
TARGET="${1:-}"; DRY=""; PROFILE="${ACP_PROFILE:-standard}"
_args=("${@:2}"); i=0
while [ $i -lt ${#_args[@]} ]; do a="${_args[$i]}"
  case "$a" in --dry-run) DRY="--dry-run";; --profile=*) PROFILE="${a#--profile=}";; --profile) i=$((i+1)); PROFILE="${_args[$i]:-}";; minimal|standard|full) PROFILE="$a";; *) echo "install: unknown argument '$a'" >&2; exit 1;; esac
  i=$((i+1)); done
case "$PROFILE" in minimal|standard|full) ;; *) echo "install: --profile must be minimal, standard, or full" >&2; exit 1;; esac
[ -n "$TARGET" ] || { echo "usage: bin/install.sh /path/to/project [--dry-run]" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)" || { echo "install: $1 is not a directory" >&2; exit 1; }
[ "$TARGET" = "$SRC" ] && { echo "install: refusing to install the pipeline into itself" >&2; exit 1; }

CONFIG="$TARGET/pipeline.config.sh"
[ -f "$CONFIG" ] || {
  echo "install: $CONFIG not found." >&2
  echo "         cp $SRC/pipeline.config.example.sh $CONFIG   # then edit it" >&2
  exit 1
}
# shellcheck disable=SC1090
. "$CONFIG"

: "${PROJECT_NAME:?set PROJECT_NAME in pipeline.config.sh}"
: "${PROJECT_SLUG:?set PROJECT_SLUG in pipeline.config.sh}"
: "${PIPELINE_ROOT:?set PIPELINE_ROOT in pipeline.config.sh}"
: "${WORKORDERS_DIR:?set WORKORDERS_DIR in pipeline.config.sh}"
: "${BUGS_DIR:?set BUGS_DIR in pipeline.config.sh}"
: "${TESTING_DIR:?set TESTING_DIR in pipeline.config.sh}"
: "${SESSIONS_DIR:?set SESSIONS_DIR in pipeline.config.sh}"
export API_BASE_URL="${API_BASE_URL:-http://localhost:3001/api/v1}" WEB_ORIGIN="${WEB_ORIGIN:-http://localhost:3000}"

VARS=(PROJECT_NAME PROJECT_SLUG PROJECT_DOMAIN GITHUB_REPO PROJECT_ROOT PIPELINE_ROOT
      WORKSPACE_DIR DOCS_DIR WORKORDERS_DIR BUGS_DIR TESTING_DIR SESSIONS_DIR
      API_APP ADMIN_APP PORTAL_APP DEV_APP WEB_APP SDK_PKG DB_NAME CLI_NAME API_BASE_URL WEB_ORIGIN
      PROJECT_DOMAIN_RE DEV_SUBDOMAINS PROD_IP)

DEST="$TARGET/$PIPELINE_ROOT"
if [ -e "$DEST" ] && [ "$(cd "$DEST" && pwd -P)" = "$(cd "$SRC" && pwd -P)" ]; then
  if [ -f "$DEST/.source" ] && [ -x "$(cat "$DEST/.source")/bin/install.sh" ] && [ "$(cd "$(cat "$DEST/.source")" && pwd -P)" != "$(cd "$SRC" && pwd -P)" ]; then
    echo "install: re-running from the pipeline source recorded at $(cat "$DEST/.source")"
    exec "$(cat "$DEST/.source")/bin/install.sh" "$@"
  fi
  echo "install: refusing to install the installed copy over itself ($DEST)." >&2
  echo "         Run install.sh from the pipeline repository (the clone of AICodePipeline), not from $PIPELINE_ROOT/bin." >&2
  exit 1
fi
say() { echo "  $*"; }

echo "Installing AICodePipeline ($PROFILE profile)"
echo "  from : $SRC"
echo "  into : $DEST"
echo "  as   : $PROJECT_NAME ($PROJECT_SLUG)"
echo

if [ "$DRY" = "--dry-run" ]; then
  echo "DRY RUN — nothing will be written."
  echo "Would render:"
  find "$SRC/core" "$SRC/harness" -type f | sed "s|$SRC/|    |"
  echo "Would create: $TARGET/{$WORKORDERS_DIR,$BUGS_DIR,$TESTING_DIR/suites,$SESSIONS_DIR/{active,archive}}"
  echo "Would link:   $TARGET/.claude/{agents,commands}"
  exit 0
fi

# --- 1. Copy core/ and harness/ verbatim, then render ---------------------
mkdir -p "$DEST"
# Overlays are the user's own agent narrowing; they survive every reinstall.
# Overlays and the harness configuration are the project's own; they survive every reinstall.
KEEP_OVERLAYS="$(mktemp -d)"; KEEP_HCONF="$(mktemp -d)"
[ -d "$DEST/core/agents/overlays" ] && cp -R "$DEST/core/agents/overlays/." "$KEEP_OVERLAYS/" 2>/dev/null || true
[ -d "$DEST/harness/config" ] && cp -R "$DEST/harness/config/." "$KEEP_HCONF/" 2>/dev/null || true
rm -rf "$DEST/core" "$DEST/harness"
cp -R "$SRC/core" "$SRC/harness" "$DEST/" || { echo "install: copying core/ and harness/ from $SRC failed" >&2; exit 1; }
find "$DEST/core" "$DEST/harness" -name .DS_Store -delete 2>/dev/null || true
printf '%s\n' "$(cd "$SRC" && pwd -P)" > "$DEST/.source"
mkdir -p "$DEST/core/agents/overlays"; cp -R "$KEEP_OVERLAYS/." "$DEST/core/agents/overlays/" 2>/dev/null || true; rm -rf "$KEEP_OVERLAYS"
[ -n "$(ls -A "$KEEP_HCONF" 2>/dev/null)" ] && { cp -R "$KEEP_HCONF/." "$DEST/harness/config/"; say "harness/config kept from the previous install"; }; rm -rf "$KEEP_HCONF"
echo "$PROFILE" > "$DEST/.profile"
mkdir -p "$DEST/bin"
cp -p "$SRC/bin/acp" "$SRC/bin/wo" "$SRC/bin/bug" "$SRC/bin/pack" "$SRC/bin/sanitize" "$SRC/bin/detect-stack" "$SRC/bin/stack-specialist" "$SRC/bin/new-project" "$SRC/bin/install.sh" "$SRC/bin/build-plugin" "$SRC/bin/eval" "$SRC/bin/lint" "$DEST/bin/"
mkdir -p "$DEST/bin/dev"
cp -p "$SRC"/bin/dev/*.sh "$DEST/bin/dev/"
chmod +x "$DEST"/bin/acp "$DEST"/bin/wo "$DEST"/bin/bug "$DEST"/bin/pack "$DEST"/bin/sanitize "$DEST"/bin/detect-stack "$DEST"/bin/stack-specialist "$DEST"/bin/new-project "$DEST"/bin/install.sh "$DEST"/bin/build-plugin "$DEST"/bin/eval "$DEST"/bin/lint "$DEST"/bin/dev/*.sh
mkdir -p "$DEST/packs"
[ -f "$DEST/packs/README.md" ] || cp "$SRC/packs/README.md" "$DEST/packs/README.md"
[ -f "$DEST/packs/INDEX.md" ] || cp "$SRC/packs/INDEX.md" "$DEST/packs/INDEX.md"
say "copied core/ harness/ bin/ and an empty packs/"

export "${VARS[@]}"
# One process renders every file: the per-file, per-variable loop this replaces
# spawned thousands of interpreters and took forty seconds on a full install.
rendered="$(RENDER_VARS="${VARS[*]}" python3 - "$DEST/core" "$DEST/harness" "$DEST/bin/dev" <<'PYEOF'
import os, re, sys
names = os.environ["RENDER_VARS"].split()
values = {n: os.environ.get(n, "") for n in names}
rx = re.compile(r"\{\{(" + "|".join(map(re.escape, names)) + r")\}\}")
exts = {".md", ".sh", ".env", ".js", ".json", ".sql", ".py", ".yaml", ".yml", ".txt"}
n = 0
for root in sys.argv[1:]:
    for d, _, files in os.walk(root):
        if "/core/templates/project" in d: continue
        for f in files:
            if os.path.splitext(f)[1] not in exts: continue
            fp = os.path.join(d, f)
            try: t = open(fp, encoding="utf-8").read()
            except (UnicodeDecodeError, OSError): continue
            u = rx.sub(lambda m: values[m.group(1)], t)
            if u != t: open(fp, "w", encoding="utf-8").write(u)
            n += 1
print(n)
PYEOF
)"
say "rendered $rendered files"

# Only the pipeline's own variables count as unresolved; skills may carry their own {{TEMPLATE}} syntax.
VAR_RE="$(printf '%s|' "${VARS[@]}")STACK_SECTION"
unresolved="$(grep -rhoE "\{\{(${VAR_RE})\}\}" "$DEST/core" "$DEST/harness" "$DEST/bin/dev" --exclude-dir=project 2>/dev/null | sort -u || true)"
[ -n "$unresolved" ] && { echo; echo "  WARNING — unresolved variables remain:"; echo "$unresolved" | sed 's/^/    /'; echo; }

# --- 2. Workspace folders -------------------------------------------------
mkdir -p "$TARGET/$WORKORDERS_DIR" "$TARGET/$BUGS_DIR" \
         "$TARGET/$TESTING_DIR/suites" "$TARGET/$TESTING_DIR/results" \
         "$TARGET/$SESSIONS_DIR/active" "$TARGET/$SESSIONS_DIR/archive"
[ -f "$TARGET/$TESTING_DIR/suites.manifest" ] || cp "$DEST/harness/config/suites.manifest" "$TARGET/$TESTING_DIR/suites.manifest"
say "created workspace folders (suite manifest: $TESTING_DIR/suites.manifest)"

# --- 3. Wire agents and slash commands into .claude/ ---------------------
mkdir -p "$TARGET/.claude/agents" "$TARGET/.claude/commands"
cp -p "$DEST"/core/agents/base/*.md  "$TARGET/.claude/agents/"
cp -p "$DEST"/core/agents/roles/*.md "$TARGET/.claude/agents/"
if [ -d "$DEST/core/agents/overlays" ]; then
  for f in "$DEST"/core/agents/overlays/*.md; do
    [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] && cp -p "$f" "$TARGET/.claude/agents/"
  done
fi
rm -f "$TARGET/.claude/agents/README.md"
[ "$PROFILE" = "full" ] && AGENT_PACKS="$(ls "$DEST/core/agents/domain" | grep -v README | tr '\n' ' ')"
[ "$PROFILE" = "full" ] && SKILL_PACKS="$(ls -d "$DEST"/core/skill-packs/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
for sp in ${SKILL_PACKS:-}; do
  [ -d "$DEST/core/skill-packs/$sp" ] || { echo "  WARNING — skill pack '$sp' not found"; continue; }
  mkdir -p "$TARGET/.claude/skills"
  for d in "$DEST/core/skill-packs/$sp"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    rm -rf "$TARGET/.claude/skills/$(basename "$d")"; cp -R "$d" "$TARGET/.claude/skills/$(basename "$d")"
  done
  say "skill pack '$sp' installed"
done
python3 - "$TARGET/.claude/agents" "$DEST/core/agents/domain" "${AGENT_PACKS:-}" <<'PYEOF'
import os, sys
installed, domain, selected = sys.argv[1:4]
sel = set(selected.split()); removed = 0
if os.path.isdir(domain) and os.path.isdir(installed):
    for pk in os.listdir(domain):
        d = os.path.join(domain, pk)
        if not os.path.isdir(d) or pk in sel: continue
        for f in os.listdir(d):
            if f.endswith(".md") and f != "README.md" and os.path.exists(os.path.join(installed, f)):
                os.remove(os.path.join(installed, f)); removed += 1
if removed: print(f"  reconciled: {removed} domain agent(s) from packs not selected removed")
PYEOF
for ap in ${AGENT_PACKS:-}; do
  if [ -d "$DEST/core/agents/domain/$ap" ]; then cp -p "$DEST"/core/agents/domain/"$ap"/*.md "$TARGET/.claude/agents/"; say "agent pack installed: $ap"
  else echo "  WARNING: no agent pack named '$ap' (available: $(ls "$DEST/core/agents/domain" | grep -v README | tr '\n' ' '))" >&2; fi
done

# Workflows — executable review pipeline, discoverable by name
if ls "$DEST"/core/workflows/*.js >/dev/null 2>&1; then
  mkdir -p "$TARGET/.claude/workflows"
  cp -p "$DEST"/core/workflows/*.js "$TARGET/.claude/workflows/"
fi
cp -p "$DEST"/core/commands/*.md "$TARGET/.claude/commands/"

# Skills — the methodology, loaded on demand rather than hoped-for
mkdir -p "$TARGET/.claude/skills"
LIFECYCLE="work-order bug-triage behavioral-testing session-handoff pack-search project-onboarding"
for d in "$DEST"/core/skills/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"
  if [ "$PROFILE" = "minimal" ]; then case " $LIFECYCLE " in *" $n "*) ;; *) continue;; esac; fi
  rm -rf "$TARGET/.claude/skills/$n"
  cp -R "$d" "$TARGET/.claude/skills/$n"
done
# Reconcile: anything pipeline-owned that this profile does not select is removed;
# the user's own skills and agents (names the pipeline does not ship) are never touched.
python3 - "$TARGET/.claude/skills" "$DEST/core/skills" "$DEST/core/skill-packs" "$PROFILE" "${SKILL_PACKS:-}" "$LIFECYCLE" <<'PYEOF'
import os, shutil, sys
installed, core, packs, profile, selected_packs, lifecycle = sys.argv[1:7]
owned = set(os.listdir(core)) if os.path.isdir(core) else set()
pack_skills = {}
if os.path.isdir(packs):
    for pk in os.listdir(packs):
        d = os.path.join(packs, pk)
        if os.path.isdir(d): pack_skills[pk] = set(x for x in os.listdir(d) if os.path.isdir(os.path.join(d, x)))
for ss in pack_skills.values(): owned |= ss
if profile == "minimal": selected = set(lifecycle.split())
else: selected = set(x for x in owned if x in os.listdir(core)) if os.path.isdir(core) else set()
for pk in selected_packs.split(): selected |= pack_skills.get(pk, set())
removed = 0
if os.path.isdir(installed):
    for name in os.listdir(installed):
        if name in owned and name not in selected:
            shutil.rmtree(os.path.join(installed, name), ignore_errors=True); removed += 1
if removed: print(f"  reconciled: {removed} pipeline skill(s) not in the {profile} profile removed (user skills untouched)")
PYEOF

say "installed $(ls "$TARGET/.claude/agents" | wc -l | tr -d ' ') agents, $(ls "$TARGET/.claude/commands" | wc -l | tr -d ' ') commands, $(ls "$TARGET/.claude/skills" | wc -l | tr -d ' ') skills, $(ls "$TARGET/.claude/workflows" 2>/dev/null | wc -l | tr -d ' ') workflows"

# --- 3b. Rules: common always, language sets by detected stack -----------
mkdir -p "$TARGET/.claude/rules"
STACK_JSON="$("$SRC/bin/detect-stack" "$TARGET" --json 2>/dev/null || echo '{}')"
RULE_SETS="$(printf '%s' "$STACK_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(" ".join(d.get("rule_sets") or ["common"]))' 2>/dev/null || echo common)"
[ -n "${EXTRA_RULE_SETS:-}" ] && RULE_SETS="$RULE_SETS $EXTRA_RULE_SETS"
installed_rules=""
for rs in $RULE_SETS; do
  if [ -d "$DEST/core/rules/$rs" ]; then
    rm -rf "$TARGET/.claude/rules/$rs"; cp -R "$DEST/core/rules/$rs" "$TARGET/.claude/rules/$rs"
    installed_rules="$installed_rules $rs"
  fi
done
say "installed rules:$installed_rules"

# --- 4. Hooks and permission baseline -------------------------------------
chmod +x "$DEST"/core/hooks/* 2>/dev/null || true
SETTINGS="$TARGET/.claude/settings.json"
ACP_PROFILE_MINIMAL="$([ "$PROFILE" = minimal ] && echo 1 || echo 0)" python3 - "$SETTINGS" "$DEST/core/config/settings.hooks.json" "$DEST/core/config/settings.baseline.json" <<'PYEOF'
import json, os, sys
target, hooks_f, base_f = sys.argv[1:4]
cur = {}
if os.path.exists(target):
    try: cur = json.load(open(target))
    except Exception: cur = {}
hooks = json.load(open(hooks_f))
base  = json.load(open(base_f))
# Hooks are merged by identity: every command carrying an "acp:" id is pipeline-owned and is
# replaced by the shipped version (upgrades); everything else in the user's settings is kept.
def is_acp(h): return "acp:" in (h.get("command") or "")
existing = cur.get("hooks") or {}
kept = {}
removed = 0
for ev, groups in existing.items():
    out = []
    for g in groups:
        hs = [h for h in (g.get("hooks") or []) if not is_acp(h)]
        removed += len(g.get("hooks") or []) - len(hs)
        if hs: out.append({**g, "hooks": hs})
    if out: kept[ev] = out
if os.environ.get("ACP_PROFILE_MINIMAL") == "1":
    note = f"hooks: none installed (minimal profile); {removed} pipeline hook(s) removed, user hooks kept"
    if kept: cur["hooks"] = kept
    else: cur.pop("hooks", None)
else:
    merged = dict(kept)
    for ev, groups in hooks["hooks"].items():
        merged.setdefault(ev, []).extend(groups)
    cur["hooks"] = merged
    n = sum(len(g.get("hooks") or []) for gs in hooks["hooks"].values() for g in gs)
    note = f"hooks: {n} pipeline hooks installed ({removed} replaced), user hooks kept"
perms = cur.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
added = [r for r in base["permissions"]["allow"] if r not in allow]
allow.extend(added)
perms["allow"] = sorted(set(allow))
deny = perms.setdefault("deny", [])
added_deny = [r for r in base["permissions"].get("deny", []) if r not in deny]
deny.extend(added_deny); perms["deny"] = sorted(set(deny)); perms.setdefault("ask", [])
os.makedirs(os.path.dirname(target), exist_ok=True)
json.dump(cur, open(target, "w"), indent=2)
print(f"  {note}; {len(added)} allow and {len(added_deny)} deny rules added")
PYEOF

# --- 5. Project CLAUDE.md, only if the project has none ------------------
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  STACK_SECTION="$(printf '%s' "$STACK_JSON" | python3 -c '
import json,sys
d=json.load(sys.stdin)
if d.get("empty"):
    print("- **Stack:** _(empty project — fill in once code exists)_"); print("- **Run locally:** _(the command)_"); print("- **Run tests:** _(the command)_")
else:
    print("- **Stack:** " + ", ".join(d["languages"] + d["frameworks"]) + (" (" + d["package_manager"] + ")" if d["package_manager"] else ""))
    c=d.get("commands",{})
    print("- **Run locally:** `" + c.get("run","_(the command)_") + "`"); print("- **Run tests:** `" + c.get("test","_(the command)_") + "`")
    if c.get("build"): print("- **Build:** `" + c["build"] + "`")
    print("- **Rule sets installed:** " + ", ".join(d["rule_sets"]))
' 2>/dev/null || echo "- **Stack:** _(fill in)_")"
  cp "$SRC/core/templates/project/CLAUDE.md" "$TARGET/CLAUDE.md"
  for v in "${VARS[@]}"; do VAR="$v" VAL="${!v-}" perl -pi -e 's/\{\{\Q$ENV{VAR}\E\}\}/$ENV{VAL}/g' "$TARGET/CLAUDE.md"; done
  STACK_JSON="$STACK_JSON" STACKS_DIR="$SRC/core/templates/project/stacks" python3 - "$TARGET/CLAUDE.md" "$STACK_SECTION" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text().replace("{{STACK_SECTION}}", sys.argv[2])
import json, os
stacks = []
try:
    d = json.loads(os.environ.get("STACK_JSON") or "{}")
    fw, langs = d.get("frameworks", []), d.get("languages", [])
    for key, cond in (("nextjs", "nextjs" in fw), ("nestjs", "nestjs" in fw), ("golang", "golang" in langs), ("python", "python" in langs),
                      ("rust", "rust" in langs), ("php", "php" in langs), ("ruby", "ruby" in langs), ("flutter", "flutter" in fw or "dart" in langs),
                      ("java", "java" in langs and "kotlin" not in langs), ("kotlin", "kotlin" in langs), ("swift", "swift" in langs), ("csharp", "csharp" in langs),
                      ("angular", "angular" in fw), ("vue", "vue" in fw), ("svelte", "svelte" in fw), ("remix", "remix" in fw)):
        if cond: stacks.append(key)
except Exception: pass
frag = ""
for k in stacks:
    fp = os.path.join(os.environ.get("STACKS_DIR", ""), k + ".md")
    if os.path.exists(fp): frag += "\n" + open(fp).read().strip() + "\n"
if frag: s = s.replace("\n---\n\n## Where Things Live", "\n---\n" + frag + "\n---\n\n## Where Things Live", 1)
p.write_text(s)
PYEOF
  say "wrote CLAUDE.md from the project template (none existed)"
else
  say "CLAUDE.md exists — left alone"
fi

echo
echo "Done. Next:"
echo "  export PATH=\"$DEST/bin:\$PATH\""
echo "  cd $TARGET && acp doctor && wo new \"My first work order\""
echo
echo "Project-specific agent rules belong in $PIPELINE_ROOT/core/agents/overlays/,"
echo "not in base/ — base agents are replaced wholesale on the next install."
