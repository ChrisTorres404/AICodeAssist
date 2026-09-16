# Test Fixing — Reusable Session Prompts

Whole-session prompts for running the systematic test-fixing method by hand.

Use these when the `/fix-tests` command is not available — a different agent
tool, a plain chat session, a teammate who wants the method without the
pipeline installed — or when a session needs a narrower brief than the command
gives. The method itself is
`{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`; the per-question
delegation templates are
`{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`; the
reasoning and the recorded case are
`{{PIPELINE_ROOT}}/core/methodology/SYSTEMATIC-TEST-FIXING-METHODOLOGY.md`.

Every prompt below is a shape. Fill in every bracket before sending it. A
prompt sent with its brackets still in it is worse than no prompt: the agent
invents values for them.

---

## What to Fill In First

Gather these once; every prompt on this page uses them.

| Placeholder | What it is |
|---|---|
| `[project]` | The project's name |
| `[test command]` | The full-suite command, with the flags this project uses |
| `[targeted test command]` | How the runner is pointed at one file or directory |
| `[build command]` | Build and static type-check |
| `[environment]` | Which environment the suite runs against |
| `[db client]` | The data-store client with connection arguments for that environment |
| `[schema]` | The namespace the failing objects live in |
| `[source dir]`, `[test dir]`, `[seed dir]` | The real directories |
| `[credentials]` | How the suite authenticates, and where the values come from |
| `[current pass rate]` | The last known number, if there is one |
| `[known issues]` | What the previous session or the handoff says is broken |

If any of these is missing from the project `CLAUDE.md`, find it once and add
it there. The next session should not have to look again.

Resolve them once and keep the resolved set beside you for the session:

```bash
grep -nE "test|build|type-check|migrat|psql|database" CLAUDE.md   # from the project root
```

Never paste a real secret into a prompt. Name where the credential comes from —
an environment variable, a secret store, the test fixture that creates the
account — and let the agent read it from there.

---

## The Full Session Prompt

The default. Covers all five phases, ends with the three session documents.

~~~markdown
Run a systematic test-fixing session on our failing suite. Work
verification-first and conservatively: fix one category, verify, measure, then
continue.

## CONTEXT

- Project: [project]
- Environment under test: [environment]
- Data store and client: [db client]
- Test command (full suite): [test command]
- Test command (one file or directory): [targeted test command]
- Build and type-check: [build command]
- Source, tests, seeds: [source dir], [test dir], [seed dir]
- Credentials: [where the suite gets them from — do not paste secrets]
- Current pass rate: [current pass rate]
- Known issues: [known issues]
- Handoff to read first: [path, if there is one]

## CONSTRAINTS

1. Verify every name against the live system before editing code that uses it.
   The live schema is the fact; the model is the claim.
2. Fix one category at a time. Re-run after each. Never batch across
   categories.
3. Delegate investigation that spans more than a few files. Investigators
   return file:line findings and do not edit.
4. Never report a test as passing without having run it and seen it pass.
   "NOT EXECUTED — PLAN ONLY" is an acceptable status; a false PASS is not.
5. Fix the implementation, not the test — unless the test is provably wrong,
   and then say so explicitly with the reasoning.
6. Run every verification query against the SAME environment the tests run
   against.

## PHASE 1 — ASSESSMENT (about 10 min). Change nothing.

1. Read the handoff, the relevant work order, and the project CLAUDE.md.
2. Capture a baseline and record suites, tests, pass rate, and duration:

   ```bash
   [test command] 2>&1 | tee /tmp/baseline.txt
   ```
3. Verify the infrastructure the suite needs: does the data store answer, do
   the objects exist, did the last migrations actually run rather than only
   register.

   ```bash
   [db client] -c "SELECT 1;"
   [db client] -c "\dt [schema].*"
   [db client] -c "SELECT name FROM [migrations table] ORDER BY 1 DESC LIMIT 10;"
   ```
4. Categorize EVERY failure and give me counts per category: build or type
   errors, schema mismatches, wiring and registration, contract mismatches,
   authentication, fixture gaps, timeouts and flakes, other.
