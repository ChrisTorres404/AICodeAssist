# {{PROJECT_NAME}} — Global Project Rules

The long form of the short rules in `{{PIPELINE_ROOT}}/core/rules/common/`.
Those rules are always loaded and state each rule once; this document carries
the reasoning, the worked examples, and the checklists. Where the two could
be read as disagreeing, the short rule wins.

Read this before starting any work on {{PROJECT_NAME}}.

---

## Work Order System

Every non-trivial change is a work order: a folder, never a loose file.

**Full methodology:** `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md`
**Templates:** `{{PIPELINE_ROOT}}/core/templates/workorders/`

### The driver creates the folder

Do not hand-assemble a work order. The driver knows what each size requires
and refuses to close one without evidence.

```bash
wo new "<title>" --size trivial|small|standard|large --area <area> --priority P1
wo status <number>          # which documents exist, which are missing
wo verify <number> --run <suite.sh>
wo close <number>           # refuses without a VERIFICATION document
```

A `standard` work order is a folder holding a SPEC, a CHECKLIST, a
TASK-BREAKDOWN, and a Prompt; VERIFICATION is added by `wo verify` and the
CLOSEOUT by `wo close`. `--size` right-sizes that: a two-line fix does not
need four documents, and no size ever waives the verification.

### Never

- A work-order `.md` file loose in a parent directory
- A work order without a folder
- A folder missing the documents its size requires
- A section left as a template placeholder

### Good examples

Any promoted work order with a complete SCTPVC lifecycle. Find them with
`pack index` and `pack show WO-####`.

### Before a work order counts as created

- [ ] Folder exists, named `WO-XXXX-<descriptive-name>`
- [ ] Every document the size requires exists
- [ ] Every placeholder is replaced with real content
- [ ] The area and priority are recorded

---

## Documentation Placement

The goal is that any agent or person can predict where a document lives
without searching for it.

### Allowed roots for new documents

| Kind | Location |
|---|---|
| Anything describing one work order | `{{WORKORDERS_DIR}}/WO-XXXX-<name>/` |
| Anything describing one bug | `{{BUGS_DIR}}/BUG-XXXX-<slug>/` |
| Architecture, design, usage, testing notes | `{{DOCS_DIR}}/` |
| Agent and analysis outputs | `{{WORKSPACE_DIR}}/Agents/` |
| Session handoffs | `{{SESSIONS_DIR}}/active/` |

Design documents are grouped by domain under `{{DOCS_DIR}}`, one folder per
domain, for example `{{DOCS_DIR}}/Architecture/`, `{{DOCS_DIR}}/Security/`,
`{{DOCS_DIR}}/Testing/`.

### Forbidden locations

Never create a new `.md` file inside application or library source trees.
Documentation there drifts out of date and nobody finds it. Updating a
`README.md` that already exists in a source tree is allowed when asked for
explicitly.

### When you are unsure

1. Tied to one work order or bug? Its folder.
2. Design, architecture, or testing? `{{DOCS_DIR}}`.
3. Neither? Ask. Source trees are never the fallback.

---

## Never Hallucinate

Work only with facts you have verified in this repository.

Before referencing any file, function, class, component, entity, table,
column, endpoint, or configuration key:

- Confirm it actually exists, in the codebase or in the live schema
- Search the repository for it first
- If you are unsure, search before assuming

If what you wanted does not exist:

- Search for an equivalent or a near-miss implementation
- Prefer reusing or extending what is there
- Do not invent an API, a component, or a column to make the story work

This is the single most expensive failure mode with AI agents. A plausible
reference to something that does not exist costs more than an admitted gap.

---

## Frontend Structure

The UI standards live in `{{PIPELINE_ROOT}}/core/rules/ui/` and load
automatically whenever a UI stack is present:

| File | Covers |
|---|---|
| `structure.md` | Feature-directory layout, import paths, where a new file goes |
| `components.md` | Design-system use, reusable props, states, work-order headers |
| `refactoring.md` | Line limits that make extraction mechanical |
| `verification.md` | What to check before a UI change is called done |

Do not restate those rules here or in an application's own documentation.
The short version: all feature code goes in a feature directory; a component
that exists is reused, not duplicated; page 150 lines, component 200, modal
50, form 80, table 100, and over the limit means extract.

Record this project's specifics — design-system name, component library,
directory root — in `{{PIPELINE_ROOT}}/core/agents/overlays/` so every UI
agent applies them, rather than in prose that nothing enforces.

### After changing UI code

Run the project's type-check and linter over the changed files and fix
everything they report before calling the work done. The project's commands
are recorded in the project `CLAUDE.md`.

---

## Database Guards

When working with schema, queries, models, repositories, or migrations:

### Always verify against the live schema

- The table exists
- The columns exist and have the types you assumed
- The keys, constraints, and relationships are what you think they are
- The change is scoped to the right schema or namespace

Models drift from the database. When the two disagree, the database is the
fact and the model is the bug.

### Migrations

- Manual queries are for inspection, never for a schema change
- Every schema change gets a migration file, checked in, run through the
  project's own migration command
- Follow the naming conventions already in the migration directory

### Reject or correct

- A reference to a table or column that does not exist
- An assumed type that the schema contradicts
- A schema change with no migration
- A change that crosses a schema or namespace boundary without saying why

### Destructive operations

