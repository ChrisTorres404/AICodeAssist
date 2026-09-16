# Agent Output Location Standards

**Purpose:** standardize where every AI agent writes its outputs, documentation,
and work products, so that a later session can find them without searching.

---

## Core Principle

**ALL agent outputs MUST go into the pipeline's configured workspace
directories.** Never the repository root. Never an application or library
source tree. This is a requirement, not a convention: an output outside these
directories is not found by the next session, is not checked by the validators,
and does not survive a handoff.

This buys four things:

- Centralized knowledge: one place to look for what an agent already worked out
- Cheap context loading: a later session points at a directory, not a search
- A clear line between generated analysis and production code
- The same organization whichever agent, tool, or model produced the file

An analysis written to the repository root is lost within a week. An analysis
written to the right directory with the right name is still useful a year later.

---

## Directory Structure

```
{{WORKSPACE_DIR}}/
├── Agents/                          # Agent-specific outputs, one folder per agent
│   ├── <agent-name>/
│   │   └── WorkOutputs/             # That agent's analyses, proposals, reviews
│   └── orchestrator/                # Coordination logs and multi-agent plans
│
├── Docs/                            # = {{DOCS_DIR}}
│   ├── Architecture/                # System and domain design, one folder per domain
│   ├── Security/
│   ├── Testing/
│   ├── Validation/                  # Validator agent reports
│   ├── Archive/                     # Historical or superseded documentation
│   ├── KnowledgeBase/               # = {{KNOWLEDGE_DIR}} — the repository described
│   ├── WorkOrders/                  # = {{WORKORDERS_DIR}}
│   │   └── WO-XXXX-<name>/
│   └── Bugs/                        # = {{BUGS_DIR}}
│       └── BUG-XXXX-<slug>/
│
├── Testing/                         # = {{TESTING_DIR}}
│   ├── suites/                      # Behavioural test suites
│   └── results/                # Execution output
│
└── Sessions/                        # = {{SESSIONS_DIR}}
    ├── active/                      # Current session work and handoffs
    └── archive/                     # Completed sessions
```

Two further branches exist, and they are installed rather than written into by
agents:

```
{{PIPELINE_ROOT}}/
├── core/instructions/               # Global instructions every agent reads
│   ├── 00-test-fixing-quick-start.md
│   ├── 01-create-work-orders.md
│   ├── 02-next-session-rules.md
│   ├── 03-e2e-test-fix-rules.md
│   ├── 04-test-fixing-agent-prompts.md
│   ├── 05-reusable-test-fixing-prompts.md
│   └── README-TEST-FIXING-SYSTEM.md
│
├── core/commands/                   # Reusable command prompts, e.g. next-session.md
│
└── core/templates/                  # Every template the drivers render from
    ├── workorders/                  # Work-order document templates
    ├── bugs/                        # Bug document templates
    ├── testing/                     # Harness, execution, verification templates
    └── sessions/                    # Session handoff templates
```

`core/instructions/` is the branch the source layout called `SystemInstructions`:
the global instructions that apply to every agent regardless of which one is
running. Agents read from it; nothing writes to it. `core/templates/` is the
templates branch: the drivers render from it, and an agent that needs a document
shape asks the driver rather than copying a template by hand.

The names above are the defaults. The authority is `pipeline.config.sh`: every
placeholder in this document resolves from it at install time, so a project that
relocates its workspace keeps these rules unchanged.

---

## Agent-Specific Output Rules

### 1. Full-platform audit agent

**Location:** `{{WORKSPACE_DIR}}/Agents/build-audit-supreme/WorkOutputs/`

```
WorkOutputs/
├── 01-repo-map.md
├── 02-backend-audit.md
├── 03-database-audit.md
├── 04-auth-and-authorization-audit.md
├── 05-frontend-audit.md
├── 06-tests-and-quality-audit.md
├── 07-infra-and-config-audit.md
└── 08-summary-and-rebuild-plan.md
```

Naming: sequential numbers, a descriptive name for the audit phase, `.md` always.
The numbering is the reading order; keep it even when a phase does not apply,
and say in that file why it was empty.

### 2. Architecture and design agents