5. Propose a plan ordered by shared root cause — largest cause first, not file
   order — and WAIT for my approval before changing anything.

## PHASE 2 — BLOCKERS (about 20 min)

6. Fix build and type errors first; nothing downstream runs until they are gone.
7. For every failure naming a column, field, table, key, or enum value: query
   the live schema for the real name BEFORE editing. Show me "code says X,
   system says Y" for each.

   ```bash
   [db client] -c "SELECT column_name FROM information_schema.columns
                   WHERE table_schema = '[schema]' AND table_name = '<table>'
                   ORDER BY ordinal_position;"
   ```
8. Fix the blocking mismatches. Record every verified name as a two-column
   mapping (stored name, code name).
9. Re-run five to ten targeted tests that exercise what you just fixed. Report
   the delta. Not the full suite yet.

   ```bash
   [targeted test command] --maxWorkers=1 --forceExit
   ```

## PHASE 3 — SYSTEMATIC SEARCH (about 30 min)

10. Take the largest shared cause and find every instance of it in one pass,
    in all four places: model and schema definitions, query construction, raw
    statements, and fixtures/seeds/test expectations.
11. Reduce the hits to a unique list of names, then verify EACH against the
    live system. Do not fix from the list; fix from the verification.
12. Fix every confirmed mismatch in one pass. This is the one place batching
    is correct, because the whole batch is one verified category.
13. Re-run the affected tests and report the delta.
14. Search again and show me that nothing of that class remains. Anything left
    that you verified as correct: write it down with the reason.

    ```bash
    grep -rn "<pattern>" [source dir] [test dir] || echo "clean"
    ```

## PHASE 4 — DELEGATED INVESTIGATION (about 20 min)

15. For what is left, delegate in this order: context (what changed, what the
    convention is, where it is documented), then active debugging (why this
    specific thing fails), then infrastructure (does it exist, did the
    migration run, is it registered).
16. Give each investigator: the symptom with the error quoted verbatim, what
    you already ruled out, the specific files to start from, and a request for
    file:line references plus the check that would confirm the fix.
17. Verify each finding against the system yourself before applying it. Then
    apply, re-run, report.

## PHASE 5 — VALIDATION (about 10 min)

18. Run the full suite:

    ```bash
    [test command] 2>&1 | tee /tmp/after-fixes.txt
    ```
19. Compare against the baseline on four measures: suites, tests and pass
    rate, duration, and the count of distinct error strings per category.
20. Write the three session documents (below). If the session is ending with
    work outstanding, write a handoff.

## DELIVERABLES

Under [sessions directory]:

1. `[date]-test-fixing-session.md` — every fix with file:line and a reason,
   before and after numbers on all four measures, what each delegation found
   (including what it ruled out), where the time went.
2. `[date]-remaining-issues.md` — the unfixed failures, still categorized,
   each with an estimate and a recommended next step, in priority order.
3. `[date]-schema-verification.md` — everything verified against the live
   system: objects, fields, migration state, the name mapping, and every
   discrepancy found, whether or not it was fixed.

Report honestly. A session that moved nothing is a finding, not a failure to
hide.
~~~

---

## Variations

### Minimal brief

For a session where the context is already known and the suite is small.

```markdown
Fix our failing test suite systematically.

- Test command: [test command]
- Environment: [environment]
- Known issue: [the one thing we already suspect]

1. Capture a baseline to a file and categorize every failure with counts.
2. Verify names against the live system before editing anything that uses them.
3. Fix the largest shared cause first, then re-run and report the delta.

Conservative: one category at a time, verify after each. Do not report a test
as passing without having run it.
```

### Delegation-first

For a suite nobody present understands yet. Buys context before any edit.

