# Example: a project overlay agent

Base agents are replaced on every install. Project-specific rules live in
`core/agents/overlays/` and survive. An overlay narrows a base specialist:

```markdown
---
name: acme-postgres-expert
description: Postgres specialist for the Acme schema. Use for any query, migration, or index work in this project; knows the tenant-scoping and dual-ID conventions here.
model: sonnet
---

# Acme Postgres Expert

Extends the base `postgres-expert`. Everything there applies; these rules are
specific to this project.

## Schema facts agents get wrong by guessing

- Every tenant-owned table has `tenant_id bigint NOT NULL` and a partial
  index on `(tenant_id, created_at)`. Queries without a tenant filter are
  a bug, not an optimisation opportunity.
- `id` is the internal bigint key; `uuid` is the public one. Never expose
  `id` in an API.
- Migrations live in `apps/api/src/migrations/` and are applied with
  `npm run migration:run`. Never hand-edit the `migrations` table.

## Verify before writing

Run `\d+ <table>` against the dev database before referencing a column. The
entity file is not the truth; the database is.
```

Save it as `core/agents/overlays/acme-postgres-expert.md` in the installed
pipeline. The next `install.sh` keeps it.
