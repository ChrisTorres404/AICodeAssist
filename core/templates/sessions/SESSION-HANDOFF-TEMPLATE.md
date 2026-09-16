# Session Handoff Template

Produced by the `/next-session` command. This is the annotated copy: every
heading carries a note on what belongs under it. `NEXT-SESSION-TEMPLATE.md`
beside it is the same eight sections as a blank form, for when you know the
format already. Filename convention:

```
next-session--<context>--YYYY-MM-DD--HHMM.md
```

Saved to `{{SESSIONS_DIR}}/active/`. Use every heading; write "N/A" where a
section does not apply. Do not rename, reorder, or summarize sections — the
value of the format is that a fresh session can rely on it.

---

# NEXT SESSION HANDOFF

**Filename:** `next-session--<context>--YYYY-MM-DD--HHMM.md`  
**Location:** `{{SESSIONS_DIR}}/active/`

---

## 1. Project Context

- **Project Name:** [short name, e.g., “{{PROJECT_NAME}} Core”]
- **Repo Root:** `[repo path or N/A]`
- **Current Branch:** `[branch or N/A]`
- **Active Work Order(s):**
    - `WO-####` — [Title]
- **High-Level Goal of This Work:**  
  One-paragraph description of WHAT and WHY.

---

## 2. Summary of This Session

### 2.1 High-Level Session Summary
3–8 bullet points explaining:

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
    - `libs/utils/...`
- **What Changed:**
    - Types/interfaces, helpers, constants, error types, etc.
- **Impact:**
    - Which parts of the system depend on these utilities now.

---

## 4. Data & Integration Details

### 4.1 Database / Schema Changes

- - **Tables touched/added/modified:**
  - Table: `...`
- - **Columns touched/added/modified:**
  - Columns: `...`
- - **Constraints / indexes touched/added/modified:**
  - Constraints / indexes: `...`
- - **Relationships / Invariants touched/added/modified:**
  - Describe important FKs, uniqueness rules, and business rules enforced.
- - **Migrations/SeedDate touched/added/modified:**
  - Migrations: `...`
  - SeedData: `...`

### 4.2 API Contracts

For any important API endpoints (new or changed):

- **Endpoint:** `METHOD /path`
- **Auth:** `public | authenticated | role/permission required (list)`.
- **Request Structure:**
    - Body/params query outline with key fields + types.
- **Response Structure:**
    - Success shape.
- - **Error Cases:**
    - Important error shapes and when they occur.

---

## 5. Current State of Work Order(s)

For each relevant WO:

- **WO-#### – [Title]:**
    - **Status:** in-progress | partially complete | blocked
    - **Completed This Session:**
        - Short bullet list tied to acceptance criteria where possible.
    - **Still TODO (for this WO):**
        - Detailed bullet list of remaining tasks.
    - **Blocked By / Dependencies:**
        - Anything needed (decisions, data, other WOs, external systems).
    - - **Acceptance Criteria Mapping:**
      - Acceptance Criteria: `...`

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

Write this section as **instructions to future Claude/AI** in the next session:

- Step 1: Read this entire handoff document carefully.
- Step 2: Confirm the active WO(s) and current branch / area of the code.
- Step 3: Re-state your understanding of:
    - The project context.
    - The goal of the active work.
    - What was done vs. what is left.
- Step 4: Propose a short, ordered plan (3–7 steps) for what to implement next.
- Step 5: Wait for my confirmation before changing any code.

Include a short bullet list of **concrete next steps**, for example:

- [ ] Implement missing validation for `POST /api/...`
- [ ] Wire UI form to new endpoint
- [ ] Add tests for ...
- [ ] Update WO-#### with final status once complete
---

## 8. Minimal Bootstrap Prompt for Next Session

At the end of the handoff, provide a small block I can copy into the next session as-is, e.g.:

> **NEXT SESSION BOOTSTRAP PROMPT**
>
> You are continuing work on: `[Project Name]`  
> Active Work Order(s): `WO-#### - [Title]`  
> Your first task: Read the full "NEXT SESSION HANDOFF" document I provide next, then:
> 1. Summarize your understanding of the project and current goal.
> 2. Summarize what was completed previously.
> 3. List 3–7 concrete next actions.
> 4. Wait for my confirmation before making any code changes.
