#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
grep -q '^## MANDATORY: Work Order Methodology' AGENTS.md || { echo "AGENTS.md does not carry the methodology"; exit 1; }
grep -q '@AGENTS.md' CLAUDE.md || { echo "CLAUDE.md does not import AGENTS.md"; exit 1; }
[ "$(wc -l < CLAUDE.md)" -lt 40 ] || { echo "CLAUDE.md duplicates the instructions instead of importing them"; exit 1; }
out="$(./.aicodepipeline/bin/detect-stack . --write 2>&1)"
case "$out" in *"AGENTS.md"*) ;; *) echo "detect-stack --write did not refresh AGENTS.md: $out"; exit 1;; esac

# an existing project with its own CLAUDE.md: it is left alone, AGENTS.md is added, and the user is told how to link them
cd "$EVAL_TMP"; mkdir -p q && cd q && git init -q
printf '# Mine\n\nMy own rules.\n' > CLAUDE.md
sed -e 's|^export PROJECT_NAME=.*|export PROJECT_NAME="Q"|' -e 's|^export PROJECT_SLUG=.*|export PROJECT_SLUG="q"|' "$PIPELINE_ROOT/pipeline.config.example.sh" > pipeline.config.sh
out="$("$PIPELINE_ROOT/bin/install.sh" . 2>&1)"
[ "$(cat CLAUDE.md)" = "$(printf '# Mine\n\nMy own rules.\n')" ] || { echo "install modified the project's own CLAUDE.md"; exit 1; }
[ -f AGENTS.md ] || { echo "install did not write AGENTS.md next to an existing CLAUDE.md"; exit 1; }
case "$out" in *"add the line  @AGENTS.md"*) ;; *) echo "install did not say how to link an existing CLAUDE.md to AGENTS.md"; exit 1;; esac
doc="$(./.aicodepipeline/bin/acp doctor . 2>&1 || true)"
case "$doc" in *"does not import AGENTS.md"*) ;; *) echo "doctor did not warn that the two instruction files diverge"; exit 1;; esac

# an existing AGENTS.md is theirs too
printf '# Theirs\n' > AGENTS.md
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1
[ "$(cat AGENTS.md)" = "# Theirs" ] || { echo "install overwrote an existing AGENTS.md"; exit 1; }
exit 0
