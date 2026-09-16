# Adopting an existing project

Most projects that want this pipeline are not new. They arrive with a record of work already
done, a test harness of their own, and a codebase nobody has measured in a while. This is the
order that works, written from an adoption that did most of it in the wrong order first.

The one-line version: **commit first, measure second, install third, wrap rather than rewrite,
then verify, close, and commit in that order.**

## Phase 0 — before you install anything

1. **Put the project under version control, and commit.** Not "it is in git somewhere": this
   directory, committed, clean. Evidence is bound to a source state, and a tree that has
   never been committed has no state to return to. A repository with no commits does not count;
   `acp doctor` says so.
2. **Confirm the directory you are adopting is the project of record.** If there is a remote,
   `acp doctor` reports how far ahead or behind it you are. An adoption once found the pushed
   tree missing an entire harness restructure, a bug sweep, and most of the unit tests, and the
   divergence surfaced hours later by accident. Decide which tree is the project before
   recording anything about it.
3. **Note what is unpinned.** Browser version, driver version ranges, any shared or remote data
   the tests depend on. Every one of those is a future false failure.

## Phase 1 — install and measure

4. `cp pipeline.config.example.sh` into the project, edit the few lines at the top, then
   `install.sh --dry-run` to see every file and every path before anything is written.
5. **Decide the workspace layout once.** Changing `WORKORDERS_DIR` and friends later means a
   reinstall; the installer names the folders it no longer reads rather than deleting them, and
   `acp doctor` notices when your instructions still point at the old layout, but neither
   moves anything for you.
6. `acp doctor`. Green here says the install is structurally sound and every agent and skill
   parses. It says nothing about whether your code works.
7. **`acp baseline`.** This is the step most adoptions skip and the one that matters most. It
   runs the project's own tests once, records the result bound to the tree it ran against, and
   reports the record against the measurement: how many items the record calls complete, how
   many have an executed pass under this tool, how many have no check at all. A failing
   baseline is information, not a block. It is the state the project is actually in, and every
   piece of evidence recorded afterwards is relative to it.

   Run the environment-free tier first if you can, and read it separately. Unit tests and a
   type check depend on nothing outside the repository. Browser suites depend on a running
   service, a reachable store, and the state of both. In one adoption the hermetic tier was 780
   for 780 while every one of eighteen failures lived in the browser layer, and most of those
   traced to environment rather than to defects. One blended number buries that.

## Phase 2 — the first commit

8. **A security test carrying a credential-shaped fixture will be refused.** Mark the line with
   `// acp:allow-secret` and say why. The pragma is per line, and it is in the diff where a
   reviewer sees it. Do not rename a good test to dodge the check.
9. **Do not chain staging onto the commit.** `git rm --cached X && git commit` fails, because the
   hook reads the index before your command runs. Stage in one command, commit in the next.
10. **Under Claude Code, hook settings live where the agent starts.** `ACP_DISABLED_HOOKS` and
    `ACP_HOOK_PROFILE` go in the `env` block of `.claude/settings.json`, or are exported before
    launching the agent. As a prefix on a single command they are silently ignored.

## Phase 3 — adopting the existing record

11. **Decide what "done" means for work that predates the pipeline, and let the tool record it
    that way.** `wo adopt <file> --number N` brings a work order in with its document unchanged,
    the number it already cites, the state `migrated`, and no verification. `bug adopt` does the
    same, and takes `--category` because an adopted number may land inside a series it does not
    belong to. `wo list --adopted` shows them; `wo stats` counts them on their own line; they
    stay out of cycle-time statistics. Use `--dry-run` to review a bulk migration before it runs.
12. **Never fabricate a verification.** Historical completion is recorded, not verified. An
    adopted item earns evidence the first time its suite genuinely runs under `wo verify`, and
    not before. This is the one rule that makes the rest of the record worth anything.

## Phase 4 — wiring the tests

13. **Wrap, do not rewrite.** If the project has a harness, `wo suite <n> --wrap '<command>'`
    scaffolds a thin suite that delegates to it and exits with its code. Set `SUITE_COMMAND` in
    `pipeline.config.sh` and that becomes the default shape, with `{wo}` and `{slug}` filled in.
    Rewriting a shared harness as shell scripts throws away the shared context that made it
    good.
14. **Make every suite establish its own preconditions, and exit 77 when it cannot.** A suite
    whose environment never came up has asserted nothing. Exit 77 is recorded as
    `NOT EXECUTED — PRECONDITION FAILED`, never as a failure of the code, and close refuses on it
    as such. In one adoption a console that redirected to its connection wizard produced eleven
    failures on one work order, all of them false, all of them reading exactly like regressions.
15. **Give the manifest a type.** `tier|type|file|label` lets `--tier essential --type unit`
    compose, so the hermetic suites can run everywhere and the browser suites only where a
    browser is.

## Phase 5 — the run, and closing

16. **Verify, then close, then commit, in any order you like.** The fingerprint binds to file
    content whether or not git tracks it, so committing does not change it. What does: any edit
    inside the tree between the pass and the close, including formatting and a teammate's
    change. Writing the next suite does not stale this one; the suite that ran is bound on its
    own, so changing it does.
17. **Read failures at the check level.** `wo list` shows `FAIL 42/43` beside `FAIL 0/15`,
    because the count a runner printed is kept with the verdict. One adoption was 97 percent
    green by check and 63 percent green by work order, and the difference was one stale
    selector in an otherwise healthy module.
18. **Triage every failure into three buckets before believing any of them:** a real defect, a
    stale check, an unmet precondition. Of ten in one adoption, three traced to a single
    unreviewed change, four to editor timing, two to shared data, and two warranted a bug.
19. **Promote what earned it.** `wo promote` carries the suites that produced the evidence into
    the pack, and marks any referenced file that did not travel. `pack lint` tells you which
    entries still have placeholder pitfalls, which are the part the next project actually needs.

## What the tool still does not do

- It cannot pin your environment. A baseline on a floating browser version and a shared,
  mutable store measures the environment as much as the code. Pin what you can and write down
  what you cannot.
- It cannot classify a failure. It can now tell "could not run" from "ran and failed", and it
  keeps the count, but "stale selector" versus "real defect" is still yours to decide.
- It cannot keep the baseline true. A baseline is a photograph, and it starts decaying the
  moment work resumes. CI running `acp check` and the project's own tests on every pull
  request is what keeps it honest; `acp ci github` adds that workflow.
