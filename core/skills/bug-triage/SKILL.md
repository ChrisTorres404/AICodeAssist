---
name: bug-triage
description: Open, investigate, or close a bug. Use when the user reports something broken, asks why a behaviour is happening, or asks to file or close a bug.
---

# Bug Triage

## Has this happened before?

```bash
{{PIPELINE_ROOT}}/bin/playbook bug "<symptom>"
```

Recurring bugs are common and the earlier folder usually contains the root
cause, which is rarely what the symptom suggests.

## Open, and route it

```bash
{{PIPELINE_ROOT}}/bin/bug new "<title>" --category auth|api|database|ui|observability|security|performance|integration|config|docs
```

The category numbers the bug in its series and prints who investigates, who
fixes, and who validates, from the routing table in
`core/rules/common/troubleshooting.md`. Say the routing out loud before you
start, then delegate accordingly. If you cannot tell the category yet, that
is the first thing to find out: reproduce it, read the error, and the
category is usually obvious.

Investigating agents **investigate only**. Hand them the error verbatim, the
files involved, what has been tried, and the database name if data is in
question. Ask for `file:line` references and for what would disprove their
theory. The fix is a separate delegation to the fixing agent, and a
different agent validates it.

## Investigate before theorising

1. **Reproduce it.** A bug you cannot reproduce is a hypothesis.
2. **Read the actual error**, including the stack and the surrounding log lines.
3. **Verify the data.** Query the database; check the column exists and what it
   holds. Do not infer schema from entity definitions — they drift.
4. **Find the boundary.** What is the last thing that works and the first that
   does not?
5. **Only then** form a root-cause theory, and state what would disprove it.

Record the symptom, the root cause, and the fix separately. They are three
different things, and conflating them is why bugs recur.

## Close

```bash
{{PIPELINE_ROOT}}/bin/bug close <number>
```

Blocked without a VERIFICATION document, for the same reason work orders are.

## A fix is not done when the symptom stops

- Does the same root cause exist anywhere else in the codebase?
- Is there a regression test that would have caught it?
- Did you remove the debug logging you added while chasing it?
