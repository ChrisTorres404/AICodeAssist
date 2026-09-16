# Systematic Test Fixing Methodology

> The long form of `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`.
> That file states the rules the `/fix-tests` command follows; this one explains
> why each rule exists, shows a recorded recovery in full, and lists the
> patterns worth reusing.

This is the method for recovering a test suite that is failing at scale —
hundreds or thousands of tests, most of them red, with no obvious place to
start. It is language- and framework-neutral. Substitute the project's own
test, build, and data-store commands; the project `CLAUDE.md` records them.

---

## Executive Summary

This is a proven method for systematically recovering a large test suite whose
failures come from mismatches between what the code assumes and what the
running system actually is. It rests on three things: **verification before
action**, **delegated investigation**, and **incremental validation** after
every change.

### Key Results

These are the measured outcomes of one recorded ninety-minute session, kept
because they set the expectation for what one session achieves. A session
produces a few percentage points, not a green suite — and it produces them
durably.

- Fixed 15 field-name mismatches between the models and the live schema
- Fixed 3 critical blockers: a service that crashed on start-up, a whole
  feature returning not-found, and a create path that silently dropped a field
- Created 7 missing tables belonging to one feature
- Applied 2 migrations that were recorded as run but had never been applied
- Improved the pass rate from 18.8% to 20.7% (+1.9 points, +10% relative)
- Reduced suite duration from 187s to 45s (-76%), which is what made the rest
  of the session possible

The duration number matters as much as the pass rate: a suite that takes three
minutes is re-run after every fix, and one that takes twenty is not.

---

## The Problem It Solves

The naive approach does not converge:

```
run the suite → read one failure → guess → change something →
run the whole suite again → a different set of tests breaks → repeat
```

Every cycle costs a full suite run, produces no measurement, and leaves no
record of what was verified. After three hours the numbers are roughly where
they started and nobody can say which changes helped.

The method replaces guessing with verification, replaces whole-suite churn
with measured increments, and ends every session with a delta backed by two
captured runs rather than an impression.

Its three load-bearing ideas:

1. **Verification before action.** The live system is the fact; the code that
   names it is the claim. Check before editing.
2. **Delegated investigation.** Specialists return `file:line` faster than a
   manual search, and the escalation order matters more than the effort.
3. **Incremental validation.** Fix one category, re-run, measure, continue.
   Never batch across categories.

---

## Which Suites Are Worth Recovering

This project's position, and it is not negotiable inside the method: a suite
is worth recovering in proportion to how much of the real system it exercises.

| Suite kind | Worth a recovery session | Why |
|---|---|---|
| Behavioural suites against the running system and its real data store | Yes, first | A pass means the system did the thing. The failures are real defects or real drift. |
| Integration suites that talk to a real data store | Yes | Same evidence, narrower scope. |
| Unit suites over isolated logic | Yes, cheaply | Fast, and the failures are usually genuine. |
| End-to-end suites built on mocked services and fixture data | Only to delete or to convert | A green run proves the code agrees with the stub. The stub drifts from the real service silently, so the suite reports health it cannot observe. |

When a recovery session finds that a large share of the failures come from
fixtures that no longer resemble the real system, the finding to report is not
"these tests need fixing". It is that the suite is measuring the fixture.
Recommend converting those cases to behavioural suites under
`{{TESTING_DIR}}/suites/` — see
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` — rather
than spending the session making a stub agree with itself.

That judgement is made with evidence, recorded in the session document, and
put to the user. It is not an excuse to stop fixing tests.

---

## Phase 1 — Assessment and Context Loading

Change nothing in this phase. Its entire output is a baseline and a
categorized list.

### 1.1 Read the context

Read, in this order:

- Any handoff under `{{SESSIONS_DIR}}/active/` — the previous session's
  numbers, what it fixed, what it left
- The work order this effort belongs to, under `{{WORKORDERS_DIR}}/`
- The project `CLAUDE.md` — the real test, build, migration, and data-store
  commands for this project
- `playbook search "<symptom>"` for any failure class already diagnosed once

Extract and write down: which environment the suite runs against, which data
store, which credentials, the last known pass rate, and the known blockers.
Guessing any of these costs more later than reading them costs now.

### 1.2 Capture a baseline

```bash
<the project's test command> 2>&1 | tee /tmp/baseline.txt
```

Before trusting that run, make sure no earlier run is still holding the
database, the port, or the workers. A suite competing with a leftover process
produces failures that have nothing to do with the code:

```bash
ps aux | grep test
```

Kill anything still running from a previous session, then capture the
baseline. Without two captured runs there is no delta, only an impression. The baseline
is written to a file, not read off the screen, because the final report quotes
both.

Record: suites total and passing, tests total and passing, the pass rate, and
the wall-clock duration. Duration matters — a suite that takes three minutes
gets re-run after every fix; one that takes twenty does not, and that alone
slows the recovery.

### 1.3 Verify the infrastructure the suite depends on

Before reading a single failure, confirm the things the suite cannot run
without actually exist.

```bash
# does the data store answer at all
<db client> -c "SELECT 1;"

