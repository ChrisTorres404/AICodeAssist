# System Instructions — Systematic Test Fixing

These are the authoritative rules for the `/fix-tests` command. Follow them
exactly. They are language- and framework-neutral: substitute the project's own
test, build, and database commands, which the project `CLAUDE.md` records.

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

### Phase 1 — Assessment

**Read the context.** Any handoff document under `{{SESSIONS_DIR}}/active/`,
the relevant work order, and the project `CLAUDE.md` for the commands this
project actually uses.

**Establish a baseline.** Run the suite, capture the full output to a file,
and record the numbers before touching anything. Without a baseline there is
no delta, and without a delta there is no evidence the session helped.

```bash
<the project's test command> 2>&1 | tee /tmp/baseline.txt
```

**Check the infrastructure the tests depend on.** Does the data store answer?
Do the tables or collections the suite needs exist? Did the last migration
actually run?

**Categorize every failure.** Do not fix anything yet. Produce counts:

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

### Phase 2 — Fix the Blockers

Blockers are failures that prevent other tests from running at all. Nothing
else is worth measuring until they are gone.

**Build and type errors first.** Extract them from the captured output, fix
them, and confirm the project builds.

**Then verify names against the real system.** For every failure that mentions
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
with evidence, not preference.

**Re-run a small targeted subset** to confirm the blockers are gone before
moving on.

### Phase 3 — Systematic Search

Once the blockers are fixed, the remaining failures usually cluster into a few
shared causes. Find **all** instances of each cause in one pass, rather than
one per test run.

The archetype is naming-convention drift: the data store uses one convention,
part of the code uses another, and the mismatch shows up as dozens of
unrelated-looking failures. The method generalizes to any systematic mismatch —
a renamed field, a changed date format, a moved endpoint prefix, a config key
that lost its namespace.

1. **Enumerate the suspect pattern across the codebase.** Data-model
   definitions, query construction, raw queries, fixtures, and test
   expectations — all four, not just the first.
2. **Verify each hit against the real system.** Record "code says X, system
   says Y" for each. Do not fix from the list; fix from the verification.
3. **Fix every confirmed mismatch in one pass.**
4. **Re-run the affected tests** and record the delta.
5. **Search again** to confirm nothing of that class remains.

### Phase 4 — Delegated Investigation

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

**Investigators investigate; they do not edit.** They return findings with
`file:line`, what they verified, and what would disprove their theory. Applying
the fix is your job, or a separate delegation. A different agent validates it.

### Phase 5 — Validation and Measurement

Re-run the targeted tests after each fix, then the full suite once at the end:

```bash
<the project's test command> 2>&1 | tee /tmp/after-fixes.txt
```

Compare against the baseline, honestly. A session that moved nothing is a
finding worth reporting, not a failure to hide.

---

## 4. Required Outputs

Every session produces these under `{{SESSIONS_DIR}}/active/`:

**`<date>-test-fixing-session.md`** — every fix with `file:line`, the before
and after numbers, what each delegated agent found, and what was verified.

**`<date>-remaining-issues.md`** — the unfixed failures, still categorized,
each with an estimate and a recommended next step, in priority order.

**`<date>-schema-verification.md`** — everything verified against the live
system: tables, fields, migration state, and every discrepancy found, whether
or not it was fixed.

If the work belongs to a work order, the same evidence goes into its
VERIFICATION document via `wo verify --run`. Never write a status by hand.

---

## 5. Delegation Rules

### Do

1. State the symptom and what you have already tried
2. Name the specific files to investigate
3. Ask for `file:line` references in the response
4. Ask for the verification step that would confirm the fix
5. Give the environment context: which database, which environment, which
   configuration
6. Quote error messages verbatim

### Do not

1. Ask an investigator to make changes
2. Send a vague prompt
3. Omit what you already ruled out
4. Ask several unrelated questions in one delegation

---

## 6. Progressive Strategy

Expect the work to move through these stages. The percentages are the shape of
a typical recovery, not a promise.

| Iteration | Focus | Effect |
|---|---|---|
| 1 | Build and type errors, blocking schema mismatches | The suite runs at all |
| 2 | Systematic mismatches found in Phase 3 | The largest single jump |
| 3 | Wiring: unregistered modules, missing routes, model and contract drift | Steady gains |
| 4 | Business logic: authentication, permissions, workflow state | The long tail |

Each iteration ends with a full run and a recorded number.

---

## 7. Verification Checklist

Before the session is complete:

- [ ] Build and type-check pass
- [ ] Every systematic mismatch of the class found in Phase 3 is gone
- [ ] The data model is verified against the live schema
- [ ] Everything the suite needs is registered and reachable
- [ ] Contracts and their consumers agree
- [ ] Targeted tests were re-run after each category of fix
- [ ] The full suite was run and the numbers captured
- [ ] The improvement is documented as before → after
- [ ] Delegated findings are recorded
- [ ] Remaining issues are categorized
- [ ] A handoff exists if the session is ending mid-work

---

## 8. Success Criteria

**For the session**

- The pass rate moved, and the delta is backed by two captured runs
- Blockers are resolved
- The data model is verified rather than assumed
- Every fix has a `file:line` reference

**For the effort overall**

- The suite passes at the level the project requires
- Every critical path is covered by a test that runs
- The data model and the live schema agree completely
- No instance of the systematic mismatch remains

---

## 9. Quick Reference

Substitute the project's own commands; these are shapes, not literals.

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

```bash
# Schema introspection (SQL)
<db client> -c "\dt <schema>.*"
<db client> -c "\d <schema>.<table>"
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>';"
```

```bash
# Finding a systematic mismatch across the codebase
grep -rn "<pattern>" <source dir>          # model definitions
grep -rn "<pattern>" <source dir>          # query construction and raw queries
grep -rn "<pattern>" <test dir>            # fixtures and expectations
```

---

## 10. Interaction Shape

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

---

## 11. Honesty

Never report a test as passing without having run it and seen it pass.
`NOT EXECUTED — PLAN ONLY` is an acceptable status. A false `PASS` is not, and
it is worse than an unfixed test, because every decision made after it is made
on a lie.

---

**Remember:** verify first, move incrementally, delegate investigation, stay
conservative, document everything.
