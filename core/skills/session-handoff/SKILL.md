---
name: session-handoff
description: Produce a continuation document so a fresh session can resume work without losing context. Use when the user says nextSession, asks for a handoff, says they are stopping for the day, or when a session is approaching its context limit.
---

# Session Handoff

This produces a document and **no code**. Stop implementation work entirely.

## Filename

```
next-session--<context>--YYYY-MM-DD--HHMM.md
```

`<context>` is the work identity — `WO-0407-rate-limiting`, `BUG-0055-cookies`,
`auth-flow-fixes`. Saved to `{{SESSIONS_DIR}}/active/`.

## Template

Use `{{PIPELINE_ROOT}}/core/templates/sessions/SESSION-HANDOFF-TEMPLATE.md`
(annotated) or `NEXT-SESSION-TEMPLATE.md` beside it (blank; each section is defined
in `core/instructions/02-next-session-rules.md`) exactly. Every heading, in order. Write `N/A` where a section does not apply
rather than deleting it — a fresh session reads the shape as much as the text.

## What makes a handoff useful

The test is whether a session with **no memory of this one** could resume in
five minutes. That means:

- Absolute file paths, not "the auth service".
- Method and component names, database columns, endpoint paths.
- What you tried that **did not** work, and why. This is the highest-value
  section and the one most often omitted — it prevents the next session from
  spending an hour rediscovering a dead end.
- The precise next action, not a goal. "Add the index on `auth.sessions.user_id`"
  beats "improve session performance".
- Any environment state the next session will not infer: a stale process, a
  server that needs restarting, a migration applied locally but not committed.

Do not summarise. Compression is what destroys handoffs.

## Source references collected

When the session read a codebase — an analysis, a documentation pass, an
investigation — the handoff carries the index of what was actually opened. A
fresh session that has this table does not repeat the reading; a fresh session
that does not, repeats all of it.

| File | Lines | What was analysed | Work order |
|---|---|---|---|
| `src/jobs/retry.ts` | L22-L74 | Backoff schedule and attempt ceiling | WO-0412 |

Paths are relative to the repository they belong to, never absolute host
paths. Include the files you opened and found nothing in — "looked here, not
there" is the most expensive thing for the next session to rediscover.

## Bootstrap prompt

End every handoff with a block the next session can be given **verbatim**,
before it is given the handoff itself. It exists so the first thing a fresh
session does is orient rather than act.

```
You are continuing work on: <project>.
Active work orders: WO-#### — <title>; WO-#### — <title>.
Target repositories: <repo> at <path>; <repo> at <path>.

I will give you the handoff document next. Your first tasks, in order:
1. Summarise your understanding of the project and the current goal.
2. List what was completed versus what remains, per work order.
3. Propose 3-7 concrete next actions.
4. Wait for my confirmation before changing any code or documents.
```

Fill in the names — a bootstrap prompt with placeholders left in it is a
prompt the next session has to repair before it can use it. Step 4 is not a
formality: a session that starts by editing has skipped the step where you
find out it misread the handoff.
