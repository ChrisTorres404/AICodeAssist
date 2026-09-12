---
description: Can this system meet a stated requirement? Evidence from the analysis, the gap, the effort, and a verdict that is allowed to be no. Usage: /feasibility "<requirement>"
---

Requirement: **$ARGUMENTS**

Load the `feasibility-analysis` skill. Requires a completed `/analyze-repo`; a `/status-matrix`
supplies the readiness of anything the answer leans on.

1. Open the work order: `{{PIPELINE_ROOT}}/bin/wo new "<requirement> feasibility" --area analysis`.
2. **Restate the requirement** as testable conditions. An unstated assumption becomes a question
   for the requester, not a guess; stop and ask if the answer changes the verdict.
3. **Map each condition to evidence**: `repo-analyst` finds what already satisfies it, with a
   `<!-- SOURCE: path:L12 -->` comment, or records that nothing does. Nothing is a finding.
4. **State the gap** per condition: what exists, what is missing, and what would have to be
   built, changed, or configured — described from the code, not from a reference architecture.
5. **Size it**: the work, the blast radius across the features the cross-feature map shows
   depend on the same code, and the risks that would make the estimate wrong.
6. **Verdict**, one of: FEASIBLE AS BUILT, FEASIBLE WITH WORK, FEASIBLE WITH MATERIAL REWORK,
   or NOT FEASIBLE AS DESIGNED — each with the conditions that decided it and what would
   change the answer. A no that is grounded is a good outcome.
7. `critical-reviewer` attacks the verdict: over-claimed capability, a condition quietly
   dropped, an estimate with no basis. `factuality-validator` confirms every cited capability.
8. Report the verdict, the conditions that drove it, and the open questions, in that order.
   Hand off to `/plan` only for a verdict of FEASIBLE.
