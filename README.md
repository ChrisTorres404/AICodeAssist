# AICodePipeline

**Make your AI coding agent prove its work.**

AI agents write code fast. They also say "done" when it is not, forget what they tried
once the session ends, and quietly weaken the tests to make them pass. This pipeline
gives an agent a way of working that does not allow any of that: every piece of work is a
work order with a spec, a test that actually ran, and a closeout the tool refuses to
write until the evidence exists. It works on any codebase in any language, and it is
free.

Built over eighteen months of shipping a production platform with AI agents, then
pulled out and made general.

---

## The problem it solves

If you have worked with a coding agent for more than a week, you have seen these:

- **"Done" that is not done.** The agent reports success. You find out later the tests
  were never run, or were run against code that has since changed.
- **Work that evaporates.** What was tried, what failed, why the fix took the shape it
  did: all of it lived in a chat window that is now gone. The next session, or the next
  person, starts from zero.
- **Shortcuts you did not authorize.** A `console.log` left in. A stub that throws
  "not implemented." A lint rule relaxed so the check goes green.
- **No memory across projects.** The same mistake, solved again, on the next codebase.

None of these are model failures. They are process failures, and a process is something
you can enforce.

## What you get

- **Work orders.** Every task gets a folder with a specification, a checklist, a prompt,
  and later a verification record and a closeout. The size of the task sets how much
  ceremony it gets; a two-line fix does not need four documents.
- **Verification that cannot be faked by typing.** `wo verify --run` executes your test
  suite and writes `EXECUTED — PASS` or `EXECUTED — FAIL` from the exit code. Nobody
  types "PASS." The result is bound to a fingerprint of your source, so if the code
  changes after the pass, the pass is stale and the tool says so.
- **A closeout the tool refuses to write without evidence.** `wo close` will not run on
  a work order whose verification is missing, failed, never finished, or still a blank
  template.
- **Rules that are enforced, not requested.** Debug logging, stubs, credentials in a
  commit, a weakened lint config, a commit that cites a work order nobody opened: each
  one is caught by a hook or a driver, not by hoping the agent remembers.
- **Packs.** When a work order closes with a pass, you can promote it. Its spec, its
  tests, and the pitfalls you wrote down while you still remembered them become
  searchable precedent for the next project.
- **Specialists.** Ninety-five agent definitions, from REST and database design to
  security review and accessibility, routed to a work order by its area.

## Five minutes

Requirements: macOS or Linux, bash 3.2 or newer, `python3`, `perl`, `git`. Nothing to
install beyond cloning this repository.

**A new project:**

```bash
git clone https://github.com/ChrisTorres404/AICodeAssist.git pipeline
pipeline/bin/new-project ~/code/my-app --name "My App"
cd ~/code/my-app
export PATH="$PWD/.aicodepipeline/bin:$PATH"
acp doctor .
```

**An existing project:**

```bash
cp pipeline/pipeline.config.example.sh /path/to/project/pipeline.config.sh   # edit the few lines at the top
pipeline/bin/install.sh /path/to/project
```

**Then your first work order:**

```bash
wo new "Rate limiting on the public API" --size small --area api
# ... fill in the SPEC, do the work, write a test ...
wo verify 0001 --run tests/rate-limit.sh      # runs it, records the result
wo close 0001                                 # drafts the closeout, or refuses
```

Try closing before verifying. It refuses, and tells you what it needs. That refusal is
the whole product in one line.

**As a Claude Code plugin instead:**

```bash
pipeline/bin/build-plugin
claude plugin add ./pipeline/dist/plugin      # then /plugin install aicodepipeline
```

## A day with it

You open a work order for the feature. The tool creates the folder and the documents
sized for the job, and names the specialist roles for that area. You or your agent fill
in the spec before writing code, because the spec is where "done" gets defined.

The work happens. In Claude Code, hooks watch it: a `console.log` written into source
is called out in the same turn, a change to `tsconfig.json` is blocked unless you say
why, and a commit carrying something that looks like a credential does not go through.

You scaffold a test suite with `wo suite` and run it with `wo verify --run`. The
result, the log, and a fingerprint of the source go into the verification record. If
you touch the code afterwards, the record is stale and close refuses until you run it
again.

You close the work order. The closeout is drafted from what actually ran. If the work
is worth remembering, you promote it into a pack, and the pitfalls you noted are there
the next time you or anyone else searches for "rate limit."

Bugs follow the same lifecycle with `bug new`, `bug verify`, `bug close`.

## How this changes your programming

- **You stop re-verifying the agent's claims by hand.** The tool already did, and it
  wrote down what it found.
- **Rework drops.** A pass bound to a source fingerprint means the thing that passed is
  the thing you are shipping. In a paired trial on the same codebase, an agent using
  the pipeline's required independent review caught a silent data-precision defect
  before handoff that an agent working without it shipped.
- **Context survives the session.** Six months from now the work order still says what
  was tried, what failed, and what the test proved. So does the next person's.
