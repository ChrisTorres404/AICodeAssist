---
description: Stop all work and produce the session handoff document so a fresh session can resume with full context. Usage: /next-session [context-slug]
---

Load the `session-handoff` skill and follow it exactly. Context: **$ARGUMENTS**

This produces one document and **no code**. Use the template at
`{{PIPELINE_ROOT}}/core/templates/sessions/SESSION-HANDOFF-TEMPLATE.md` (annotated) or
`NEXT-SESSION-TEMPLATE.md` beside it (blank; each section is defined in
`core/instructions/02-next-session-rules.md`), every heading, in order, `N/A` where a
section does not apply. Save it to
`{{SESSIONS_DIR}}/active/next-session--<context>--YYYY-MM-DD--HHMM.md`.

The section most often skipped and most valuable: what you tried that did
**not** work, and why.
