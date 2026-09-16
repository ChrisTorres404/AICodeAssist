# System Instructions — Systematic Test Fixing

These are the authoritative rules for the `/fix-tests` command. Follow them
exactly. They are language- and framework-neutral: substitute the project's own
test, build, and database commands, which the project `CLAUDE.md` records.

The long form — the reasoning behind each rule, a recorded recovery in full,
the triage taxonomy and the metrics — is
`{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md`.
First session with this method: read
`{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md` first.

---

## 1. Purpose

`/fix-tests` starts a **systematic test-fixing session** on a suite that is
failing at scale. The method exists because the naive approach — read a
failure, guess, change something, re-run everything — does not converge.

The session:

- Fixes large suites where the failures share a small number of root causes
- Verifies against the real system before changing anything
- Moves in measured increments: fix, verify, measure, repeat
- Delegates investigation to specialists rather than searching by hand
- Ends with a documented delta, not an impression

A session is about ninety minutes and is expected to move the pass rate by two
to five points on a suite failing at scale. A suite in that condition takes
four to six sessions to reach a healthy number; see section 6.

### What it will not do

It will not make a suite of mocked services and fixture data agree with
itself. A green run against a stub proves the code matches the stub, and a
stub drifts from the real service silently — so the suite reports health it
cannot observe.

Recovery effort is spent in this order: behavioural suites against the running
system first, then integration suites that talk to a real data store, then
unit suites over isolated logic. When a large share of the failures turn out
to be fixtures that no longer resemble the real system, the finding to report
is that the suite is measuring the fixture — recommend converting those cases
to behavioural suites under `{{TESTING_DIR}}/suites/` rather than spending the
session on the stub. Put that to the user with the evidence; it is a finding,
not a licence to stop fixing tests.

---

## 2. Critical Principles

### Always

1. **Verify before assuming.** A column, a table, an enum value, a route, a
   config key: check that it is what you think it is.
2. **Delegate investigation.** Specialists investigate faster and return
   `file:line`. Do not grep your way through a large codebase by hand.
3. **Work incrementally.** Fix one category, re-run, measure, then continue.
4. **Stay conservative.** One category of failure at a time.
5. **Document with references.** Every change gets a `file:line` and a reason.

### Never

1. **Never assume a name.** Schemas and APIs drift from the code that uses them.
2. **Never batch fixes** across categories without verifying in between.
3. **Never skip the re-run** after a change.
4. **Never override what the user told you** about the state of the system.
5. **Never fix blindly.** Understand the root cause before editing.
6. **Never fix the test to match broken behavior** unless the test is provably
   wrong — and then say so explicitly, with the reasoning.

---

## 3. The Workflow

### Phase 1 — Assessment (about 10 minutes)

#### Step 1 — Read the context

Any handoff document under `{{SESSIONS_DIR}}/active/`, the relevant work order,
and the project `CLAUDE.md` for the commands this project actually uses.
Extract: project name, environments, data stores, how the suite authenticates,
the current pass rate, and the known issues.

```bash
ls {{SESSIONS_DIR}}/active/
cat {{SESSIONS_DIR}}/active/next-session-handoff.md
```

#### Step 2 — Establish a baseline

Run the suite, capture the full output to a file, and record the numbers before
touching anything. Without a baseline there is no delta, and without a delta
there is no evidence the session helped.

```bash
<the project's test command> 2>&1 | tee /tmp/baseline.txt
```

Check that no earlier run is still holding the database, the port, or the
workers before trusting that output:

```bash
ps aux | grep test
```

#### Step 3 — Check the infrastructure the tests depend on

Does the data store answer? Do the tables or collections the suite needs exist?
Did the last migration actually run, or only register?

```bash
<db client> -c "SELECT 1;"
<db client> -c "\dt <schema>.*"
<db client> -c "SELECT name FROM <migrations table> ORDER BY 1 DESC LIMIT 10;"
```

#### Step 4 — Categorize every failure

Do not fix anything yet. Produce counts:

| Category | Why it matters |
|---|---|
| Build or type errors | Blocking — nothing downstream can run |
| Schema or data-model mismatches | Blocking — the system will not initialize |
| Wrong status codes or response shapes | The test and the code disagree about the contract |
| Authentication or session failures | Usually one cause behind many failures |
| Timeouts and flakes | Often environmental, not a code defect |
| Everything else | Triage individually |

A category with forty failures and one root cause is the best use of the next
twenty minutes. Order the work by that, not by file order.

