# Test Fixing — Quick Start

Read this before your first systematic test-fixing session. It covers what to
prepare, what the session feels like, what to expect from it, and what to do
when it goes wrong.

The authoritative rules are
`{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`. This page is
the on-ramp, not a substitute for it.

---

## What This Is

A method for recovering a test suite that is failing at scale, and the command
that runs it. It exists because the obvious approach — read a failure, guess,
change something, re-run everything — does not converge. The method replaces
guessing with verification and whole-suite churn with measured increments.

What it gives you:

- A baseline and a final run, so the session ends with a number rather than an
  impression
- Failures grouped by shared root cause, so twenty minutes goes where forty
  failures are, not where one is
- Names verified against the live system before anything is edited
- Investigation delegated to specialists that return `file:line`
- Three documents that let the next session start where this one stopped

What it is not: a way to make a suite of mocked services and fixture data
agree with itself. Effort goes to behavioural suites against the running
system first, then integration suites against a real data store, then unit
suites over isolated logic.

---

## Files That Make Up the System

Six files, each with one job. Knowing which is which saves reading the wrong
one.

### 1. The command

```
{{PIPELINE_ROOT}}/core/commands/fix-tests.md
```

The entry point: type `/fix-tests` to start. Installed into the project's
command directory, so it is available without any argument or setup.

### 2. The rules

```
{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md
```

The complete methodology and the rules the command follows. This is the
authority; everything else is navigation around it.

### 3. The delegation prompt library

```
{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
```

Ready-to-use templates for the investigator agents, one per kind of question.

### 4. The session prompt library

```
{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md
```

Whole-session prompts for driving the method by hand, in any tool, with no
command available.

### 5. The long-form methodology

```
{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md
```

Why each rule exists, a recorded recovery in full, the reusable patterns, and
the measurements.

### 6. The index

```
{{PIPELINE_ROOT}}/core/instructions/README-TEST-FIXING-SYSTEM.md
```

What each file is for and which one to read when.

---

## Before the First Session

### 1. Collect the context

The method stalls on missing facts, and finding them mid-session costs more
than finding them now:

- Which environment does the suite run against, and which data store
- How the suite authenticates, and where those credentials come from
- The real test, targeted-test, build, type-check, migration, and data-store
  commands
- The last known pass rate, if there is one
- What the previous session or the handoff says is already broken

If the commands are not in the project `CLAUDE.md`, put them there now.

Write them into a handoff document before you start — optional, but it is what
the next session reads first:

```markdown
## Project context
- Project: [name]
- Data stores: [development], [test]
- Test credentials: [account] / [where the secret comes from]
- Pass rate: [X%]
- Known issues: [list]
```

### 2. Capture a baseline yourself

You do not need the command to do this, and having it beforehand makes the
first ten minutes productive:

```bash
<the project's test command> 2>&1 | tee /tmp/baseline.txt
```

Note four numbers: suites passing, tests passing, the pass rate, and the
duration.

### 3. Check that the system under test is current

A stale process serving an old build is the most common cause of a fix that
appears to change nothing.
Confirm the thing the tests talk to is running the code you are about to edit.

---

## Running a Session

```
/fix-tests [suite or path]
```

With no argument it runs the critical suite first and starts from its
failures. Without the command — a different tool, a plain chat session — use a
prompt from
`{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md`; the
method is identical.

### The five phases

The session moves through five phases in ninety minutes:

| Phase | Minutes | What happens |
|---|---|---|
| 1. Assessment | 10 | Read the context, capture a baseline, verify the infrastructure, categorize every failure with counts. Change nothing. |
| 2. Blockers | 20 | Build and type errors, then the schema mismatches that stop the system initializing. Verify names against the live system before editing. |
| 3. Systematic search | 30 | Find every instance of the largest shared cause in one pass, verify each, fix them together, prove the class is gone. |
| 4. Delegated investigation | 20 | Context, then active debugging, then infrastructure. Investigators return `file:line` and do not edit. |
| 5. Validation | 10 | Re-run, compare against the baseline on all four measures, write the three documents. |

