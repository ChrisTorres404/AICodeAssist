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

**Supported platforms:** macOS and Linux, bash 3.2+, `python3`, `perl`, `git`.
Windows is not supported. Nothing else needs installing.

**New project, one command:**

```bash
bin/new-project ~/code/my-app --name "My App" --domain myapp.io
```

**Existing project:**

```bash
cp pipeline.config.example.sh /path/to/project/pipeline.config.sh   # edit it
bin/install.sh /path/to/project                 # --profile minimal | standard | full
```

`minimal` is rules, agents, commands, and the six lifecycle skills with no
hooks; `standard` (the default) adds every skill and the hook set; `full`
adds every domain agent pack and every optional skill pack. `new-project`
takes the same flag, plus `--skill-pack` and `--agent-pack` for one at a time.

**As a Claude Code plugin, no install step:**

```bash
bin/build-plugin
claude plugin add ./dist/plugin        # then /plugin install aicodepipeline
```

Either way you get: the drivers, 95 agents, 162 skills plus 9 optional skill packs, 32 slash commands, 15 hooks, 16 stack profiles, per-language
rules chosen by stack detection, a permission baseline, and a project
`CLAUDE.md` with the run and test commands filled in from what `detect-stack`
finds (for an empty project, run `detect-stack . --write` once code exists; it
also installs the language rule sets the code now needs).

---

## The work-order lifecycle