```markdown
Our test suite is failing at scale and I want the investigation done before
any code changes.

1. Capture a baseline run to a file and categorize the failures with counts.
2. Delegate, in parallel where the questions are independent:
   - Context: what changed recently in [area], what the current conventions
     are, and where that is documented.
   - Active debugging: root-cause the top three distinct error strings.
   - Infrastructure: verify the objects, migration state, and registration
     that the failing features depend on.
3. Bring back the findings with file:line, tell me which are verified and
   which are theories, and propose a fix order by shared root cause.

Investigators investigate; nobody edits until I approve the order.

Environment: [environment]. Test command: [test command].
```

### One issue, many failures

For a single error string that accounts for a large share of the failures.

```markdown
We have [N] test failures sharing the error: "[exact error text]"

1. Verify the live system for whatever that error names — object, field, key,
   enum value — in [environment]. Show me the real state.
2. Find every reference to it in the code: model definitions, query
   construction, raw statements, and fixtures/seeds/test expectations.
3. Tell me which side is wrong, with evidence, before changing anything.
4. Fix the confirmed mismatches in one pass.
5. Re-run [the affected tests] and report before → after.
6. Search again and show me the class is gone.

Delegate if the investigation runs past fifteen minutes.
```

### Continuing a previous session

```markdown
Continue the test-fixing effort from this handoff: [path]

1. Re-read the handoff and the schema-verification document from last session —
   the verified name mapping is in there; do not derive it again.
2. Capture a fresh baseline; confirm the numbers still match the handoff. If
   they do not, find out what changed before fixing anything.
3. Take the top item from the remaining-issues document and work it with the
   same method: verify, fix one category, re-run, measure.
4. Update all three session documents and write the next handoff.
```

---

## Adapting to the Failure Mix

| The failures are mostly | Adjust |
|---|---|
| One naming convention against another | Phase 3 is the session. Skip most delegation; the enumerate-verify-fix loop is the whole job, and it goes fast once the first name is verified. |
| Whole features unreachable | Lead with infrastructure delegation: registration, routes, migration state. One missing line often restores dozens of tests. |
| Authentication and permissions | Lead with active debugging and trace one failing flow end to end. Check seeded roles and permissions before touching code — the usual cause is data, not logic. |
| Contract disagreements | Decide the source of truth first: the published contract, or the running implementation. Fix everything to that one side in a single pass. |
| Timeouts and flakes | Treat as environmental until proven otherwise: connection-pool exhaustion, a stale process serving an old build, parallelism the suite cannot take. Re-run serially before diagnosing code. |
| Fixtures that no longer resemble the real system | Stop and report. The suite is measuring the fixture. Recommend converting those cases to behavioural suites rather than spending the session making a stub agree with itself. |

---

## Rules of Engagement

### Absolute rules

1. **ALWAYS verify the live schema BEFORE making changes.**
2. **NEVER assume a name** — read it out of the running system.
3. **ALWAYS test fixes incrementally** — no batches across categories.
4. **USE delegation for investigation** — do not burn the session searching by
   hand.

### When to use each agent

| Agent | Use it for | Model |
|---|---|---|
| A broad search agent (`code-explorer`, `Explore`) | Finding documentation, historical context, a pattern across many files | Fast — the work is search, not reasoning |
| A debugging specialist (`support-engineer-expert`) | Errors and exceptions, tracing data through layers, root-cause analysis | Strong reasoning — inference over indirect evidence |
| A data-store validator (`database-validator-expert`) | Verifying state, migration execution, object existence, registration | Strong, with data-store expertise |

### Progressive fix strategy

| Iteration | Focus | Run | Expect |
|---|---|---|---|
| 1 | Build and type errors; the blockers that stop the system initializing | 5-10 targeted tests | 5-15% |
| 2 | The systematic mismatch class, fixed in one pass | 20-30 targeted tests | 15-25% |
| 3 | Wiring: unregistered modules, missing routes, contract drift | 50-100 tests | 25-35% |
| 4 | Business logic: authentication, permissions, workflow state | Full suite | 35-50% |

**Goal: 70%+ pass rate after four to six iterations (6-9 hours.)**

---

## Expected Outputs

After all five phases, the session has produced:

