---
description: Carry a verified, closed work order or bug into the project's pack with a catalog entry and pitfalls. Usage: /promote WO-#### | /promote BUG-####
---

Target: **$ARGUMENTS**

1. `{{PIPELINE_ROOT}}/bin/wo promote <n>` or `bug promote <n>`. It refuses
   unverified work and work that fails `sanitize`; if it refuses, fix the
   cause, do not bypass it.
2. Open the pack's `CATALOG.md` and write the **Pitfalls** lines for this
   entry: what went wrong, what would have found it faster, what the next
   person should check first. This is the most valuable part of the entry
   and only you can write it.
3. Report the pack, the folder, and the pitfalls you recorded.