**Location:** `{{WORKSPACE_DIR}}/Agents/<agent-name>/WorkOutputs/`

Each such agent owns one folder, subdivided by output kind:

```
WorkOutputs/
├── analyses/              # Analysis documents
├── schemas/               # Schema proposals
├── flows/                 # Flow diagrams and explanations
├── api-designs/           # API specifications
├── migrations/            # Migration plans
└── reviews/               # Code and architecture reviews
```

Naming: lowercase with dashes; a date when the document is time-sensitive
(`schema-proposal-YYYY-MM-DD.md`); a descriptive prefix (`analysis-`, `schema-`,
`flow-`, `api-`). Where an agent specializes further, keep the prefix specific
(`policy-`, `rls-`) so a directory listing reads as an index.

### 3. Synthesis across two or more design agents

When one agent's job is to reconcile competing designs, its outputs are
decisions, not proposals, and the folder says so:

```
WorkOutputs/
├── unified-architecture/  # The agreed architecture
├── merged-schemas/        # Merged schema designs
├── merged-flows/          # Merged flows
├── conflict-resolutions/  # How each conflict was resolved, and why
├── final-decisions/       # Decision records
└── integration/           # Integration plans and guides
```

Naming: `unified-` for final outputs, `comparison-` for comparisons, `decision-`
for decision records. A conflict resolution that does not record the rejected
option is not a resolution; it is a preference.

### 4. Domain and stack experts

**Location:** `{{DOCS_DIR}}/<Area>/`

| Area | Holds |
|---|---|
| `Architecture/` | Module structure, service boundaries, integration design |
| `Frontend/` | Component architecture, state management, design-system guidance |
| `Backend/` | API patterns, module structure, authentication and authorization flow |
| `Database/` | Schema overview, migration strategy, performance work |
| `Testing/` | Test strategy, harness documentation, coverage analysis |
| `DevOps/` | Build, container, pipeline, and deployment documentation |
| `Security/` | Threat models, control documentation, review findings |

```
{{DOCS_DIR}}/
├── Frontend/
│   ├── component-architecture.md
│   ├── state-management-patterns.md
│   └── design-system-guide.md
├── Backend/
│   ├── module-structure.md
│   ├── api-patterns.md
│   └── authentication-flow.md
└── Database/
    ├── schema-overview.md
    ├── migration-strategy.md
    └── performance-optimization.md
```

### 5. Validator agents

**Location:** `{{DOCS_DIR}}/Validation/`

```
Validation/
├── frontend-validation-reports/
│   └── YYYY-MM-DD-<feature-name>.md
├── database-validation-reports/
│   └── YYYY-MM-DD-<schema-or-table>.md
└── project-validation-reports/
    └── YYYY-MM-DD-WO-XXXX.md
```

Naming: always date-first, then the context — the feature, the schema object, or
the work-order number. A validation report without a date cannot be aged out.

### 6. Orchestrator

**Location:** `{{WORKSPACE_DIR}}/Agents/orchestrator/`

Holds session coordination logs, multi-agent workflow plans, and cross-system
integration plans.

Naming:

- `coordination-<initiative>-YYYY-MM-DD.md`
- `workflow-<feature-name>.md`
- `integration-plan-<systems>.md`

### 7. Work orders and bugs

Anything that describes one work order or one bug belongs in that item's own
folder, never in an agent folder:

| Kind | Location |
|---|---|
| Work-order specification, checklist, breakdown, prompt, verification, closeout | `{{WORKORDERS_DIR}}/WO-XXXX-<descriptive-name>/` |
| Bug issue, verification, closeout, prompt | `{{BUGS_DIR}}/BUG-XXXX-<slug>/` |
| Behavioural suites | `{{TESTING_DIR}}/suites/` |
| Executed test output | `{{TESTING_DIR}}/results/` |

The folder is created by the driver (`wo new`, `bug new`), not by hand. If an
agent's analysis is really about one work order, it goes in that work order's
folder and the agent folder gets nothing.

### 8. Work order standards

#### Project-wide work orders

**Location:** `{{WORKORDERS_DIR}}/WO-XXXX-<descriptive-name>/`

