#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# pre-push — refuse a force push or a deletion of a shared branch.
#
# The rule already existed as a markdown hook rule (core/hooks/rules/
# block-force-push-shared.md), which matches the text of a Bash tool call and so
# only ever fires inside Claude Code. Anything else — another agent, a person at
# a terminal, a script — rewrote shared history unopposed. Git runs this hook no
# matter who is pushing, so this is the same rule where it actually holds.
#
# Blocking under every profile. There is no advisory form of losing someone
# else's commits. (The minimal profile installs no git hooks at all, so this
# script is simply not wired there.)
#
# Git gives the hook `<remote-name> <remote-url>` as arguments and one line per
# ref on stdin:
#
#     <local-ref> <local-sha> <remote-ref> <remote-sha>
#
# A deletion has an all-zero local sha; a branch the remote does not have yet has
# an all-zero remote sha. Anything else is a force push exactly when the commit
# the remote has is not an ancestor of the one being pushed.
#
# Override, for the case where rewriting the shared branch is the intent:
#
#     ACP_ALLOW_FORCE_PUSH=1 git push --force origin main
# ---------------------------------------------------------------------------
set -uo pipefail

# Shared: branches other people build on. `release/*` is a prefix, the rest exact.
shared_branch() {
  case "$1" in
    main|master|develop|production) return 0;;
    release/*) return 0;;
    *) return 1;;
  esac
}

# An all-zero object id, whatever the repository's hash length. An empty field is
# not one: it means the line was malformed, and a malformed line judges nothing.
zero_sha() {
  [ -n "$1" ] || return 1
  case "$1" in *[!0]*) return 1;; *) return 0;; esac
}

refused=0
note() { printf 'pre-push: %s\n' "$*" >&2; }

# read -r with no IFS change: git separates the four fields with single spaces.
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -n "$remote_ref" ] || continue
  branch="${remote_ref#refs/heads/}"
  [ "$branch" != "$remote_ref" ] || continue      # a tag or a note; this rule is about branches
  shared_branch "$branch" || continue             # your own branches are your own business

  if zero_sha "$local_sha"; then
    note "refusing to delete the shared branch '$branch' on '${1:-the remote}'."
    note "  Everyone tracking it loses it, and the branch is what their work returns to."
    note "  If the branch really is finished: delete it in the host's interface, where the"
    note "  decision is recorded, or repeat this with  ACP_ALLOW_FORCE_PUSH=1  to override here."
    refused=1
    continue
  fi

  zero_sha "$remote_sha" && continue              # the remote does not have it yet; nothing to lose

  if ! git cat-file -e "$remote_sha^{commit}" 2>/dev/null; then
    note "the commit '$remote_ref' points at on '${1:-the remote}' ($(printf '%.12s' "$remote_sha")) is not in this clone,"
    note "  so nothing here can show this push would keep it. Run  git fetch  and push again."
    note "  To push anyway:  ACP_ALLOW_FORCE_PUSH=1 git push ..."
    refused=1
    continue
  fi

  if ! git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null; then
    note "refusing a force push to the shared branch '$branch' on '${1:-the remote}'."
    note "  $(printf '%.12s' "$remote_sha") is not an ancestor of $(printf '%.12s' "$local_sha"): commits on the remote would be dropped."
    note "  Rebase onto it and push normally:  git pull --rebase && git push"
    note "  Or, if this branch is only yours:  git push --force-with-lease"
    note "  To rewrite the shared branch deliberately:  ACP_ALLOW_FORCE_PUSH=1 git push --force ..."
    refused=1
  fi
done

if [ "$refused" -eq 1 ]; then
  if [ "${ACP_ALLOW_FORCE_PUSH:-}" = "1" ]; then
    note "ACP_ALLOW_FORCE_PUSH=1 — allowed. Tell the people on this branch before they pull."
    exit 0
  fi
  exit 1
fi
exit 0
