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

### Required folder structure (non-negotiable)

```
{{WORKORDERS_DIR}}/WO-XXXX-[Descriptive-Name]/
├── WO-XXXX-SPEC.md              # Main specification (REQUIRED)
├── WO-XXXX-CHECKLIST.md         # Implementation checklist (REQUIRED)
├── WO-XXXX-TASK-BREAKDOWN.md    # Task breakdown with estimates (REQUIRED)
├── WO-XXXX-Prompt.md            # AI implementation prompt (REQUIRED)
├── WO-XXXX-VERIFICATION.md      # Test verification (REQUIRED before closeout)
└── WO-XXXX-CLOSEOUT.md          # Closeout report (REQUIRED on completion)
```

### Work order creation workflow

When the request is "create a work order to [task]", these steps are mandatory
and in this order:

1. **Analyse the codebase first.** Search for what exists, read the data model,
   find the related endpoints, and map the dependencies on other work orders.
2. **Open it with the driver**, which creates the folder, allocates the number,
   and renders every document the size requires from its template:

   ```bash
   wo new "<Title>" --size standard --area <area> --priority P1
   ```

3. **Fill in all sections** — no placeholders left behind.
4. **Verify the required documents exist** before calling it created:

   ```bash
   wo status <number>
   ```

### Never

- A work-order `.md` file loose in a parent directory
- A work order without a folder
- A folder missing the documents its size requires
- A section left as a template placeholder

### Good examples

Any promoted work order with a complete SCTPVC lifecycle. Find them with
`playbook index` and `playbook show WO-####`.

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

### Work order document placement examples

If a document describes one work order, it lives in that work order's folder —
not beside it, and not in a general documentation tree:

```
{{WORKORDERS_DIR}}/WO-0204-Access-Policy-Enforcement/WO-0204-IMPLEMENTATION-COMPLETE.md
{{WORKORDERS_DIR}}/WO-0203-Session-Model-Alignment/WO-0203-Session-Smoke-Tests.md
```

### Design and usage documents

Use the documentation root for architecture, security, authorization behaviour,
usage examples, and testing notes, grouped by domain:

```
{{DOCS_DIR}}/{Domain}/{DocName}.md
```

```
{{DOCS_DIR}}/Security/Access-Policy-Decorators-Usage.md
{{DOCS_DIR}}/Auth/Session-and-Token-Model.md
{{DOCS_DIR}}/Testing/Auth-Session-Flow-Smoke-Tests.md
```

### Forbidden locations

New `.md` files must never be created in an application or library source
tree:

```
apps/**
apps/**/src/**
src/**
packages/**
```

Never create a new `.md` file inside application or library source trees —
`apps/**`, `src/**`, `packages/**`, or whatever this project calls them, at any
depth. Documentation there drifts out of date and nobody finds it. Updating a
`README.md` that already exists in a source tree is allowed when asked for
explicitly.

Full agent-by-agent placement rules, including where each agent's analyses and
validator reports go: `{{PIPELINE_ROOT}}/core/methodology/AGENT-OUTPUT-STANDARDS.md`.

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

## Implementation Order

A feature is built from the contract outwards, never the other way round:

```
1. Backend      the API endpoint, its model, its authorization, its tests
2. Client       the typed client library or SDK method that calls it
3. Interface    the UI that consumes the client
```

The backend defines the contract. The client gives every consumer one typed way
to reach it. The UI consumes the client rather than hand-rolling requests.

Never skip a layer. A UI built before the client duplicates request logic that
then drifts; a client built before the endpoint encodes a contract nobody has
agreed to. Where a project has no client library layer, the order is backend
then interface, and the interface still goes through one shared request module.

Each layer is verified before the next one starts. Finding a contract mistake
in the endpoint's own tests costs minutes; finding it from the UI costs a day.

---

## Develop Locally First

```
1. Change the code  →  2. Verify locally  →  3. Promote to the
   containerized or production-like environment  →  4. Verify again
```

Iterating against the local environment is faster and debuggable. The
production-like environment stays production-like precisely because it is not
where the experimenting happens. Both verifications are real runs; promoting a
change is not the same as testing it.

---

## Code Quality Standards

Production-level code only. This is the rule the others exist to protect.

1. **No hallucinated code.** Verify that the file, table, column, method, or
   route exists before referencing it.
2. **No placeholder implementations.** Every function is complete.
3. **No fake outputs.** Report only what a real execution produced.
4. **No assumptions.** Investigate when unsure.
5. **Verify everything.** Existence is checked, not inferred.

### What "production-level" means

- The code handles its edge cases
- Error handling is implemented, not deferred to a comment
- Types are complete and correct
- Queries reference real tables and columns
- Imports reference files that exist
- Tests can actually run against the real system

### What is not accepted

- `// TODO: implement this later`
- `throw new Error('Not implemented')`
- Code referencing a file, table, or method that does not exist
- Test results that were never executed
- "Should work" in place of a verification

