# The Test-Fixing System

A systematic method for recovering a test suite that is failing at scale,
together with the command that starts it and the delegation templates it uses.

It exists because the naive approach does not converge: read a failure, guess,
change something, run everything again, watch a different set of tests break.
The method replaces guessing with verification and replaces whole-suite churn
with measured increments.

---

## What It Is

| File | What it is | When it is read |
|---|---|---|
| `{{PIPELINE_ROOT}}/core/commands/fix-tests.md` | The `/fix-tests` slash command | The user types it |
| `{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md` | The on-ramp: what to prepare, what a session feels like, what to expect, what to do when it goes wrong | Before the first session |
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | The authoritative method: five phases, the rules, the checklists | Loaded by the command |
| `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md` | Delegation templates, one per question | Loaded by the command; used in phase 4 |
| `{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md` | Whole-session prompts for running the method by hand, and per-failure-mix adaptations | When the command is unavailable, or the brief is narrower than the command's |
| `{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md` | The long form: why each rule exists, a recorded recovery in full, the triage taxonomy, the metrics | Learning the method, or deciding whether a suite is worth recovering |
| `{{PIPELINE_ROOT}}/core/instructions/README-TEST-FIXING-SYSTEM.md` | This index | Anyone learning the system |

The command loads the `behavioral-testing` skill and both instruction files,
so nothing has to be pasted by hand. Each file states one thing once: the rules
live in 03, the per-question templates in 04, the whole-session prompts in 05,
the reasoning and the case in the methodology, and the on-ramp in 00.

### What each file contains

#### 1. The slash command

**File:** `{{PIPELINE_ROOT}}/core/commands/fix-tests.md`
**Purpose:** the entry point — type `/fix-tests` to start
**Type:** command definition
**Size:** about 50 lines

It points at the authoritative instructions, gives the workflow overview, and
makes sure the method is followed rather than improvised.

```
/fix-tests [suite or path]
```

#### 2. The authoritative instructions

**File:** `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`
**Purpose:** the complete method, with the exact rules to follow
**Type:** authoritative instructions
**Size:** about 600 lines

Contains: the five-phase approach, the verification pattern, the delegation
strategy, the progressive fix strategy, the verification checklist, the success
criteria, and the quick-reference commands. Loaded automatically when the
command is invoked.

#### 3. The delegation prompt library

**File:** `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`
**Purpose:** ready-to-use templates, one per kind of question
**Type:** prompt templates
**Size:** about 400 lines

Contains: context-search templates, debugging templates, infrastructure
verification templates, the usage guidelines, and the practices that separate a
useful delegation from a wasted one.

```
1. Identify the question — context, debugging, or verification
2. Choose the template
3. Fill in every bracket
4. Launch the agent
5. Read the findings and verify the load-bearing ones
6. Apply the fix and re-run
```

#### 4. The quick-start guide

**File:** `{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md`
**Purpose:** the step-by-step on-ramp
**Type:** user guide
**Size:** about 600 lines

Contains: how to use the system, what to expect per session, the rules that
matter most, common problems and their solutions, the customization guide, the
recorded outcomes, and the FAQ. For anyone new to the method.

#### 5. The session prompt library

**File:** `{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md`
**Purpose:** whole-session prompts for driving the method by hand
**Type:** reference templates
**Size:** about 780 lines

Contains: the full session prompt, four narrower variations, the agent prompt
templates, the verification checklist, the anti-patterns, the troubleshooting
guide, the cheat sheet, and one fully filled worked example. Use it in any
tool, with or without the command.

#### 6. The long-form methodology

**File:** `{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md`
**Purpose:** the reasoning, and a recorded recovery in full
**Type:** methodology and case study
**Size:** about 900 lines

Contains: a complete session walkthrough, the key success factors, the detailed
agent workflow, the reusable patterns, the lessons learned, the metrics, and
the steps to reproduce the method from nothing.

### How the pieces fit

```
                    /fix-tests
                        |
                        v
        03-e2e-test-fix-rules.md   (the authoritative method)
                        |
    +-------+-------+---+---+-------+-------+
    |       |       |       |       |
   P1      P2      P3      P4      P5
 assess  blockers  sweep  delegate  validate
                            |
                            v
          04-test-fixing-agent-prompts.md   (one prompt per question)
                            |
                            v
          three session documents + a handoff
                            |
                            v
                     /next-session
```

Off to one side, and used without the command: `00` before the first session,
`05` when the method has to be driven by hand, and the methodology whenever
the question is *why* rather than *how*.