- Documentation of every fix applied, with `file:line`
- Before and after pass-rate metrics, from two captured runs
- A list of the remaining issues, categorized
- The delegation findings, including what each one ruled out
- Confirmation that the data model and the live schema agree

---

## Sample Interaction Flow

```
You:    [paste the full session prompt]

Agent:  reads the handoff
        checks the infrastructure
        reviews the previous results
        creates a task list with the five phases
        proposes an action plan
        WAITS for approval

You:    "Proceed with the conservative approach"

Agent:  fixes the build and type errors
        verifies names against the live schema
        fixes the blocker that stopped initialization
        runs a targeted subset
        reports the delta (X% → Y%)
        proposes the next step

You:    "Continue with the systematic search"

Agent:  enumerates every instance of the class
        verifies each against the live system
        fixes them in one pass
        lists the fixes
        re-runs and reports

You:    "Use a delegation to investigate [issue]"

Agent:  launches the right investigator
        shows the findings
        applies the recommended fix
        verifies with tests
        reports
```

---

## Verification Checklist

Before marking a session complete:

- [ ] Build and type errors are all resolved
- [ ] No instance of the mismatch class remains in the model definitions
- [ ] No instance of it remains in query construction
- [ ] No instance of it remains in raw statements
- [ ] No instance of it remains in fixtures, seeds, or test expectations
- [ ] The live schema was verified against every model the session touched
- [ ] Everything the suite needs is registered and reachable
- [ ] Contracts and the models they map to agree
- [ ] Targeted tests were re-run after each fix category
- [ ] The full suite was run and its metrics captured to a file
- [ ] The improvement is documented as before → after on all four measures
- [ ] The delegation findings are written down, ruled-out items included
- [ ] The remaining issues are categorized with estimates and priority
- [ ] The next session's handoff exists

---

## Anti-Patterns to Avoid

**Do not:**

- Assume the store uses the convention the code uses — verify first
- Fix several categories without testing in between
- Skip a verification step because the answer looks obvious
- Override what the user told you about the state of the system
- Search by hand when a delegation does it faster and better
- Trust documentation over the running system
- Make a change based on an old migration file rather than the live schema
- Batch fixes without an incremental run

**Do:**

- Verify the live system for every name the code references
- Re-run after each category of fix
- Delegate the investigations that span files
- Take the user's account of the system's history seriously
- Check every environment the suite touches, not only the first
- Reduce hits to a unique list before verifying, so nothing is checked twice
- Write findings down as they happen, not at the end
- Measure continuously, so you know whether to continue or re-triage

---

## Expected Timeline

| Session | Content | Result |
|---|---|---|
| 1 (90 min) | Assessment 10, blockers 20, systematic search 30, delegation 20, validation 10 | +2-5% |
| 2 (90 min) | Continue the systematic fixes, one category at a time | +5-10% |
| 3 (90 min) | Authentication, authorization, permission grants | +10-15% |
| 4 (90 min) | Remaining edge cases, final validation | 70%+ total |

**Total: 6-9 hours to a test suite that can be trusted.**

---

## Success Metrics

### Session success

- Pass rate improved by two points or more, backed by two captured runs
- The blockers are resolved and the system initializes
- At least one delegation was used and its finding verified
- The live schema was verified against the models
- Every fix is documented with `file:line`

### Project success

- 70%+ pass rate achieved
- Every critical path is covered by a test that runs against the real system
- The data model and the live schema agree completely
- No instance of the systematic mismatch remains in the active codebase
- Everything the suite needs is registered correctly

---

## Customization Guide

### For your project

Replace these before sending any prompt on this page:

```
[project]           → this project's name
[dev database]      → the database the application uses in development
[test database]     → the database the suite runs against, if it differs
[credentials]       → where the suite's test account comes from — never the secret
[path]              → the working directory the commands run from
[schema]            → the namespace the failing objects live in
[test command]      → the real runner invocation, with its real flags
```

Adjust these to the project:

- The mismatch pattern to search for, which depends on the conventions in play
- The agent names, which depend on the agents installed
- The failure categories, which depend on what this suite actually fails on
- The time estimates, which depend on the size of the suite

