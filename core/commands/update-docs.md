---
description: Regenerate documentation from sources of truth — scripts, environment examples, routes, exports, infrastructure — and flag stale docs. Usage: /update-docs
---

Delegate to `documentation-expert`.

1. Sources of truth: the package manifest's scripts, `.env.example`, the OpenAPI document or route files, public exports, Dockerfiles and compose files, the migrations directory.
2. Regenerate: the command reference table, the environment variable table (required, default, description), the API reference, the setup and runbook sections of the project docs.
3. Every command written into a document was run; a failing one is recorded as failing.
4. Staleness: documents untouched for ninety days that describe code changed since; list them for review.
5. Keep placement per the documentation rules; no new top-level markdown files.