---

## Quick Start

### 1. Verify the installation

```bash
ls {{PIPELINE_ROOT}}/core/commands/fix-tests.md
ls {{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md
ls {{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
ls {{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md

# and that the command actually points at the rules file
grep "03-e2e-test-fix-rules.md" {{PIPELINE_ROOT}}/core/commands/fix-tests.md
```

The last check is the one that catches a half-finished install: the files are
all present, the command runs, and it silently follows none of the rules
because the reference in it was never rewritten.

### 2. First-time setup

Read the on-ramp, then make sure the project's own commands are recorded where
the method expects to find them:

```bash
cat {{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md
grep -nE "test|build|type-check|migrat|database" CLAUDE.md   # from the project root
```

### 3. Run the first session

```bash
# capture the baseline before anything else
<the project's test command> 2>&1 | tee /tmp/baseline.txt

# start the session, and work the five phases
/fix-tests

# afterwards, compare
grep -E "<the runner's summary lines>" /tmp/baseline.txt
grep -E "<the runner's summary lines>" /tmp/after-fixes.txt
```

---

## How to Run It

```
/fix-tests [suite or path]
```

With no argument it runs the critical suite first and starts from its failures.

The session then moves through five phases:

| Phase | What happens |
|---|---|
| 1. Assessment | Read the context, capture a baseline run, check the infrastructure, categorize every failure. Change nothing. |
| 2. Blockers | Build and type errors, then the schema mismatches that stop the system initializing. Verify names against the live system before editing. |
| 3. Systematic search | Find every instance of each shared root cause in one pass, verify each, fix them together. |
| 4. Delegated investigation | Escalate what is left: context, then active debugging, then infrastructure. Investigators return `file:line`; they do not edit. |
| 5. Validation | Re-run, compare against the baseline, document the delta honestly. |

The agent proposes a plan at the end of phase 1 and waits for approval before
changing anything.

---

## Why It Works

**A baseline first.** Without two captured runs there is no delta, only an
impression. Every session starts and ends with a full run written to a file.

**Verification before assumption.** The live schema is the fact; the model is
the claim. Most large-scale failures come from the two having drifted apart,
and no amount of reading the code reveals which side is wrong.

**Shared root causes.** Forty failures rarely have forty causes. Categorizing
before fixing turns an endless queue into three or four pieces of work.

**Delegated investigation.** Specialists return `file:line` faster than a
manual search, and the escalation order — context, then debugging, then
infrastructure — resolves most failures at the step people skip.

**Honest measurement.** `NOT EXECUTED — PLAN ONLY` is an acceptable status. A
false `PASS` is not: every decision made after it is made on a lie.

---

## Workflow Comparison

### Before — the manual approach

Without the method:

```
run the suite → read one failure → guess → change something →
run the whole suite again → a different set of tests breaks → repeat
```

Three hours, no measurement, no record of what was verified, and no way to say
which change helped.

### After — the systematic approach

With it:

```
assess (10 min)   baseline captured, every failure categorized and counted
blockers (20)     build errors, then the mismatches that stop initialization
sweep (30)        every instance of the largest shared cause, verified, fixed
delegate (20)     context, then debugging, then infrastructure
validate (10)     full run, delta on four measures, three documents
```

Ninety minutes, a number backed by two captured runs, and a handoff that makes
the next session start where this one stopped.

### When to use each file

| File | When to use it | Who reads it |
|---|---|---|
| `core/commands/fix-tests.md` | Starting a session | The user types it |
| `core/instructions/03-e2e-test-fix-rules.md` | Automatically, by the command | The agent |
| `core/instructions/04-test-fixing-agent-prompts.md` | During Phase 4 | The agent, and the user choosing a template |
| `core/instructions/00-test-fixing-quick-start.md` | First time using the system | The user, learning |
| `core/instructions/05-reusable-test-fixing-prompts.md` | Driving the method by hand, in any tool | The user |
| `core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md` | Understanding why, and reading the recorded case | The user, learning |

---

## What It Produces

Under `{{SESSIONS_DIR}}/active/`:

| Document | Contents |
|---|---|
| `<date>-test-fixing-session.md` | Every fix with `file:line`, before and after numbers, what each delegated agent found |
| `<date>-remaining-issues.md` | The unfixed failures, still categorized, with estimates and a priority order |
| `<date>-schema-verification.md` | Everything verified against the live system, including discrepancies left unfixed |

If the work belongs to a work order, the same evidence goes into its
VERIFICATION document through `wo verify --run`, which writes the status from
the suite's exit code. Nobody types `PASS`.