### For different scenarios

**Scenario 1 — one naming convention against another.** Skip most of the
delegation. Phase 3 is the session; the enumerate-verify-fix loop is the whole
job and it moves fast once the first name is verified.

**Scenario 2 — whole features missing or unreachable.** Lead with the
data-store validator. Check registration in the composition root and confirm
the migrations actually executed rather than merely registered.

**Scenario 3 — authentication and authorization failures.** Lead with the
debugging specialist and trace one failing flow end to end. Check the seeded
roles, permissions, and test accounts before touching any code; the usual cause
is data, not logic.

---

## Agent Prompt Templates

Fuller versions of these, with worked results, are in
`{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`.

### Template 1 — documentation and context search

```markdown
Search the codebase for documentation from [timeframe] about [topic].
I need to understand:

1. [Specific question 1]
2. [Specific question 2]
3. [Specific question 3]

Search locations:
- [documentation directory]
- [migrations directory, and the range that matters]
- [specific file patterns]

Return the exact documentation with file paths and line numbers, so I can
understand [the rules / the technical requirement / the schema change].
Do not make any changes.
```

### Template 2 — bug diagnosis

```markdown
I need deep troubleshooting for a [component] bug:

**Symptom:** [method] [endpoint] returns [status] "[error message, verbatim]"

**What I've already done:**
1. [Verification step, and what it ruled out]
2. [Fix attempt, and what happened]
3. [Data-store check, and what it showed]

**The problem:** [description of the unexpected behaviour]

**Files to investigate:**
- [File 1] ([the method or class to check])
- [File 2] ([what to look for])
- [File 3] ([the suspected location])

**What I need:**
1. Root cause: [the specific technical question]
2. A data-flow trace: entry point → handler → service → model → data store
3. The exact fix, with file:line references
4. The verification step that would confirm the fix worked

Trace the data flow and find where the value is lost. Do not make changes.
```

### Template 3 — infrastructure verification

```markdown
[Component] endpoints return [status] "[error]" but the code exists. Verify:

**1. Module registration:**
- Is [module] registered in the application's composition root?
- Check [composition root path]
- Are its handlers exported from the module?

**2. Data-store infrastructure:**
- Verify these exist: [object 1], [object 2], [object 3]
- Environment: [environment and client]
- I believe I created these earlier — verify they are actually there
- Run a real query against each, and include the output

**3. Migration status:**
- Was migration [identifier] fully executed, not merely recorded?
- Check the migrations table
- Verify every object that migration creates exists

**4. Seed data:**
- Are the required permissions seeded? Check [permission codes] in [table]
- Does [reference data] exist in [table]?

**What I need:**
1. The exact reason [endpoint] returns [status]
2. What is missing — registration, export, object, seed data
3. The specific fix, with file:line references
4. The verification queries that confirm the fix

Use real queries to verify everything. Do not make changes.
```

---

## Troubleshooting Guide

### Tests still failing after the mismatch class was fixed

**Check:**

1. Did you verify every environment the suite touches, not only the first?
2. Are there raw statements you missed?
3. Are the table or collection names using the other convention too, not just
   the field names?
4. Do the migration files create objects under the old convention?

**Solution:**

```bash
# raw statements carrying the pattern
grep -rniE "(FROM|JOIN|INTO|UPDATE) +[a-z]+_[a-z]+" <source dir>
```

### A stale process is serving the old build

**Check:** whether the thing the tests talk to is running the code you just
changed. This is the most common cause of a correct fix that appears to change
nothing.

**Solution:**

```bash
# what is still running from an earlier session
ps aux | grep test

# and what is holding the port the suite talks to
lsof -ti :<port>
```

Stop them, restart the system under test, and re-run before concluding
anything about the fix.

### A delegation comes back empty

**Check:**

1. Was the prompt specific enough?
2. Did you give exact paths or patterns to start from?
3. Is the material actually in the locations you named?

**Solution:** use more specific terms, give several search locations, and ask
for a broad sweep first before the narrow question.