```bash
acp wo new "Rate limiting" --size standard --priority P1   # folder + required docs
acp wo start 0407 · block 0407 "reason" · note 0407 "text"  # status and session notes
acp wo suite 0407          # scaffold the behavioural suite (sources the harness, exits non-zero on failure)
acp wo verify 0407 --run suites/wo-0407.sh   # runs it; stamps EXECUTED — PASS/FAIL from exit code
acp wo close 0407          # REFUSES without a VERIFICATION document
acp wo integrate "Batch name" --covers 0402,0403,0404   # parallel work: prove the modules compose
acp wo promote 0407        # carry it into a pack; writes one catalog entry file, so parallel promotions never conflict
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

Commit `.aicodepipeline/` and `pipeline.config.sh` with the project: a teammate
who clones gets the same drivers, rules, hooks, and agents, and the config
resolves its own location, so nothing is machine-specific. Update the pipeline
by running `install.sh` from a clone of this repository (never from the
installed copy; it refuses).

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
| No closeout or promotion without `EXECUTED — PASS` verification | `wo close`, `bug close`, `wo promote` refuse on missing, plan-only, or failed | always |
| A closeout in the working tree rests on executed evidence | `evidence-gate.py` Stop hook | standard warns, strict blocks |
| No `console.log`, `TODO: implement`, not-implemented stubs | `quality-gate.py` PostToolUse | standard warns, strict blocks |
| Commits reference a work order | `wo-reference.py` PreToolUse | advisory |
| A commit cites a work order or bug that does not exist | `wo-reference.py` as a git `commit-msg` hook, wired at install | blocks, whether the message came from `-m`, `-F`, stdin or an editor (`ACP_WO_REFERENCE=warn` to override) |
| A verification document that is still mostly template | `wo close`, `bug close` refuse (`ALLOW_PLACEHOLDERS=1` to override) | always |
| Force-push to shared branches, `--no-verify`, destructive shell | markdown hook rules | block / warn |
| Sessions open oriented | `session-orient.sh` SessionStart | all |
| Credentials in staged changes | `commit-quality.py` PreToolUse on `git commit` | blocks; debug logging warns |
| Lint, format, strictness config weakened to pass a check | `config-protection.py` PreToolUse | blocks (`ACP_ALLOW_CONFIG_EDIT=1` to override) |
| Edited files formatted with the project's own formatter | `post-edit-format.py` PostToolUse | standard |
| Type errors after an edit, reported for that file only | `post-edit-typecheck.py` PostToolUse | strict |
| UI drift: hard-coded colours, `transition-all`, unnamed icon buttons, undesigned empty states | `design-quality.py` PostToolUse | advisory |
| UI line limits (page 150, component 200, modal 50, form 80, table 100) | `ui-size-check.py` PostToolUse | standard warns, strict blocks |
| Debug output in Go, Rust, Java, C#, Ruby, PHP, Python, JS | `quality-gate.py` PostToolUse | standard warns, strict blocks |
| Scratch files at the repository root | `doc-file-warning.py` PreToolUse | advisory |
| Orientation note written before context compaction | `pre-compact.py` PreCompact | all |
| Documentation claims: every `<!-- SOURCE: path -->` resolves, over-claim language flagged | `doc-claims-check.py` PostToolUse | standard warns, strict blocks |

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

### The commit-msg hook

Two of these checks live in Claude Code's hook system, which sees the command a session is
about to run. That is early feedback, and it is not the whole picture: a commit message can
reach git by `-F`, by stdin, or from an editor without ever appearing in a command. So the
traceability check is also installed as a git `commit-msg` hook, which sees the final message
every time. Installing wires it; `acp doctor` reports whether it is there.

If the repository already has a `commit-msg` hook, installing leaves it alone rather than
overwriting work you did not ask it to touch. The guarantee then applies only once you chain
the check into your own hook:

```sh
"$(git rev-parse --show-toplevel)/.aicodepipeline/core/hooks/wo-reference.py" "$@" || exit $?
```

### What the evidence rules do and do not guarantee

The drivers refuse a closeout without an executed pass, refuse one whose latest run failed or
never finished, and refuse one whose source moved while the suite ran. That is a check on
process, not an authentication of evidence, and the difference matters:

- **A document can be written by hand.** A verification file with a pass line and no run log is
  accepted. Files on your disk are yours; nothing here can prove otherwise. The rules stop work
  drifting past its own tests. They do not stop someone determined to fake the result.
- **A suite that asserts nothing passes.** The drivers record an exit code. A suite that
  collects no tests and exits zero is a pass, because nothing else was ever claimed.
- **A suite that swallows failures passes.** `false` followed by a successful command exits
  zero. Write suites that propagate failure.
- **Git hooks do not travel through a clone.** They live in the repository, not in its history.
  Every fresh clone starts without them, so run `acp install <project>` once in each clone. This
  is not specific to the pipeline; it is how git hooks work.

### Upgrading an existing installation

Re-run the installer over the project:

```bash
acp install <project>
```

That is the migration path, and it is the only one. It replaces the pipeline's own hooks by
their `acp:` identity, keeps every hook and setting that is yours, and adds anything new since
the version you have. `acp doctor` only reports; it never edits git hooks, so a project that
was installed before a hook existed will not be told it is missing one until the installer has
run again. If you maintain several projects, re-run it in each.

---

## Rules and agents

`core/rules/common/` is ten short files, always loaded: work orders, testing,
coding style, code review, security, git, agents, patterns, documentation,
troubleshooting. `core/rules/ui/`
carries the UI standards — feature-folder structure, reusable components,
line limits that trigger extraction (page 150, component 200, modal 50, form
80, table 100), import paths, and verification — and loads whenever a UI
stack is present. Twenty-one language sets extend them; `install.sh` picks the
right ones from what `bin/detect-stack` finds.

Agents: 52 technology specialists and 43 process roles, selected by
description, every one built out with responsibilities, code templates, a
validation checklist, patterns, anti-patterns, and common issues. Opt-in domain packs add 19 more: `identity` (auth, OAuth/OIDC, multi-tenant, SDK
platforms), `ml`, `network`, `healthcare`, and `gan` (`AGENT_PACKS="identity ml"`). Project-specific narrowing goes in `core/agents/overlays/`, which
survives reinstalls.

---

## Understanding and documenting code you did not write

The same evidence discipline applies to claims about code, not just code. A
second lifecycle, `wo new --area analysis` and `--area docs`, reads a
repository without touching it and produces documentation whose every claim
traces to a source file:

```bash
/analyze-repo ./their-service   # eight-phase read-only analysis → Feature Profiles + source index
/status-matrix                  # honest badges: implemented, partial, in development, planned, not available
/docs-faq · /docs-brief · /docs-primer · /docs-reference · /docs-developer
/integration-kit                # playbook, PM brief, API quick reference, decision matrix
/feasibility "can it do X?"     # verdict, mechanism, integration path, blocker or not
/review-docs <path>             # factuality-validator, then critical-reviewer
```

Three rules make it honest. **Source or silence**: anything that cannot be
traced to a file is omitted, never invented, and every claim carries a
`<!-- SOURCE: path:L12 -->` comment that a hook verifies (the hook proves the reference exists; the
factuality validator proves the source supports the claim). **No implemented
badge without a code reference**, and every partial lists its limitations.
**The validator is never the author**: a factuality validator marks each
claim VERIFIED, UNVERIFIED, or DISCREPANCY, and a critical reviewer hunts
contradictions and over-claims before a document reaches VALIDATED.

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

The repository ships the machinery and no corpus: `packs/` starts empty in
every install, and `pack search` returns nothing until you promote your first
work order. The author's own packs stay private; the pipeline is the part that
was general enough to share. To share a pack, run `bin/sanitize` on it first.

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

The pipeline tests itself the same way. `bin/acp test` is the whole gate in one
command — lint, the sanitizer over every shipped directory, every evaluation,
the plugin build, and plugin validation — and `TESTING.md` documents each check
on its own, with expected output, for anyone deciding whether this repository
works.

`acp eval run` executes the evaluations under `harness/evals/`: each one
installs into a scratch project, drives a hook or a driver, and asserts on what
happened (a commit with a credential is blocked, a work order refuses to close
without verification, each install profile ships what it promises, seventeen
stacks each get the right rules and commands). `acp eval live` goes further and
drives real sessions, then checks what they left behind. Add one with
`acp eval new` whenever an agent, rule, or hook change could regress silently.

---

## Layout

```
core/       governance, methodology, instructions, templates, agents, skills,
            hooks, rules, commands, workflows, config.   {{VARIABLE}} templated.
harness/    behavioral + load test frameworks.            Templated.
packs/      your domain experience, built by promotion. Sanitize before sharing.
core/skill-packs/  optional skill collections (healthcare, network, marketing,
            supply-chain, business-ops, science, ml, web3, media); SKILL_PACKS
bin/        acp, new-project, install.sh, build-plugin, wo, bug, pack, sanitize,
            detect-stack, stack-specialist, lint, eval, dev/, maintenance scripts
docs/       getting-started tutorial, harness guide, agent security, an overlay
            example.  TESTING.md and CONTRIBUTING.md are at the root.
```

`THIRD-PARTY-NOTICES.md` carries the licence notices the law requires; nothing
else in the tree names another project.

---

## Author

Christian Torres — [github.com/ChrisTorres404](https://github.com/ChrisTorres404)

MIT licensed.