Every work order in the project lives in one directory, numbered, whatever
initiative it belongs to and whichever agent opened it:

```
{{WORKORDERS_DIR}}/
├── WO-0201-Schema-Migration/
│   ├── WO-0201-SPEC.md
│   ├── WO-0201-CHECKLIST.md
│   └── ...
├── WO-0202-API-Bootstrap/
└── WO-0210-Logging-System/
```

An initiative is expressed as a numbered band (`wo new --series 0200`), not as a
nested folder per initiative. `wo list` groups by number, so the band is the
grouping.

#### Agent-specific work orders: a deliberate difference

The layout this standard came from gave each agent its own
`WorkOrders/{active,completed,templates}` tree beneath its agent folder. **This
pipeline does not do that, on purpose.** There is exactly one work-order
directory, `{{WORKORDERS_DIR}}`, managed by the `wo` driver, and agent folders
carry only `WorkOutputs/`.

The reason is that a work order has two properties that cannot be maintained per
agent:

1. **Its number must be unique across the whole project.** The `wo` driver
   allocates numbers in one place, which is what makes two agents creating work
   simultaneously safe. Per-agent directories mean per-agent counters, and
   per-agent counters collide the first time two agents run at once.
2. **Its closeout guard must be enforced in one place.** `wo close` refuses a
   work order without executed verification. A second work-order tree is a
   second lifecycle nobody gates, and it is where unverified work accumulates.

So the three sub-branches map like this:

| Source layout | Here | Why |
|---|---|---|
| `WorkOrders/active/` | `{{WORKORDERS_DIR}}` + `wo list --active` | State is recorded in the work order, not in its path, so the number and folder stay stable forever |
| `WorkOrders/completed/` | `{{WORKORDERS_DIR}}` + `wo list --closed` | A closed work order is still cited by commits and suites; moving it would break every reference |
| `WorkOrders/templates/` | `{{PIPELINE_ROOT}}/core/templates/workorders/` | One set of templates that the driver renders, rather than a copy per agent that drifts |

An agent that wants work tracked opens a work order with `wo new`. Its analysis
— the thing that is genuinely the agent's own product — goes under
`{{WORKSPACE_DIR}}/Agents/<agent-name>/WorkOutputs/`.

### 9. Session documentation

#### Active sessions

**Location:** `{{SESSIONS_DIR}}/active/`

| Kind | File |
|---|---|
| Current session summary | `session-summary-YYYY-MM-DD-<topic>.md` |
| Handoff to the next session | `next-session-handoff.md` |

#### Archived sessions

**Location:** `{{SESSIONS_DIR}}/archive/`

Naming: `session-YYYY-MM-DD-<topic>.md`. A session is archived when its handoff
has been consumed by the session that followed it, not when it ends.

---

## File Naming Conventions

### General rules

1. **Lowercase with dashes:** `my-document-name.md`
2. **Date when relevant:** `YYYY-MM-DD-description.md`, date first when the
   document is a report of something that happened on a day
3. **Descriptive names:** not `doc1.md` but `rbac-implementation-guide.md`
4. **Version suffix when iterating:** `schema-proposal-v2.md`
5. **A prefix that says what kind of document it is**

### Document types

| Type | Prefix | Example |
|---|---|---|
| Analysis | `analysis-` | `analysis-authorization-gaps.md` |
| Proposal | `proposal-` | `proposal-unified-schema.md` |
| Guide | `guide-` | `guide-migration-process.md` |
| Review | `review-` | `review-api-endpoints.md` |
| Decision | `decision-` | `decision-session-strategy.md` |
| Report | `report-` | `report-test-coverage.md` |
| Summary | `summary-` | `summary-WO-XXXX.md` |

---

## Wiring This Into an Agent

An agent only follows this standard if its own definition says so. Each agent
file carries an output block naming its directory and its subdirectories:

```markdown
## Output Location Constraints

All outputs go to:
`{{WORKSPACE_DIR}}/Agents/<this-agent>/WorkOutputs/`

Subdirectories: analyses/ schemas/ flows/ api-designs/ migrations/ reviews/

File naming: lowercase-with-dashes, date when relevant, descriptive prefix.
```