- **You can hand more to the agent.** The rules hold whether or not anyone is watching.
- **Your projects compound.** Every promoted work order makes the next one start from
  precedent instead of a blank page.

## Does it actually work?

The honest evidence so far, all of it reproducible from this repository:

- A blind recovery run on a mature, real codebase found ten of ten planted defects.
- Twenty-three adversarial scenarios, written by an independent reviewer to break the
  lifecycle, pass. That includes four simultaneous creators getting distinct work-order
  numbers, a verification interrupted mid-run leaving no stale pass behind, and a failed
  upgrade leaving the project intact.
- The pipeline tests itself with the same discipline: `bin/acp test` runs thirty
  behavioural evaluations, each of which installs into a scratch project and asserts on
  what actually happened.

What it does not claim: that it makes an agent faster. In the paired trial the two
arms finished within seconds of each other once the defect was repaired. The gain is
in what reaches you, not how quickly.

## What it will not do

These are limits of the design, written down so nobody discovers them the hard way:

- **It cannot stop someone determined to fake evidence.** A verification file written by
  hand with a pass line is accepted. The files are on your disk, and nothing here can
  prove otherwise. The rules keep work from drifting past its own tests; they do not
  authenticate the tests.
- **A suite that asserts nothing passes.** The tool records an exit code. Write tests
  that can fail.
- **Git hooks do not travel through a clone.** Every fresh clone runs `acp install`
  once. That is how git works, not something the pipeline can change.

## Works with your tools

The drivers (`wo`, `bug`, `pack`, `acp`) are plain bash and run under any coding agent
or none. The git `commit-msg` hook runs regardless of who typed the command. The
templates and the methodology are files any agent can read.

The session hooks, the slash commands and the specialist subagents are Claude Code
features. Without Claude Code you keep the drivers, the git hook, the templates and the
methodology, and you lose the in-session early warnings. Everything the tool refuses to
do, it still refuses.

---

# Reference

Everything above is enough to start. What follows is the detail.

## The work-order lifecycle

```bash
acp wo new "Rate limiting" --size standard --priority P1   # folder + required docs
acp wo start 0407 · block 0407 "reason" · note 0407 "text"  # status and session notes
acp wo suite 0407          # scaffold the behavioural suite
acp wo verify 0407 --run suites/wo-0407.sh   # runs it; stamps EXECUTED — PASS/FAIL from the exit code
acp wo close 0407          # refuses without an executed pass
acp wo integrate "Batch name" --covers 0402,0403,0404   # parallel work: prove the modules compose
acp wo promote 0407        # carry it into a pack
acp wo list · show · status · stats
```

`acp` is the front door; every subcommand is also a standalone script in `bin/`.
`acp doctor` tells you whether an install is healthy, and proves it by opening,
verifying and closing a throwaway work order in place.

**Size sets the ceremony.**

| Size | Created at open | Always required to close |
|---|---|---|
| `trivial` | one document | VERIFICATION |
| `small` | SPEC | VERIFICATION |
| `standard` | SPEC, CHECKLIST, TASK-BREAKDOWN, Prompt | VERIFICATION |
| `large` | standard plus SDK and UI implementation docs | VERIFICATION |

**Honest status, always.** `EXECUTED — PASS`, `EXECUTED — FAIL`, `NOT EXECUTED — PLAN
ONLY`, or `RUNNING` for a verification that started and never finished. The last two
exist so the first is never used falsely.

## Working with others

Commit `.aicodepipeline/` and `pipeline.config.sh` with the project. A teammate who
clones gets the same drivers, rules, hooks and agents, and the config resolves its own
location. Simultaneous work is safe: identities are reserved atomically, and promotions
write one catalog entry file each so parallel promotions never conflict.

```bash
acp wo publish 0407    # opens a GitHub issue carrying the full work order
acp wo sync 0407       # pushes the current spec and status to the issue
acp wo import 77       # creates WO-0077 from an existing issue
```

Needs the `gh` CLI, authenticated. In a monorepo, whole-tree fingerprinting means an
unrelated commit can make your evidence stale; run the suite again and it is current.

## What is enforced