Never drop or delete a database, schema, or table unless the user has asked
for that specific action in this conversation. If a migration fails, stop and
ask. Do not reset or recreate to make an error go away.

---

## API Guards

When working on endpoints, handlers, services, request or response models,
middleware, or interceptors:

### Always verify

- The models the endpoint touches exist
- Request and response shapes reference real fields
- The services and repositories called exist and have the signatures used

### Stay consistent with

- The project's existing authorization checks
- Its route registration and versioning patterns
- Its response envelope: one shape for every response, carrying a status
  indicator, the payload, an error field, and pagination metadata where it
  applies

### Every API change

- Matches the conventions of the endpoints beside it
- Carries a traceability comment naming the work order and the reason

### Reject or correct

- An invented model or field that the schema does not have
- An endpoint that skips the authorization the rest of the surface applies
- A call to a service, method, or route that does not exist

When unsure, read the nearest existing endpoint and follow it.

---

## UI/UX Guards

### Search before creating

Before writing any component, search for one that already does the job.

- Fully satisfies the need: reuse it as it is
- Partly satisfies it: extend it
- Nothing close exists: only then write a new one

Two components doing the same thing is a defect, not a convenience.

### Structure and reuse

- One design system, one styling system, no ad-hoc styling beside it
- Components take props; a component hardcoded to one screen is a page
  fragment, not a component
- Layout, logic, and presentation stay separable
- Feature UI goes in the feature's own directory, route components in its
  pages directory

Full rules: `{{PIPELINE_ROOT}}/core/rules/ui/`.

---

## Work Order Traceability

Every code change traces to a work order. For each new or substantially
modified block, record the work order id, the date, what the code does, why
it exists, and any related work order.

```
// [WO-0021] 2026-01-14
// Added per-account routing for outbound notification providers.
// Reason: accounts need to override the default provider configuration.
// Related: WO-0019 (notification template refactor)
```

The same comment in SQL:

```sql
-- [WO-0030] 2026-01-14
-- Backfilled is_active for existing accounts.
-- Reason: align existing records with the new activation workflow.
-- Related: WO-0028 (account onboarding endpoint)
```

Use the comment syntax of the language you are in. Commit messages lead with
the same id: `WO-0021: add per-account provider routing`.

---

## Pre-Work Checklist

Before starting any task:

1. Read this document and the short rules in `{{PIPELINE_ROOT}}/core/rules/common/`
2. Search the packs for precedent: `pack search "<problem>"`
3. Search the codebase for an existing implementation
4. Verify the database objects exist, if the work touches data
5. Check the real directory structure, if the work touches UI
6. Decide where new files go before creating any
7. Add traceability comments as you write
8. Run a validator agent before declaring the work done

---

## Security Rules

Principles, not framework code. They hold whatever the stack is.

### Machine authentication is opt-in, per endpoint

Machine-to-machine credentials — API keys, service tokens, signed webhook
secrets — are enabled on the specific endpoints that need them and nowhere
else. Never apply a machine-auth check globally, and never suggest it.

Human authentication and machine authentication are separate paths with
separate credentials. Mixing them means a user-facing endpoint can be driven
by a key that was never meant to reach it, and a machine endpoint can be
driven by a browser session. Explicit beats implicit; a misapplied global
guard is discovered by an incident, not by a test.

### Authorization is checked against the resource

Authenticating the caller answers who they are. Authorization answers whether
*this* caller may act on *this* record. Check it against the record being
touched, on every protected path, including the ones that only read.

A check that runs on the list endpoint and not the detail endpoint is not a
check. A check derived from a value the client supplied is not a check.

### Secrets come from configuration

Keys, passwords, tokens, and connection strings come from environment
variables or a secret manager, are validated as present at startup, and never
appear in source, in logs, in error messages, or in a test fixture. Anything
that may have leaked is rotated, not merely deleted.

### At the boundary

- Validate every input where it enters the system
- Parameterize every query
- Escape every output that reaches a browser
- Protect state-changing requests against cross-site request forgery
- Rate-limit anything abusable
- Let error messages say what the caller did wrong and nothing about the
  internals

### When you find something

Stop, bring in the security role, fix the critical finding before anything
else, rotate what was exposed, then search the codebase for the same pattern
elsewhere. Findings are rarely unique.

Checklist form: `{{PIPELINE_ROOT}}/core/rules/common/security.md`.

---

## Validator Agents

A validator is never the agent that did the work. Call one before marking
anything complete.

| Use | Agent |
|---|---|
| Final check before completion — files exist, structure is right, nothing hallucinated | `project-validator-expert` |
| Any database work, before the change | `database-validator-expert` |
| Any UI work — directories, duplication, imports | `frontend-validator-expert` |
| Security-sensitive change | `owasp-top10-expert` |
| Code quality review of a finished change | `code-reviewer` |
| Before anything leaves the machine | `release-sanitizer` |

Routing for everything else is in `{{PIPELINE_ROOT}}/core/rules/common/agents.md`
and `troubleshooting.md`.

---

## Reference Examples

There is no canonical example feature. Before building:

1. `pack search "<problem>"` — a solved, tested, closed-out work order beats
   a blank template, and the pitfalls are already recorded.
2. Find the nearest existing feature in this codebase and read it end to end:
   its directory layout, its naming, its error handling, its tests.
3. Follow it. Consistency with what is here matters more than what you would
   have chosen on a blank page.

---

When in doubt, search first. Never assume. Never hallucinate.
