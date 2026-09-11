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
exactly. Every heading, in order. Write `N/A` where a section does not apply
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
