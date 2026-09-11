---
description: Produce executed verification evidence for a work order or bug. Usage: /verify WO-#### [suite] | /verify BUG-#### [suite]
---

Load the `behavioral-testing` skill. Target: **$ARGUMENTS**

1. Identify or write the behavioral suite that exercises this change against
   the running system and asserts on state, not only status codes. Model it on
   an existing suite: `{{PIPELINE_ROOT}}/bin/pack suite "<topic>"`.
2. Run it through the driver so the result is recorded mechanically:
   `{{PIPELINE_ROOT}}/bin/wo verify <n> --run <suite>` (or `bug verify`).
   The status is stamped from the exit code; you do not write it.
3. If it fails, that is the finding. Record it, fix the implementation, run
   again. Do not edit the status line.
4. Report the status exactly as recorded and where the log is.
