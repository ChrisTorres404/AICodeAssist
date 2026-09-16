# AICodePipeline

A work-order system for coding agents. Every task gets a spec, a test that is actually
run, and a closeout the tool will not write until the test has passed. It works on any
codebase in any language, with any coding agent or with none, and it is free.

## Features

**Work orders and bugs**

- `wo new` creates a work order folder with a spec, checklist, task breakdown, prompt, and review document. Four sizes, from one document to seven.
- `wo verify --run` runs a test suite and records `EXECUTED — PASS` or `EXECUTED — FAIL` from the exit code, with the log.
- The result is tied to a content hash of the source tree and of the suite. A later edit makes the pass stale.
- `wo close` refuses without a current passing run, a filled-in verification document, and, for standard and large sizes, a review by someone other than the implementer.
- `wo integrate` verifies a batch of parallel work orders together.
- `wo start`, `block`, `note`, `list`, `show`, `status`, `stats` track state and session notes.
- `wo publish`, `sync`, `import` connect a work order to a GitHub issue.
- `bug new`, `bug verify`, `bug close` run the same lifecycle for bugs, with numbered categories.
- `wo adopt` and `bug adopt` bring existing records in as history without claiming a test ran.
- `wo new --paths` limits the source hash and checks to part of a monorepo.
- Work-order and bug numbers are reserved atomically, so parallel agents never collide.

**Enforcement**

- `acp check` runs the rule set over staged changes, changes since a ref, a list of paths, or a work order's changed files. It blocks credentials, weakened lint, format, or type config, and closeouts without a pass.
- Git `pre-commit` and `commit-msg` hooks written at install. A commit that cites a work order nobody opened is refused whether the message came from `-m`, `-F`, stdin, or an editor.
- `acp ci github` adds a GitHub Actions workflow that runs the same checks on pull requests.
- A git `pre-push` hook refuses a force push to, or deletion of, a shared branch (`main`, `master`, `develop`, `production`, `release/*`).
- UI drift, formatting, and type errors are checked by `acp check` too, so they are reported at commit time under any agent.
- Fifteen session hooks for Claude Code on three profiles (`minimal`, `standard`, `strict`): quality gate, config protection, evidence gate, formatting, type checking, design checks, UI size limits, documentation claims, session orientation, and a note before context compaction.
- Custom rules as markdown files in `.claude/hook-rules/`, no code required.
- `acp:allow-secret` and `Acp-Allow-Reference` overrides that live in the diff, not in an environment variable.

**Intake and adoption**

- Install opens six intake work orders with finished specs and suites: source state, instructions, baseline, record, suites, knowledge base. `acp intake status` reports progress.
- `acp intake inventory` reads a repository and reports its git state, stack, instruction files, hooks, CI, and the kind of record it keeps, with `wo adopt` commands where it can.
- `acp baseline` runs the project's own tests once and records the result.
- `wo suite --wrap` and `SUITE_COMMAND` reuse the test runner a project already has.
- Exit 77 records `NOT EXECUTED — PRECONDITION FAILED` for a suite whose environment was not available.

**Knowledge base**

- An analysis of the project, one profile per feature, a status matrix, and a source index with a content hash per cited file, under `KNOWLEDGE_DIR`.
- Three levels set at install: `lite` is built by the tool from the source tree, `standard` needs the narrative written, `full` needs every claim validated. `acp kb scaffold` builds the lite level and can be re-run safely.
- `acp kb status` reports each profile as current, stale, or broken and lists source no profile describes. `acp kb bind` refreshes the index.
- `wo close`, the pre-commit hook, and CI name the profiles that describe changed files.

**Agents, skills, rules, and commands**

- 96 agents: 53 technology specialists and 43 process roles. 19 more in optional agent sets (`identity`, `ml`, `network`, `healthcare`, `gan`). Routed to a work order by its area and written into its prompt.
- 169 skills and 9 optional skill sets (business-ops, healthcare, marketing, media, ml, network, science, supply-chain, web3).
- 32 slash commands for Claude Code, including `/plan`, `/feature-dev`, `/pr`, `/review-pr`, `/test-coverage`, `/checkpoint`, and `/prd`.
- 10 common rule files, a UI rule set, and 23 language rule sets chosen by `bin/detect-stack` from 16 stack profiles.
- `acp agent`, `acp agents`, `acp command`, `acp commands`, `acp skill`, and `acp skills` print any agent, slash command, or skill as text for use under any tool.
- Overlays in `core/agents/overlays/` narrow agents per project and survive reinstalls.

