# System instructions — next-session handoff rules

These are the authoritative rules for how to respond when the user enters the
command:

```
nextSession
```

The slash command `/next-session` and the `session-handoff` skill are the same
procedure under a different trigger. This document MUST be followed *exactly*.

---

# 1. Purpose of nextSession

The `nextSession` command generates a **continuation handoff packet** that
contains everything needed for a new session to continue development without
losing context.

It must:

- summarize the entire current session
- include all technical details
- record decisions, changes, and remaining tasks
- embed API, database, and code references
- be self-contained
- prevent the next model from going rogue
- allow the user to resume work immediately

---

# 2. File storage location

All next-session documents live at:

```
{{SESSIONS_DIR}}/active/
```

When the command runs, you MUST output the correct filename so the user can
save it properly.

---

# 3. File naming convention (MANDATORY)

Every next-session file MUST be named using:

```
next-session--<context>--YYYY-MM-DD--HHMM.md
```

### Where:

### `next-session`
Constant prefix.

### `<context>` (required)
One of:

- A work order:
    - `WO-XXXX`
- A feature or area:
    - `api-auth-refresh`
    - `admin-ui-navigation`
    - `db-migration-users`
- Multiple work orders:
    - `WO-XXXX+WO-YYYY`

If the user does not specify context, infer the dominant work order or feature.

### `YYYY-MM-DD`
ISO date.

### `HHMM`
24-hour time (no colon).

### Example filenames:

```
next-session--WO-XXXX--2026-01-09--1420.md
next-session--api-rbac-refactor--2026-01-09--1705.md
next-session--db-migration-orgs--2026-01-10--0830.md
```

---

# 4. Rules for running nextSession

When the user types `nextSession`, you MUST:

### 4.1 STOP all normal work

- No new code
- No implementation
- No refactoring
- No architecture changes
- No questions

You ONLY generate the next-session handoff.

---

### 4.2 The output MUST contain TWO SECTIONS:

## (A) The filename
This MUST appear at the top in this exact format:

```
**Filename:** next-session--<context>--YYYY-MM-DD--HHMM.md
**Location:** {{SESSIONS_DIR}}/active/
```

## (B) The full structured document
You MUST output the "NEXT SESSION HANDOFF" markdown document EXACTLY following
the template below.

---

# 5. ABSOLUTE RULES

- Use ALL headings
- Use exact formatting — do not modify section names
- If something does not apply, write "N/A" rather than omitting the heading
- Write in detailed, technical language
- Include file paths, method names, components, database columns, and API information
- The document must be enough for a fresh session to continue instantly
- No missing sections
- No summarizing the template
- No creative license

---

# 6. NEXT SESSION HANDOFF TEMPLATE (USE EXACTLY)

The fillable copy of this template is shipped at
`{{PIPELINE_ROOT}}/core/templates/sessions/NEXT-SESSION-TEMPLATE.md`; the same
structure with inline guidance on what belongs under each heading is at
`{{PIPELINE_ROOT}}/core/templates/sessions/SESSION-HANDOFF-TEMPLATE.md`. Paste
this EXACT template in your output. Do NOT rename, remove, or reorder sections.

---

# NEXT SESSION HANDOFF

**Filename:** `next-session--<context>--YYYY-MM-DD--HHMM.md`
**Location:** `{{SESSIONS_DIR}}/active/`

---

## 1. Project Context

- **Project Name:** [short name]
- **Repo Root:** `[repo path or N/A]`
- **Current Branch:** `[branch or N/A]`
- **Active Work Order(s):**
    - `WO-XXXX` — [Title]
- **High-Level Goal of This Work:**
  One-paragraph description of WHAT and WHY.

---

## 2. Summary of This Session

### 2.1 High-Level Session Summary
3-8 bullet points explaining:

- what was done
- what was implemented
- decisions made
- bugs found
- progress made
- blockers

### 2.2 Key Design Decisions
For each:

- **Decision:**
- **Reason:**

---

## 3. Code Changes This Session

### 3.1 Backend / API Changes

- For each change:

- **File(s):**
    - `{{API_APP}}/src/...`
    - `...`
- **What Changed:**
    - Added/updated controllers, services, DTOs, entities, middleware, guards, etc.
