# Testing AICodePipeline

You have just cloned this repository and need to decide whether it works. This
page is the whole procedure. It is written for an outside engineer or an
automated agent: every command below exists in the tree and was run to produce
the output shown.

Nothing here writes outside the repository except `harness/evals/results/`,
`dist/`, the `mktemp -d` scratch directories the evaluations work in, and the
`/tmp/smoke` project in the manual path at the end.

## Prerequisites

| Needed | For |
|---|---|
| macOS or Linux, bash 3.2+ | everything (Windows is not supported) |
| `python3`, `perl`, `git` | the drivers, the installer, the hooks |
| `node` | only the Node fixture in the manual smoke path |
| `claude` CLI | plugin validation, and the live-session tier |

Nothing needs installing: no package manager, no build step, no dependencies.

```bash
cd <your-clone-of-this-repo>
```

All paths below are relative to that directory.

---

## The one command

```bash
bin/acp test
```

It runs the lint, the sanitizer over every shipped directory, every
evaluation, the plugin build, and — when the `claude` CLI is on PATH — plugin
validation. Takes a minute or two. Expected output:

```
== lint
0 error(s), 0 warning(s) across the pipeline
== sanitize
  core clean
  bin clean
  docs clean
  harness clean
  packs clean
== evaluations
  fresh-install-day-one            PASS (5s)
  hook-blocks-database-drop        PASS (0s)
  hook-commit-quality-blocks-secret PASS (0s)
  hook-config-protection           PASS (0s)
  hook-doc-claims                  PASS (1s)
  install-profiles                 PASS (9s)
  install-self-guard               PASS (16s)
  lint-and-sanitize-clean          PASS (1s)
  stack-fixtures                   PASS (41s)
  wo-close-needs-verification      PASS (3s)

  19 passed, 0 failed — harness/evals/results/2026-09-11--195943.md

== plugin
  built dist/plugin
  plugin validates

ALL CHECKS PASSED
```

**Exit 0 and a final line of `ALL CHECKS PASSED` is the pass condition.**
Anything else prints `CHECKS FAILED` and exits non-zero. `bin/acp test --live`
adds the live-session tier described further down; it spends tokens, so it is
not part of the default run.

If the `claude` CLI is absent the plugin line reads
`(claude CLI not found; plugin validation skipped)` and that is not a failure.
A `== portability` section runs after the plugin build whenever
`bin/maintenance/portability-check.sh` is present and executable, and must also
pass:

```
portability-check — 49 shell scripts under <repo>

  clean — nothing found that runs on only one of macOS and Linux
```

---

## The checks individually

Run these when `bin/acp test` fails and you need to know which part broke.

### 1. Lint the shipped surface

```bash
bin/lint            # add --strict to make warnings fail
```

Validates every agent (frontmatter, model, a dispatchable description, minimum
depth), every skill (a `SKILL.md` with name and description), the hook rules
and hooks JSON, the rule files, and scans for personal paths, invisible or
bidirectional unicode, and template variables left unresolved outside
templates. **Proves:** nothing ships malformed or carrying a host path.

```
0 error(s), 0 warning(s) across the pipeline
```

Exit 0 clean, 1 warnings only, 2 errors.

### 2. Sanitize every shipped directory

```bash
for d in core bin docs harness packs; do bin/sanitize "$d"; done
```

Scans for secrets, personal identifiers, internal infrastructure, host paths,
and dangerous files. **Proves:** the tree is safe to publish. Each directory
ends with a verdict:

```
# Sanitization Report: docs

**Files scanned:** 4
**Verdict:** PASS

## Critical findings (0)
## Warnings (0)

## Recommendation

Clear. Safe to share.
```

Exit 0 clean, 1 warnings, 2 critical findings. **A single critical finding is a
FAIL.** Add `--report report.md` to write it to a file, `--quiet` to suppress
the report body.

### 3. The evaluations

```bash
bin/eval list              # what exists
bin/eval run               # all of them; exit 1 if any fails
bin/eval run stack-fixtures   # one
```

Each evaluation installs the pipeline into a scratch project, drives a hook or
a driver for real, and asserts on what happened.

| Evaluation | Proves |
|---|---|
| `fresh-install-day-one` | a brand-new project installs with no unresolved variables, passes `acp doctor`, and can run `pack search` and the first work-order commands |
| `hook-blocks-database-drop` | the destructive-SQL rule still blocks `DROP DATABASE` |
| `hook-commit-quality-blocks-secret` | a staged AWS-style key blocks the commit; a clean commit passes |
| `hook-config-protection` | editing an existing `tsconfig` is blocked, creating one is allowed |
| `hook-doc-claims` | `SOURCE` comments pointing at missing files are reported, traced claims are silent, only strict blocks |
| `install-profiles` | minimal, standard, and full install what they promise |
| `install-self-guard` | `install.sh` run from the installed copy refuses instead of deleting the install |
| `lint-and-sanitize-clean` | the tree passes its own lint and sanitizer |
| `stack-fixtures` | seventeen stacks each get the right rule sets, stack profile, Stack line, and run/test commands |
| `wo-close-needs-verification` | close and promote refuse on missing, plan-only, or failed verification |

Expected output is one line per evaluation and a summary; exit 0 when
`0 failed`:

```
  stack-fixtures                   PASS (41s)

  1 passed, 0 failed — harness/evals/results/2026-09-11--195812.md
```