# do the tables or collections the suite needs exist
<db client> -c "\dt <schema>.*"

# did the last migration actually run, or only register
<db client> -c "SELECT name FROM <migrations table> ORDER BY 1 DESC LIMIT 10;"
```

A migration that is recorded as applied but whose objects do not exist is a
common and expensive trap: every downstream failure looks like application
logic. A recorded session opened with exactly this — seven tables belonging to
one feature were absent although the migration was listed as run. Nothing else
in that suite could be diagnosed until they existed.

Take a schema snapshot before changing anything. It costs one command and it
is the only way to answer "did I change that, or was it already like this?"
three hours later:

```bash
<db client> -c "SELECT table_name, column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = '<schema>'
                ORDER BY table_name, ordinal_position;" \
  > /tmp/schema-snapshot-before.txt
```

At the end of the session, take the same snapshot again and diff the two:

```bash
diff /tmp/schema-snapshot-before.txt /tmp/schema-snapshot-after.txt
```

Verify after fixing, too:

```bash
<db client> -c "\dt <schema>.<prefix>*"        # the objects are there
<db client> -c "SELECT COUNT(*) FROM <schema>.<seeded table>;"   # and the reference data
```

---

### 1.4 Triage

Categorize every failure before fixing any of it. Produce counts, not
impressions. This is still Phase 1: nothing is edited yet.

#### The taxonomy

| Category | Severity | Why it is in this bucket | Typical root causes |
|---|---|---|---|
| Build or type errors | Blocking | Nothing downstream runs | A rename that missed a call site, a dependency that moved, a generated type that is stale |
| Schema or data-model mismatches | Blocking | The system will not initialize | The live schema and the models disagree about a name, a type, or nullability |
| Wiring and registration | High | Whole features 404 or fail to resolve | A module, route, or provider that is never registered |
| Contract mismatches | High | The test and the code disagree about the shape | Status codes, response envelopes, field names, date formats |
| Authentication and session failures | High | One cause behind many failures | Credentials, seeded roles or permissions, session setup, guards |
| Fixture and seed-data gaps | Medium | The test's preconditions were never created | Reference data absent, seeds that fail silently |
| Timeouts and flakes | Medium | Often environmental, not a defect | Connection-pool exhaustion, a stale process, parallelism |
| Everything else | Triage individually | — | — |

#### The ordering rule

**Order by shared root cause, not by file.** A category with forty failures
and one cause is the best possible use of the next twenty minutes; a category
with three failures and three causes is the worst. The count of failures per
category is the whole point of producing the counts.

Priority when categories tie:

1. Build and type errors — the suite cannot run at all
2. Schema mismatches that stop the system initializing
3. Wiring — a single registration can restore a whole feature's tests
4. Contract mismatches — usually mechanical once one is understood
5. Authentication — one cause, many symptoms, but needs investigation
6. The long tail

#### Extracting the counts

```bash
grep -c "<the runner's failure marker>" /tmp/baseline.txt
grep -E "<the runner's summary lines>" /tmp/baseline.txt
grep -E "error [A-Z]+[0-9]+|SyntaxError|Cannot find" /tmp/baseline.txt | sort | uniq -c | sort -rn
```

Group the distinct error strings and count them. Three error strings covering
eighty per cent of the failures is the normal shape, and finding that shape is
the deliverable of this phase.

---

## Phase 2 — Fix the Blockers

Blockers prevent other tests from running. Nothing else is worth measuring
until they are gone.

### 2.1 Build and type errors first

Extract them from the captured output, fix them, confirm the project builds.
If the build itself is what is broken, delegate to `build-error-resolver`,
which fixes with a minimal diff rather than investigating.

### 2.2 Then verify every name against the live system

For every failure that names a column, field, table, key, or enum value, check
the live schema **before** editing code.

```bash
# the real shape of one table
<db client> -c "\d <schema>.<table>"