**Methodology**

- Eleven methodology documents in `core/methodology/`, indexed by `core/methodology/README.md`: project rules, work orders, bugs, behavioural testing, UI scenario testing, the database gold-standard baseline, systematic test fixing, test inventory and gap analysis, agent output locations, and knowledge extraction.
- Reference templates in `core/templates/reference/`: incident postmortem, QA smoke test, port allocation, database normalization audit, test accounts registry, documentation index.
- Design notes in `docs/patterns/`: behavioural suites in CI, and the four-layer validation design.
- Seven operating instructions in `core/instructions/`: the work-order lifecycle, the session-handoff standard, and the five documents of the test-fixing system.
- The testing methodology states the position that mocked end-to-end suites were abandoned in favour of behavioural tests run against the real running system, and what "real" means for each part of a test.
- Templates for work orders, bugs, testing, sessions, documentation, intake, and a design-system instruction set the adopter fills in for their own component library.

**Documenting code you did not write**

- `wo new --area analysis` and `--area docs` with `/analyze-repo`, `/status-matrix`, `/docs-brief`, `/docs-primer`, `/docs-reference`, `/docs-faq`, `/docs-developer`, `/integration-kit`, `/feasibility`, and `/review-docs`.
- Every claim carries a `<!-- SOURCE: path:line -->` comment that a hook verifies.

**Playbooks**

- `wo promote` moves a closed work order, its suites, and its notes into a playbook. `playbook list`, `playbook search`, `playbook show`, `playbook lint`, `playbook catalog`.
- Parallel promotions write separate catalog files and never conflict.

**Testing and release tooling**

- A behavioural test harness with configurable auth, database checks, and manifest-driven runners, plus a k6 load harness.
- `bin/sanitize` scans for secrets, personal identifiers, IP addresses, SSH strings, key files, internal host names, and host paths before anything is shared.
- `bin/acp test` runs lint, the sanitizer, 54 behavioural evaluations, the plugin build, and plugin validation. `acp eval new` adds an evaluation.
- `acp doctor` checks an install and proves it by running a throwaway work order.

**Install and portability**

- `new-project` for a new project, `install.sh` for an existing one, `build-plugin` for a Claude Code plugin. Three install profiles.
- Reinstall upgrades in place and keeps your hooks, settings, overlays, and harness config.
- Instructions written to `AGENTS.md` for Codex, Cursor, and other agents; `CLAUDE.md` imports it.
- Bash 3.2, macOS and Linux, tested on both in CI.

## Requirements

macOS or Linux, bash 3.2 or newer, `python3`, `perl`, and `git`. Nothing else to install.

## Install

Clone the repository once. Each project gets its own copy of the pipeline under
`.aicodepipeline/`, which you commit with the project.

**New project:**

```bash
git clone https://github.com/ChrisTorres404/AICodeAssist.git pipeline
pipeline/bin/new-project ~/code/my-app --name "My App"
cd ~/code/my-app
export PATH="$PWD/.aicodepipeline/bin:$PATH"
acp doctor .
```

**Existing project:**

```bash
cp pipeline/pipeline.config.example.sh /path/to/project/pipeline.config.sh   # edit the lines at the top
pipeline/bin/install.sh /path/to/project
```

**As a Claude Code plugin:**

```bash
pipeline/bin/build-plugin
claude plugin add ./pipeline/dist/plugin      # then /plugin install aicodepipeline
```

## First work order

```bash
wo new "Rate limiting on the public API" --size small --area api
# fill in the SPEC, do the work, write a test
wo verify 0001 --run tests/rate-limit.sh      # runs the test and records the result
wo close 0001                                 # writes the closeout, or refuses
```

Run `wo close` before `wo verify` and it refuses and says what it needs.

## What happens after install

Installing puts the files in place. It also opens six small work orders, each with a
finished spec and a test suite. The project counts as operational when all six have closed
on a passing run.

