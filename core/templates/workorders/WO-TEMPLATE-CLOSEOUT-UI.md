# WO-XXXX: Closeout Report (UI)

**Work Order:** WO-XXXX - [Title]
**Status:** COMPLETE | PARTIAL | BLOCKED
**Completed:** YYYY-MM-DD
**Duration:** [X sessions / Y hours]
**Implementer:** [Name/Agent]
**Reviewer:** [Name if applicable]

---

## Executive Summary

[2-3 sentences summarizing what was built and what a user can now do that they could not before]

**Key Outcomes:**
- [Outcome 1]
- [Outcome 2]
- [Outcome 3]

---

## Deliverables

### 1. Components

**Files Created:**
- `[path/to/component]` - [What it renders and where it is used]
- `[path/to/component]` - [What it renders and where it is used]

**Behaviour:**
- [What it does on interaction]
- [Loading, empty, and error states it covers]

### 2. Pages and Routes

**Files Created:**
- `[path/to/page]` - [The route it serves]

**Navigation:**
- [Where users arrive from]
- [Where the page can send them]

### 3. State and Data

**Files Created:**
- `[path/to/hook-or-store]` - [What it holds and who reads it]

**Behaviour:**
- [What is fetched, when, and what is shown while it is in flight]
- [What survives a reload, and what does not]

### 4. Styles and Tokens

**Files Changed:**
- `[path/to/styles]` - [What changed]

**Design System:**
- [Tokens used rather than literal values]
- [Anything new added to the shared system, and why it had to be]

---

## Testing Results

### Component Tests
- [X] tests passing

### Behavioral Tests (browser)
- [Test suite name]: PASSED/FAILED
- Evidence: `[path/to/evidence]`
- Screenshots: `[path/to/screenshots]`

### Rendering and Accessibility
- Keyboard reachable end to end: [result]
- Contrast at the target ratio: [result]
- Console clean through every verified flow: [result]
- Narrowest supported width: [result]

---

## Checklist Completion

- [ ] [Checklist item 1]
- [ ] [Checklist item 2]
- [ ] [Checklist item 3]
- [ ] [Any incomplete items - explain why]

---

## Known Issues / Technical Debt

| Issue | Severity | Notes |
|-------|----------|-------|
| [Issue 1] | Low/Med/High | [Explanation] |
| [Issue 2] | Low/Med/High | [Explanation] |

---

## Follow-Up Work Orders

| WO ID | Title | Priority | Reason |
|-------|-------|----------|--------|
| WO-XXXX | [Title] | P1 | [Why needed] |
| WO-YYYY | [Title] | P2 | [Why needed] |

---

## Lessons Learned

1. [Lesson 1]
2. [Lesson 2]
3. [Lesson 3]

---

## Sign-Off

**Implementation Complete:** [Date]
**Tested:** [Date]
**Deployed:** [Date or N/A]
**Closed:** [Date]

---

## Appendix

### A. Routes Added or Changed
```
[path] - [what renders there, and who may see it]
[path] - [what renders there, and who may see it]
```

### B. Component API
```
<ComponentName prop={...} /> - [the props that matter and what they do]
```

### C. Configuration Changes
```
[Config key]: [Value] - [Purpose]
```