The directories are created on demand; nothing breaks if they do not exist yet:

```bash
mkdir -p "{{DOCS_DIR}}"/{Architecture,Frontend,Backend,Database,Testing,DevOps,Security}
mkdir -p "{{DOCS_DIR}}/Validation"/{frontend-validation-reports,database-validation-reports,project-validation-reports}
mkdir -p "{{SESSIONS_DIR}}"/{active,archive}
```

---

## Agent Compliance Checklist

When an agent produces output, it MUST:

- [ ] Write to the correct workspace subdirectory for its kind of output
- [ ] Use the naming convention: lowercase, dashes, prefix, date where relevant
- [ ] Create the subdirectory if it does not exist
- [ ] Record the output in the agent's index or in the session handoff, so the
      next session finds it without a search
- [ ] Never write an analysis or proposal to the repository root
- [ ] Never write documentation into an application or library source tree
- [ ] Never write to a directory the project has deprecated
- [ ] Include the date in the filename when the document is time-sensitive

---

## Rollout Plan

Adopting this standard in a project that has not been following it takes four
steps, in order. The install performs the first and the fourth; the middle two
are done once, by hand, per project.

### Phase 1 — install the agent definitions

Done by `bin/install.sh`: every agent is rendered with frontmatter, a model, and
a dispatchable description, into `.claude/agents/` and any other agent directory
the project uses. Verify with:

```bash
bin/lint .
```

### Phase 2 — give each agent its output block

Each agent definition carries the block from [Wiring This Into an
Agent](#wiring-this-into-an-agent), naming its own directory and subdirectories.
An agent without that block will write somewhere reasonable-looking and wrong.

### Phase 3 — record the locations in the agent index

The project's agent index lists, for each agent, where its output goes. That is
what a person reads when they are looking for something an agent produced six
weeks ago and do not remember which agent produced it.

### Phase 4 — create the directory structure

Nothing breaks if a directory is missing, but creating them up front makes the
layout discoverable:

```bash
mkdir -p "{{WORKSPACE_DIR}}/Agents"
mkdir -p "{{WORKORDERS_DIR}}" "{{BUGS_DIR}}"
mkdir -p "{{TESTING_DIR}}"/{suites,results}
mkdir -p "{{SESSIONS_DIR}}"/{active,archive}
```

---

## Examples

### Correct

```
# A design agent analysing an authentication flow
{{WORKSPACE_DIR}}/Agents/<agent-name>/WorkOutputs/analyses/analysis-session-flow-YYYY-MM-DD.md

# A database expert writing a schema guide
{{DOCS_DIR}}/Database/schema-design-patterns.md

# The audit agent writing its repository map
{{WORKSPACE_DIR}}/Agents/build-audit-supreme/WorkOutputs/01-repo-map.md

# The frontend validator reporting on a feature
{{DOCS_DIR}}/Validation/frontend-validation-reports/YYYY-MM-DD-authorization-components.md

# Anything describing one work order
{{WORKORDERS_DIR}}/WO-XXXX-<descriptive-name>/WO-XXXX-SPEC.md
```

### Incorrect

```
# Repository root
ANALYSIS.md

# A source tree
apps/<app>/src/NOTES.md

# A deprecated location the project moved away from
docs/work-orders/analysis.md

# No date, no prefix, unclear name
{{DOCS_DIR}}/stuff.md

# Right workspace, wrong directory for the kind of document
{{SESSIONS_DIR}}/schema-proposal.md
```

---

## Enforcement

1. Every agent definition references this document, or restates its own output
   location block from it.
2. The agent index records the output location for each agent.
3. The project validator checks that outputs landed in the right place before a
   work order closes.
4. Session handoffs verify that the session's outputs are where the next session
   will look for them.

---

## When You Are Unsure

1. Does the document describe one work order or one bug? Its folder.
2. Is it an agent's own analysis or proposal? That agent's `WorkOutputs/`.
3. Is it design, architecture, or testing documentation? `{{DOCS_DIR}}/<Area>/`.
4. Still unsure? Ask the orchestrator, or use `documentation-expert`.

A source tree is never the fallback.
