# Next Session Template

The blank fill-in copy of the handoff. Same eight sections as
`SESSION-HANDOFF-TEMPLATE.md`, with the guidance stripped out: copy this one
when you already know the format and want a form to type into. Copy
`SESSION-HANDOFF-TEMPLATE.md` instead when you want each heading to tell you
what belongs under it. The rules the two share are in
`{{PIPELINE_ROOT}}/core/instructions/02-next-session-rules.md`.

Save the filled-in copy to
`{{SESSIONS_DIR}}/active/next-session--<context>--YYYY-MM-DD--HHMM.md`. Use
every heading; write "N/A" where a section does not apply rather than deleting
it. Do not rename, reorder, or summarize sections — the value of the format is
that a fresh session can rely on it.

---

# NEXT SESSION HANDOFF

**Filename:** `next-session--<context>--YYYY-MM-DD--HHMM.md`
**Location:** `{{SESSIONS_DIR}}/active/`

---

## 1. Project Context

- **Project Name:**
- **Repo Root:**
- **Current Branch:**
- **Active Work Order(s):**
    - `WO-XXXX` —
- **High-Level Goal of This Work:**

---

## 2. Summary of This Session

### 2.1 High-Level Session Summary

-
-
-

### 2.2 Key Design Decisions

- **Decision:**
  **Reason:**
- **Decision:**
  **Reason:**

---

## 3. Code Changes This Session

### 3.1 Backend / API Changes

- **File(s):**
    - `{{API_APP}}/src/`
- **What Changed:**
- **Important Functions / Classes / Endpoints:**
- **Notes / Gotchas:**

### 3.2 Frontend / UI Changes

- **File(s):**
    - `{{ADMIN_APP}}/src/`
    - `{{WEB_APP}}/src/`
- **What Changed:**
- **Important Components / Hooks:**
- **UX / Behavior Notes:**

### 3.3 Shared / Types / Utilities

- **File(s):**
    - `{{SDK_PKG}}/src/`
- **What Changed:**
- **Impact:**

---

## 4. Data & Integration Details

### 4.1 Database / Schema Changes

- **Tables touched/added/modified:**
- **Columns touched/added/modified:**
- **Constraints / indexes touched/added/modified:**
- **Relationships / Invariants touched/added/modified:**
- **Migrations / Seed data touched/added/modified:**

### 4.2 API Contracts

- **Endpoint:** `METHOD /path`
    - **Auth:**
    - **Request Structure:**
    - **Response Structure:**
    - **Error Cases:**

---

## 5. Current State of Work Order(s)

- **WO-XXXX — [Title]:**
    - **Status:** in-progress | partially complete | blocked
    - **Completed This Session:**
    - **Still TODO (for this WO):**
    - **Blocked By / Dependencies:**
    - **Acceptance Criteria Mapping:**

---

## 6. Known Issues, Risks & Edge Cases

- **Known Issues:**
- **Risks:**
- **Edge Cases Still Unhandled:**

---

## 7. How to Resume in the Next Session

- Step 1: Read this entire handoff document carefully.
- Step 2: Confirm the active work order(s) and current branch / area of the code.
- Step 3: Re-state your understanding of the project context, the goal of the
  active work, and what was done vs. what is left.
- Step 4: Propose a short, ordered plan (3-7 steps) for what to implement next.
- Step 5: Wait for my confirmation before changing any code.

Concrete next steps:

- [ ]
- [ ]
- [ ]

---

## 8. Minimal Bootstrap Prompt for Next Session

> **NEXT SESSION BOOTSTRAP PROMPT**
>
> You are continuing work on: `[Project Name]`
> Active Work Order(s): `WO-XXXX — [Title]`
> Your first task: Read the full "NEXT SESSION HANDOFF" document I provide next, then:
> 1. Summarize your understanding of the project and current goal.
> 2. Summarize what was completed previously.
> 3. List 3-7 concrete next actions.
> 4. Wait for my confirmation before making any code changes.