| Rule | Mechanism | Profile |
|---|---|---|
| No closeout or promotion without `EXECUTED — PASS` | `wo close`, `bug close`, `wo promote` refuse on missing, plan-only, failed, or unfinished | always |
| A pass is bound to the source it ran against | close refuses if the tree changed after the pass, or while the suite ran | always |
| A verification document that is still mostly template | `wo close`, `bug close` refuse (`ALLOW_PLACEHOLDERS=1` to override) | always |
| A commit cites a work order or bug that does not exist | git `commit-msg` hook, wired at install; sees `-m`, `-F`, stdin and editor messages alike | blocks (`ACP_WO_REFERENCE=warn` to override) |
| Credentials in staged changes | `commit-quality.py` on `git commit` | blocks; debug logging warns |
| Lint, format, or strictness config weakened to pass a check | `config-protection.py` | blocks (`ACP_ALLOW_CONFIG_EDIT=1` to override) |
| A closeout in the working tree rests on executed evidence | `evidence-gate.py` Stop hook | standard warns, strict blocks |
| `console.log`, `TODO: implement`, not-implemented stubs, debug output in nine languages | `quality-gate.py` | standard warns, strict blocks |
| Commits reference a work order | `wo-reference.py` | advisory |
| Force-push to shared branches, `--no-verify`, destructive shell | markdown hook rules | block / warn |
| Edited files formatted with the project's own formatter | `post-edit-format.py` | standard |
| Type errors after an edit, for that file only | `post-edit-typecheck.py` | strict |
| UI drift: hard-coded colours, `transition-all`, unnamed icon buttons | `design-quality.py` | advisory |
| UI line limits (page 150, component 200, modal 50, form 80, table 100) | `ui-size-check.py` | standard warns, strict blocks |
| Documentation claims: every `<!-- SOURCE: path -->` resolves | `doc-claims-check.py` | standard warns, strict blocks |
| Sessions open oriented; a note is written before context compaction | `session-orient.sh`, `pre-compact.py` | all |

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

The session hooks see the command an agent is about to run. A commit message can reach
git by `-F`, by stdin, or from an editor without ever appearing in a command, so the
traceability check is also installed as a git `commit-msg` hook, which sees the final
message every time. If the repository already has a `commit-msg` hook, installing
leaves it alone; chain the check into yours to get the same guarantee:

```sh
"$(git rev-parse --show-toplevel)/.aicodepipeline/core/hooks/wo-reference.py" "$@" || exit $?
```

### Install profiles

`minimal` is rules, agents, commands and the six lifecycle skills with no hooks;
`standard` (the default) adds every skill and the hook set; `full` adds every optional
agent pack and skill pack. `install.sh --profile` and `new-project --profile` take the
same values, plus `--skill-pack` and `--agent-pack` for one at a time.

### Upgrading

```bash
acp install <project>
```

Re-run the installer over the project. It replaces the pipeline's own hooks by their
`acp:` identity, keeps every hook and setting that is yours, and adds anything new. A
failed install leaves the project intact; the replacement is staged before anything is
removed, and your own overlays and harness configuration are held with the project
until the install commits. `acp doctor` only reports; it never edits git hooks.

## Rules and agents

`core/rules/common/` is ten short files, always loaded: work orders, testing, coding
style, code review, security, git, agents, patterns, documentation, troubleshooting.
`core/rules/ui/` carries the UI standards and loads whenever a UI stack is present.
Twenty-one language sets extend them; `install.sh` picks the right ones from what
`bin/detect-stack` finds.

Agents: 52 technology specialists and 43 process roles, each with responsibilities,
code templates, a validation checklist, patterns and anti-patterns. Opt-in domain
packs add 19 more (`identity`, `ml`, `network`, `healthcare`, `gan`). Project-specific
narrowing goes in `core/agents/overlays/`, which survives reinstalls.

## Understanding code you did not write

The same evidence discipline applies to claims about code. `wo new --area analysis`
and `--area docs` read a repository without touching it and produce documentation whose
every claim traces to a source file:

```bash
/analyze-repo ./their-service   # eight-phase read-only analysis
/status-matrix                  # honest badges: implemented, partial, planned, not available
/docs-faq · /docs-brief · /docs-primer · /docs-reference · /docs-developer
/feasibility "can it do X?"     # verdict, mechanism, integration path
/review-docs <path>             # factuality validation, then critical review
```

**Source or silence:** anything that cannot be traced to a file is omitted, never
invented, and every claim carries a `<!-- SOURCE: path:L12 -->` comment a hook verifies.
**The validator is never the author.**

## Packs

```bash
pack list
pack search "rate limit"
pack show WO-0407
```

`wo promote` moves a verified work order into your project's pack and writes a catalog
entry. The repository ships the machinery and no corpus: `packs/` starts empty, and the
author's own packs stay private. To share a pack, run `bin/sanitize` on it first.

## Before anything leaves your machine

```bash
bin/sanitize <dir> --report report.md
```

Secrets, personal identifiers, internal infrastructure, host paths, dangerous files. A
single critical finding is a FAIL, and `wo promote` refuses to promote work that fails.

## Testing the pipeline itself

`bin/acp test` is the whole gate in one command: lint, the sanitizer over every shipped
directory, every behavioural evaluation, the plugin build and plugin validation.
`TESTING.md` documents each check with its expected output. `acp eval new` adds an
evaluation whenever an agent, rule or hook change could regress silently.

## Layout

```
core/       methodology, templates, agents, skills, hooks, rules, commands, config
harness/    behavioural and load test frameworks
packs/      your domain experience, built by promotion
bin/        acp, new-project, install.sh, build-plugin, wo, bug, pack, sanitize,
            detect-stack, lint, eval
docs/       getting-started tutorial, harness guide, agent security, overlay example
```

## Author

Christian Torres — [github.com/ChrisTorres404](https://github.com/ChrisTorres404)

MIT licensed. `THIRD-PARTY-NOTICES.md` carries the notices the licence requires.
