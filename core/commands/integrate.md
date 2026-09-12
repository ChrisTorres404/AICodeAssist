---
description: Close out a batch of parallel work orders with an integration work order whose suite proves the modules compose, not just that each one passes alone. Usage: /integrate "<batch name>" --covers 0002,0003,0004
---

Args: **$ARGUMENTS**

Parallel work orders verify themselves in isolation. Every one of them can be
green while a record written through one module never appears in another's
output. This is the step that catches that.

1. `{{PIPELINE_ROOT}}/bin/wo integrate "<batch name>" --covers <numbers>` — opens the
   integration work order and scaffolds a suite with every covered suite wired in.
   Each covered work order must already have its own suite; the driver refuses otherwise.
2. Write the composition checks: create one entity through the first module, then assert
   that every other module surfaces it. One walk across the whole batch beats twenty
   assertions inside one module.
3. `wo verify <n> --run <suite>` runs the covered suites first, then the walk. The status
   comes from the exit code.
4. `wo close <n>`. A batch whose integration work order is not closed on an executed pass
   is not finished, however green the individual work orders look.
5. `wo promote <n>` — the composition failures you found are the pitfalls worth carrying.
