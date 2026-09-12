---
description: Read-only eight-phase analysis of a repository — structure, features, API surface, data models, auth, dependencies, Feature Profiles, cross-feature map. Every other documentation command depends on it. Usage: /analyze-repo [path]
---

Target: **$ARGUMENTS** (default: this repository)

Load the `repo-analysis` skill. Read `{{PIPELINE_ROOT}}/core/rules/common/documentation.md`
before the first file: the target is read-only and source-or-silence governs every line.

1. Open the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> analysis" --area analysis`.
   Every artefact lands in that folder. Nothing is written into the analysed repository,
   and no build, test, or git command is run against it.
2. Delegate the eight phases to `repo-analyst`, using `code-explorer` for any trace that
   outgrows one context: structure and stack, feature inventory, API surface, data models,
   authentication and authorization, dependencies and integrations, Feature Profiles,
   cross-feature map. Complete all eight. A phase that found nothing is recorded as empty,
   never filled in from expectation.
3. Write the analysis document into the work-order folder from
   `{{PIPELINE_ROOT}}/core/templates/docs/`, with a `Critical Findings` section only if a
   security or data-loss defect was actually observed.
4. Produce a **Feature Profile** for every feature in the inventory (the `feature-profile`
   skill, nine parts). A feature named without a profile is an incomplete deliverable.
5. Collect the source-reference index — every file read, its line ranges, and what each
   one established — as the evidence the rest of the set is checked against.
6. `narrative-curator` scores the profiles: one-sentence test, value articulated, use cases
   and edge cases present, no name-only references. Rewrite what it fails.
7. `factuality-validator` checks the claims against the index and the source. It did not
   write the document and it never does.
8. Report the counts (features, endpoints, entities, profiles), what confidence each domain
   carries, and which downstream commands the analysis can now support.
