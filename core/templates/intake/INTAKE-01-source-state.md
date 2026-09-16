# WO-XXXX: Source state — the project is under version control

**Intake step:** 1 of 6
**Suite:** `intake-01-source-state.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

Every piece of evidence this tool records is a statement about one particular state of your
source. A directory that has never been committed has no state to return to, so a pass
recorded against it can never be reproduced or disputed. This step asks for the one thing
the rest of the pipeline assumes: a repository, in this directory, with at least one commit.
It also reports what the remote says, because an adoption that measures the wrong tree
measures nothing.

## What the suite checks

- `git rev-parse --show-toplevel` succeeds inside the project root, so this really is a
  repository. When the root is tracked by a repository further up, the suite says so and
  passes.
- `git rev-parse HEAD` succeeds, so there is history to bind evidence to. The count of
  uncommitted paths is reported alongside it.
- The remote is reported. When a branch tracks an upstream, the suite prints how far ahead
  of and behind it this tree is, from
  `git rev-list --left-right --count '@{upstream}...HEAD'`. A remote with nothing tracked,
  or no remote at all, passes with a note. A remote is recommended, not required; knowing
  which tree is the project of record is what matters.

## When it fails

- **This is not a git repository.** Nothing here is under version control. Run `git init`
  in the project root, then `git add -A && git commit -m baseline`.
- **The repository has no commits.** A repository with no history has nothing to return to.
  Run `git add -A && git commit -m baseline`.
- **The remote is behind.** This passes, and prints a note: the pushed tree is not this
  tree. Decide which one is the project of record before recording anything about it. An
  adoption once found the pushed tree missing an entire harness restructure, and the
  divergence surfaced hours later by accident.
- **git is not on PATH.** The suite exits 77, which the driver records as
  NOT EXECUTED — PRECONDITION FAILED. Install git and run it again.

## What "done" means

The project root is a git repository, it has at least one commit, and you know whether a
remote holds the same tree you are about to measure. The suite exits 0, `wo verify` records
EXECUTED — PASS, and `wo close` accepts the work order.
