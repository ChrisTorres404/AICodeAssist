---
description: Primer for managers, architects, and decision-makers — what this is, what it does, how it fits, what it needs, and why it matters. Usage: /docs-primer [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `developer-docs` skill for tier discipline and the `feature-profile` skill for depth.
Requires a completed `/analyze-repo`.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> primer" --area docs`.
2. `documentation-expert` writes it from the analysis and the Feature Profiles, using the
   primer template in `{{PIPELINE_ROOT}}/core/templates/docs/`: executive summary, what this
   is in plain language, key capabilities by domain, architecture overview, integration
   touchpoints, dependencies, value, glossary.
3. Three to eight pages. Technical terms are allowed and are explained on first use; the test
   is whether the reader can explain the system to their own team afterwards.
4. Narrative before every table. A table nobody introduced is a table nobody reads.
5. `narrative-curator` applies the same gates as the brief: one-sentence test per capability,
   value articulated, no name-only references, no passive descriptions of mechanisms.
6. `factuality-validator` verifies every claim against the source index, and every capability
   statement against the status matrix where one exists.
7. Report the capabilities covered, the ones deliberately left to the technical reference, and
   any term the glossary could not define from the source.