### Phase 2 — Fix the Blockers (about 20 minutes)

Blockers are failures that prevent other tests from running at all. Nothing
else is worth measuring until they are gone.

#### Step 5 — Build and type errors first

Extract them from the captured output, fix them, and confirm the project builds.

```bash
<the project's build command> 2>&1 | tee /tmp/build-errors.txt
<the project's type-check command>
```

#### Step 6 — Verify names against the real system

For every failure that mentions
a column, field, table, or key, check the live schema before editing code. For
a SQL database:

```bash
# what tables exist
<db client> -c "\dt <schema>.*"

# the real shape of one table
<db client> -c "\d <schema>.<table>"

# exact column names, in order
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"
```

Then find every place the code names it, and reconcile. **The live schema is
the fact; the model is the claim.** When they disagree, decide which is wrong
with evidence, not preference. Sometimes the model is right and the migration
never ran — a different fix entirely, and only the verification tells you which
one you are looking at.

```bash
# and what the code names
grep -rn "<name>" <source dir>
```

#### Step 7 — Record every name you verify

Keep a mapping in the session's
schema-verification document so the next session reads it instead of deriving
it again:

| Stored name | Code name | Wrong guess that cost time |
|---|---|---|
| `routemethod` | `routeMethod` | `route_method` |
| `routepath` | `routePath` | `route_path` |
| `detectedat` | `detectedAt` | `detected_at` |
| `accountid` | `accountId` | `account_id` |
| `userid` | `userId` | `user_id` |
| `primaryemail` | `primaryEmail` | `primary_email` |
| `creatortype` | `creatorType` | `creator_type` |
| `modifiertype` | `modifierType` | `modifier_type` |
| `invitedby` | `invitedBy` | `invited_by` |

That is a filled example from a real recovery, and the shape is the point: the
third column is what stops the next session repeating the guess. Replace the
rows with this project's own verified names — every row added only after the
name was read out of the live schema, never from the convention it looks like
it follows.

A mismatch class that recurs — one convention in the store, another in the
code — belongs in an agent overlay under
`{{PIPELINE_ROOT}}/core/agents/overlays/`, so the next session starts knowing
it. Overlays survive reinstalls; edits to this file do not.

#### Step 8 — Run a targeted test

Five to ten tests that exercise what was just fixed, run serially, to confirm
the blockers are gone before moving on. Not the full suite; that comes at the
end.

```bash
<the project's test command> <path/to/one/area> --maxWorkers=1 --forceExit
```

### Phase 3 — Systematic Search (about 30 minutes)

Once the blockers are fixed, the remaining failures usually cluster into a few
shared causes. Find **all** instances of each cause in one pass, rather than
one per test run.

The archetype is naming-convention drift: the data store uses one convention,
part of the code uses another, and the mismatch shows up as dozens of
unrelated-looking failures. The method generalizes to any systematic mismatch —
a renamed field, a changed date format, a moved endpoint prefix, a config key
that lost its namespace.

#### Step 9 — Enumerate the suspect pattern across the codebase

Data-model definitions, query construction, raw queries, fixtures, and test
expectations — all four, not just the first.

```bash
# 1. model and schema definitions
grep -rn "<pattern>" <source dir> --include="*<model file suffix>"

# 2. query construction
grep -rn "<pattern>" <source dir>

# 3. raw statements
grep -rniE "(FROM|JOIN|WHERE) +<pattern>" <source dir>

# 4. fixtures, seeds, and test expectations
grep -rn "<pattern>" <test dir> <seed dir>
```

#### Step 10 — Verify each hit against the real system

Record "code says X, system says Y" for each. Do not fix from the list; fix from
the verification.

```bash
# reduce to unique names first, so nothing is checked twice
grep -rhoE "<pattern>" <source dir> | sort -u

# then verify each one
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE column_name LIKE '%<name>%';"
```

#### Step 11 — Fix every confirmed mismatch in one pass

One pass, one commit per class, each referencing the work order.

#### Step 12 — Re-run the affected tests and record the delta

```bash
<the project's test command> <path/to/one/area> --maxWorkers=1 --forceExit
```

#### Step 13 — Search again and prove the class is gone

An empty result is the exit condition for this phase.

```bash
grep -rn "<pattern>" <source dir> <test dir> || echo "clean"
```

A remaining hit you have verified as correct is also acceptable — but write it down, with the reason, in the schema-verification
document.