### Fixes do not improve the pass rate

**Check:**

1. Are the tests running against the environment you think they are?
2. Did the fix actually apply? `git diff`.
3. Is the system under test serving the new build, or a stale process?
4. Are there cascading causes — the fix was right and revealed the next one?

**Solution:**

```bash
# run the targeted subset immediately after the fix, serially
<targeted test command> --maxWorkers=1 --forceExit

# and compare error-category counts, not only the pass rate
grep -E "<the runner's error markers>" /tmp/after-fixes.txt | sort | uniq -c | sort -rn
```

---

## Quick Reference Commands

### Database verification

```bash
# list the tables in a schema
<db client> -c "\dt <schema>.*"

# show one table's structure
<db client> -c "\d <schema>.<table>"

# exact column names, in order
<db client> -c "SELECT column_name FROM information_schema.columns
                WHERE table_schema = '<schema>' AND table_name = '<table>'
                ORDER BY ordinal_position;"

# does this name exist anywhere
<db client> -c "SELECT table_name, column_name FROM information_schema.columns
                WHERE column_name = '<name>';"

# migration state
<db client> -c "SELECT name FROM <migrations table> ORDER BY 1 DESC LIMIT 10;"
```

### Code search

```bash
# model and schema definitions
grep -rn "<mapping declaration>" <source dir>

# the mismatch pattern in model definitions
grep -rnE "<mapping declaration>.*'[a-z]+_[a-z]+'" <source dir>

# query construction
grep -rn "<query builder call>" <source dir> | grep "_"

# raw statements
grep -rn "<raw query call>" <source dir> -A5 | grep "_"
```

### Testing

```bash
# one file or directory, serially
<targeted test command> --maxWorkers=1 --forceExit

# the full suite, captured
<test command> 2>&1 | tee /tmp/test-run.txt

# the summary lines
grep -E "<the runner's summary lines>" /tmp/test-run.txt
```

### Session bookkeeping

```bash
# has this failure class already been diagnosed and closed out
playbook search "<symptom>"

# record the session's numbers on the work order
wo note <number> "session N: X% -> Y%, <what was fixed>"

# write the verification from a real run, never by hand
wo verify <number> --run {{TESTING_DIR}}/suites/wo-<number>-<name>.sh
```

---

## Cheat Sheet: Stored Name to Code Name

A filled example from a real recovery, kept filled on purpose: the third column
is what stops the next session repeating the guess. Replace the rows with this
project's own verified names, adding a row only after the name was read out of
the live schema.

### Fields

| Stored name | Code property | Wrong guesses that cost time |
|---|---|---|
| `routemethod` | `routeMethod` | `route_method`, `RouteMethod` |
| `routepath` | `routePath` | `route_path` |
| `accountid` | `accountId` | `account_id` |
| `userid` | `userId` | `user_id` |
| `primaryemail` | `primaryEmail` | `primary_email` |
| `creatortype` | `creatorType` | `creator_type` |
| `modifiertype` | `modifierType` | `modifier_type` |
| `detectedat` | `detectedAt` | `detected_at` |
| `invitedby` | `invitedBy` | `invited_by` |
| `groupid` | `groupId` | `group_id` |
| `policygroupid` | `policyGroupId` | `policygroup_id` |
| `permissionid` | `permissionId` | `permission_id` |
| `created` | `created` | `created_at`, `createdAt` |
| `modified` | `modified` | `updated_at`, `updatedAt` |

### Tables

| Stored name | Wrong guesses that cost time |
|---|---|
| `usergroupmember` | `user_group_member` |
| `userpolicygroup` | `user_policy_group` |
| `unprotectedroutes` | `unprotected_routes` |

Keep this table in the session's schema-verification document, and promote a
class that recurs into an agent overlay under
`{{PIPELINE_ROOT}}/core/agents/overlays/`, where it survives a reinstall.

---

## Final Prompt Example

A fully filled version of the full session prompt, with every bracket resolved.
Copy it and substitute this project's values — the point of showing it filled is
that you can see what "filled in" actually means.