At the end of Phase 1 the agent proposes a plan and **waits for approval**
before changing anything. Read that plan: the category counts in it are the
single most useful artefact of the session, and if they look wrong, they are
wrong now rather than after twenty minutes of fixes.

---

## What to Expect

### Session by session

| Session | Focus | Improvement in the session | Cumulative band | Outcome |
|---|---|---|---|---|
| 1 | Blockers: build and type errors, schema mismatches that stop initialization | +2-5 points | 5-15% | The application initializes without crashing |
| 2 | The systematic mismatches found in the sweep | +5-10 points | 15-25% | Most data-store errors resolved |
| 3 | Wiring: unregistered modules, missing routes, contract drift | +10-15 points | 25-35% | Business logic reachable |
| 4 | Business logic: authentication, permissions, workflow state | +10-15 points | 35-50% | The long tail is what is left |
| 5-6 | Remaining edge cases and flakes | Diminishing | The project's target | A suite that can be trusted |

Two to five points of pass rate per session is the normal result on a suite in
this condition. Four to six sessions is the normal cost of a recovery.

**Read the pass rate against the duration.** A first session often moves the
rate very little while cutting the suite's runtime dramatically — that is the
signature of an application that stopped crashing during initialization, and
it is what makes the second session's larger gain possible. A session that
eliminated two whole error categories has done more than one that moved the
rate three points by fixing individual tests.

---

## The Rules That Matter Most

### Always

1. Verify a name against the live system before editing code that uses it
2. Delegate any investigation that spans more than a few files
3. Fix one category, re-run, measure, then continue
4. Record every fix with a `file:line` and a reason
5. Run verification queries against the same environment the tests run against

### Never

1. Never assume a name, however obvious the convention looks
2. Never batch fixes across categories without verifying in between
3. Never skip the re-run after a change
4. Never override what the user told you about the state of the system
5. Never make a change on the strength of old documentation; confirm it
   against the system as it is now
6. Never fix a test to match broken behavior unless the test is provably
   wrong — and then say so, with the reasoning
7. Never report a test as passing without having run it and seen it pass

---

## The Verification Pattern

Use it for every failure that names a column, field, table, key, or enum
value. It is the core of the whole method:

```bash
# 1. the real shape
<db client> -c "\d <schema>.<table>"

# 2. exact names, in order
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"

# 3. what the code names
grep -rn "<name>" <source dir>

# 4. decide which side is wrong, with evidence
# 5. fix, using the verified name
# 6. re-run the affected tests
```

Steps 1 and 4 are what get skipped under time pressure, and skipping them is
what produces a second wrong fix on top of the first.

---

## Delegating

| You need | Ask | Model | Expect back in |
|---|---|---|---|
| Context: what changed, what the convention is, where it is documented | `code-explorer`, or a broad `Explore` sweep | Fast — the work is search, not reasoning | 5-10 min |
| Root cause of one specific failure | `support-engineer-expert` | Strong reasoning — inference over indirect evidence | 10-20 min |
| Whether the objects, migrations, seed data, and registration exist | `database-validator-expert` | Strong — the queries are easy, the conclusions are not | 10-15 min |
| Data missing or wrong with nothing thrown | `silent-failure-hunter` | Strong reasoning | 10-20 min |
| The build or type-check itself is broken | `build-error-resolver` | Strong | 10-20 min |

Go in that order. Step one is the step people skip, and it is the one that
most often makes steps two and three unnecessary: a convention that changed
last month explains a hundred failures, and no amount of debugging one test
reveals it.

Templates are in
`{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`. Fill in
every bracket. A vague delegation returns a vague finding and costs the same
time as a good one.

**If you delegate, you collect.** The investigator's final message is its
deliverable: read it, check it against the system yourself, then apply the fix.
A finding you did not verify is a claim.

### The launch pattern

