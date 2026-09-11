# BUG-XXXX: [Short Title]

## Metadata

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-XXXX |
| **Severity** | Critical / High / Medium / Low |
| **Status** | Open / In Progress / Fixed / Verified / Closed |
| **Reported By** | [Name or system] |
| **Reported Date** | YYYY-MM-DD |
| **Fixed Date** | YYYY-MM-DD or `-` if not fixed |
| **Related WO(s)** | WO-XXXX, WO-YYYY (if applicable) |
| **Affected Version** | v0.0.0 |
| **Fixed Version** | v0.0.0 or `-` |
| **Environment(s)** | Local / Dev / Stage / Prod |
| **Subsystem(s)** | e.g. Analytics, Auth, Observability, Admin UI, SDK |

---

## Summary

Brief one-paragraph description of the bug.

### Impact Assessment

| Impact Area | Description |
|-------------|-------------|
| **Who is affected?** | tenants / admins / end-users / internal tools |
| **What is impacted?** | features / data correctness / security / performance |
| **Business risk** | e.g. misleading analytics, auth risk, billing errors |

---

## Original Implementation Context

> This tells future devs/AI where the *original behavior* came from.

**Work Order(s):**

- `WO-XXXX: <Title>` - [Link to WO folder]
- `WO-YYYY: <Title>` - [Link to WO folder] (if multiple)

**Key Files / Modules (Original Implementation):**

| File | Purpose |
|------|---------|
| `path/to/file1.ts` | What it does |
| `path/to/file2.tsx` | What it does |
| `path/to/view_or_sql.sql` | What it does |

**Existing Code Annotations (Before Fix):**

```ts
// WO-XXXX: <Work Order title>
// Purpose: <one-line purpose of this implementation>
```

---

## Reproduction Steps

1. Step one (include specific values/inputs)
2. Step two
3. Step three
4. Observe [specific behavior]

**Minimal Reproduction:**
```bash
# Command or code to reproduce
```

---

## Expected Behavior

What should happen when the above steps are followed.

---

## Actual Behavior

What actually happens (include error messages, wrong values, etc.).

---

## Error Evidence

```
Error messages, stack traces, SQL outputs, or API responses
```

**Screenshots:** (if applicable)
- [Screenshot description]

**Logs:** (if applicable)
```
Relevant log entries
```

---

## Root Cause Analysis

### Technical Root Cause

Detailed explanation of why the bug occurred:
- Logic error
- Configuration issue
- Data model problem
- API contract mismatch
- Race condition
- etc.

### Contributing Factors

- [ ] Missing unit tests
- [ ] Unclear requirements in original WO
- [ ] Edge case not considered
- [ ] Integration issue between modules
- [ ] Third-party dependency issue
- [ ] Other: [describe]

---

## Fix Design

### Approach

High-level description of how to fix this (not just "change X to Y").

### Scope

**In Scope:**
- Bullet list of what will be changed

**Out of Scope:**
- Things explicitly deferred to a future WO

### Files to Modify

| File | Change Type | Description |
|------|-------------|-------------|
| `path/to/file.ts` | New / Modified / Removed | Brief description |
| `path/to/file2.tsx` | Modified | Brief description |

### Code Changes (Before / After)

**Before:**
```typescript
// Short representative snippet (NOT entire file)
```

**After:**
```typescript
// Short representative snippet (NOT entire file)
```

### Code Annotation Standard

After fixing, add comments linking both the WO and Bug:

```ts
// WO-XXXX: <Work Order title>
// BUG-XXXX: <Bug short title / what was fixed>
// Summary: <one or two lines describing the fix or constraint>
```

**Important:** Do NOT delete the original WO comments.

---

## Testing

### Manual Testing

- [ ] Test case 1: [scenario + expected outcome]
- [ ] Test case 2: [scenario + expected outcome]
- [ ] Edge case 1: [scenario + expected outcome]
- [ ] Regression check: [verify related functionality]

### Automated Tests

- [ ] Unit test added/updated: `path/to/test.spec.ts`
- [ ] Integration test added/updated: `path/to/test.integration.ts`
- [ ] Behavioral test added/updated: `path/to/behavioral-test.sh`
- [ ] CI pipeline passing

---

## Prevention

### Process Improvements

- [ ] Add to code review checklist
- [ ] Update WO requirements template
- [ ] Improve test coverage requirements
- [ ] Other: [describe]

### Code / Architecture Improvements

- [ ] Add central utility function
- [ ] Improve type definitions
- [ ] Add runtime guards/validation
- [ ] Other: [describe]

---

## Rollback Plan

If the fix causes issues:

1. [Step to rollback - e.g., git revert commit]
2. [Feature flag to disable]
3. [Config toggle]
4. [Monitoring to watch]

---

## Checklist Before Closing

- [ ] Fix implemented and code reviewed
- [ ] Unit/integration tests added
- [ ] Manual testing passed
- [ ] CI pipeline passing
- [ ] Code annotations added
- [ ] Documentation updated (if applicable)
- [ ] Deployed to Dev/Stage/Prod
- [ ] Monitored post-deployment
- [ ] Closeout document created: `BUG-XXXX-[slug]-CLOSEOUT.md`