| Work order | The suite checks |
|---|---|
| Source state | the project is a git repository with at least one commit |
| Instructions | `AGENTS.md` names the configured layout and `CLAUDE.md` imports it |
| Baseline | the project's own tests ran once and the result was recorded |
| Record | existing work orders or documents were inventoried and brought in |
| Suites | at least one test suite exists |
| Knowledge base | the code is described and every claim points at a source file |

On a new project with no source yet, the baseline, suites, and knowledge-base steps pass with a
note that there is nothing to run or describe yet.

`acp intake status` shows progress. `acp intake inventory` reads the repository and reports
its git state, stack, instruction files, hooks, CI, and what kind of record it has: pipeline
work orders, numbered documents, ADRs, loose documentation, or none. Where it can, it prints
the `wo adopt` commands to bring that record in.

**Knowledge base.** `KNOWLEDGE_DIR` holds an analysis of the project, one profile per
feature, a status matrix, and a source index with a content hash for each cited file.
`acp kb status` reports each profile as current, stale, or broken and lists source files no
profile describes. `wo close` names the profiles that describe files the work order changed
and writes that into the closeout. The same check runs in the pre-commit hook and in CI.

The knowledge base has a level, set with `KNOWLEDGE_LEVEL` in the config or `--kb-level` on
`new-project`:

| Level | Who builds it | The intake step passes when |
|---|---|---|
| `lite` | the tool, at intake, from the source tree: a survey, one profile per feature citing its files, the status matrix, the index | every citation resolves |
| `standard` | an agent writes the narrative sections of each profile | no profile is still mostly scaffold prompts |
| `full` | an agent validates every claim against source | every profile is marked validated and reviewed |

`acp kb scaffold` builds the lite level. Running it again adds new features, marks features
whose directory is gone as orphaned, and never overwrites narrative someone wrote. `wo close`
runs it in grow mode, so a new feature gets a profile stub when the work order that added it
closes. `acp kb status` lists the profiles short of the configured level.

## Adopting an existing project

Commit first, measure second, install third. Then wrap the test runner you already have
instead of rewriting it.

- `acp baseline` runs the project's own tests once and records the result against the
  current tree. `acp doctor` asks for it.
- `wo adopt <file> --number N` brings an existing work order in as history. The document
  is not changed and no verification is claimed. `bug adopt` does the same for bugs.
- `wo suite <n> --wrap '<command>'` scaffolds a suite that calls your existing runner.
  `SUITE_COMMAND` in the config makes that the default.
- A suite that exits 77 is recorded as `NOT EXECUTED — PRECONDITION FAILED`, not as a
  failure. Use it when the environment the suite needs is not there.

The full runbook is in [docs/adopting-an-existing-project.md](docs/adopting-an-existing-project.md).

## Works with any coding agent

The drivers (`wo`, `bug`, `playbook`, `acp`) are bash scripts and run from any shell. The git
hooks run no matter which tool made the commit. Install writes the instructions to
`AGENTS.md`, which Codex, Cursor, and most agents read, and a short `CLAUDE.md` that imports
it. The agents routed to a work order are written into the work order's own prompt, so any
tool doing the work reads them. `acp agent <name>`, `acp command <name>`, and
`acp skill <name>` print any agent, slash command, or skill from a shell. `AGENTS.md` explains
how to follow them without Claude Code.