If you cannot verify something exists, investigate or ask. Neither costs as
much as a confident reference to something imaginary.

### Pre-implementation checklist

Before writing any code:

- [ ] **Configuration over hardcoding** — settings and constants, no magic numbers
- [ ] **Error handling planned** — clear messages, the right exception types
- [ ] **No debug or dev-only code paths** — no stray printing, no test stubs,
      no fallback that only exists to make a demo work
- [ ] **Following the existing pattern** — the nearest similar code was read first

### Self-review before declaring done

Before marking any work complete:

- [ ] **Read every changed file, line by line** — not the diff summary, the files
- [ ] **Debug logging removed** — the project's logger, at the right level
- [ ] **No magic numbers** — extracted to configuration or constants
- [ ] **Proper typing** — no escape-hatch types, validation where input enters
- [ ] **Error handling complete** — clear messages, correct exception types
- [ ] **Dead code and parallel copies removed** — the old path is gone, not kept

### Production mindset questions

Three questions, asked before calling anything finished:

1. **Would I deploy this to production right now?** If not, fix it first.
2. **Would a reviewer approve this?** No shortcuts, no bandaids.
3. **Does this match the quality of the code around it?** Consistency matters
   more than personal preference.

### Anti-patterns that have cost rework

1. **Test-driven tunnel vision.** Tests passing is not the same as production
   ready. A passing test over bad code still ships bad code. When the tests go
   green, review the implementation.
2. **Incremental patching.** Fixing the immediate symptom and moving on leaves
   the shape of the problem intact. After a fix lands, step back and read the
   whole implementation.
3. **Expedience over quality.** Debug logging left in. Values copy-pasted
   instead of abstracted. Cleanup skipped once the bug stopped reproducing.
4. **Ignoring the project's own standards.** Re-read these rules before
   declaring work complete; they exist because each of these failures happened.

### Implementation principles

The four anti-patterns above each have a corresponding habit that prevents
them. These are how the work is done, not a review step at the end:

1. **Start with the proper pattern.** Use configuration, the project's logger,
   and real error handling from the first line. Retrofitting them is a second
   pass that usually does not happen.
2. **Clean as you go.** Remove debug code the moment the problem it was added
   for is solved, not "before the commit".
3. **Self-review before completion.** Read every change with a production
   deployment in mind, not with the test result in mind.
4. **Follow the project's standards.** Re-read these rules before declaring
   work complete.

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

Do not restate those rules in an application's own documentation; the short
version is below, and `core/rules/ui/` is the authority.

### Primary rule: the features directory

All new feature-specific code goes in one place:

```
src/features/{feature-name}/
```

Never create a new feature tree as `components/{feature-name}/`,
`pages/{feature-name}/`, or `src/{feature-name}/`. Full rule:
`{{PIPELINE_ROOT}}/core/rules/ui/structure.md`.

### Directory template for each feature

```
src/features/{feature-name}/
├── pages/           # Route components for this feature
├── components/      # Feature-specific UI components
│   ├── dialogs/     # Modals and dialogs, one per file
│   ├── forms/       # Forms, one per file
│   └── tables/      # Tables, one per file
├── hooks/           # Feature-specific hooks
├── services/        # Feature-specific APIs and business logic
└── types/           # Feature-specific types
```

### Component extraction rules

Apply these limits strictly. A unit that crosses its limit is extracted; this
is a rule, not a preference. Full rule:
`{{PIPELINE_ROOT}}/core/rules/ui/refactoring.md`.

| Component type | Max lines | Action when exceeded |
|----------------|-----------|----------------------|
| Page component | 150 lines | Factor out sections into subcomponents |
| Component | 200 lines | Factor out logical sections |
| Modal or dialog | 50 lines | Extract to `components/dialogs/` |
| Form | 80 lines | Extract to `components/forms/` |
| Table | 100 lines | Extract to `components/tables/` |
| Complex section | 80 lines | Extract to a separate component |

A component that passes 100 lines has already triggered the search for
sub-components, before any of the hard limits above is reached.

### Import rules

For shared and global components, use the alias:

```typescript
// CORRECT
import { Button } from '@/components/ui/button';
import { ErrorBoundary } from '@/components/common/ErrorBoundary';
```

Within a feature, use relative imports:

```typescript
// CORRECT
import { TemplateCard } from './TemplateCard';
import { useTemplates } from '../hooks/useTemplates';
```

Never reach out of a feature with a deep relative path:

```typescript
// WRONG — a deep relative path to a shared component
import { Button } from '../../../components/ui/button';
```

### Before creating new frontend code — checklist

1. **Is this part of an existing feature?**
   Yes → put it under `src/features/{existing-feature}/...`
2. **Is this a completely new feature?**
   Yes → create `src/features/{new-feature}/` from the template above
3. **Is this truly shared UI across multiple features?**
   Only then consider `src/components/common/`
4. **Does the component exceed the line limits?**
   Apply the extraction rules above
