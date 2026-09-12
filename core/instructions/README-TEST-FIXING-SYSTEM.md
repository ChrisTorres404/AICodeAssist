# The Test-Fixing System

A systematic method for recovering a test suite that is failing at scale,
together with the command that starts it and the delegation templates it uses.

It exists because the naive approach does not converge: read a failure, guess,
change something, run everything again, watch a different set of tests break.
The method replaces guessing with verification and replaces whole-suite churn
with measured increments.

---

## What It Is

| File | What it is | Who reads it |
|---|---|---|
| `{{PIPELINE_ROOT}}/core/commands/fix-tests.md` | The `/fix-tests` slash command | The user types it |
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | The authoritative method: five phases, the rules, the checklists | Loaded by the command |
| `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md` | Delegation templates for the investigation phase | Loaded by the command; used in phase 4 |
| `{{PIPELINE_ROOT}}/core/instructions/README-TEST-FIXING-SYSTEM.md` | This index | Anyone learning the system |

The command loads the `behavioral-testing` skill and both instruction files,
so nothing has to be pasted by hand.

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

**With a work order.** Open one for the recovery effort
(`wo new "<title>" --area testing`), run `/fix-tests` inside it, and close it
with `wo verify --run` and `wo close`. The closeout rests on the two captured
runs.

**With a session handoff.** `/next-session` writes the handoff from the session
documents above: fixes applied, current numbers, remaining issues, next steps.
The next session reads it in phase 1 and continues from there.

**With the packs.** `pack search "<symptom>"` before investigating. A failure
class that has been diagnosed once is usually recorded with the fix and the
pitfall that caused it.

---

## Adapting It to This Project

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

---

## Troubleshooting

**The command does nothing.** Confirm `/fix-tests` is installed and that both
instruction files are present:

```bash
ls {{PIPELINE_ROOT}}/core/commands/fix-tests.md
ls {{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md
ls {{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md
```

**A delegation comes back vague.** The prompt was vague. Use a template from
the library, name specific files, quote the error verbatim, say what you have
already ruled out, and ask for `file:line` explicitly.

**Nothing improves.** Check, in this order: are you running against the
environment you think you are; were the fixes actually applied (`git diff`);
is this the suite that was failing; and did the system pick up the change, or
is a stale process still serving the old build?

---

## Maintenance

- After a session, record any new mismatch class in an agent overlay
- When the suite's structure changes, re-check the commands in the project
  `CLAUDE.md`
- After a large schema change, re-verify the data model against the live
  system before the next session, not during it
