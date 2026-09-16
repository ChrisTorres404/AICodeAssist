#!/usr/bin/env bash
set -uo pipefail
# A user judges the tool by what their own copy says, and the copy is rendered
# with absolute paths the source tree never sees. Install under a path shaped
# like a home directory: that is the input that turns a rendered path into an
# error, and "Users/dev" is matched by the rule on macOS and Linux alike.
home="$EVAL_TMP/Users/dev"
mkdir -p "$home" && cd "$home" || { echo "could not prepare the fixture directory"; exit 1; }
"$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null 2>&1 || { echo "new-project failed"; exit 1; }
cd p || exit 1
L=./.aicodepipeline/bin/lint

out="$($L 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "a fresh install's own lint is not clean (exit $rc):"; echo "$out"; exit 1; }
printf '%s\n' "$out" | grep -q "^0 error(s)" || { echo "lint did not report zero errors:"; echo "$out"; exit 1; }

# The commands that ship inside the install must resolve the project at run
# time; none of them may carry the directory it happened to be installed into.
leaks="$(grep -rl "$home" .aicodepipeline/bin 2>/dev/null)"
[ -z "$leaks" ] || { echo "installed commands carry the install path:"; echo "$leaks"; exit 1; }

# The frontmatter check has two implementations. Most machines have no PyYAML
# and run the fallback, so lint it that way too.
mkdir -p "$EVAL_TMP/noyaml"
printf 'raise ImportError("yaml unavailable for this run")\n' > "$EVAL_TMP/noyaml/yaml.py"
out="$(PYTHONPATH="$EVAL_TMP/noyaml" python3 "$L" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "lint is not clean when PyYAML is unavailable (exit $rc):"; echo "$out"; exit 1; }

# The control: a clean report is only worth something if a broken file still
# fails. Drop in a skill whose frontmatter is not YAML and lint must name it.
probe=.aicodepipeline/core/skills/acp-lint-probe
mkdir -p "$probe"
cat > "$probe/SKILL.md" <<'EOF'
---
name: acp-lint-probe
description: >-broken folded scalar
  Use when proving the linter still reads frontmatter.
---

# Probe
EOF
out="$($L 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "lint accepted malformed skill frontmatter (exit $rc):"; echo "$out"; exit 1; }
printf '%s\n' "$out" | grep -q "acp-lint-probe/SKILL.md: frontmatter is not valid YAML" || { echo "lint did not name the malformed frontmatter:"; echo "$out"; exit 1; }
out="$(PYTHONPATH="$EVAL_TMP/noyaml" python3 "$L" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "the no-PyYAML fallback accepted malformed frontmatter (exit $rc):"; echo "$out"; exit 1; }

rm -rf "$probe"
$L >/dev/null 2>&1 || { echo "lint stayed dirty once the probe was removed"; exit 1; }
exit 0
