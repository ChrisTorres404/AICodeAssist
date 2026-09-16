# Work Order Templates

## MANDATORY: Work Order Methodology

**Every work order in {{PROJECT_NAME}} follows this structure. No exceptions.**

---

## Required Folder Structure

Every work order MUST have its own folder with the following files:

```
WO-XXXX-[Descriptive-Name]/
├── WO-XXXX-SPEC.md                 # Technical specification (REQUIRED)
├── WO-XXXX-CHECKLIST.md            # Implementation checklist (REQUIRED)
├── WO-XXXX-TASK-BREAKDOWN.md       # Task breakdown with estimates (REQUIRED)
├── WO-XXXX-Prompt.md               # AI implementation prompt (REQUIRED)
├── WO-XXXX-CLOSEOUT.md             # Closeout report (REQUIRED on completion)
├── WO-XXXX-sdk-implementation.md   # SDK implementation details (if SDK work)
└── WO-XXXX-ui-implementation.md    # UI implementation details (if UI work)
```

---

## Template Files

### Core Templates (REQUIRED for all WOs)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-SPEC.md` | Technical specification with code examples | Always |
| `WO-TEMPLATE-CHECKLIST.md` | Implementation checklist with phases | Always |
| `WO-TEMPLATE-TASK-BREAKDOWN.md` | Task breakdown with time estimates | Always |
| `WO-TEMPLATE-PROMPT.md` | AI implementation prompt | Always |
| `WO-TEMPLATE-CLOSEOUT.md` | Closeout report template | On completion |

### Alternative Main Spec Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-MAIN.md` | High-level work order spec (less detailed) | Simple WOs without code |
| `WO-TEMPLATE-SPEC-ANALYSIS.md` | Spec shaped for an investigation rather than a build | `--area analysis` or `--area docs` |
| `WO-TEMPLATE-MASTER.md` | Every section of the methodology in one document | A cross-cutting work order best read as one argument, or handed to someone who should not have to open five files. Also the reference shape: it shows how the per-document set fits together |

### Specialized Templates (Use when applicable)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-SDK-IMPLEMENTATION.md` | Client-library resource and method design | WO touches the client library or SDK |
| `WO-TEMPLATE-UI-IMPLEMENTATION.md` | UI component specifications | WO involves frontend UI work |
| `WO-TEMPLATE-REVIEW.md` | Review record before close | Rendered by the driver when a work order needs a reviewer's sign-off |

### Closeout Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-CLOSEOUT.md` | Closeout report | On completion |
| `WO-TEMPLATE-CLOSEOUT-UI.md` | Closeout whose deliverables are components, pages, state and styles | On completion of a UI work order — `wo close` picks it automatically |

---

## How to Create a New Work Order

Do not copy these templates by hand. The driver does steps 1 to 3 for you; you
do 4 and 5. The steps are written out so you can tell whether the driver did
what it should, and so the shape is clear if you ever have to build one by hand.

### Step 1: Create the Folder

```bash
playbook search "<problem>"                  # precedent first, always
wo new "<title>" --size standard --area backend --priority P1
```

The driver picks the next free number, creates
`{{WORKORDERS_DIR}}/WO-XXXX-[Descriptive-Name]/`, and records the routing at the
top of the spec. Do not choose a number by hand — two people choosing collide.

### Step 2: Copy Core Templates (REQUIRED)

Rendered into the folder under their final names:

- `WO-TEMPLATE-SPEC.md` → `WO-XXXX-SPEC.md` (technical spec with code)
- `WO-TEMPLATE-CHECKLIST.md` → `WO-XXXX-CHECKLIST.md`
- `WO-TEMPLATE-TASK-BREAKDOWN.md` → `WO-XXXX-TASK-BREAKDOWN.md`
- `WO-TEMPLATE-PROMPT.md` → `WO-XXXX-Prompt.md`

**Alternative:** for a work order with no code design to record,
`WO-TEMPLATE-MAIN.md` → `WO-XXXX-[Title].md` in place of the SPEC. `--size
trivial` and `--size small` choose it automatically; `--area analysis` and
`--area docs` use `WO-TEMPLATE-SPEC-ANALYSIS.md` instead.

### Step 3: Copy Specialized Templates (if applicable)

```bash
wo new "<title>" --size large --sdk --ui     # adds the specialized documents
```

- `WO-TEMPLATE-SDK-IMPLEMENTATION.md` → `WO-XXXX-sdk-implementation.md` (with `--sdk`)
- `WO-TEMPLATE-UI-IMPLEMENTATION.md` → `WO-XXXX-ui-implementation.md` (with `--ui`, or `--area ui`)

### Step 4: Fill In Details

1. **Fill in the SPEC before writing code.** A spec written afterwards is a
   description, not a specification.
2. **Replace every `[placeholder]`** with verified content. A heading with a
   bracket left in it is an unfinished document.
3. **Track state with the driver**: `wo start`, `wo block`, `wo note`,
   `wo status`.

### Step 5: On Completion

