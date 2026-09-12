# Getting started

Fifteen minutes, one real feature, start to finish: scaffold a project, open a
work order, write the code, run a behavioural suite, close on evidence, and
carry what you learned into a pack. Two tracks run side by side — **Node** and
**Python/FastAPI**; the pipeline is identical, only the code differs. Every command below is real and every output block is copied from
a run of it.

**You need:** macOS or Linux, bash, `python3`, `perl`, `git`, and Node or
Python for your track. Claude Code if you want the agents, skills, and hooks;
the drivers work without it. `<pipeline>` is your clone of this repository,
`<project>` the project you are creating.

---

## 1. Scaffold

```bash
cd <pipeline>
bin/new-project ~/code/task-tracker --name "Task Tracker" --domain example.com
cd ~/code/task-tracker
export PATH="$PWD/.aicodepipeline/bin:$PATH"
```

```
  rendered 728 files
  installed 95 agents, 32 commands, 162 skills, 1 workflows
  installed rules: common
  hooks installed; 77 allow and 21 deny rules added
  wrote CLAUDE.md from the project template (none existed); git initialised
```

`--profile minimal` gives rules, agents, commands, and the six lifecycle skills
with no hooks; `standard` is the default; `full` adds the domain agent packs and
every optional skill pack.

## 2. Read the CLAUDE.md it generated

It is yours — `install.sh` never overwrites it. Read the **Project specifics**
section at the bottom first; that is what an agent reads to locate your code.
On an empty project it is honest about knowing nothing yet: `- **Stack:**
_(empty project — fill in once code exists)_`, and the same for run and test.

## 3. Check the install

```bash
acp doctor
```

```
  PASS  pipeline installed at .aicodepipeline/
  PASS  no unresolved template variables
  PASS  hooks wired in .claude/settings.json
  PASS  agents: 95    skills: 162    rules: common
  WARN  CLAUDE.md Project Specifics still has placeholders — run: detect-stack . --write

healthy — 1 warning(s)
```

A FAIL means the install is broken; a WARN is a to-do.

## 4. Write some code

**Node track** — `package.json` with `dev` and `test` scripts, and
`src/server.js`: an HTTP service with `/health`, `POST /api/v1/tasks`, and
`GET /api/v1/tasks`. No dependencies; `node:http` is enough.

**Python track** — `pyproject.toml` with `fastapi` in `dependencies`,
`app/main.py` with `app = FastAPI()` and the same three routes, and `tests/`.

Keep it small. The point is the lifecycle around it, not the service.

## 5. Tell the pipeline what the project is

```bash
detect-stack . --write
```

```
updated ./CLAUDE.md: **Stack:** javascript (npm)        # Node track
updated ./CLAUDE.md: **Stack:** python, fastapi (pip)   # Python track
installed rule sets: typescript                        # or: python
```

It rewrites the Stack / Run / Test / Build lines of CLAUDE.md in place and
installs the rule sets the code now needs — on the Python track, `Run locally:
uvicorn app.main:app --reload` and `Run tests: pytest`. Add a `tsconfig.json`
and the Stack line reads `typescript` instead. Run it again whenever the stack
changes; without `--write` it only prints.

## 6. Open a work order

```bash
wo new "Task create endpoint" --area backend --size standard
```

```
WO-0001 created (standard): <project>/Workspace/Docs/WorkOrders/WO-0001-task-create-endpoint
    WO-0001-CHECKLIST.md   WO-0001-Prompt.md   WO-0001-SPEC.md   WO-0001-TASK-BREAKDOWN.md

Delegation (backend):
  implement with : nodejs-expert
  backup         : architect
  validate with  : project-validator-expert

Next: fill in the SPEC before writing code. Closeout is blocked until
      WO-0001-VERIFICATION.md exists with real execution evidence.
```

`--area` routes the work to the right agents (`backend api database auth rbac
frontend ui styling testing cicd docker security performance docs analysis`).
`--size` sets the ceremony: `trivial` one document, `small` a SPEC, `standard`
four, `large` adds SDK and UI docs. Every size requires a verification to close.

## 7. Fill in the SPEC

Open `WO-0001-SPEC.md` and replace the placeholders — what changes, the API
shape, the acceptance criteria, what the tests must prove. Do this **before**
the code: it is the contract the verification is checked against.

## 8. Scaffold the behavioural suite

```bash
wo suite 1
```

```
Suite scaffolded: Workspace/Testing/suites/wo-0001-task-create-endpoint.sh
Fill in the checks, start the service, then:  wo verify 0001 --run Workspace/Testing/suites/wo-0001-task-create-endpoint.sh
```

It sources the harness config and helpers, waits for the service, and exits
non-zero on any failure. Replace the commented example with one line per
behaviour:

```bash
J='content-type: application/json'
check "$(code "$BASE/health")" 200 "health answers 200"
check "$(code -X POST -H "$J" -d '{"title":"spec first"}' "$BASE/tasks")" 201 "POST /tasks creates a task"
check "$(code -X POST -H "$J" -d '{}' "$BASE/tasks")" 400 "POST /tasks rejects a missing title"
check "$(curl -s "$BASE/tasks" | grep -c 'spec first')" 1 "the created task is in the list"
```

`API_BASE` comes from `.aicodepipeline/harness/config/test-config.env` and
defaults to `http://localhost:3001/api/v1`; export it to point elsewhere.

## 9. Start the service and verify

```bash
node src/server.js &                            # Node track
.venv/bin/uvicorn app.main:app --port 3001 &    # Python track
wo verify 1 --run Workspace/Testing/suites/wo-0001-task-create-endpoint.sh
```

A failing run is recorded as a failing run; fix the code, re-run the same
command, and the document is rewritten:

```
WO-0001 verification document created: <project>/.../WO-0001-VERIFICATION.md
Running: Workspace/Testing/suites/wo-0001-task-create-endpoint.sh
EXECUTED — FAIL (exit 1) — recorded in WO-0001-VERIFICATION.md, full log in WO-0001-VERIFICATION-20260911-200025-47676.log
...
EXECUTED — PASS (exit 0) — recorded in WO-0001-VERIFICATION.md, full log in WO-0001-VERIFICATION-20260911-200112-59672.log
```

Nobody types `PASS`. The status comes from the suite's exit code and the full
log is kept beside the document as the evidence.

## 10. Close

Closing before the suite passed is refused:

```
wo: refusing to close WO-0001: verification is EXECUTED — FAIL. Fix the work, re-run:  wo verify 0001 --run <suite.sh>
```

Before it will close, write up the verification document. `wo verify` records what
ran and what it returned; the narrative around it is yours. Close refuses a document
that is still mostly the shipped template, because a form nobody filled in reads as
evidence and is not. If the remaining prompts genuinely do not apply, `ALLOW_PLACEHOLDERS=1`
says so explicitly.

With an executed PASS on file and the verification written up, `wo close 1` drafts the closeout:

```
WO-0001 closeout drafted: <project>/.../WO-0001-CLOSEOUT.md
Fill it in from the verification report — do not claim results that were not executed.
```

## 11. Write down what you learned, then promote it

Fill in **Lessons Learned** now, while you still remember; `wo promote 1`
refuses a closeout that still says `[Lesson 1]`. Then it lands in a pack, and
`pack search "suite"` finds it again from your next project:

```
WO-0001 promoted to pack 'task-tracker': <project>/.aicodepipeline/packs/task-tracker/workorders/WO-0001-task-create-endpoint
Catalog entry appended: <project>/.aicodepipeline/packs/task-tracker/CATALOG.md

CATALOG — task-tracker
  WO-0001 — Task create endpoint
    pitfall:  1. The suite must assert on the list endpoint, not only the create response
    pitfall:  2. A 400 case is worth an assertion of its own — the happy path alone hid the missing title check
```

That is the point of a pack: the mistakes come back before you repeat them.

## 12. A bug, end to end

```bash
bug new "Whitespace-only title is accepted" --category api
```

```
BUG-0100 opened: <project>/Workspace/Docs/Bugs/BUG-0100-whitespace-only-title-is-accepted

Routing (api):
  investigate with : support-engineer-expert + rest-expert
  fix with         : nodejs-expert
```

Each category owns a number series (`auth` 0001, `api` 0100, `database` 0200,
`ui` 0300, `observability` 0400, `security` 0500…). The gate is the same:

```
bug: refusing to close BUG-0100: no BUG-0100-VERIFICATION.md.
    The methodology forbids a closeout without executed-test evidence. Run:  bug verify 0100 --run <suite.sh>
```

Write a suite that reproduces the defect, fix the code, then `bug verify 100
--run <suite.sh>` and `bug close 100`.

## 13. Understanding code you did not write

The same discipline covers claims about code. In Claude Code, `/analyze-repo .`
opens its own work order (`wo new "<repo> analysis" --area analysis`), runs an
eight-phase read-only analysis, and writes a Feature Profile per feature into
that folder. Every claim carries the file it came from:


```markdown
The store never raises: it returns `None` for a missing note, and the HTTP layer
is the only place that turns that into a 404. <!-- SOURCE: app/store.py:33 -->
```

A hook resolves every `SOURCE` path and line as the document is written and
reports any that does not exist; anything untraceable is left out rather than
guessed. `/status-matrix`, `/docs-faq`, `/docs-primer`, `/feasibility`, and
`/review-docs` build on the same analysis.

## 14. The hooks you will see fire

Write `console.log` into a source file and the gate answers before you move on:
```
Quality gate — 1 issue(s) just written into <project>/src/server.js:
  server.js:1  console.log — use the project logger
These violate the project's code-quality rules. Fix them now, in this turn.
```

Every session opens oriented:

```
In-flight work orders (SCTPVC = Spec/Checklist/Tasks/Prompt/Verification/Closeout):
  WO-0002  SCTP.. open         standard task-tracker-analysis
Search prior work before specifying anything new: .aicodepipeline/bin/pack search "<term>"
```

Others block a commit carrying a credential, refuse edits that weaken a lint or
strictness config, and stop a closeout resting on `NOT EXECUTED — PLAN ONLY`.
`ACP_HOOK_PROFILE` decides how hard they push (`minimal | standard | strict`).

## An existing project instead

```bash
cp <pipeline>/pipeline.config.example.sh <your-project>/pipeline.config.sh
$EDITOR <your-project>/pipeline.config.sh     # PROJECT_NAME, PROJECT_SLUG, the app paths
<pipeline>/bin/install.sh <your-project>
```

The stack is detected from the code already there, so the rule sets and the
CLAUDE.md stack section arrive filled in. An existing `CLAUDE.md` is left alone
— merge in what you want from `<pipeline>/core/templates/project/CLAUDE.md`.
Re-run `install.sh` from the pipeline clone to update; authored work and
`core/agents/overlays/` survive.

## Or as a plugin, with no install at all

```bash
cd <pipeline> && bin/build-plugin
claude plugin add ./dist/plugin        # then /plugin install aicodepipeline
```

You get the commands, agents, skills, and hooks with nothing written into the
project; `acp doctor` reports plugin mode. The drivers still want a
`pipeline.config.sh` to know where to put things.

**Next:** `CLAUDE.md` in your project (edit it; agents read it first) ·
`docs/harness.md` (the harness in full) · `TESTING.md` (how to verify the
pipeline itself) · `acp help`, or `wo`, `bug`, `pack` with no arguments.