---

## Working With the Rest of the Pipeline

### With a work order

Open one for the recovery effort, run `/fix-tests` inside it, and close it on
executed evidence. The closeout rests on the two captured runs.

```bash
wo new "Test suite recovery" --area testing --size standard
wo start <number>
wo note <number> "session 1: X% -> Y%"
wo verify <number> --run {{TESTING_DIR}}/suites/wo-<number>-suite-recovery.sh
wo close <number>
```

### With a session handoff

`/next-session` writes the handoff from the session documents above: fixes
applied, current numbers, remaining issues, next steps. The next session reads
it in phase 1 and continues from there.

```bash
/next-session
```

### With the playbooks

Search before investigating. A failure class that has been diagnosed once is
usually recorded with the fix and the pitfall that caused it.

```bash
playbook search "<symptom>"
playbook suite "<term>"
```

---

## Customization Guide

### For your project

The method is language- and framework-neutral. Two things make it concrete:

1. **The project's own commands** — test, build, type-check, migrate, database
   client. These live in the project `CLAUDE.md`, filled in at install time by
   stack detection. The instructions reference them, never a specific tool.
2. **Recurring patterns worth recording.** When a session uncovers a mismatch
   class specific to this codebase — a naming convention, a field that is
   always wrong in the same way — record it in an agent overlay under
   `{{PIPELINE_ROOT}}/core/agents/overlays/`, so the next session starts
   knowing it. Overlays survive reinstalls; edits to the instruction files do
   not.

```bash
ls {{PIPELINE_ROOT}}/core/agents/overlays/
cat {{PIPELINE_ROOT}}/core/agents/overlays/README.md
```

---

## Adapting It to Different Test Types

The five phases are written for a suite that talks to a real data store. Adjust
them for what you actually have:

### Unit tests over isolated logic

Skip the schema verification in Phase 2 — the blockers there are build errors,
imports, and stale generated types. Delegation is rarely worth it, because the
questions do not span files. Phases 1, 2, and 5 carry the session.

### Integration tests against a real data store

Run all five phases as written. Give Phase 4 more of the budget than the table
suggests: integration failures are where the multi-layer traces live, and a
delegated trace is far cheaper than a manual one.

### End-to-end and behavioural suites

Run all five phases, weight Phase 2 heavily towards schema verification, and
add one check before Phase 1: is the system under test actually running,
current, and serving the build you are about to change? A stale process is the
single most common cause of a correct fix that appears to do nothing.

### Browser and UI flows

Reproduce the failure with a browser runner before changing any code. UI
failures are environmental more often than any other kind — a timing
assumption, a viewport, a fixture account that no longer exists.

---

## Success Metrics

### Per session (90 minutes)

- Pass rate improved by 2-5 points, backed by two captured runs
- The blockers are resolved and the system initializes
- The live schema was verified against every model the session touched
- One or two delegations were used and their findings verified
- Every fix is documented with `file:line` and a reason
- The suite's duration was recorded alongside the pass rate

### Effort complete (four to six sessions)

- 70%+ pass rate achieved, or the project's own higher bar
- Every critical path is covered by a test that runs against the real system
- The data model and the live schema agree completely
- No instance of the systematic mismatch remains in the active codebase
- Everything the suite needs is registered and reachable

---

## Troubleshooting

**The command does nothing.** Confirm `/fix-tests` is installed and that the
instruction files are present:

```bash
ls {{PIPELINE_ROOT}}/core/commands/fix-tests.md
ls {{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md
ls {{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md
ls {{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
ls {{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md
```

If the command is unavailable for another reason — a different agent tool, a
plain chat session — the method still runs from a prompt in `05`.

**A delegation comes back vague.** The prompt was vague. Use a template from
the library, name specific files, quote the error verbatim, say what you have
already ruled out, and ask for `file:line` explicitly.

**Nothing improves.** Check, in this order: are you running against the
environment you think you are; were the fixes actually applied (`git diff`);
is this the suite that was failing; and did the system pick up the change, or
is a stale process still serving the old build? Compare the error-category
counts rather than only the pass rate: a category eliminated is progress even
when the rate has not moved.

The fuller diagnostic list — fixes that do not stick, tests that pass
individually and fail together, a suite that got slower — is in
`{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md`.

---

## Support and FAQ

### Getting help

```bash
# the on-ramp
cat {{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md

# the reasoning and the recorded case
cat {{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md

# the delegation templates
cat {{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
```

### Common questions

