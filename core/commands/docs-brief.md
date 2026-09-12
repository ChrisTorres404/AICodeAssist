---
description: Product brief for leadership — the landscape, the capability snapshot, maturity per domain, and rollout readiness, in business terms with no jargon. Usage: /docs-brief [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `executive-docs` skill. Requires completed Feature Profiles and, for readiness
claims, a `/status-matrix`.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> product brief" --area docs`.
2. `product-strategist` groups the Feature Profiles into capability domains and assesses each
   one's maturity — foundational, differentiating, or emerging — from what the analysis found.
3. Write the brief from `{{PIPELINE_ROOT}}/core/templates/docs/`: the landscape before this
   system, what it is in one paragraph, the capability snapshot, maturity, the scale in
   narrated numbers, readiness, and a phased rollout that follows from the badges.
4. Two to four pages. Every technical term defined where it first appears, or cut.
5. `narrative-curator` checks the story arc and that every capability answers "so what?" for
   the reader's own teams. Bullet soup and table-only sections come back.
6. `factuality-validator` verifies every number and capability claim against the analysis and
   its source index. It is not the author.
7. Readiness language matches the status matrix exactly. A domain that is PARTIAL in the
   matrix is not "available" in the brief.
8. Report the domains covered, the maturity spread, and anything the brief deliberately omits
   because the evidence did not support it.
