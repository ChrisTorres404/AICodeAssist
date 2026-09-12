---
description: Honest implementation status for every feature the analysis found — one badge, one code reference, one limitation each. No IMPLEMENTED badge without a code reference. Usage: /status-matrix [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `status-matrix` skill. Requires a completed `/analyze-repo`; without one, run that first.

1. Work in the analysis work order, or open one: `{{PIPELINE_ROOT}}/bin/wo new "<repo> status matrix" --area analysis`.
2. `repo-analyst` extracts every feature from the inventory and groups it by capability domain.
   The matrix covers the whole inventory; a feature left out is a gap, not a tidy table.
3. `critical-reviewer` assigns the badge — IMPLEMENTED, PARTIAL, IN DEVELOPMENT, PLANNED,
   NOT AVAILABLE — against the source, not against the folder layout. A directory is not a
   feature and a file is not an implementation.
4. Every IMPLEMENTED badge carries a `<!-- SOURCE: path:L12 -->` comment naming the code that
   proves it. No reference, no badge: it drops to the honest one.
5. Every PARTIAL and IN DEVELOPMENT row states the specific limitation, in the reader's terms,
   not "some functionality may be missing".
6. Write the matrix from `{{PIPELINE_ROOT}}/core/templates/docs/`, with the roll-up counts per
   domain and an integration-readiness line that follows from them rather than softening them.
7. Reconcile: any badge that contradicts an FAQ answer, a Feature Profile, or an integration
   document is a finding, and the matrix is the source of truth the others are corrected to.
8. Report the distribution across the five badges and the features whose status is genuinely
   undetermined. Undetermined is a legitimate answer; optimism is not.
