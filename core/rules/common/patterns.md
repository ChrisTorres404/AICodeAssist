# Patterns

## Search before building

Before writing anything non-trivial: search the playbooks for precedent, then the
codebase for an existing implementation, then the ecosystem for a maintained
library. Adopt, extend, or compose before building. Build only informed by
what you found.

## Data access

Encapsulate storage behind a repository interface with standard operations.
Business logic depends on the interface, never on the driver.

## API responses

One envelope shape for every response: a status indicator, the payload, an
error field, and pagination metadata where it applies.

## Identifiers

Internal integer ids for joins and performance; opaque public ids for URLs and
APIs. Never expose the internal one.
