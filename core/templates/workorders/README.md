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

### Alternative Main Spec Template

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-MAIN.md` | High-level work order spec (less detailed) | Simple WOs without code |

### Specialized Templates (Use when applicable)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-SDK-IMPLEMENTATION.md` | SDK resource/method design | WO involves SDK work |
| `WO-TEMPLATE-UI-IMPLEMENTATION.md` | UI component specifications | WO involves frontend UI work |

---

## How to Create a New Work Order

Do not copy these templates by hand. The driver renders the right set for the
size you choose, numbers the work order, and records the routing.

```bash
pack search "<problem>"                      # precedent first, always
wo new "<title>" --size standard --area backend --priority P1
wo new "<title>" --size large --sdk --ui     # adds the specialized documents
```

Then:

1. **Fill in the SPEC before writing code.** A spec written afterwards is a
   description, not a specification.
2. **Replace every `[placeholder]`** with verified content. A heading with a
   bracket left in it is an unfinished document.
3. **Track state with the driver**: `wo start`, `wo block`, `wo note`,
   `wo status`.
4. **Close with evidence**: `wo verify <n> --run <suite>` then `wo close <n>`.
   The closeout is generated; it is refused without a verification document.

`WO-TEMPLATE-MAIN.md` is the lighter alternative to the SPEC for a work order
with no code design to record; `--size trivial` and `--size small` use the
lighter shapes automatically.

---

## Good Examples

There is no canonical list. Search for the nearest precedent:

```bash
pack wo "<problem>"      # work orders across every installed pack
pack index               # everything, by completeness
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
the project `CLAUDE.md` once you have. There is no universal scheme.

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
