# AICodePipeline

**by Christian Torres**

An engineering pipeline for working with AI coding agents that refuses to take
"done" on faith. Every unit of work is a work order with a specification, a
verification record built from tests that actually ran, and a closeout. The
driver will not produce a closeout without the evidence. Hooks catch debug
logging and stubs as they are written. Packs carry what you learned into the
next project, pitfalls included.

Built over a year of shipping a production identity platform with AI agents,
then extracted and made general so it works on any codebase, in any language.

---

## Start here

**New project, one command:**

```bash
bin/new-project ~/code/my-app --name "My App" --domain myapp.io
```

**Existing project:**

```bash
cp pipeline.config.example.sh /path/to/project/pipeline.config.sh   # edit it
bin/install.sh /path/to/project
```

**As a Claude Code plugin, no install step:**

```bash
bin/build-plugin
claude plugin add ./dist/plugin        # then /plugin install aicodepipeline
```

Either way you get: the drivers, 47 agents, 6 skills, 8 slash commands, 5 hooks, per-language
rules chosen by stack detection, a permission baseline, and a project
`CLAUDE.md` with the run and test commands already filled in.

---

## The work-order lifecycle

```bash
acp wo new "Rate limiting" --size standard --priority P1   # folder + required docs
acp wo start 0407 · block 0407 "reason" · note 0407 "text"  # status and session notes
acp wo verify 0407 --run suites/wo-0407.sh   # runs it; stamps EXECUTED — PASS/FAIL from exit code
acp wo close 0407          # REFUSES without a VERIFICATION document
acp wo promote 0407        # carry it into a pack, with a catalog entry
acp wo list · show · status · stats
```

`acp` is the front door; every subcommand is also a standalone script in
`bin/` you can call or edit directly. `acp doctor` tells you whether an
install is healthy.

**Size sets the ceremony.** A two-line fix does not need four documents.

| Size | Created at open | Always required to close |
|---|---|---|
| `trivial` | one document | VERIFICATION |
| `small` | SPEC | VERIFICATION |
| `standard` | SPEC, CHECKLIST, TASK-BREAKDOWN, Prompt | VERIFICATION |
| `large` | standard plus SDK and UI implementation docs | VERIFICATION |

The verification requirement never relaxes, and `wo verify` is the only thing
that should create the document: with `--run` it executes the suite and writes
the status from the exit code, so nobody types `PASS`. `bug` runs the same
lifecycle for defects, including `verify` and `promote`.

## Working with others

```bash
acp wo publish 0407    # opens a GitHub issue carrying the full work order
acp wo sync 0407       # pushes the current spec and status to the issue
acp wo import 77       # creates WO-0077 from an existing issue, numbers matched
```

The folder is the record; the issue is the shared view. `wo verify --run`
comments the result on the issue, and `wo close` closes it. Needs the `gh`
CLI, authenticated. Every work order records its `owner`.

**Honest status, always.** `EXECUTED — PASS`, `EXECUTED — FAIL`, or
`NOT EXECUTED — PLAN ONLY`. The third exists so the first is never used
falsely. The Stop hook checks that a closeout is not resting on the third.

---

## Enforcement, not exhortation

| Rule | Mechanism | Profile |
|---|---|---|
| No closeout without executed verification | `wo close`, `bug close` refuse | always |
| A closeout in the working tree rests on executed evidence | `evidence-gate.py` Stop hook | standard warns, strict blocks |
| No `console.log`, `TODO: implement`, not-implemented stubs | `quality-gate.py` PostToolUse | standard warns, strict blocks |
| Commits reference a work order | `wo-reference.py` PreToolUse | advisory |
| Force-push to shared branches, `--no-verify`, destructive shell | markdown hook rules | block / warn |
| Sessions open oriented | `session-orient.sh` SessionStart | all |

```bash
export ACP_HOOK_PROFILE=strict          # minimal | standard | strict
export ACP_DISABLED_HOOKS=acp:pre:wo-reference
```

Add your own rule as a markdown file in `.claude/hook-rules/`, no code:

```markdown
---
name: warn-direct-prod-db
event: bash
pattern: psql .*prod
action: warn
---
That looks like the production database. Are you sure?
```

---

## Rules and agents

`core/rules/common/` is eight short files, always loaded: work orders, testing,
coding style, code review, security, git, agents, patterns. `core/rules/ui/`
carries the UI standards — feature-folder structure, reusable components,
line limits that trigger extraction (page 150, component 200, modal 50, form
80, table 100), import paths, and verification — and loads whenever a UI
stack is present. Twenty-one language sets extend them; `install.sh` picks the
right ones from what `bin/detect-stack` finds.

Agents: 38 technology specialists and 9 process roles, selected by
description. Project-specific narrowing goes in `core/agents/overlays/`, which
survives reinstalls.

---

## Packs: precedent, not just process

A pack is a domain's accumulated experience: work orders, bugs, test suites,
architecture, and a catalog of pitfalls.

```bash
pack list
pack search "rate limit"
pack show WO-0407
```

`wo promote` moves a verified work order into your project's pack and writes a
catalog entry. Edit the **Pitfalls** lines while you still remember. That is
how the pipeline gets smarter the more you use it.

The `identity-platform` pack ships with the repository: 482 work orders, 74
bug investigations, 263 behavioral suites from a production IAM platform. It
**fails sanitization** and is not installed by default. See below.

---

## Before anything leaves your machine

```bash
bin/sanitize <dir> --report report.md
```

Secrets, personal identifiers, internal infrastructure, host paths, dangerous
files. A single critical finding is a FAIL. `new-project` refuses to install a
pack that fails; `wo promote` refuses to promote a work order that fails. The
`release-sanitizer` agent reviews the report with judgement.

---

## Testing

`harness/` is a behavioral test framework: real requests against a running
system, then assertions on the state that changed. One config file switches
the whole suite between environments. `harness/load/` is a k6 capacity
harness. Unit tests are welcome; they are not verification evidence on their
own.

---

## Layout

```
core/       governance, methodology, instructions, templates, agents, skills,
            hooks, rules, commands, workflows, config.   {{VARIABLE}} templated.
harness/    behavioral + load test frameworks.            Templated.
packs/      your domain experience, built by promotion. Sanitize before sharing.
bin/        new-project, install.sh, build-plugin, wo, bug, pack, sanitize,
            detect-stack, dev/, maintenance scripts
docs/       harness guide, an overlay example
```

`THIRD-PARTY-NOTICES.md` credits the one external project a few mechanisms
were adapted from.

---

## Author

Christian Torres — [github.com/ChrisTorres404](https://github.com/ChrisTorres404)

MIT licensed.