1. **Identify the need** — context, debugging, or verification
2. **Choose the template** from `04-test-fixing-agent-prompts.md`
3. **Fill in every bracket** with this project's real values
4. **Launch it**, naming the agent and the question:

   ```
   Launch the database-validator-expert to check whether the reporting
   feature's tables exist and whether its module is registered.
   ```

5. **Read the findings** and check the load-bearing ones yourself
6. **Apply the fix**
7. **Re-run the targeted subset** and record the delta

### Example agent usage

**Scenario:** every endpoint of one feature returns not-found, although the
handlers and tables appear to exist.

```
You:    Launch the database-validator-expert to check the reporting
        feature's infrastructure.

Agent:  [runs real queries, returns findings]
        - the feature's tables exist (7 queries, output included)
        - its permissions are seeded (9 rows confirmed)
        - its handlers declare the expected routes
        - the feature's module is NOT registered in the composition root
        Fix: add the import and the registration entry at <file>:47

You:    [apply the fix, re-run the targeted subset, confirm the routes answer]
```

The ruled-out list is half the value: it is why the next twenty minutes are not
spent checking the tables again.

---

## When It Goes Wrong

### Nothing improves after a round of fixes

Check in this order:

1. Are you running against the environment you think you are — both the tests
   and the verification queries?
2. Were the fixes actually applied? `git diff`.
3. Is the system under test serving the new build, or is a stale process still
   running the old one?
4. Is this the suite that was failing?
5. Are there cascading causes — the fix was right and revealed the next one?
   Compare error-category counts, not just the pass rate: a category
   eliminated is progress even when the rate did not move.

### A delegation comes back vague or empty

The prompt was vague. Name the
specific files, quote the error verbatim, say what you already ruled out, ask
for `file:line` explicitly, and give the environment. If the search genuinely
found nothing, widen the locations before widening the question.

### The fixes hold but the tests still fail on the same names

You searched one place. Go back through all four: model and schema definitions, query
construction, raw statements, and fixtures/seeds/test expectations. Raw
statements and seed data are the two that get missed.

Raw statements are the ones that hide from a model-level search. Sweep for
them directly:

```bash
# Raw statements carrying a two-word identifier the models may have renamed
grep -rn "FROM\|JOIN" <source dir> | grep " [a-z]*_[a-z]* "
```

### Tests pass individually and fail together

Environmental: connection-pool
exhaustion, shared fixture state, ordering, parallelism. Re-run serially
before diagnosing code.

### The suite got slower

Usually good — the system is now reaching further in
before failing. Confirm against the error categories rather than assuming a
regression.

### The command does not start

Check, in order:

1. The command file exists where the tool looks for it — the project's command
   directory should contain `fix-tests.md`, installed from
   `{{PIPELINE_ROOT}}/core/commands/fix-tests.md`
2. The rules file it points at exists:
   `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`
3. Both files are readable from the working directory the tool is running in

```bash
ls {{PIPELINE_ROOT}}/core/commands/fix-tests.md
ls {{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md
```

If the tool has no slash-command mechanism at all, none of this matters: paste
a prompt from `05-reusable-test-fixing-prompts.md` instead. The method does not
depend on the command.

---

## Customization for Your Project

### What to supply

The templates carry brackets. Replace every one of them before sending a
prompt; a bracket that reaches an agent is a question the agent cannot answer.

| Placeholder | Replace with |
|---|---|
| `[project name]` | This project's name |
| `[dev database]` | The database the application uses in development |
| `[test database]` | The database the suite runs against, if it differs |
| `[credentials]` | Where the suite's test account comes from — the config key, not the secret |
| `[path]` | The working directory the commands run from |
| `[schema]` | The schema or namespace the tables live in |
| `[test command]` | The real command, with the real flags |

### Keep a name mapping

The single highest-value artefact a session produces, and the one most often
left behind. Fill it in as names are verified, and keep it in
`{{SESSIONS_DIR}}/active/<date>-schema-verification.md`:

```
Stored name        Code property      Wrong guess that cost time
-----------------  -----------------  --------------------------
routemethod        routeMethod        route_method
routepath          routePath          route_path
detectedat         detectedAt         detected_at
accountid          accountId          account_id
userid             userId             user_id
createdat          createdAt          created_at
```

The third column is the point. A session that records only the correct name
lets the next session make the same wrong guess. A class of mismatch that shows
up twice belongs in an agent overlay under
`{{PIPELINE_ROOT}}/core/agents/overlays/`, not in a session document.

---

## What a Session Leaves Behind

### The three documents

Three documents under `{{SESSIONS_DIR}}/active/`:

| Document | Contents |
|---|---|
| `<date>-test-fixing-session.md` | Every fix with `file:line` and a reason, before and after numbers on all four measures, what each delegation found — including what it ruled out — and where the time went |
| `<date>-remaining-issues.md` | The unfixed failures, still categorized, each with an estimate and a recommended next step, in priority order |
| `<date>-schema-verification.md` | Everything verified against the live system: objects, fields, migration state, the name mapping, and every discrepancy found, fixed or not |

If the work belongs to a work order, the same evidence goes into its
VERIFICATION document through `wo verify --run`, which writes the status from
the suite's exit code. Nobody types `PASS`.

#### File 1 — the session summary

```
{{SESSIONS_DIR}}/active/<date>-test-fixing-session.md
```

Fixes applied with `file:line`, before and after metrics, what each delegation
found, and where the time went.

#### File 2 — the remaining issues

```
{{SESSIONS_DIR}}/active/<date>-remaining-issues.md
```

The unfixed failures, still categorized, with an estimate and a priority for
each and a recommended next step.

#### File 3 — the schema verification

```
{{SESSIONS_DIR}}/active/<date>-schema-verification.md
```

Every object and field verified against the live system, the migration state,
the name mapping, and every discrepancy found — including the ones not fixed.

Run `/next-session` at the end: it writes the handoff from those three
documents, and the next session reads it in Phase 1.

---

## Integration With Other Commands

### Works well with

| Command | Use it |
|---|---|
| `/next-session` | At the end of a session, to write the handoff the next one reads |
| `/wo` | To open a work order covering a multi-session recovery, and to close it on the final run |
| `/checkpoint` | Mid-session, before a large or risky batch of fixes |

### Example workflow

```
1. /fix-tests                     start, work the five phases (90 min)
2. wo note <n> "session 1: 18.8% → 20.7%, 15 name mismatches, 3 blockers"
3. /next-session                  write the handoff
4. [next session] /fix-tests      resume from the handoff
5. wo verify <n> --run <suite>    once the target is reached
6. wo close <n>                   close on the executed evidence
```

---

## Tips

### Maximize efficiency

1. **Delegate searching early.** The instinct to grep by hand costs the most
   time in the session and returns the least.
2. **Work one category at a time.** Jumping between categories makes the
   numbers unattributable.
3. **Write findings down as they happen.** Reconstructing them at the end is
   how `file:line` references get lost.
4. **Measure often.** Knowing the rate of improvement is what tells you whether
   to continue in this direction or stop and re-triage.
5. **Record the name mapping.** Every session that re-derives it is paying for
   the previous session's omission.

### Maintain quality

1. **Verify every assumption about the data store** against the live schema,
   not against a model file and not against memory.
2. **Test incrementally.** Small steps with frequent validation; a batch that
   fails tells you nothing about which change caused it.
3. **Keep notes on what worked and what did not.** The failed approaches are
   worth as much to the next session as the successful ones.
4. **Trust the conservative path.** A smaller, verified fix that holds beats a
   sweeping change that has to be unpicked.
5. **Put a recurring mismatch class in an agent overlay** under
   `{{PIPELINE_ROOT}}/core/agents/overlays/`, so the next session starts
   knowing it. Overlays survive reinstalls; edits to the instruction files do
   not.