Search all four places, not the first one. Searching only the model
definitions is the most common way this phase is left half-done, and the
failures it leaves behind look like new, unrelated defects in the next
session.

### Phase 4 — Delegated Investigation (about 20 minutes)

For anything that resists the first three phases, delegate. Escalate in this
order; most failures resolve at the step people skip.

| Step | Need | Agent |
|---|---|---|
| 1 | Context: what changed, what the conventions are, where the documentation is | `code-explorer` or the `Explore` agent |
| 2 | Active debugging: why does this specific endpoint or test fail | `support-engineer-expert` |
| 3 | Infrastructure: does the table exist, did the migration run, is the module wired up | `database-validator-expert` |
| 4 | Failures that hide: empty catches, swallowed errors, misleading fallbacks | `silent-failure-hunter` |
| 5 | The build or type-check itself is broken | `build-error-resolver` |

Prompt templates: `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`.
Longer session prompts for driving this by hand:
`{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md`.

Match the model to the shape of the question, not to the urgency of the
failure:

| The question | What it needs |
|---|---|
| Where is this documented; sweep many files for a pattern | A fast model — the work is search, not reasoning |
| Trace a request through four layers and find where the value is lost | A strong reasoning model — the work is inference over indirect evidence |
| Do these objects, fields, and seed rows exist | A strong model with data-store expertise; the queries are easy, the conclusions are not |

**Investigators investigate; they do not edit.** They return findings with
`file:line`, what they verified, and what would disprove their theory. Applying
the fix is your job, or a separate delegation. A different agent validates it.

### Phase 5 — Validation and Measurement (about 10 minutes)

#### Step 14 — Re-run the targeted tests after each fix

```bash
<the project's test command> <path/to/one/area> --maxWorkers=1 --forceExit
```

#### Step 15 — Run the full suite

```bash
<the project's test command> 2>&1 | tee /tmp/after-fixes.txt
```

#### Step 16 — Extract and compare the metrics

```bash
grep -E "Tests:|Suites:|Time:" /tmp/baseline.txt
grep -E "Tests:|Suites:|Time:" /tmp/after-fixes.txt
```

Record all four numbers before and after: suites passing, tests passing, pass
rate, and duration. Compare against the baseline, honestly. A session that moved nothing is a
finding worth reporting, not a failure to hide.

---

## 4. Required Outputs

Every session produces these under `{{SESSIONS_DIR}}/active/`:

**`<date>-test-fixing-session.md`** — every fix with `file:line`, the before
and after numbers, what each delegated agent found, the time spent on each
phase, and what was verified.

**`<date>-remaining-issues.md`** — the unfixed failures, still categorized,
each with an estimate and a recommended next step, in priority order.

**`<date>-schema-verification.md`** — everything verified against the live
system: tables, fields, migration state, and every discrepancy found, whether
or not it was fixed.

If the work belongs to a work order, the same evidence goes into its
VERIFICATION document via `wo verify --run`. Never write a status by hand.

---

## 5. Delegation Rules

### When to use each agent