**Close with evidence.** `wo verify <n> --run <suite>` writes the verification
from the suite's exit code, and then:

```bash
wo close <n>
```

- `WO-TEMPLATE-CLOSEOUT.md` → `WO-XXXX-CLOSEOUT.md`

The closeout is generated, and `wo close` is refused without a verification
document that says `EXECUTED — PASS`.

---

## Gold Standard Examples

A gold standard work order is one a later reader can implement from: a spec
with no brackets left in it, a task breakdown whose files exist, a verification
that was executed, and a closeout whose lessons are specific. Keep a short list
of yours here as you close them — one per area is enough.

| Area | Gold standard in this project |
|---|---|
| `backend` | `[WO-XXXX-<name>]` |
| `frontend` / `ui` | `[WO-XXXX-<name>]` |
| `auth` / `security` | `[WO-XXXX-<name>]` |
| `database` | `[WO-XXXX-<name>]` |

Until that list exists, there is no canonical one. Search for the nearest
precedent instead:

```bash
playbook wo "<problem>"  # work orders across every installed playbook
playbook index           # everything, by completeness
```

A promoted work order carries its spec, its verification, and the pitfalls
found along the way. Start from one whenever the problem rhymes.

---

## Non-Negotiable Rules

1. **Every WO gets its own folder** - No loose `.md` files in the parent directory
2. **All 4 required files must exist** - Main spec, checklist, task breakdown, prompt
3. **Closeout on completion** - Every completed WO must have a closeout report
4. **Consistent naming** - `WO-XXXX-[Title].md` format always
5. **No shortcuts** - This methodology ensures quality and traceability

---

## Numbering and Areas

The driver assigns the number. `--series N` keeps related work in one band, so
a multi-part effort stays together without an index document to maintain:

```bash
wo new "Report data model"        --series 1200
wo new "Report ingestion service" --series 1200     # the next free 12xx
```

Choose the bands to match this project's own domains, and write them down in
the project `CLAUDE.md` once you have. There is no universal scheme. The shape
one project arrived at, as an illustration only — yours will differ:

| Series | Theme |
|--------|-------|
| 0000-0099 | Foundation — core platform setup |
| 0100-0199 | The first subsystem |
| 0200-0299 | Authorization model |
| 0300-0399 | Public API and client library |
| 0400-0499 | The primary user-facing flows |
| 0500-0599 | The browser-side library |
| 0600-0699 | Background jobs and scheduling |
| 0700-0799 | Notifications — email, push, webhooks |
| 0800-0899 | Import, export, and bulk operations |
| 0900-0999 | Configuration and settings |
| 1000-1099 | Security hardening |
| 1100-1199 | Data model and schema migrations |
| 1200-1299 | Reporting |
| 1300-1399 | Search and indexing |
| 1400-1499 | Observability — logging, metrics, dashboards |
| 1500-1599 | Performance and capacity |
| 1600-1699 | Caching and invalidation |
| 1700-1799 | Integrations with external systems |
| 1800-1899 | Developer experience and tooling |
| 1900-1999 | Product and developer documentation |
| 2000-2099 | Build, packaging, and release |
| 2100-2199 | Admin interface |
| 2200-2299 | End-user interface |
| 2300-2399 | Accessibility and internationalization |
| 2400-2499 | Test infrastructure |
| 2500-2599 | Deployment and infrastructure |
| 3000-3099 | Compliance and audit trail |
| 3100-3199 | Support and operability |
| 3200-3299 | Usage and billing |

Leave gaps. A band that fills up is cheaper to split than to renumber.

`--area` is the other half: it records who implements, who backs them up, and
who validates, and prints the routing when the work order is opened.

| Area | Records |
|---|---|
| `backend`, `api`, `database` | The stack's backend, API, and data specialists |
| `auth`, `rbac`, `security` | The security and identity specialists |
| `frontend`, `ui`, `styling` | The stack's UI specialist and a UI validator |
| `testing`, `performance` | The testing and performance specialists |
| `cicd`, `docker` | The build and deployment specialists |
| `docs` | The documentation role |

`--area ui` and `--area frontend` also add the UI implementation document. The
validator is never the agent that implemented. Full routing table:
`{{PIPELINE_ROOT}}/core/rules/common/agents.md`.

---

## Validation Checklist

Before considering a work order "created", verify:

- [ ] Folder exists with correct name (`WO-XXXX-[Name]/`)
- [ ] Technical spec file exists (`WO-XXXX-SPEC.md`)
- [ ] Checklist exists (`WO-XXXX-CHECKLIST.md`)
- [ ] Task breakdown exists (`WO-XXXX-TASK-BREAKDOWN.md`)
- [ ] Prompt exists (`WO-XXXX-Prompt.md`)
- [ ] SDK implementation exists (`WO-XXXX-sdk-implementation.md`) - if SDK work
- [ ] UI implementation exists (`WO-XXXX-ui-implementation.md`) - if UI work
- [ ] All placeholders replaced with real content
- [ ] Dependencies listed
- [ ] Success criteria defined
- [ ] File locations specified