**How do I start?** Type `/fix-tests` and work the five phases. If the command
is unavailable, paste a prompt from `05`.

**Which agent should I use?** Context first, then active debugging, then
infrastructure. The routing table is in `03`, Phase 4.

**How long will it take?** Four to six sessions, 6-9 hours, to reach 70% from a
suite failing at scale.

**Can I customize it?** Yes. Fill in the project's own commands, and record the
mismatch classes specific to this codebase in an agent overlay.

**What if the suite is mostly mocks?** Do not spend the session making a stub
agree with itself. Report it, and recommend converting those cases to
behavioural suites.

---

## Maintenance

### After every session

- Record any new mismatch class in an agent overlay, so it is known before the
  next session rather than rediscovered during it
- Carry the verified name mapping forward in the schema-verification document
- Write the handoff, even when the work is unfinished — especially then

### Periodically

- Re-read the remaining-issues documents as a set; a cause that appears in
  three of them is a single piece of work, not three
- Re-check the commands in the project `CLAUDE.md` when the suite's structure
  or the runner changes
- Revisit the time estimates against what sessions actually cost here

### After a large schema or contract change

- Re-verify the data model against the live system *before* the next session,
  not during it
- Run the full suite once to re-baseline; the old number no longer describes
  anything

```bash
<the project's test command> 2>&1 | tee /tmp/rebaseline.txt
grep -E "<the runner's summary lines>" /tmp/rebaseline.txt
```

- Update the name mapping, and check whether the change invalidated an overlay

---

## Next Steps

### For a first-time user

1. Read `{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md`
2. Fill in the project's own commands in its `CLAUDE.md`
3. Capture a baseline run to a file
4. Type `/fix-tests`
5. Work the five phases
6. Write the three session documents and the handoff

### For an experienced user

1. Type `/fix-tests`
2. Delegate early rather than searching by hand
3. Track the four measures session to session, not just the pass rate
4. Refine the delegation templates from what actually returned useful findings
5. Promote what the recovery learned: `wo promote <number>`

### For advanced use

1. Adjust the phase budgets in `03` to what sessions actually cost here
2. Add this codebase's recurring mismatch classes to an agent overlay
3. Write the pre-flight checks the recovery kept wanting — a name checker that
   compares every model's fields against the live schema, and a
   migration-completeness checker that verifies the objects a recorded
   migration claims to have created
4. Run those checks in CI, before the suite, so a mismatch fails fast with a
   clear message instead of as forty unrelated-looking test failures
5. Publish the suite's pass rate, duration, and error-category counts per run
   as a build artifact, so the multi-session arc is a graph rather than a memory

---

## File Locations Summary

```
{{PIPELINE_ROOT}}/
├── core/
│   ├── commands/
│   │   └── fix-tests.md                          [the slash command]
│   ├── instructions/
│   │   ├── 00-test-fixing-quick-start.md         [quick start]
│   │   ├── 03-e2e-test-fix-rules.md              [authoritative rules]
│   │   ├── 04-test-fixing-agent-prompts.md       [delegation templates]
│   │   ├── 05-reusable-test-fixing-prompts.md    [session prompts]
│   │   └── README-TEST-FIXING-SYSTEM.md          [this index]
│   └── methodology/
│       └── SYSTEMATIC-TEST-FIXING-METHODOLOGY.md [reasoning and case]
└── harness/                                      [runners, helpers, config]

{{SESSIONS_DIR}}/active/                          [what a session writes]
{{TESTING_DIR}}/suites/                           [the suites it verifies with]
{{TESTING_DIR}}/results/                          [the captured runs]
```

Six documents, and a harness the suites run from.

---

## Version History

This section is a changelog for the system itself. Add an entry when the method
changes, not when a session runs.

### 1.0

- First release: the command, the rules, the delegation templates, the session
  prompts, the quick start, and the long-form methodology
- Five-phase method with verification-first ordering
- Delegation routing by question shape, with an escalation order
- Honest status vocabulary, and a closeout guard that rests on executed runs

---

## Origins

The method was not designed; it was extracted from a recorded recovery of a
large failing suite and then generalized until nothing project-specific
remained. The measurements quoted throughout — a first session that moved the
pass rate 1.9 points while cutting the suite's duration by 76%, and roughly 95
minutes saved by three delegated investigations — come from that session.

Everything here is language- and framework-neutral by construction: the
commands are shapes resolved from the project's own configuration, and the
examples use generic table and field names. If something in this system reads
as specific to one stack, that is a defect in this documentation, not a
constraint of the method.