5. **Search for an existing similar component first.**
   Exists and satisfies the requirement → reuse it.
   Exists and partially satisfies it → enhance it.
   Only create a new one when nothing suitable exists.

### Existing shared directories: use them, do not restructure them

Most codebases already have shared trees beside the feature directory —
shared components, shared services, core utilities, route-level pages. They
are there to be used. Import from them freely, and add to them when a work
order explicitly calls for a genuinely shared component.

What you may not do is grow a new feature inside them. New feature-specific
logic scattered under a shared tree is how a codebase ends up with the same
feature in three places. New feature trees go in the feature directory; the
shared trees stay shared.

Never create a nested duplicate of the application path
(`apps/<app>/apps/<app>/src/features/...`). It happens when a tool runs from
the wrong working directory, it type-checks, and it is invisible in a diff.
Check the path you are writing to before creating the first file.

Record this project's specifics — design-system name, component library,
directory root — in `{{PIPELINE_ROOT}}/core/agents/overlays/` so every UI
agent applies them, rather than in prose that nothing enforces.

### After changing UI code

Run the project's type-check and linter over the changed files and fix
everything they report before calling the work done. The project's commands
are recorded in the project `CLAUDE.md`. For a TypeScript front end that is:

```bash
cd {{ADMIN_APP}}
npx tsc --noEmit
```

Fix every type and import error it reports before marking the work complete.

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

### ORM Entities

Where the project maps tables onto objects — an entity class, a model, a
record type, whatever the layer is called here:

- The definition matches the live schema, column for column and type for type
- The naming convention is the one already used by the definitions beside it
- The relationship declarations match the real keys and constraints
- A new definition follows the existing pattern rather than introducing a
  second one

### Manual SQL

- Manual queries are fine for a quick data check, and for an emergency fix
- A manual schema change is always followed by a migration file that makes
  the same change, checked in, so the next environment gets it too
- Never leave a schema change that exists only in one database

### Migrations

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
for that specific action in this conversation. Without that explicit request,
these are forbidden:

- Dropping a database, by command-line tool or by statement
- Dropping a schema, with or without a cascade
- Dropping or truncating a table
- Any bulk delete or update without a verified `WHERE` clause
- Re-running a destructive migration to "get back to a clean state"

If a migration fails, stop and ask how to proceed. Do not reset or recreate to
make an error go away. A failed migration is recoverable; a dropped database
with the only copy of the development data is not.

A database with several schemas has several blast radii. Confirm which schema
a statement touches before running it. A typical split looks like this —
substitute the project's own names, and record them in the project
`CLAUDE.md`:

| Schema | Purpose |
|---|---|
| `public` | Default schema; the migrations table lives here |
| `auth` | Accounts, credentials, sessions |
| `org` | Organizations, tenants, membership |
| `access` | Roles, permissions, policies |
| `audit` | Audit trail and history |
| `settings` | System and per-tenant configuration |
| `notifications` | Outbound messages and delivery logs |
| `reporting` | Aggregates and exports |

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

And in JSX, where the comment has to sit inside the braces:

```jsx
{/* [WO-0042] 2026-01-14
    Created AccountActivityCard for the dashboard.
    Reason: consolidate the activity display into one reusable card.
    Related: WO-0040 (dashboard layout refactor)
*/}
```

Use the comment syntax of the language you are in. Commit messages lead with
the same id: `WO-0021: add per-account provider routing`. This is mandatory for
all code changes; the commit-traceability hook refuses a commit that cites a
work order nobody opened.

---

## Pre-Work Checklist

Before starting any task:

1. Read this document and the short rules in `{{PIPELINE_ROOT}}/core/rules/common/`
2. Search the playbooks for precedent: `playbook search "<problem>"`
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

In a framework with route decorators, that reads as one guard on one route:

```typescript
// Only on the server-to-server endpoint, never registered globally
@UseGuards(MachineAuthGuard)
@Get('/external-webhook-callback')
async handleExternalWebhook(@Req() req) {
  // machine-to-machine only; no browser session reaches this handler
}
```

The same rule in a middleware-based framework is one guard mounted on one
route, not on the router.

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

1. `playbook search "<problem>"` — a solved, tested, closed-out work order beats
   a blank template, and the pitfalls are already recorded.
2. Find the nearest existing feature in this codebase and read it end to end:
   its directory layout, its naming, its error handling, its tests.
3. Follow it. Consistency with what is here matters more than what you would
   have chosen on a blank page.

---

## Before You Start Any Work

1. Read the relevant methodology — work order, testing, or bug — in
   `{{PIPELINE_ROOT}}/core/methodology/`
2. Create the proper folder structure, with every required document, using the
   driver rather than by hand
3. Verify that the files, tables, and methods you intend to reference actually
   exist before referencing them
4. Follow the project's implementation order for a feature
5. Write behavioral tests, and execute them, before any closeout
6. Test locally first, then in the containerised environment

---

When in doubt, search first. Never assume. Never hallucinate.