A failure writes the last 40 lines of that evaluation's log into the results
file. `stack-fixtures` is the long one — it performs seventeen full installs, so
it takes anywhere from forty seconds to several minutes depending on the disk —
and it prints `KNOWN GAP` lines: shortfalls in stack detection that are recorded
deliberately and do not fail the run.

### 4. Build the plugin

```bash
bin/build-plugin
```

**Proves:** the plugin packaging still assembles from the same sources as the
installer.

```
built <repo>/dist/plugin (528 files)
  agents=95 skills=162 commands=32 rules=23 hooks=15
  WARNING unresolved: {{PIPELINE_ROOT}}
```

Exit 0. The `WARNING unresolved: {{PIPELINE_ROOT}}` line is expected on the
current tree — in plugin mode there is no installed path to resolve it to — and
`bin/acp test` does not treat it as a failure.

### 5. Validate the plugin

```bash
claude plugin validate dist/plugin
```

```
Validating marketplace manifest: <repo>/dist/plugin/.claude-plugin/marketplace.json

✔ Validation passed
```

Exit 0. **Proves:** the manifest, agents, commands, skills, and hooks are
loadable by Claude Code. Skip if the CLI is not installed.

---

## The live tier: real sessions

```bash
bin/eval live            # every scenario
bin/eval live feature    # one
```

**Requires the `claude` CLI, and it spends tokens** — four scenarios, minutes
each. This is the only tier that proves the *instruction* layer works: that
the agents, skills, commands, rules, and generated `CLAUDE.md` actually produce
the lifecycle rather than describing it.

Each scenario scaffolds a fresh project from `harness/evals/live/_fixture/`,
installs the pipeline, commits, runs `claude -p` with permissions bypassed
inside that directory only, saves the JSON transcript, and runs a check script.

| Scenario | Asks the session to | Passes when |
|---|---|---|
| `feature` | add a `GET /api/v1/tasks/stats` endpoint through the full lifecycle | a work order was opened, the SPEC has no template placeholders and names the feature, the endpoint is in `src/server.js` with no `console.log`, a suite exists, the verification says `EXECUTED — PASS`, the closeout has real lessons, and the work order was promoted into a pack |
| `close-refusal` | close WO-0001 with verification explicitly skipped | either no closeout was written and the session said why, or a closeout exists **and** the verification really is `EXECUTED — PASS` |
| `analyze` | run `/analyze-repo .` | a work order with `area=analysis` exists, its documents carry at least three `<!-- SOURCE: -->` comments, and the doc-claims hook resolves every one of them |
| `hooks` | add request logging and a small helper, no work order | the logging exists, `src/util.js` was created, and no `console.log` survived the quality gate |

Tuning: `EVAL_LIVE_MODEL` (default `sonnet`), `EVAL_LIVE_MAX_TURNS` (default
80), `EVAL_LIVE_PROFILE` (default `standard`), `EVAL_KEEP=1` to keep the
scratch project of a failing scenario. Results land in
`harness/evals/results/live-<timestamp>.md` with turns and cost per scenario,
and the full transcript beside it as `live-<timestamp>-<scenario>.json`.

Run this tier before a release and after any change to agents, skills,
commands, rules, templates, or the `CLAUDE.md` template.

---

## Manual smoke path — five minutes, ten commands

For a human who wants to see it work rather than trust a green run. Nothing
here touches the repository.

```bash
bin/new-project /tmp/smoke --name "Smoke" --domain example.com   # 1. scaffold
cd /tmp/smoke && export PATH="$PWD/.aicodepipeline/bin:$PATH"    # 2. drivers on PATH
acp doctor                                                       # 3. expect: healthy
printf '{"scripts":{"dev":"node src/server.js","test":"node --test"}}' > package.json
mkdir -p src && echo 'export const x = 1' > src/server.js
detect-stack . --write                                           # 4. expect: Stack: javascript (npm)
wo new "Smoke test" --area backend                               # 5. expect: WO-0001 + four documents
wo suite 1                                                       # 6. expect: a suite in Workspace/Testing/suites/
wo close 1                                                       # 7. expect: REFUSED, no verification
bug new "Smoke bug" --category api                               # 8. expect: BUG-0100
pack search "anything"                                           # 9. expect: "no packs yet", exit 0
acp lint                                                         # 10. expect: 0 errors
```

Step 7 is the one that matters: `wo close` must refuse. If it produces a
closeout, the central guarantee of this pipeline is broken.

Clean up with `rm -rf /tmp/smoke`.

---

## How to report a failure

Include, in this order:

1. **The command and its full output**, plus `bash --version`,
   `python3 --version`, `uname -sr`, and `git rev-parse HEAD`.
2. **The results file** the run names —
   `harness/evals/results/<timestamp>.md` for `bin/eval run`, or
   `harness/evals/results/live-<timestamp>.md` plus the matching
   `live-<timestamp>-<scenario>.json` transcript for `bin/eval live`. The
   results file already contains the tail of each failing evaluation's log.
3. **For a live failure**, re-run that one scenario with `EVAL_KEEP=1` and
   attach the path it reports — the scratch project is kept with the work
   orders, suites, and `CLAUDE.md` the session actually produced.
4. **For an install or doctor failure**, the output of `acp doctor <project>`
   and the project's `pipeline.config.sh` with any values you consider private
   replaced.
5. **For a lint or sanitize failure**, the report itself
   (`bin/sanitize <dir> --report report.md`) rather than a summary of it.

Do not attach a scratch project without running `bin/sanitize` on it first.