6. **Take the user's account of system state seriously.** They know things
   about the system's history that are not in the code — and the code is
   exactly the artefact that has drifted.

---

## Recorded Outcomes

One session from the record this method came out of, kept because it sets the
expectation.

**Starting point.** 1408 tests at an 18.8% pass rate. The schema had recently
been standardized; nobody knew how many distinct problems that had created.

**Session 1 results.**

- 15 field-name mismatches fixed between the models and the live schema
- 3 critical blockers fixed: a service crashing at start-up, a whole feature
  returning not-found, and a create path silently dropping a field
- 7 missing tables created, from a migration recorded as applied but never run
- Pass rate 18.8% → 20.7%, in 90 minutes
- Suite duration 187s → 45s, a 76% reduction

**Why the duration matters more than the rate here.** The application had been
crashing during initialization; once it stopped, the suite got far enough to
reveal the real failures. That is what made the next session's larger gain
possible.

**What the session credited the result to.**

- Verifying names against the live schema rather than assuming the convention
- Delegating three investigations, which saved roughly 95 minutes of manual work
- Fixing one category at a time, which kept every number attributable
- Writing the three documents, which is why the next session did not restart

---

## Next Steps

### After the first session

1. Read the metrics — pass rate and duration, before and after
2. Run `/next-session` to write the handoff
3. Prioritize what is left, from the remaining-issues document
4. Decide the next session's single focus, and write it down

### After reaching the target

1. Open a work order recording the recovery, and close it on the final run
2. Update the project's test documentation with what the suite now covers
3. Build the pre-flight checks the recovery kept wanting — a name checker and a
   migration-completeness checker are the two that pay for themselves
4. Promote the work order so the recovery is reusable: `wo promote <number>`

### Ongoing

1. Run the suite before any large change, not after
2. Re-verify the schema against the models when a migration lands
3. Keep the name mapping current
4. Record each new mismatch class in an agent overlay

---

## Questions

### Q: How long until the suite is healthy?

Four to six sessions, at two to five points each, for a suite failing at
scale. Faster if the failures share one cause; slower if they are genuine
defects, because those fixes are real work.

### Q: Can I use this for unit tests?

Yes. Skip the schema verification in Phase 2 — the blockers there are build
errors, imports, and stale generated types — and expect to delegate less.

### Q: Do I have to use the delegated agents?

No. Most sessions use one or two. Use them when a question spans more than a
few files.

### Q: What if the data store uses a different convention from the examples?

The examples are shapes. The method is enumerate, verify against the live
system, fix what is confirmed — which is convention-agnostic.

### Q: What if there is no handoff document?

Start anyway, and write one at the end. The first session on a suite never has
one.

### Q: Can I change the phases?

Yes, but keep the core cycle: verify, fix, test, measure. The phase boundaries
are a budget, not a ritual; the cycle inside them is the method.

### Q: The categories in the plan look wrong. Now what?

Say so before approving. Re-triage costs minutes at that point and an hour
later.

---

## Support and Resources

### Documentation files

| File | What it is |
|---|---|
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | The rules |
| `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md` | The delegation templates |
| `{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md` | The session prompts |
| `{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md` | The long-form methodology |

### Quick commands

```bash
# start a session
/fix-tests

# confirm the command is installed
ls {{PIPELINE_ROOT}}/core/commands/fix-tests.md

# read the rules
cat {{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md

# read the delegation templates
cat {{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
```

---

## Related

| Document | What it is |
|---|---|
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | The authoritative rules the command follows |
| `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md` | Delegation templates for Phase 4 |
| `{{PIPELINE_ROOT}}/core/instructions/05-reusable-test-fixing-prompts.md` | Whole-session prompts for running the method by hand |
| `{{PIPELINE_ROOT}}/core/instructions/README-TEST-FIXING-SYSTEM.md` | The index for the whole system |
| `{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md` | The long form: reasoning, a recorded recovery, the metrics |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` | What counts as verification evidence |
