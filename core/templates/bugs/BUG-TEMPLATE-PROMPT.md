You are operating inside the {{WORKSPACE_DIR}} / {{PROJECT_NAME}} context.

Bug: BUG-XXXX – [Short Title]
Severity: [Critical / High / Medium / Low]
Owner: Christian
Date: YYYY-MM-DD

You are a **[role - e.g., senior backend engineer, frontend React developer]** specializing in [specialization].

Your job: **Fix BUG-XXXX** while maintaining code quality, adding proper test coverage, and following the {{PROJECT_NAME}} architecture rules.

---

## 1. Bug Files You MUST Read First

Base path: `{{PROJECT_ROOT}}/{{BUGS_DIR}}/BUG-XXXX-[slug]/`

You MUST read:
1. `BUG-XXXX-[slug].md` (bug issue document)

Also read the related Work Order(s):
- `{{PROJECT_ROOT}}/{{WORKORDERS_DIR}}/WO-XXXX-[folder]/`

---

## 2. Bug Summary

**Problem:** [One sentence describing what's broken]

**Root Cause:** [One sentence describing why it's broken]

**Impact:** [Who is affected and how]

---

## 3. Reproduction Steps

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. Observe: [What happens]

---

## 4. Files to Investigate

Before fixing, examine these files:

| File | Purpose |
|------|---------|
| `path/to/problematic/file.ts` | Where the bug manifests |
| `path/to/related/file.ts` | Related code that may be affected |
| `path/to/test/file.spec.ts` | Existing tests (if any) |

---

## 5. Fix Requirements

### What to Fix
1. [Specific change 1]
2. [Specific change 2]
3. [Specific change 3]

### What NOT to Change
- [Don't refactor X]
- [Don't change Y unless necessary]
- [Keep Z as-is]

### Code Annotation Requirement

After fixing, add comments in the affected code:

```ts
// WO-XXXX: [Original Work Order title]
// BUG-XXXX: Fixed [brief description of what was fixed]
// Summary: [one line explaining the fix]
```

---

## 6. Testing Requirements

**TESTING METHODOLOGY:** {{PROJECT_NAME}} uses **Behavioral Testing** (NOT Jest E2E tests).

You MUST read:
- `{{PROJECT_ROOT}}/{{DOCS_DIR}}/BEHAVIORAL-TESTING-METHODOLOGY.md`

### Required Tests
- [ ] Unit test covering the fix
- [ ] Regression test for original functionality
- [ ] Edge case test (if applicable)

### Test Locations
| Test Type | File Path |
|-----------|-----------|
| Unit test | `path/to/test.spec.ts` |
| Behavioral test | `path/to/behavioral-test.sh` |

---

## 7. Success Criteria

1. Bug no longer reproduces with the original steps
2. No regression in related functionality
3. All existing tests still pass
4. New test(s) cover the fix
5. Code annotations added
6. Build succeeds without errors

---

## 8. Architecture Rules Reminder

Remember the {{PROJECT_NAME}} architecture flow:

**Database → Entity → Service/Controller → SDK → Frontend**

If the fix involves:
- **Backend API changes**: Update SDK wrapper too
- **SDK changes**: Ensure frontend uses SDK, not direct API calls
- **Database changes**: Add migration and update entity
- **Type changes**: Update types in both backend and SDK

Read the full architecture rules:
- `{{PROJECT_ROOT}}/{{BUGS_DIR}}/Bug-Prompts/Bug-API-SDK-UI-Standardization-prompt.md`

---

## 9. Deliverables

After fixing, you must have:

1. **Code fix** - The actual code changes
2. **Tests** - New/updated tests proving the fix works
3. **Closeout** - Create `BUG-XXXX-[slug]-CLOSEOUT.md` using the template

---

## 10. Begin

1. Read the bug document
2. Reproduce the bug (verify it exists)
3. Implement the fix
4. Add tests
5. Verify all tests pass
6. Add code annotations
7. Create closeout document

Begin implementation.