Claude Code additionally gets session hooks, slash commands, and subagents. Those give
earlier warnings inside a session. The same rules run again at `wo close`, in the git hooks,
and in CI, so nothing is refused only under Claude Code. The table under
[Under Claude Code and under anything else](#under-claude-code-and-under-anything-else) lists
every rule and where it runs in each case.

---

# Reference

## Work-order commands

```bash
acp wo new "Rate limiting" --size standard --priority P1   # folder and documents
acp wo start 0407 · block 0407 "reason" · note 0407 "text"  # status and notes
acp wo suite 0407                                           # scaffold the test suite
acp wo verify 0407 --run suites/wo-0407.sh                  # run it and record the result
acp wo close 0407                                           # closeout; refuses without a pass
acp wo integrate "Batch name" --covers 0402,0403,0404       # verify parallel work orders together
acp wo promote 0407                                         # move it into a playbook
acp wo list · show · status · stats
```

`acp` is the front door. Every subcommand is also a script in `bin/`. `acp doctor` checks an
install and proves it by opening, verifying, and closing a throwaway work order.

**Sizes**

| Size | Created at open | Required to close |
|---|---|---|
| `trivial` | one document | VERIFICATION |
| `small` | SPEC | VERIFICATION |
| `standard` | SPEC, CHECKLIST, TASK-BREAKDOWN, Prompt, REVIEW | VERIFICATION, REVIEW |
| `large` | standard plus SDK and UI implementation docs | VERIFICATION, REVIEW |

**Statuses:** `EXECUTED — PASS`, `EXECUTED — FAIL`, `NOT EXECUTED — PLAN ONLY`,
`NOT EXECUTED — PRECONDITION FAILED`, and `RUNNING` for a verification that started and
did not finish.

**What the source hash covers.** Every file's content, tracked by git or not, so committing
does not change it. The suite that ran is hashed separately. Any edit inside the tree between
the pass and the close makes the pass stale. `wo new --paths packages/api` limits the hash and
the close-time checks to part of a monorepo.

## Working with others

Commit `.aicodepipeline/` and `pipeline.config.sh`. A teammate who clones gets the same
drivers, rules, and agents. Git hooks are not part of a clone, so each fresh clone runs
`acp install .` once. Work-order numbers are reserved atomically, and each
promotion writes its own catalog file, so parallel work does not conflict.

```bash
acp wo publish 0407    # open a GitHub issue from the work order
acp wo sync 0407       # push the current spec and status to the issue
acp wo import 77       # create a work order from an existing issue
```

These need the `gh` CLI, authenticated.

## What is enforced

| Rule | Where | Profile |
|---|---|---|
| No closeout or promotion without `EXECUTED — PASS` | `wo close`, `bug close`, `wo promote` | always |
| A pass is tied to the source and the suite it ran against | close refuses if either changed after the pass | always |
| A suite that could not run is not a failure | exit 77 records `NOT EXECUTED — PRECONDITION FAILED` | always |
| A verification document still mostly template is refused | `wo close`, `bug close` (`ALLOW_PLACEHOLDERS=1` overrides) | always |
| Standard and large work orders need a review by someone who did not write them | `wo close` needs a filled-in `WO-####-REVIEW.md` (`ACP_SKIP_REVIEW=1` overrides) | always |
| Credentials, a weakened lint/format/type config, or a closeout without a pass in the changed files | `acp check`, run by `wo close`, the `pre-commit` hook, and CI | always |
| A commit cites a work order or bug that does not exist | `commit-msg` hook; sees `-m`, `-F`, stdin, and editor messages | blocks (`ACP_WO_REFERENCE=warn` overrides) |
| Credentials in staged changes | `commit-quality.py` on `git commit` | blocks; debug logging warns |
| Lint, format, or strictness config weakened | `config-protection.py` | blocks (`ACP_ALLOW_CONFIG_EDIT=1` overrides) |
| A closeout in the tree rests on a passing run | `evidence-gate.py` Stop hook | standard warns, strict blocks |
| `console.log`, `TODO: implement`, stubs, debug output in nine languages | `quality-gate.py` | standard warns, strict blocks |
| A test fixture that looks like a credential | `// acp:allow-secret` on that line lets it through | blocks otherwise |
| A commit message that must quote a non-existent work order | `Acp-Allow-Reference: WO-9999` trailer lets it through | blocks otherwise |
| The pipeline's own vendored source | skipped by every scanner | never reported |
| Force push to, or deletion of, a shared branch | git `pre-push` hook (`ACP_ALLOW_FORCE_PUSH=1` overrides) | always |
| `--no-verify`, database drops, destructive shell commands | markdown hook rules, Claude Code only | block / warn |
| Edited files formatted with the project's formatter | `post-edit-format.py` formats in Claude Code; `acp check` reports without writing | standard |
| Type errors after an edit, for that file | `post-edit-typecheck.py`; `acp check --types` | strict |
| Hard-coded colours, `transition-all`, unnamed icon buttons | `design-quality.py`; `acp check` | advisory, strict blocks |
| UI file line limits (page 150, component 200, modal 50, form 80, table 100) | `ui-size-check.py` | standard warns, strict blocks |
| Every `<!-- SOURCE: path -->` in documentation resolves | `doc-claims-check.py` | standard warns, strict blocks |
| Session orientation and a note before context compaction | `session-orient.sh`, `pre-compact.py` | all |

```bash
export ACP_HOOK_PROFILE=strict          # minimal | standard | strict
export ACP_DISABLED_HOOKS=acp:pre:wo-reference
```

Under Claude Code the session hooks run in the agent's environment, not in the shell of the
command they inspect. Set these in the `env` block of `.claude/settings.json` or export them
before starting the agent. A hook that reads the git index reads it before your command runs,
so stage changes in a separate command from the `git commit`.

Add your own rule as a markdown file in `.claude/hook-rules/`:

```markdown
---
name: warn-direct-prod-db
event: bash
pattern: psql .*prod
action: warn
---
That looks like the production database. Are you sure?
```

### Where the rules run

| Tier | Runs | Needs | Catches an agent that skips the driver |
|---|---|---|---|
| Work order | `wo verify`, `wo close`, `bug close` | nothing, not even git | no |
| Local | git `pre-commit`, `commit-msg`, and `pre-push` hooks, written at install | git | yes |
| Shared | CI on the pull request (`acp ci github` adds the workflow) | a remote | yes, humans included |

All three call the same implementation. The session hooks in `.claude/settings.json` run
only inside Claude Code and are an early warning, not the enforcement.

`acp check` runs the rule set over the staged changes, changes since a ref, a list of paths,
or the files a work order changed since it opened. The last one works without git, from a
manifest `wo new` takes of the tree. Blocking everywhere: credential-like values, a modified
lint, format, or strictness config, and a closeout whose latest verification is not a pass.
Advisory, blocking under strict: debug logging, stubs, oversized UI files, documentation
claims that point at nothing, UI drift, unformatted files, and, with `--types` or
`ACP_CHECK_TYPES=1`, type errors. Strict is `--strict`, `ACP_STRICT=1`, or
`ACP_HOOK_PROFILE=strict`.

Without git, only the work-order tier runs. Install and doctor both print the command to
initialise a repository.

### Under Claude Code and under anything else

| Rule | Under Claude Code | Under any other agent |
|---|---|---|
| Credentials in changed files | session hook on `git commit` | `acp check` at `wo close`, pre-commit hook, CI. Blocks |
| Weakened lint, format, or type config | session hook blocks the edit | `acp check`. Blocks |
| Closeout without a passing run | Stop hook | `wo close` refuses; `acp check`. Blocks |
| Commit cites a work order that does not exist | session hook and `commit-msg` hook | `commit-msg` hook. Blocks |
| Debug logging, stubs | session hook after each edit | `acp check`. Advisory, strict blocks |
| Hard-coded colours and other UI drift | session hook after each edit | `acp check`. Advisory, strict blocks |
| Formatting | session hook formats the file | `acp check` reports, does not write. Advisory, strict blocks |
| Type errors | session hook after each edit | `acp check --types`. Advisory, strict blocks |
| UI file size limits, documentation claims | session hook | `acp check`. Advisory, strict blocks |
| Knowledge base profiles affected by a change | none in session | `wo close`, pre-commit hook, CI |
| Force push to, or deletion of, a shared branch | markdown rule on the command, and the `pre-push` hook | `pre-push` hook. Blocks |
| `--no-verify` | markdown rule | not enforceable; it turns git hooks off |
| Database drops, destructive shell commands, commented-out security checks | markdown rules on the command | not checked |
| Scratch files such as `NOTES.md` and `TODO.md` | session hook warns | not checked |
| Project linter over staged files | session hook on `git commit` | not checked |
| Custom rules in `.claude/hook-rules/` | session hook | not read |
| Session orientation, note before context compaction | session hooks | no equivalent moment |
| Slash commands, skills, subagents | native | `acp command`, `acp skill`, `acp agent` print them as text |

### The commit-msg hook

A commit message can reach git by `-F`, by stdin, or from an editor without appearing in a
command line, so the work-order reference check is installed as a git `commit-msg` hook. If
the repository already has one, install leaves it alone. Chain the check into yours:

```sh
"$(git rev-parse --show-toplevel)/.aicodepipeline/core/hooks/wo-reference.py" "$@" || exit $?
```

### Install profiles

`minimal` installs rules, agents, commands, and the six lifecycle skills, with no hooks.
`standard` (the default) adds every skill and the hook set. `full` adds every optional agent
set and skill set. `install.sh --profile` and `new-project --profile` take the same
values, plus `--skill-set` and `--agent-set` for one at a time.

### Upgrading

```bash
acp install <project>
```

Re-run the installer over the project. It replaces the pipeline's own hooks by their `acp:`
identity, keeps every hook and setting that is yours, and adds anything new. A failed
install leaves the project as it was. `acp doctor` only reports and never edits git hooks.

## Rules and agents

`core/rules/common/` holds ten short files that are always loaded: work orders, testing,
coding style, code review, security, git, agents, patterns, documentation, troubleshooting.
`core/rules/ui/` loads when a UI stack is present. Twenty-one language sets extend them;
`install.sh` picks the right ones from what `bin/detect-stack` finds.

Agents: 52 technology specialists and 43 process roles, each with responsibilities, code
templates, a checklist, patterns, and anti-patterns. Opt-in agent sets add 19 more (`identity`,
`ml`, `network`, `healthcare`, `gan`). Project-specific changes go in
`core/agents/overlays/`, which survives reinstalls.

## Documenting code you did not write

`wo new --area analysis` and `--area docs` read a repository without changing it and
produce documentation in which every claim points at a source file:

```bash
/analyze-repo ./their-service   # eight-phase read-only analysis
/status-matrix                  # implemented, partial, planned, not available
/docs-faq · /docs-brief · /docs-primer · /docs-reference · /docs-developer
/feasibility "can it do X?"     # verdict, mechanism, integration path
/review-docs <path>             # factuality check, then critical review
```

Anything that cannot be traced to a file is left out. Every claim carries a
`<!-- SOURCE: path:L12 -->` comment that a hook checks. The validator is never the author.

## Playbooks

```bash
playbook list
playbook search "rate limit"
playbook show WO-0407
```

A playbook is a closed, verified work order kept for reuse: its spec, the suite that proved
it, and the pitfalls noted at closeout. `wo promote` moves a closed work order into the
project's playbooks with the suites that produced its evidence and writes a catalog entry.
`playbook lint` reports entries whose pitfalls section is still the placeholder.
`playbooks/` starts empty. Run `bin/sanitize` on a playbook before sharing it.

## Sanitizer

```bash
bin/sanitize <dir> [<dir>...] --report report.md
```

Finds secrets, personal identifiers, private and public IP addresses, SSH connection
strings, key-file references, internal host names, host paths, and dangerous files. Host
names are warnings; everything else critical is a FAIL. `new-project` refuses to install a
playbook that fails and `wo promote` refuses to promote a work order that fails.

## Testing the pipeline itself

`bin/acp test` runs lint, the sanitizer over every shipped directory, every behavioural
evaluation, the plugin build, and plugin validation. Each evaluation installs the pipeline
into a scratch project and asserts on what happened. `TESTING.md` documents each check.
`acp eval new` adds an evaluation. Results for each release are in `docs/releases/`.

## Layout

```
core/       methodology, instructions, templates, agents, skills, hooks, rules,
            commands, config
harness/    behavioural and load test frameworks, runners, evaluations
playbooks/  your promoted work orders
bin/        acp, new-project, install.sh, build-plugin, wo, bug, playbook, sanitize,
            detect-stack, lint, eval
docs/       getting-started tutorial, harness guide, agent security, releases
```

Inside `core/`:

```
methodology/   the long-form documents, indexed by core/methodology/README.md
instructions/  operating instructions: work orders, session handoff, test fixing
rules/         the short always-loaded rules: common, ui, and per-language sets
templates/     work orders, bugs, testing, sessions, docs, intake, project
```

## Author

Christian Torres — [github.com/ChrisTorres404](https://github.com/ChrisTorres404)

MIT licensed. `THIRD-PARTY-NOTICES.md` carries the notices the licence requires.