~~~markdown
I need you to systematically fix our failing test suite using a conservative,
verification-first approach.

## PROJECT CONTEXT

- Project: the platform API
- Environment under test: local development
- Data store and client: PostgreSQL, via `psql -h localhost -p 5432 -d app_dev`
- Test command (full suite): `npm run test:e2e -- --maxWorkers=4 --forceExit`
- Test command (one file): `npm run test:e2e -- <path> --maxWorkers=1 --forceExit`
- Build and type-check: `npm run build` and `npm run type-check`
- Source, tests, seeds: `src/`, `test/e2e/`, `src/database/seeds/`
- Credentials: the suite creates its own account through the registration
  fixture; the seed password comes from TEST_USER_PASSWORD in the environment
- Current pass rate: 18.8% (264 of 1404 tests)
- Known issue: the schema was recently standardized to lowercase names, and
  much of the code still spells them with underscores
- Handoff to read first: Workspace/Sessions/active/next-session-handoff.md

## YOUR TASKS

### Phase 1 — Assessment (10 min)

1. Read the handoff at the path above.
2. Check that the tables the suite needs exist — the reporting tables were
   reported missing last session.
3. Capture a baseline run and record suites, tests, pass rate, and duration:

   ```bash
   npm run test:e2e -- --maxWorkers=4 --forceExit 2>&1 | tee /tmp/baseline.txt
   ```
4. Categorize every failure and give me counts per category.
5. Propose a plan ordered by shared root cause, and WAIT for my approval.

### Phase 2 — Blockers (20 min)

6. Fix the build and type errors; nothing downstream runs until they are gone.
7. For every failure naming a column, query the live schema for the real name
   BEFORE editing, and show me "code says X, system says Y".
8. Fix the service that crashes during initialization.
9. Run a targeted subset and report the delta:

   ```bash
   npm run test:e2e -- test/e2e/auth --maxWorkers=1 --forceExit
   ```

### Phase 3 — Systematic search (30 min)

10. Find every underscore-spelled name in all four places: model definitions,
    query construction, raw statements, and fixtures/seeds/expectations.
11. Reduce to a unique list and verify EACH against the live schema.
12. Fix every confirmed mismatch in one pass.
13. Search again and show me the class is gone:

    ```bash
    grep -rnE "'[a-z]+_[a-z]+'" src/ test/ || echo "clean"
    ```

### Phase 4 — Delegated investigation (20 min)

14. Delegate the context question: what the naming standardization actually
    decided, and where that decision is written down.
15. Delegate the debugging question: why template creation fails with a
    not-null violation on a field the request definitely carries.
16. Delegate the infrastructure question: why every reporting endpoint returns
    not-found although the handlers and tables exist.
17. Verify each finding yourself, then apply, re-run, and report.

### Phase 5 — Validation (10 min)

18. Run the full suite:

    ```bash
    npm run test:e2e -- --maxWorkers=4 --forceExit 2>&1 | tee /tmp/after-fixes.txt
    ```
19. Compare against the baseline on all four measures.
20. Write the three session documents under Workspace/Sessions/active/.

## CRITICAL RULES

- ALWAYS verify the live schema BEFORE making changes
- NEVER assume a name — read it out of the running system
- TEST incrementally: fix → verify → measure → repeat
- DELEGATE investigations that span more than a few files
- Never report a test as passing without having run it and seen it pass

Work conservatively: one category at a time, verify after each.
~~~

---

## Before You Send

- [ ] Every bracket is filled in
- [ ] No secret is pasted into the prompt — only where to read it from
- [ ] The environment named in the prompt is the one the suite runs against
- [ ] The commands are this project's real commands, copied from `CLAUDE.md`
- [ ] The prompt asks for counts and file:line references, not a narrative
- [ ] The prompt says what the deliverables are and where they go

When a session goes wrong — nothing improves, a delegation comes back vague,
fixes that do not stick — the diagnostic list is in
`{{PIPELINE_ROOT}}/core/instructions/00-test-fixing-quick-start.md`.