- **Important Functions / Classes / Endpoints:**
    - `POST /api/...` — what it does, inputs, outputs, auth rules.
    - `SomeService.someMethod()` — purpose and key logic.
- **Notes / Gotchas:**
    - Anything future-you must remember to avoid bugs.

### 3.2 Frontend / UI Changes

- For each change:
- **File(s):**
    - `{{ADMIN_APP}}/src/features/...`
    - `{{WEB_APP}}/src/...`
- **What Changed:**
    - New pages, components, hooks, modals, forms, navigation, etc.
- **Important Components / Hooks:**
    - `FeatureXPage` — what it renders, main flows.
    - `useSomethingHook()` — what it manages (state, async calls).
- **UX / Behavior Notes:**
    - Form validation, loading states, error handling, redirects, edge cases.

### 3.3 Shared / Types / Utilities

- **File(s):**
    - `{{SDK_PKG}}/src/...`
    - `packages/shared-types/src/...`
- **What Changed:**
    - Types/interfaces, helpers, constants, error types, etc.
- **Impact:**
    - Which parts of the system depend on these utilities now.

---

## 4. Data & Integration Details

### 4.1 Database / Schema Changes

- **Tables touched/added/modified:**
  - Table: `...`
- **Columns touched/added/modified:**
  - Columns: `...`
- **Constraints / indexes touched/added/modified:**
  - Constraints / indexes: `...`
- **Relationships / Invariants touched/added/modified:**
  - Describe important FKs, uniqueness rules, and business rules enforced.
- **Migrations / Seed data touched/added/modified:**
  - Migrations: `...`
  - Seed data: `...`

### 4.2 API Contracts

For any important API endpoints (new or changed):

- **Endpoint:** `METHOD /path`
- **Auth:** `public | authenticated | role/permission required (list)`.
- **Request Structure:**
    - Body/params/query outline with key fields + types.
- **Response Structure:**
    - Success shape.
- **Error Cases:**
    - Important error shapes and when they occur.

---

## 5. Current State of Work Order(s)

For each relevant work order:

- **WO-XXXX — [Title]:**
    - **Status:** in-progress | partially complete | blocked
    - **Completed This Session:**
        - Short bullet list tied to acceptance criteria where possible.
    - **Still TODO (for this WO):**
        - Detailed bullet list of remaining tasks.
    - **Blocked By / Dependencies:**
        - Anything needed (decisions, data, other work orders, external systems).
    - **Acceptance Criteria Mapping:**
        - Acceptance criteria: `...`

---

## 6. Known Issues, Risks & Edge Cases

List all relevant items, for example:

- **Known Issues:**
    - Bug descriptions with where/how to reproduce.
- **Risks:**
    - Tech debt, performance concerns, security concerns, coupling, etc.
- **Edge Cases Still Unhandled:**
    - Explicitly list flows that are NOT covered yet.

---

## 7. How to Resume in the Next Session

Write this section as **instructions to the agent running the next session**:

- Step 1: Read this entire handoff document carefully.
- Step 2: Confirm the active work order(s) and current branch / area of the code.
- Step 3: Re-state your understanding of:
    - The project context.
    - The goal of the active work.
    - What was done vs. what is left.
- Step 4: Propose a short, ordered plan (3-7 steps) for what to implement next.
- Step 5: Wait for my confirmation before changing any code.

Include a short bullet list of **concrete next steps**, for example:

- [ ] Implement missing validation for `POST /api/...`
- [ ] Wire UI form to new endpoint
- [ ] Add tests for ...
- [ ] Update WO-XXXX with final status once complete

---

## 8. Minimal Bootstrap Prompt for Next Session

At the end of the handoff, provide a small block I can copy into the next
session as-is, e.g.:

> **NEXT SESSION BOOTSTRAP PROMPT**
>
> You are continuing work on: `[Project Name]`
> Active Work Order(s): `WO-XXXX — [Title]`
> Your first task: Read the full "NEXT SESSION HANDOFF" document I provide next, then:
> 1. Summarize your understanding of the project and current goal.
> 2. Summarize what was completed previously.
> 3. List 3-7 concrete next actions.
> 4. Wait for my confirmation before making any code changes.

---

# 7. End of system instructions

Use this exact structure every time the user types `nextSession`.
