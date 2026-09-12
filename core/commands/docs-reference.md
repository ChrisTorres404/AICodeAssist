---
description: Reference-grade technical documentation — every endpoint, data model, configuration item, and error code, each traced to source. Usage: /docs-reference [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `developer-docs` skill. Requires a completed `/analyze-repo`; the API surface and
data-model phases are the input.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> technical reference" --area docs`.
2. `api-reference-writer` documents the surface from the route and schema files themselves:
   method, path, authentication, request shape, response shape, status codes, rate limits.
   Shapes come from the type or schema definition, never from the entity it resembles.
3. `documentation-expert` assembles the rest against the reference template in
   `{{PIPELINE_ROOT}}/core/templates/docs/`: scope, architecture detail, data models,
   authentication and authorization, configuration, dependencies, integration points, error
   codes with cause and resolution, operational considerations, source references.
4. Every endpoint, shape, and configuration item carries a `<!-- SOURCE: path:L12 -->` comment.
   An item that cannot carry one is omitted, not approximated.
5. Error codes come from the code that raises them. An error nobody can trigger is not an
   error code, it is an invention.
6. `factuality-validator` re-derives a sample of endpoints and shapes from source and reports
   any divergence as blocking; `critical-reviewer` scans for over-claims and status drift.
7. Report the counts documented, the endpoints found but deliberately excluded as internal,
   and anything the analysis surfaced at LOW confidence and this document therefore omits.
