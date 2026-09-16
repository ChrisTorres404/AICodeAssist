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
- A real adoption into a mature monorepo, 95 work orders and 44 bugs migrated and 27
  suites wired, produced 29 findings. Every one that was a defect is fixed and has a
  regression evaluation; the ones that were design gaps became `acp baseline`, `wo adopt`,
  `wo suite --wrap`, and exit 77.
- The pipeline tests itself with the same discipline: `bin/acp test` runs fifty
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

## Intake: what happens before the pipeline trusts your project

Installing puts the files in place. It does not make the project operational, because
nothing has been measured or described yet. So installing also opens six small work
orders, each with a spec that ships complete and a suite that proves the step, and the
pipeline's own rule applies to its own setup: nobody types PASS.

| Step | The suite proves |
|---|---|
| Source state | a repository with at least one commit; the remote and its drift reported |
| Instructions | `AGENTS.md` names the configured layout and `CLAUDE.md` imports it |
| Baseline | the project's own tests ran once, recorded against this exact tree |
| Record | the existing record was inventoried and brought in without fabricated evidence |
| Suites | at least one way to produce evidence exists |
| Knowledge base | the repository is described, and every claim resolves to source |

`acp intake status` shows where you are; `acp doctor` says operational only when all six
have closed on executed evidence. `acp intake inventory` does the classifying: it reads
the repository without touching it, works out whether its record is pipeline-shaped,
numbered, ADR-shaped, loose, or absent, catalogues every document, and writes the exact
`wo adopt` commands for what can be adopted. Loose documentation is indexed and left
alone unless you choose otherwise.

**The knowledge base** is the same eight-phase analysis the pipeline uses to document
code it did not write, run against your own: an analysis document, a Feature Profile
per feature with every claim traced to a file and line, a status matrix, and a source
index with a content hash for each cited file. It stays true the way evidence does.
`acp kb status` reports every profile as current, stale, or broken and names the source
no profile describes. `wo close` tells you which profiles the change you are closing
touched, and writes that into the closeout. The same rule runs in the pre-commit hook
and in CI. Updating a profile is work for an agent; knowing when is the tool's job.

## Adopting a project that already exists

Most projects that want this are not new. They have a record of work already done, a test
harness of their own, and a codebase nobody has measured in a while. The tool has a path for
each, and one order that avoids most of the trouble: commit first, measure second, install
third, wrap rather than rewrite, then verify, close, and commit in that order.

- **`acp baseline`** runs the project's own tests once, records the result bound to the tree
  it ran against, and reports the record against the measurement. Structure checks say nothing
  about whether the tests pass; this is the step that asks, and `acp doctor` asks for it.
- **`wo adopt <file> --number N`** brings an existing work order in as history: the document
  unchanged, the number it already cites, a state that is neither open nor closed, and no
  verification. Adopted work is recorded, not verified, until a suite genuinely runs. `bug adopt`
  does the same and keeps the category in the metadata, because an adopted number may land in
  a series it does not belong to.
- **`wo suite <n> --wrap '<command>'`** scaffolds a suite that delegates to the runner the
  project already has instead of the shipped HTTP template. `SUITE_COMMAND` in the configuration
  makes that the default shape.
- **Exit 77 means "I could not run."** A suite whose environment never came up has asserted
  nothing, and is recorded as `NOT EXECUTED — PRECONDITION FAILED`, never as a failure.

The full runbook, with the mistakes it was written from, is in
[docs/adopting-an-existing-project.md](docs/adopting-an-existing-project.md).

## Works with your tools

The drivers (`wo`, `bug`, `pack`, `acp`) are plain bash and run under any coding agent
or none. The git `commit-msg` hook runs regardless of who typed the command. The
templates and the methodology are files any agent can read.

The session hooks, the slash commands and the specialist subagents are Claude Code
features. Everything else reaches every agent: the instructions are written to `AGENTS.md`,
which Codex, Cursor and most agents read, and `CLAUDE.md` imports it; the specialists routed
for a work order are written into the work order's own prompt; and the rules run at
`wo close`, in a git pre-commit hook, and in CI, none of which care which agent typed. Without
Claude Code you lose the in-session early warnings and nothing else. Everything the tool
refuses to do, it still refuses.

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

Needs the `gh` CLI, authenticated.

**What the fingerprint binds to.** Every file's content, tracked or not, so committing does
not change it; and the suite that ran, bound on its own, so writing the next suite does not
stale this one. What does change it: any edit, formatting, or a teammate's change inside the
tree between the pass and the close. `wo new --paths` narrows the tree to the part the work
order touches; run the suite again and the evidence is current.

## What is enforced

