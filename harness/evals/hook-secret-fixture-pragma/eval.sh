#!/usr/bin/env bash
set -uo pipefail
H="$PIPELINE_ROOT/core/hooks/commit-quality.py"
C="$PIPELINE_ROOT/core/hooks/check.py"
cd "$EVAL_TMP"; git init -q r >/dev/null 2>&1; cd r || { echo "no fixture repo"; exit 1; }
git config user.email e@x; git config user.name e

hook() { printf '%s' '{"tool_input":{"command":"git commit -m x"}}' | python3 "$H" 2>&1; }

# The fixture is assembled at runtime so this evaluation's own source never carries
# a credential-shaped string. It is the shape a security test uses: the value the
# test asserts is never rendered.
SECRET_LINE="const REAL_SECRET = '$(printf '%s%s' 'sk-live-do-not' '-render-9f2b1c')';"

mkdir -p packages/ui/src/domain
F=packages/ui/src/domain/sidecarEmit.test.ts

# unmarked, in a test file: still blocked — a fixture is where a real credential hides best
printf '%s\n' "$SECRET_LINE" > "$F"; git add "$F"
out="$(hook)"; rc=$?
[ "$rc" -eq 2 ] || { echo "an unmarked credential in a test file was accepted (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *"acp:allow-secret"*) ;; *) echo "the refusal named no way forward:"; echo "$out"; exit 1;; esac

# marked on the line, with a reason: committable
printf '%s  // acp:allow-secret — fixture, asserted never to be emitted\n' "$SECRET_LINE" > "$F"; git add "$F"
out="$(hook)"; rc=$?
[ "$rc" -eq 0 ] || { echo "a fixture marked acp:allow-secret was still refused (exit $rc)"; echo "$out"; exit 1; }

# the pragma is per line, not per file: a second unmarked credential still blocks
printf '%s  // acp:allow-secret — fixture\nconst OTHER_SECRET = "%s";\n' \
  "$SECRET_LINE" "$(printf '%s%s' 'AKIA' 'ABCDEFGHIJKLMNOP')" > "$F"; git add "$F"
out="$(hook)"; rc=$?
[ "$rc" -eq 2 ] || { echo "the pragma exempted the whole file instead of the line (exit $rc)"; echo "$out"; exit 1; }

# check agrees with the hook, or a commit one lets through the other refuses
printf '%s  // acp:allow-secret — fixture, asserted never to be emitted\n' "$SECRET_LINE" > "$F"; git add "$F"
out="$(python3 "$C" --root . --paths "$F" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "check refused a fixture the commit hook allows (exit $rc)"; echo "$out"; exit 1; }
printf '%s\n' "$SECRET_LINE" > "$F"
out="$(python3 "$C" --root . --paths "$F" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "check accepted an unmarked credential (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *"acp:allow-secret"*) ;; *) echo "check's refusal named no way forward:"; echo "$out"; exit 1;; esac
exit 0