The escalation table in [Phase 4](#phase-4--delegated-investigation-about-20-minutes)
is the routing rule: context first, then active debugging, then infrastructure,
then the two specialists. Go in that order. Step one is the one people skip and
the one that most often makes steps two and three unnecessary.

### Agent prompt best practices

#### Do

1. State the symptom and what you have already tried
2. Name the specific files to investigate
3. Ask for `file:line` references in the response
4. Ask for the verification step that would confirm the fix
5. Give the environment context: which database, which environment, which
   configuration
6. Quote error messages verbatim

#### Do not

1. Ask an investigator to make changes
2. Send a vague prompt
3. Omit what you already ruled out
4. Ask several unrelated questions in one delegation

---

## 6. Progressive Strategy

A suite failing at scale is not recovered in one sitting. Expect the work to
move through these stages. The bands are the shape of a typical recovery, not
a promise: a suite whose failures share one cause moves faster, and one whose
failures are genuine defects moves slower, because those fixes are real work.

| Iteration | Focus | What to run at the end | Effect | Typical band |
|---|---|---|---|---|
| 1 | Build and type errors, blocking schema mismatches | 5-10 targeted tests | The suite runs at all | 5-15% |
| 2 | Systematic mismatches found in Phase 3 | 20-30 targeted tests | The largest single jump | 15-25% |
| 3 | Wiring: unregistered modules, missing routes, model and contract drift | 50-100 tests | Steady gains | 25-35% |
| 4 | Business logic: authentication, permissions, workflow state | The full suite | The long tail | 35-50% |
| 5-6 | Remaining edge cases and flakes | The full suite | Convergence | The project's target |

Run the smallest set that can show the fix worked, and widen it as the
categories close. Running the whole suite after every change in iteration 1
buys nothing and costs the session its momentum; running only a handful in
iteration 4 hides the regressions the later fixes cause.

**Goal: 70%+ pass rate after four to six iterations (6-9 hours.)** That is the
figure to plan against for a suite failing at scale, and the point at which the
remaining failures are usually genuine defects rather than systematic
mismatches. A project with a higher bar sets its own target; the arc is the
same.

Each iteration ends with a full run, a recorded number, and a handoff. **Write
the handoff whether or not the work is finished, and whether or not the session
went well** — the session that stops without one costs the next session its
first twenty minutes.

### Expected timeline

#### The session budget

| Phase | Minutes |
|---|---|
| 1. Assessment | 10 |
| 2. Blockers | 20 |
| 3. Systematic search | 30 |
| 4. Delegated investigation | 20 |
| 5. Validation | 10 |
| **Total** | **90** |

Four to six of those sessions is the normal cost of reaching 70%+ from a
failing-at-scale state — 6 to 9 hours in total. Budget the whole arc, not the
first session.

Read the pass rate against the suite's duration. A suite that got dramatically
faster usually stopped crashing during initialization, which is the work that
makes the *next* session's gains possible even though it moves the rate
little. Report both numbers and say which happened.

---

## 7. Verification Checklist

Before the session is complete:

- [ ] Build and type-check pass
- [ ] A baseline run was captured to a file before anything changed
- [ ] Every failure was categorized and counted before anything was fixed
- [ ] Every systematic mismatch of the class found in Phase 3 is gone, and a
      repeat search proves it
- [ ] The data model is verified against the live schema, in the same
      environment the tests run against
- [ ] The verified name mapping is written down for the next session
- [ ] Everything the suite needs is registered and reachable
- [ ] Contracts and their consumers agree
- [ ] Targeted tests were re-run after each category of fix
- [ ] The full suite was run and the numbers captured to a file
- [ ] The improvement is documented as before → after, with the duration and
      the error-category counts alongside the pass rate
- [ ] Every fix carries a `file:line` and a reason
- [ ] Delegated findings are recorded, including the ones that ruled things out
- [ ] Remaining issues are categorized, with an estimate and a priority
- [ ] Any recurring mismatch class is recorded in an agent overlay
- [ ] A handoff exists if the session is ending mid-work

---

## 8. Success Criteria

**For the session**

- The pass rate moved by two points or more, and the delta is backed by two
  captured runs — or, if it did not, the session says so and explains why
- Blockers are resolved: the system initializes and the suite runs
- At least one whole error category was eliminated, counted before and after
- The data model is verified rather than assumed, and the mapping is written
  down
- Every fix has a `file:line` reference and a reason
- The suite's duration was recorded alongside the pass rate

**For the effort overall**

- 70%+ pass rate achieved, or the project's own higher bar if it has one
- The suite passes at the level the project requires
- Every critical path is covered by a test that runs against the real system
- The data model and the live schema agree completely
- No instance of the systematic mismatch remains, proven by a repeat search
- Everything the suite needs is registered and reachable
- The recurring mismatch classes are recorded in an agent overlay, so the
  knowledge outlives the session

---

## 9. Quick Reference

Substitute the project's own commands; these are shapes, not literals.

### Testing

```bash
# Baseline and final runs
<test command> 2>&1 | tee /tmp/baseline.txt
<test command> 2>&1 | tee /tmp/after-fixes.txt

# One test or one directory
<test command> <path/to/one/test>

# Build and type-check
<build command>
<type-check command>
```

### Database verification

```bash
# Schema introspection (SQL)
<db client> -c "SELECT 1;"                 # does it answer at all
<db client> -c "\dt <schema>.*"
<db client> -c "\d <schema>.<table>"
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE column_name = '<one name>';"     # does this name exist anywhere
<db client> -c "SELECT name FROM <migrations table> ORDER BY 1 DESC LIMIT 10;"
<db client> -c "SELECT COUNT(*) FROM <schema>.<seeded table>;"
```

### Code search

```bash
# Finding a systematic mismatch across the codebase — all four places
grep -rn "<pattern>" <source dir>          # 1. model and schema definitions
grep -rn "<pattern>" <source dir>          # 2. query construction
grep -rn "<pattern>" <source dir>          # 3. raw statements
grep -rn "<pattern>" <seed dir> <test dir> # 4. fixtures, seeds, expectations

# Reduce to unique names before verifying, so nothing is checked twice
grep -rn "<pattern>" <source dir> | sed "s/.*<extract the name>//" | sort -u

# Prove the class is gone
grep -rn "<pattern>" <source dir> <test dir> | grep -v "<archived or vendored paths>"
```

### Measuring

```bash
# Counting categories, before and after
grep -E "<the runner's summary lines>" /tmp/baseline.txt
grep -E "<the runner's error markers>" /tmp/baseline.txt | sort | uniq -c | sort -rn
```

---

## 10. Adapting to This Project

The method is language- and framework-neutral. Two things make it concrete.

**1. The project's own commands.** Everything above is written as a shape.
Before the session starts, resolve each one from the project `CLAUDE.md` and
use the real command for the rest of the session:

| Shape | Resolve to |
|---|---|
| `<the project's test command>` | The suite runner, plus the flags this project uses for a full run |
| `<test command> <path>` | How this runner is pointed at one file or directory |
| `<build command>`, `<type-check command>` | The build and static-check commands |
| `<db client>` | The data-store client, with the connection arguments for the environment under test |
| `<migrations table>` | Wherever this project records applied migrations |
| `<source dir>`, `<test dir>`, `<seed dir>` | The real directories |
| `<schema>` | The namespace the failing objects live in |

Resolve them once, at the top of the session, and write the resolved set into
the session document so the next session inherits it:

```
[project name]    → this project's name
[dev database]    → the database the application uses in development
[test database]   → the database the suite runs against, if it differs
[credentials]     → the config key the suite's test account comes from
[path]            → the working directory the commands run from
[schema]          → the namespace the failing objects live in
[test command]    → the real runner invocation, with its real flags
```

If any of these is missing from `CLAUDE.md`, find it once and add it there;
the next session should not have to.

**2. The environment.** Name it out loud before the first fix: which
environment the suite runs against, which data store, and which credentials.
Every verification query in this document must be run against **the same**
environment the tests run against. A name verified in one environment and a
test executed in another is the most expensive mistake available here, because
every conclusion drawn afterwards is wrong in a way that looks like progress.

### Adjusting for the kind of suite

| Suite | Adjustment |
|---|---|
| Unit tests over isolated logic | Skip the schema verification in Phase 2. The blockers are build errors, imports, and stale generated types. Delegation is rarely worth it. |
| Integration tests against a real data store | Run all five phases as written. |
| Behavioural suites against the running system | Run all five phases, and add one check before Phase 1: is the system under test actually running, current, and serving the build you just changed? A stale process is the most common cause of a fix that "changes nothing". |
| Browser or UI flows | Reproduce with `e2e-runner` before fixing anything; the failure is often environmental. |

---

## 11. Interaction Shape

**User:** `/fix-tests`

**Agent:** reads the handoff and work order, checks the infrastructure, runs
the baseline, categorizes the failures, proposes a plan — and **waits for
approval** before changing anything.

**User:** approves.

**Agent:** fixes the blockers, verifies against the live system, runs a
targeted subset, reports the delta, proposes the next step.

**User:** continues.

**Agent:** performs the systematic search, verifies each hit, fixes them in one
pass, re-runs, reports.

**User:** asks for a specific issue to be investigated.

**Agent:** delegates with a template from the prompt library, reviews the
findings, applies the fix, verifies, reports.

Condensed, that is:

```
User:  /fix-tests
Agent: reads context → checks infrastructure → baseline → categorizes
       → proposes a plan → WAITS
User:  approves
Agent: fixes blockers → verifies names → targeted run → reports X% → Y%
User:  continue
Agent: systematic search → verify each → fix in one pass → re-run → reports
User:  investigate <specific issue>
Agent: delegates → reviews findings → applies fix → verifies → reports
Agent: full run → compares all four numbers → writes the three documents
```

---

## 12. Honesty

Never report a test as passing without having run it and seen it pass.
`NOT EXECUTED — PLAN ONLY` is an acceptable status. A false `PASS` is not, and
it is worse than an unfixed test, because every decision made after it is made
on a lie.

---

**Remember:** verify first, move incrementally, delegate investigation, stay
conservative, document everything.
