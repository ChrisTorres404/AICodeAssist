#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install.sh — render the pipeline into a target project
#
#   bin/install.sh /path/to/project [--dry-run]
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
TARGET="${1:-}"; DRY="${2:-}"
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

VARS=(PROJECT_NAME PROJECT_SLUG PROJECT_DOMAIN GITHUB_REPO PROJECT_ROOT PIPELINE_ROOT
      WORKSPACE_DIR DOCS_DIR WORKORDERS_DIR BUGS_DIR TESTING_DIR SESSIONS_DIR
      API_APP ADMIN_APP PORTAL_APP DEV_APP WEB_APP SDK_PKG DB_NAME CLI_NAME
      PROJECT_DOMAIN_RE DEV_SUBDOMAINS PROD_IP)

DEST="$TARGET/$PIPELINE_ROOT"
say() { echo "  $*"; }

echo "Installing AICodePipeline"
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
rm -rf "$DEST/core" "$DEST/harness"
cp -R "$SRC/core" "$SRC/harness" "$DEST/"
mkdir -p "$DEST/bin"
cp -p "$SRC/bin/acp" "$SRC/bin/wo" "$SRC/bin/bug" "$SRC/bin/pack" "$SRC/bin/sanitize" "$SRC/bin/detect-stack" "$SRC/bin/new-project" "$SRC/bin/install.sh" "$SRC/bin/build-plugin" "$DEST/bin/"
mkdir -p "$DEST/bin/dev"
cp -p "$SRC"/bin/dev/*.sh "$DEST/bin/dev/"
chmod +x "$DEST"/bin/acp "$DEST"/bin/wo "$DEST"/bin/bug "$DEST"/bin/pack "$DEST"/bin/sanitize "$DEST"/bin/detect-stack "$DEST"/bin/new-project "$DEST"/bin/install.sh "$DEST"/bin/build-plugin "$DEST"/bin/dev/*.sh
say "copied core/ harness/ bin/"

rendered=0
while IFS= read -r f; do
  for v in "${VARS[@]}"; do
    val="${!v-}"
    VAR="$v" VAL="$val" perl -pi -e 's/\{\{\Q$ENV{VAR}\E\}\}/$ENV{VAL}/g' "$f"
  done
  rendered=$((rendered + 1))
done < <(find "$DEST/core" "$DEST/harness" "$DEST/bin/dev" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.env' -o -name '*.js' -o -name '*.json' -o -name '*.sql' \) -not -path '*/core/templates/project/*')
say "rendered $rendered files"

unresolved="$(grep -rhoE '\{\{[A-Z_]+\}\}' "$DEST/core" "$DEST/harness" "$DEST/bin/dev" --exclude-dir=project 2>/dev/null | sort -u || true)"
[ -n "$unresolved" ] && { echo; echo "  WARNING — unresolved variables remain:"; echo "$unresolved" | sed 's/^/    /'; echo; }

# --- 2. Workspace folders -------------------------------------------------
mkdir -p "$TARGET/$WORKORDERS_DIR" "$TARGET/$BUGS_DIR" \
         "$TARGET/$TESTING_DIR/suites" "$TARGET/$TESTING_DIR/results" \
         "$TARGET/$SESSIONS_DIR/active" "$TARGET/$SESSIONS_DIR/archive"
say "created workspace folders"

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

# Workflows — executable review pipeline, discoverable by name
if ls "$DEST"/core/workflows/*.js >/dev/null 2>&1; then
  mkdir -p "$TARGET/.claude/workflows"
  cp -p "$DEST"/core/workflows/*.js "$TARGET/.claude/workflows/"
fi
cp -p "$DEST"/core/commands/*.md "$TARGET/.claude/commands/"

# Skills — the methodology, loaded on demand rather than hoped-for
mkdir -p "$TARGET/.claude/skills"
for d in "$DEST"/core/skills/*/; do
  [ -d "$d" ] || continue
  mkdir -p "$TARGET/.claude/skills/$(basename "$d")"
  cp -p "$d"/*.md "$TARGET/.claude/skills/$(basename "$d")/"
done

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
python3 - "$SETTINGS" "$DEST/core/config/settings.hooks.json" "$DEST/core/config/settings.baseline.json" <<'PYEOF'
import json, os, sys
target, hooks_f, base_f = sys.argv[1:4]
cur = {}
if os.path.exists(target):
    try: cur = json.load(open(target))
    except Exception: cur = {}
hooks = json.load(open(hooks_f))
base  = json.load(open(base_f))
if "hooks" not in cur:
    cur["hooks"] = hooks["hooks"]
    note = "hooks installed"
else:
    note = "hooks left alone (settings.json already defines them)"
perms = cur.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
added = [r for r in base["permissions"]["allow"] if r not in allow]
allow.extend(added)
perms["allow"] = sorted(set(allow))
perms.setdefault("deny", []); perms.setdefault("ask", [])
os.makedirs(os.path.dirname(target), exist_ok=True)
json.dump(cur, open(target, "w"), indent=2)
print(f"  {note}; {len(added)} permission rules added")
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
  python3 - "$TARGET/CLAUDE.md" "$STACK_SECTION" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); p.write_text(p.read_text().replace("{{STACK_SECTION}}", sys.argv[2]))
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