| Rule | Mechanism | Profile |
|---|---|---|
| No closeout or promotion without `EXECUTED — PASS` | `wo close`, `bug close`, `wo promote` refuse on missing, plan-only, failed, or unfinished | always |
| A pass is bound to the source it ran against, and to the suite that ran | close refuses if the tree or the suite changed after the pass, or the tree moved while the suite ran | always |
| A suite that could not run is not a failure | exit 77 records `NOT EXECUTED — PRECONDITION FAILED`; close refuses on it as such | always |
| A verification document that is still mostly template | `wo close`, `bug close` refuse (`ALLOW_PLACEHOLDERS=1` to override) | always |
| A standard or large work order closed without a review by someone who did not write it | `wo close` refuses without a filled-in `WO-####-REVIEW.md` (`ACP_SKIP_REVIEW=1` to override) | always, any tool |
| Credentials, a weakened lint/format/type config, or a closeout without an executed pass, in what a work order changed | `acp check`, run by `wo close`, by the git `pre-commit` hook, and by CI | always, any tool |
| A commit cites a work order or bug that does not exist | git `commit-msg` hook, wired at install; sees `-m`, `-F`, stdin and editor messages alike | blocks (`ACP_WO_REFERENCE=warn` to override) |
| Credentials in staged changes | `commit-quality.py` on `git commit` | blocks; debug logging warns |
| Lint, format, or strictness config weakened to pass a check | `config-protection.py` | blocks (`ACP_ALLOW_CONFIG_EDIT=1` to override) |
| A closeout in the working tree rests on executed evidence | `evidence-gate.py` Stop hook | standard warns, strict blocks |
| `console.log`, `TODO: implement`, not-implemented stubs, debug output in nine languages | `quality-gate.py` | standard warns, strict blocks |
| Commits reference a work order | `wo-reference.py` | advisory |
| A credential-shaped test fixture | `commit-quality.py` and `acp check` honour `// acp:allow-secret` on that line, in the diff where a reviewer sees it | blocks otherwise |
| The pipeline's own vendored source | `commit-quality.py`, `quality-gate.py` and `acp check` skip the installed pipeline and `.claude/` copies | never reported |
| A commit message that must quote a work order that does not exist | `wo-reference.py` honours an `Acp-Allow-Reference: WO-9999` trailer in both the tool hook and the git hook | blocks otherwise |
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

Under Claude Code the session hooks run in the agent's own environment, not in the shell of
the command they inspect, so these have to be set where the agent starts: in the `env` block
of `.claude/settings.json`, or exported before launching it. As a prefix on a single command
they are silently ignored. And a hook that reads the git index reads it before your command
runs, so staging changes must be a separate command from the `git commit` they affect.

Every refusal that can fire on correct code has a visible way past it, in the diff rather
than in an environment variable: a credential-shaped test fixture carries
`// acp:allow-secret`, and a commit message that must quote a work order that does not exist
carries an `Acp-Allow-Reference: WO-9999` trailer.

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

### Where enforcement lives, and why it does not depend on Claude Code

Most of the table above can run in three places, and all three call one implementation:

| Tier | Runs | Needs | Catches an agent that skips the driver |
|---|---|---|---|
| Work order | `wo verify`, `wo close`, `bug close` | nothing, not even git | no |
| Local backstop | git `pre-commit` and `commit-msg` hooks, written at install | git | yes |
| Shared backstop | CI on the pull request (`acp ci github` adds the workflow) | a remote | yes, humans included |

The session hooks in `.claude/settings.json` run only inside Claude Code. They are the early
warning, not the enforcement: the same rules are said again at `wo close`, at commit time, and
on the pull request, and those three do not care which agent typed. Switching tools mid-project
loses the early warning and nothing else, because the state is in files, not in a session.

`acp check` is the rule set on its own, over the staged set, changes since a ref, an explicit
list of paths, or the files a work order has changed since it opened. That last one works
without git, from a manifest `wo new` takes of the tree. Blocking everywhere: credential-like
values, a lint, format or strictness configuration that was modified, and a closeout whose
latest verification is not an executed pass. Advisory, and blocking under the strict profile:
debug logging, stubs, oversized UI files, documentation claims that trace to nothing.

Without git, the work-order tier is all there is. That is still the tier that does the work,
but nothing can catch a closeout written by hand. A local repository with no remote costs
nothing and turns the backstop on; install and doctor both say so and give the command.

**Instructions reach every agent.** Install writes `AGENTS.md`, which Codex, Cursor and most
agents read, and a short `CLAUDE.md` that imports it. Your own copies of either are never
touched; doctor warns when the two have diverged. **Specialists reach every agent** the same
way: `wo new` writes the routed roles, their guidance and the path to each definition into the
work order's own prompt, so whatever tool does the work reads them. Under Claude Code the
prompt names the subagent to delegate to. `acp agent <name>` prints any of them from a shell.

**Evidence can be scoped.** In a monorepo, `wo new --paths packages/api` binds the fingerprint,
the manifest and the close-time checks to that part of the tree, so an unrelated commit
elsewhere does not invalidate the work order's evidence.

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

`wo promote` moves a verified work order into your project's pack, carries the suites that
produced its evidence with it, and writes a catalog entry. `pack lint` reports the entries
whose pitfalls are still the placeholder. The repository ships the machinery and no corpus: `packs/` starts empty, and the
author's own packs stay private. To share a pack, run `bin/sanitize` on it first.

## Before anything leaves your machine

```bash
bin/sanitize <dir> --report report.md
```

Secrets, personal identifiers, internal infrastructure, host paths, dangerous
files. Internal infrastructure means private and public IP addresses, SSH
connection strings, key-file references, and internal host names — a host under
a reserved private suffix (`.internal`, `.corp`, `.local`, `.lan`, `.intranet`,
`.home.arpa`) or a deep name under a top-level domain public documentation does
not use. Host names are reported as warnings, not critical findings: the shape
of a name is a judgement call, and the point is to put a person in front of it.

A single critical finding is a FAIL. `new-project` refuses to install a
pack that fails; `wo promote` refuses to promote a work order that fails. The
`release-sanitizer` agent reviews the report with judgement.

---

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
