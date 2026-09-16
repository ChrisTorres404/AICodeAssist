#!/usr/bin/env bash
set -uo pipefail
H="$PIPELINE_ROOT/core/hooks/wo-reference.py"
cd "$EVAL_TMP"; mkdir -p p && cd p || exit 1
git init -q >/dev/null 2>&1; git -c user.email=e@x -c user.name=e commit -q --allow-empty -m init >/dev/null 2>&1
mkdir -p Workspace/Docs/WorkOrders Workspace/Docs/Bugs

# the hook as a PreToolUse hook: the message is inside the command line
tool_hook() { printf '%s' "{\"tool_input\":{\"command\":\"git commit -m \\\"$1\\\"\"}}" | python3 "$H" 2>&1; }
# the hook as git's commit-msg hook: the message is in a file
msg_hook() { printf '%b' "$1" > "$EVAL_TMP/msg"; python3 "$H" "$EVAL_TMP/msg" 2>&1; }

# undeclared, in both forms: still refused, and the refusal names the trailer
out="$(tool_hook "docs: the traceability test quotes WO-9999")"; rc=$?
[ "$rc" -eq 2 ] || { echo "an undeclared phantom was accepted by the tool hook (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *Acp-Allow-Reference*) ;; *) echo "the tool hook's refusal named no way forward:"; echo "$out"; exit 1;; esac
out="$(msg_hook "docs: the traceability test quotes WO-9999\n")"; rc=$?
[ "$rc" -eq 1 ] || { echo "an undeclared phantom was accepted by the commit-msg hook (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *Acp-Allow-Reference*) ;; *) echo "the commit-msg refusal named no way forward:"; echo "$out"; exit 1;; esac

# declared in the trailer: accepted in both forms
out="$(tool_hook "docs: the traceability test quotes WO-9999\n\nAcp-Allow-Reference: WO-9999")"; rc=$?
[ "$rc" -eq 0 ] || { echo "the tool hook ignored Acp-Allow-Reference (exit $rc)"; echo "$out"; exit 1; }
out="$(msg_hook "docs: the traceability test quotes WO-9999\n\nAcp-Allow-Reference: WO-9999\n")"; rc=$?
[ "$rc" -eq 0 ] || { echo "the commit-msg hook ignored Acp-Allow-Reference (exit $rc)"; echo "$out"; exit 1; }

# a list, comma or space separated, and bugs as well as work orders
out="$(msg_hook "docs: about WO-9999, WO-8888 and BUG-0404\n\nAcp-Allow-Reference: WO-9999, WO-8888 BUG-0404\n")"; rc=$?
[ "$rc" -eq 0 ] || { echo "a list of declared identifiers was not honoured (exit $rc)"; echo "$out"; exit 1; }

# the declaration covers what it names and nothing else
out="$(msg_hook "docs: about WO-9999 and WO-7777\n\nAcp-Allow-Reference: WO-9999\n")"; rc=$?
[ "$rc" -eq 1 ] || { echo "a declaration of one identifier covered another (exit $rc)"; echo "$out"; exit 1; }
case "$out" in *WO-7777*) ;; *) echo "the refusal did not name the undeclared identifier:"; echo "$out"; exit 1;; esac
case "$out" in *WO-9999*) echo "the refusal named the declared identifier:"; echo "$out"; exit 1;; *) ;; esac

# everything else about the hook is unchanged: a real work order passes, a
# message naming none stays advisory
mkdir -p Workspace/Docs/WorkOrders/WO-0123-real
out="$(msg_hook "WO-0123: the work this commit belongs to\n")"; rc=$?
[ "$rc" -eq 0 ] || { echo "a commit citing a real work order was refused (exit $rc)"; echo "$out"; exit 1; }
rc=0; tool_hook "chore: tidy the build script" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] || { echo "an unreferenced commit was blocked (exit $rc)"; exit 1; }
exit 0
