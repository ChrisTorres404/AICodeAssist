---
description: Consumer-facing developer documentation — quickstart, task guides, reference, concepts — plus a placement manifest and a navigation proposal. Usage: /docs-developer [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `developer-docs` skill. Written for someone who will never open this repository.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> developer docs" --area docs`.
2. `developer-experience-writer` identifies the integration paths that actually exist — client
   library, HTTP, or both — and writes each tier in order:
   **quickstart** (three to five steps, working call in under five minutes),
   **task guides** (one per common task, with prerequisites, decisions, and verification),
   **reference** (every parameter, error, and configuration option),
   **concepts** (only where the mental model is not obvious from the guides).
3. Every sample carries authentication and error handling. Every replaceable value is prefixed
   and says where the reader gets it. Internal class, module, and work-order names never appear.
4. Every error documented has a status, a body, a plain-English cause, and the fix.
5. `api-reference-writer` verifies the reference tier against the route and schema files.
6. Write the **placement manifest**: each produced file mapped to its path in the target
   documentation tree. Write the **navigation proposal** separately — proposed entries, at most
   three levels deep, organised by task. Propose; do not edit the target repository.
7. `critical-reviewer` checks for over-claims and status drift; `factuality-validator` confirms
   every endpoint, shape, and configuration item against source.
8. Report the tiers produced, the integration paths covered, and the orphan or broken
   cross-links the review found, resolved.