# exact field names, in order
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"
```

Then find every place the code names it and reconcile:

```bash
grep -rn "<name>" <source dir>
```

**The live schema is the fact; the model is the claim.** When they disagree,
decide which is wrong with evidence, not preference. Sometimes the model is
right and the migration never ran — that is a different fix entirely, and only
the verification tells you which one you are looking at.

### 2.3 The worked example

A recorded session: the application crashed at startup inside a service that
upserts a row for every route it discovers. The error named a column that did
not exist.

```
column "<a>_<b>" does not exist
```

The reflex is to change the model. The method is to look first:

```bash
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"
```

The live schema used one convention throughout; the service's upsert clause
used another, for three field names. The database had been standardized in
earlier work and this one call site had been missed. The fix was three strings
in one conflict-target clause:

```
# before — the convention the code assumed
.orUpdate(['<a>_<b>'], ['<c>_<d>', '<e>_<f>'])

# after — the convention the live schema actually uses
.orUpdate(['<ab>'], ['<cd>', '<ef>'])
```

One edit, and the application initialized. Every test in the suite had been
failing behind it. **This is the normal shape of a suite failing at scale:**
the number of red tests says almost nothing about the number of defects.

### 2.4 Re-run a targeted subset

Five to ten tests, chosen because they exercise the thing just fixed. Confirm
the blocker is gone before moving on. Do not run the full suite yet.

Run the subset serially, and make the runner exit when the tests are done:

```bash
<test command> <path/to/one/area> --maxWorkers=1 --forceExit
```

`--maxWorkers=1` (or the runner's equivalent serial flag) matters while
diagnosing: parallel workers sharing one database produce failures that come
from the other worker, not from the code, and those are the failures that waste
a session. `--forceExit` stops a run whose open handles — a connection pool, a
listening server, a timer — would otherwise hold the process open after the
last test and make a passing run look like a hang.

---

## Phase 3 — Systematic Search

Once the blockers are gone, the remaining failures cluster into a few shared
causes. Find **all** instances of each cause in one pass rather than one per
test run.

### The archetype

Naming-convention drift: the data store uses one convention, part of the code
uses another, and the mismatch surfaces as dozens of unrelated-looking
failures. The method generalizes to any systematic mismatch — a renamed field,
a changed date format, a moved endpoint prefix, a configuration key that lost
its namespace, an enum whose values were re-cased.

### The four places to look

Searching only the first place is the single most common way this phase is
left half-done.

| Place | What lives there |
|---|---|
| Model and schema definitions | The declared mapping between code names and stored names |
| Query construction | Builder calls, filters, joins, ordering |
| Raw statements | Hand-written SQL or equivalent, inside services and migrations |
| Fixtures, seeds, and test expectations | The values the tests assert against |

```bash
# 1. model definitions that map a code name to a stored name
grep -rn "<the mapping syntax>" <source dir>

# 2. query construction
grep -rn "\.where\|\.andWhere\|\.filter\|\.orderBy" <source dir> | grep "<pattern>"

# 3. raw statements
grep -rn "INSERT INTO\|UPDATE \|DELETE FROM\|SELECT .* FROM" <source dir> | grep "<pattern>"

# 4. fixtures, seeds, and expectations
grep -rn "<pattern>" <seed dir> <test dir>
```

### The loop

1. **Enumerate** the suspect pattern across all four places. Reduce to a
   unique list of names — the same name usually appears many times, and fixing
   from the raw grep output means verifying the same name repeatedly.

   ```bash
   grep -rn "<the mapping syntax>" <source dir> \
     | sed "s/.*<extract the name>//" | sort -u > /tmp/suspect-names.txt
   ```

2. **Verify each against the live system.** Record `code says X, system says Y`
   per name. Do not fix from the enumeration; fix from the verification. Some
   of the suspects will be correct, and editing those creates new failures.

   ```bash
   while read -r name; do
     echo -n "$name -> "
     <db client> -tAc "SELECT column_name FROM information_schema.columns
                       WHERE column_name = '<normalized $name>';"
   done < /tmp/suspect-names.txt
   ```

3. **Fix every confirmed mismatch in one pass.** This is the one place batching
   is correct, because all of the changes belong to one verified category.

4. **Re-run the affected tests** and record the delta.

5. **Search again** to prove nothing of that class remains.

   ```bash
   grep -rn "<pattern>" <source dir> <test dir> | grep -v "<archived or vendored paths>"
   ```

   An empty result is the exit condition for this phase. A non-empty result
   that you have verified as correct is also acceptable — but it is written
   down, with the reason, in the schema-verification document.

### Keep the mapping

Every name the session verified goes into the session's schema-verification
document as a two-column mapping: stored name, code name. The next session
reads it instead of re-deriving it, and a recurring mismatch class belongs in
an agent overlay under `{{PIPELINE_ROOT}}/core/agents/overlays/` so that it is
known before the next session starts.

---

## Phase 4 — Delegated Investigation

Anything that survives the first three phases gets delegated. Delegation is not
a fallback for being stuck; it is faster than a manual search for any question
that spans more than a few files.

### The escalation order

Most failures resolve at the step people skip.

| Step | The question | Agent |
|---|---|---|
| 1 | Context: what changed, what is the convention, where is it documented | `code-explorer`, or a broad `Explore` sweep |
| 2 | Active debugging: why does this specific endpoint or test fail | `support-engineer-expert` |
| 3 | Infrastructure: does it exist, did the migration run, is it registered | `database-validator-expert` |
| 4 | Failures that hide: empty catches, swallowed errors, misleading fallbacks | `silent-failure-hunter` |
| 5 | The build or type-check itself is broken | `build-error-resolver` |

Step 1 is the one that gets skipped, and it is the one that most often makes
steps 2 and 3 unnecessary. A convention that changed last month explains a
hundred failures; no amount of debugging a single test reveals it.

### Matching the model to the question

| The question | What it needs |
|---|---|
| Find where something is documented; sweep many files for a pattern | A fast model. The work is search, not reasoning. |
| Trace a request through four layers and find where the value is lost | A strong reasoning model. The work is inference over indirect evidence. |
| Verify that objects, fields, and seed data exist | A strong model with data-store expertise; the queries are easy, the conclusions are not. |

Route by the shape of the question, not by the urgency of the failure.

### Investigators investigate; they do not edit

They return findings with `file:line`, what they verified, and what would
disprove their theory. Applying the fix is your job or a separate delegation,
and a different agent validates it. An investigator that edits has destroyed
the independence that made the finding worth having.

### Three recorded delegations

Each of these is the shape of a real delegation from a recorded session. The
prompt templates are in
`{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`.

#### Delegation 1 — context: is this field required or optional

**Trigger.** Registration failed on a not-null violation for a field the code
sometimes omits, and nobody could say whether omitting it was legal.

**Asked for.** Recent documentation, migrations, and decision notes about that
field: is it required or optional now, what rules govern it, when did it last
change.

**Returned.** A migration that had made the field nullable, the flags that
decide when it is required, the business rules behind both modes, and the
detail that the migration had never been applied to this environment.

**Why it helped.** The answer was not in the code. Reading the model would
have produced a confident wrong conclusion. The fix was to apply the missing
migration, not to change anything.

**Manual equivalent.** Roughly half an hour of searching, with a real chance of
never finding the decision note.

#### Delegation 2 — active debugging: a field is dropped in flight

**Trigger.** Creating a record failed with a not-null violation on a field the
request definitely carried. The input contract declared it; the request sent
it; the stored row had nothing.

**Asked for.** A trace from entry to the data store, the root cause, and the
exact fix with `file:line`.

**Returned.** The model mapped the stored field to a differently named
property. The input contract used the stored name. The create path spread the
input object onto the model, so the mismatched key was silently ignored — no
error anywhere, just a missing value. Two fix options with trade-offs, and a
recommendation.

**Why it helped.** Four layers, and the defect was in the seam between two of
them. The value of the finding was as much the explanation as the fix: that
spread-onto-a-model pattern silently drops every mismatched key, which is a
class of bug, not an incident.

**Manual equivalent.** Around forty-five minutes.

#### Delegation 3 — infrastructure: a whole feature returns not-found

**Trigger.** Every endpoint of one feature returned not-found although the
handlers, services, and tables all existed.

**Asked for.** Verify the wiring, the routes, the tables, the migration state,
and the seeded permissions, and say which one is missing.

**Returned.** Tables present, permissions seeded, handlers correctly declared —
and the feature's module was never registered in the application's composition
root. One line. The report included the verification queries it had run, so
the negative results were checkable.

**Why it helped.** It converted "something in this feature is broken" into
"this one line is missing", and the ruled-out list was as valuable as the
finding.

**Manual equivalent.** Around twenty minutes of checking the wrong places
first.

### What good delegation looks like

Do:

1. State the symptom and quote the error verbatim
2. List what you already tried and what it ruled out
3. Name the specific files to start from
4. Ask for `file:line` references in the response
5. Ask for the verification step that would confirm the fix
6. Give the environment: which data store, which configuration

Do not:

1. Ask an investigator to make changes
2. Send a vague prompt — a vague delegation returns a vague finding, and the
   time is spent either way
3. Omit what you ruled out — it will be tried again
4. Bundle unrelated questions into one delegation
5. Paraphrase an error message

### If you delegate, you collect

A spawned investigation is not a finished one. The subagent's final message is
its deliverable: read it, check it against the system yourself, then integrate
it. A finding you did not verify is a claim, and the method does not run on
claims.

---

## Detailed Agent Workflow

The three delegations above, written out as reusable prompts. Copy the
template, fill in the brackets, and keep the structure — the structure is what
makes the finding actionable rather than an essay.

### Agent #1 — context search

**Trigger:** you need to know what the rule actually is, and the code cannot
tell you because the code is what is in question.

```markdown
Search the codebase for documentation from [timeframe] about [topic].
I need to understand:
1. [Specific question 1]
2. [Specific question 2]
3. [Specific question 3]

Search locations:
- [Path 1]
- [Path 2]
- [Pattern to look for]

Return the exact documentation with file paths so I can understand the
[business rules / technical details].
```

**What it returned:** five file locations with line numbers; the rule that the
field had become optional; the configuration flag that decides when it is
required; the migration SQL that made the change; and worked examples of both
modes.

**How it helped:** it removed the guessing. The answer was a decision recorded
outside the code, and it identified a migration that had never been applied —
which was the actual fix.

**Time saved:** roughly 30 minutes of manual file searching.

### Agent #2 — debugging specialist

**Trigger:** a failure with a cryptic message that survives the obvious checks.

```markdown
I need deep troubleshooting for a [component] bug:

**Symptom:** [endpoint] returns [status] "[error message, verbatim]"

**What I've already done:**
1. [Action 1, and what it ruled out]
2. [Action 2, and what it ruled out]
3. [Action 3, and what it ruled out]

**The problem:** [description of the unexpected behaviour]

**Files to investigate:**
- [File 1] (what to check in it)
- [File 2] (what to check in it)
- [File 3] (what to check in it)

**What I need:**
1. Root cause: [specific question]
2. [Specific question 2]
3. The exact fix, with file:line references

Do not make any changes. Return findings only.
```

**What it returned:** a complete trace from request through handler, service,
model, and data store; the root cause — the model mapped the stored field to a
differently named property, and spreading the input object silently dropped the
mismatched key; two fix options with trade-offs; and a recommendation with the
reasoning.

**How it helped:** the defect was in the seam between two layers, where nobody
looks. The explanation was worth more than the fix, because that spread-onto-a-
model pattern drops every mismatched key, silently, everywhere it appears.

**Time saved:** roughly 45 minutes of manual debugging.

### Agent #3 — infrastructure validator

**Trigger:** something that clearly exists in the code does not work at all.

```markdown
[Component] endpoints are returning [status] "[error]" but the code exists.
Verify:

**1. Module registration:**
- Is [module] registered in the application's composition root?
- Check [file path]

**2. Handler registration:**
- Does [module] export its handlers?
- Check the route declarations and their prefixes

**3. Tables and collections:**
- Verify [objects] exist
- Environment: [which data store, which configuration]
- I believe I created these earlier — verify they are actually there

**4. Migration and seed data:**
- Was migration [identifier] fully executed, not merely recorded?
- Are there seed data requirements? Check [seed file]

**What I need:**
1. The exact reason [endpoint] returns [status]
2. What is missing — registration, export, routes, objects, seed data
3. The specific fix, with file locations

Use real queries to verify everything. Do not make any changes.
```

**What it returned:** every table present (seven queries, output included);
every permission seeded (nine confirmed); handlers, services, contracts and
models all correct; and the one actual defect — the feature's module was never
registered in the composition root. One line, with the exact import and the
verification command to confirm the fix.

**How it helped:** it converted "something in this feature is broken" into
"this one line is missing", and the ruled-out list was as valuable as the
finding.

**Time saved:** roughly 20 minutes of checking the wrong places first.

---

## Phase 5 — Validation and Measurement

### After each fix

Re-run the targeted subset for the category just fixed. Record the before and
after for that subset. If it did not move, stop and find out why before fixing
anything else — a fix that changes nothing is usually a fix that was not
applied, or was applied against the wrong environment.

### At the end of the session

```bash
<the project's test command> 2>&1 | tee /tmp/after-fixes.txt
```

Compare against the baseline on four numbers:

| Measure | Why it is recorded |
|---|---|
| Suites passing / total | Coarse, but the first thing anyone asks |
| Tests passing / total, as a rate | The headline delta |
| Duration | A suite that got faster usually stopped crashing; a suite that got slower usually started reaching further into the system |
| Distinct error strings and their counts | The real progress measure: categories eliminated, not tests passed |

A session that moved the pass rate very little but eliminated two whole error
categories has done more than one that moved it three points by fixing
individual tests. Report both, and say which one happened.

A session that moved nothing is a finding worth reporting, not a failure to
hide.

### Honesty

Never report a test as passing without having run it and seen it pass.
`NOT EXECUTED — PLAN ONLY` is an acceptable status. A false `PASS` is not, and
it is worse than an unfixed test, because every decision made after it is made
on a lie. The three permitted statuses are defined in
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`.

---

## Key Success Factors

### 1. Verification-first

Never assume a name. The pattern, every time:

```
1. Query the live system for the real name
2. Search the code for what it names
3. Compare, and record both
4. Decide which side is wrong, with evidence
5. Fix
6. Re-run the affected tests
```

Steps 1 and 3 are the ones under time pressure that get skipped, and skipping
them is what produces the second wrong fix on top of the first.

### 2. Conservative increments

Fix → verify → measure → repeat, one category at a time. Batching across
categories means that when the numbers move, nobody knows which change did it —
and when they move the wrong way, nobody knows which change to revert.

The one exception is within a verified category: once every instance of one
mismatch class has been individually verified, fix them together.

### 3. Delegation as a first resort for search

Any question spanning more than a few files is faster delegated, and the
escalation order — context, debugging, infrastructure — resolves most failures
at step one.

### 4. Taking direction from the user

A recorded session turned on one instruction: *check against the actual
database; the entire schema was standardized*. Everything before it was
trial and error; everything after it was verification. The user knows things
about the system's history that are not in the code, and a correction of that
kind changes the method for the rest of the session, not just the next edit.

When the user says the state of the system is X, the correct response is to
verify against X and adjust the approach — not to argue from the code, which
is exactly the artefact that has drifted.

---

## Reusable Patterns

### Pattern 1 — name verification

```bash
# 1. the real shape
<db client> -c "\d <schema>.<table>"

# 2. exact names, in order
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"

# 3. what the code names
grep -rn "<name>" <source dir>

# 4. fix using the verified name
# 5. re-run the affected tests
```

### Pattern 2 — systematic mismatch sweep

```bash
# 1. enumerate
grep -rn "<pattern>" <source dir> > /tmp/hits.txt

# 2. reduce to unique names
sed "s/.*<extract>//" /tmp/hits.txt | sort -u > /tmp/names.txt

# 3. verify each against the live system
while read -r n; do echo -n "$n -> "; <db client> -tAc "<lookup for $n>"; done < /tmp/names.txt

# 4. fix confirmed mismatches in one pass
# 5. re-run
# 6. search again; expect nothing of that class to remain
```

### Pattern 3 — the fix-verify cycle

```bash
# 1. a small targeted subset, run serially
<test command> <path/to/one/area> --maxWorkers=1 --forceExit

# 2. identify one to three specific failures
# 3. fix them
# 4. re-run the SAME subset, the SAME way
<test command> <path/to/one/area> --maxWorkers=1 --forceExit

# 5. record the delta
# 6. improved → continue; unchanged → investigate before fixing anything else
```

### Pattern 4 — the investigation sequence

```
Symptom, stated precisely and quoted verbatim
  1. Context      → what changed, what the convention is, where it is written
  2. Debugging    → why this specific thing fails
  3. Infrastructure → does it exist, did it run, is it registered

For each: say what you tried, name the files, ask for file:line, ask for the
check that would confirm the fix. Then verify the finding yourself.
```

---

## Lessons Learned

### Do

1. Verify names against the live system before assuming anything
2. Delegate investigations that span more than a few files
3. Test incrementally, on small subsets, and measure each one
4. Document findings as they happen, not at the end
5. Take the user's account of system state seriously and adjust the method
6. Check every environment the suite might be pointed at, not just one
7. Reduce to unique values before verifying, so nothing is checked twice
8. Record the verified mapping for the next session

### Do not

1. Never assume a name, however obvious the convention looks
2. Never batch fixes across categories without verifying in between
3. Never skip the re-run after a change
4. Never override what the user told you about the state of the system
5. Never fix blindly — understand the root cause first
6. Never fix a test to match broken behavior unless the test is provably
   wrong, and then say so explicitly with the reasoning
7. Never trust documentation over the live system; documentation goes stale
   and the live system cannot
8. Never report a number you did not capture

---

## Metrics and Return

From a recorded ninety-minute session on a suite of roughly fourteen hundred
tests across a hundred and forty-six files:

| Where the time went | Minutes |
|---|---|
| Manual investigation | 15 |
| Delegated investigation | 10 |
| Editing code | 30 |
| Running tests | 35 |
| **Total** | **90** |

| What delegation replaced | Manual estimate |
|---|---|
| Documentation and history search | 30 min |
| Tracing a value lost across four layers | 45 min |
| Verifying infrastructure and registration | 20 min |
| **Total** | **95 min** |

The same work performed manually was estimated at around three hours, so the
session ran at roughly twice the pace with better evidence behind each change.

What it produced:

| Result | Value |
|---|---|
| Pass rate | 18.8% → 20.7% |
| Suite duration | 187s → 45s (-76%) |
| Name mismatches fixed | 15, across models, services, and seeds |
| Blocking defects fixed | 3 |
| Missing tables created | 7 |
| Migrations applied that had registered but never run | 2 |

Read the pass rate against the duration. The suite got four times faster
because the application stopped crashing during initialization — which is also
why the pass rate moved less than the work suggests. Most of that session's
value was removing the blockers that made the next session's gains possible,
and the honest way to report it is exactly that.

**Expect two to five points of pass rate per session** on a suite in this
condition, and expect the first session to be mostly blockers.

---

## The Multi-Session Arc

A suite failing at scale is not recovered in one sitting. The shape:

| Iteration | Focus | Typical band |
|---|---|---|
| 1 | Build and type errors, blocking schema mismatches | The suite runs at all; 5-15% |
| 2 | The systematic mismatches found in the sweep | The largest single jump; 15-25% |
| 3 | Wiring: unregistered modules, missing routes, contract drift | Steady gains; 25-35% |
| 4 | Business logic: authentication, permissions, workflow state | The long tail; 35-50% |
| 5-6 | Remaining edge cases and flakes | The project's target |

Each iteration ends with a full run, a recorded number, and a handoff. The
percentages are the shape of a typical recovery, not a promise; a suite whose
failures are mostly one cause moves faster, and one whose failures are genuine
defects moves slower because the fixes are real work.

---

## Reproducing the Method

**Phase 1 — Assessment (10 min).** Read the handoff and work order. Capture a
baseline to a file. Verify the infrastructure. Categorize every failure and
count each category.

**Phase 2 — Blockers (20 min).** Fix build and type errors. Verify names
against the live system. Fix the blocking mismatches. Re-run a targeted
subset.

**Phase 3 — Systematic search (30 min).** Enumerate the suspect pattern across
models, queries, raw statements, and fixtures. Verify each hit. Fix the
confirmed ones in one pass. Search again to prove the class is gone.

**Phase 4 — Delegated investigation (20 min).** Context, then debugging, then
infrastructure. Verify each finding yourself. Apply the fixes.

**Phase 5 — Validation (10 min).** Re-run the targeted tests, then the full
suite. Compare against the baseline on all four measures. Write the three
session documents.

Ninety minutes, and the session ends with a handoff whether or not the work is
finished.

---

## What a Session Produces

Under `{{SESSIONS_DIR}}/active/`:

| Document | Contents |
|---|---|
| `<date>-test-fixing-session.md` | Every fix with `file:line` and a reason, before and after numbers, what each delegation found, where the time went |
| `<date>-remaining-issues.md` | The unfixed failures, still categorized, each with an estimate and a recommended next step, in priority order |
| `<date>-schema-verification.md` | Everything verified against the live system: objects, fields, migration state, and every discrepancy found, whether or not it was fixed |

If the work belongs to a work order, the same evidence goes into its
VERIFICATION document through `wo verify --run`, which writes the status from
the suite's exit code. Nobody types `PASS`.

`/next-session` writes the handoff from these three documents, and the next
session reads it in Phase 1.

---

## Tools

```bash
# schema introspection (SQL)
<db client> -c "\dt <schema>.*"
<db client> -c "\d <schema>.<table>"
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>';"
<db client> -c "SELECT name FROM <migrations table> ORDER BY 1 DESC LIMIT 10;"

# code search
grep -rn "<pattern>" <source dir>
grep -rn "<pattern>" <test dir>

# tests
<test command> 2>&1 | tee /tmp/baseline.txt
<test command> <path/to/one/area>
```

Delegation, by the shape of the question:

```
Task → a broad search agent          documentation and convention search
Task → a debugging specialist        tracing a failure through layers
Task → a data-store validator        verifying objects, fields, and seed data
```

File operations, and what each is for in this method:

```
Read   check the actual code or configuration, never the remembered version
Edit   fix one mismatch at a time, so a re-run attributes the change correctly
Grep   find every occurrence of a pattern before fixing any of them
Bash   run the data-store queries and the tests, and capture both to files
```

Pipeline drivers used alongside them:

| Driver | Use |
|---|---|
| `playbook search "<symptom>"` | Check whether this failure class is already diagnosed |
| `wo verify --run` | Write a work order's verification status from a real run |
| `bug new --category <name>` | Open a bug for a defect the recovery uncovered but will not fix here |
| `acp` | The pipeline's own entry point; `acp --help` lists the rest |

---

## Automation Worth Building

Each of these turns a manual phase into a check that runs before the session:

1. **A pre-flight name check** — compare every model's declared field names
   against the live schema and report the mismatches. This removes most of
   Phase 3 once it exists.
2. **A migration completeness check** — for every migration recorded as
   applied, verify that the objects it creates exist. Catches the
   registered-but-not-run trap at startup rather than three hours in.
3. **A suite health record** — pass rate, duration, and error-category counts
   per run, stored over time, so the multi-session arc is a graph rather than a
   memory.

---

## Session Checklist

- [ ] Build and type-check pass
- [ ] A baseline run was captured to a file before anything changed
- [ ] Every failure was categorized and counted before anything was fixed
- [ ] Every name touched was verified against the live system
- [ ] Every systematic mismatch of the class found in the sweep is gone, and a
      repeat search proves it
- [ ] Everything the suite needs is registered and reachable
- [ ] Contracts and their consumers agree
- [ ] Targeted tests were re-run after each category of fix
- [ ] The full suite was run at the end and the numbers captured to a file
- [ ] The improvement is documented as before → after on all four measures
- [ ] Every fix carries a `file:line` and a reason
- [ ] Delegated findings are recorded, including the ones that ruled things out
- [ ] Remaining issues are categorized with estimates and priority
- [ ] The verified name mapping is written down for the next session
- [ ] A recurring mismatch class is recorded in an agent overlay
- [ ] A handoff exists if the session is ending mid-work

---

## Appendix: Full Fix List

The complete list of changes from the recorded session, grouped by kind. It is
here as a worked example of what a session's output looks like when it is
written down properly: every fix names the file and what changed in it, so the
next session can tell what was done from what was merely attempted.

### Schema fixes (2)

1. Made the organization reference on the user table nullable.
2. Added the two flags on the account table that decide whether an organization
   is required, and which organization model applies.

### Model fixes (3 files, 7 fields)

1. `user-organization` model: `invited_by`, `invitation_accepted`, `expires_at`,
   and the join column, all corrected to the names the live schema uses.
2. `module-license` model: `creator_type`, `modifier_type`.
3. `system-module` model: `creator_type`, `modifier_type`.

### Service fixes (4 files, 5 references)

1. `route-discovery` service: `route_method`, `route_path`, `detected_at`.
2. `user-group` service: `account_id`.
3. `session-invalidation` service: the group-member table name.
4. `tenants` service: `account_id`, in two places.

### Contract fixes (1 file, 1 field)

1. The template input contract: renamed `code` to `slug`, to match the property
   the model actually exposes.

### Configuration fixes (1 file)

1. The application composition root: registered the feature module that was
   missing, which is what made the whole feature return not-found.

### Test fixes (2 files)

1. The alerts listing test: a syntax error that broke the whole file.
2. The template deletion test: updated to the corrected field name, and given
   the fields the contract now requires.

### Seed fixes (1 file, 5 statements)

1. The database seeder: five field names corrected against the live schema.

---

## Success Criteria

A session is finished when every one of these is true and demonstrable. They
are the same items for any project; the names change, the conditions do not.

- [ ] The build and type-check pass
- [ ] No service crashes on start-up
- [ ] Every feature whose endpoints returned not-found is reachable again
- [ ] The create paths that silently dropped a field now store it
- [ ] Every nullability and constraint mismatch found is resolved in the schema
      or in the model, deliberately, and recorded
- [ ] The pass rate improved, measured against a captured baseline
- [ ] The suite duration did not regress, and ideally improved
- [ ] A repeat search finds no remaining instance of the mismatch class that
      the systematic sweep was opened for

Mark one of these only from a run you executed and captured. A checklist filled
in from memory is the failure mode this whole method exists to avoid.

---

## Related

| Document | What it is |
|---|---|
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | The rules the `/fix-tests` command follows |
| `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md` | Delegation templates for Phase 4 |
| `{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md` | Session prompts for driving the method by hand |
| `{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md` | The first-session walkthrough |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` | What counts as verification evidence |
| `{{PIPELINE_ROOT}}/core/rules/common/troubleshooting.md` | Which specialist investigates which category |
