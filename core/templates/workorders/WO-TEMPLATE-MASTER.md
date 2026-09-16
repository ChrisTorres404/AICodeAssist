# WO-XXXX: [Title]

<!--
=============================================================================
{{PROJECT_NAME}} WORK ORDER TEMPLATE — master
=============================================================================
One document carrying every section the methodology asks for, in order:

- Behavioral testing (evidence-based verification)
- Layered architecture (data store -> entity -> service -> client library -> UI)
- The project's design system
- Automated testing patterns

WHEN TO USE THIS ONE:
The driver renders the per-document set — SPEC, CHECKLIST, TASK-BREAKDOWN,
Prompt — and that is the normal path:

    wo new "<title>" --size standard --area backend --priority P1

Use this master template instead when a work order is better read as a single
document: a cross-cutting change whose spec, plan, tests and closure are one
argument, or a work order handed to someone outside the project who should not
have to open five files. It is also the reference shape — every section below
appears in one of the per-document templates, so this is where to look when you
want to see how the pieces fit together.

BY HAND:
1. Copy to: {{WORKORDERS_DIR}}/WO-XXXX-[Title]/
2. Rename to: WO-XXXX-[Title].md
3. Fill in all sections
4. Create the companion documents: wo-XXXX-test-harness.md and
   WO-XXXX-VERIFICATION.md
=============================================================================
-->

**Work Order ID:** WO-XXXX
**Title:** [Full descriptive title]
**Status:** NOT STARTED | IN PROGRESS | BLOCKED | COMPLETE
**Priority:** P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low)
**Owner:** TBD
**Parent WO:** [Parent WO if exists, or "None"]
**Series:** XXXX – [Series Name]
**Date Created:** YYYY-MM-DD
**Est. Duration:** X days

---

## Dependencies

**Depends On:**
- [WO-XXXX] - [Brief description of dependency]
- None (Foundation WO)

**Blocks:**
- [WO-XXXX] - [What this unblocks]
- [Feature/Deployment that requires this]

**Related Audit Finding:**
- [Reference to audit, security review, or bug report]

---

## Objective

[2-3 sentence description of what this work order accomplishes]

**Why This Matters:**
- [Business/security/performance reason 1]
- [Business/security/performance reason 2]
- [Compliance/enterprise requirement]
- [Competitive positioning against the alternatives in this market]

---

## In-Scope

1. **[Feature/Component 1]**
   - [Specific deliverable]
   - [Specific deliverable]

2. **[Feature/Component 2]**
   - [Specific deliverable]
   - [Specific deliverable]

3. **[Testing/Documentation]**
   - [Test suite]
   - [Documentation updates]

---

## Out of Scope

- [Explicitly excluded item 1]
- [Explicitly excluded item 2]
- [Future enhancement - covered in WO-XXXX]

---

## Architecture / Design Notes

### Current State (Problem)

```
// Example of the problematic code pattern, in this project's language
// Explain what is wrong and why
```

### Target State (Solution)

```
// Example of the correct implementation
// Show the pattern to follow
```

### Data Flow

```
[Diagram or description of data flow]
Data store -> Entity -> Service/Controller -> Client library -> UI
```

---

## Layered Architecture Compliance

<!--
MANDATORY: a feature is built outward, one layer at a time. The UI calls the
client library; it never calls the transport directly. If this project has no
client-library layer, delete this section rather than leaving it empty — a
half-filled table is read as a requirement nobody met.
-->

### Data / Entity Layer

| Change | Table/Column | Description |
|--------|--------------|-------------|
| ADD | `table_name.column` | [Purpose] |
| MODIFY | `table_name.column` | [What changes] |
| MIGRATE | `migration_name` | [Migration description] |

### API Layer (Service/Controller/Module)

| Type | Name | Path/Method | Description |
|------|------|-------------|-------------|
| Service | `FeatureService` | N/A | [Business logic] |
| Controller | `FeatureController` | `GET /feature` | [Endpoint purpose] |
| Request contract | `CreateFeatureInput` | N/A | [Validation rules] |
| Access control | `FeatureGuard` | N/A | [Who may call it] |

### Client Library Layer

| Method | Signature | File | Description |
|--------|-----------|------|-------------|
| `feature.create()` | `(input: CreateFeatureInput) => Promise<Feature>` | `{{SDK_PKG}}` resources | [Usage] |
| `useFeature()` | `() => QueryResult<Feature>` | `{{SDK_PKG}}` hooks | [UI binding] |

### Frontend Integration

```tsx
// CORRECT: through the client library
import { useFeature, useFeatureMutations } from "{{SDK_PKG}}";

function FeaturePage() {
  const { data, isLoading, error } = useFeature();
  const { createFeature } = useFeatureMutations();

  // ...
}

// INCORRECT: a direct transport call from the UI. Never do this — it bypasses
// the types, the error handling, and the auth the client library owns.
// const response = await fetch("/feature");
```

---

## UI Implementation (the project's design system)

<!--
MANDATORY: all UI follows the design system recorded in
{{DOCS_DIR}}/DESIGN-SYSTEM.md. Replace the example values below with that
document's own: the radius token, the interaction treatments, the label
treatment, and the transition duration.
-->

### Components to Create/Modify

| Component | Type | Location | Description |
|-----------|------|----------|-------------|
| `FeatureList` | New | `[components directory]` | [Purpose] |
| `FeatureForm` | New | `[components directory]` | [Form fields] |
| `FeatureModal` | New | `[components directory]` | [Modal content] |

### Design Patterns to Apply

- [ ] The shared container component for cards and panels
- [ ] The shared interaction class for hover on interactive elements
- [ ] The shared metric display for any number on the page
- [ ] The shared active-state treatment
- [ ] Loading, error and empty states, all three, from the shared components
- [ ] The label treatment from the typography scale
- [ ] The entry/stagger animation for lists

### Colour Usage

Token names, not literal values — the value lives in one place.

| Element | Token | Notes |
|---------|-------|-------|
| Primary action | `primary` | [Where it appears in this work order] |
| Success state | `success` | [...] |
| Warning state | `warning` | [...] |
| Error state | `destructive` | [...] |
| Elevated tier | `accent` | [...] |

---

## Phased Tasks (Implementation Plan)

Every task names the file it lands in and who owns it.

### Phase 1: [Phase Name] (X hours)

| Task | Description | File(s) | Assignee |
|------|-------------|---------|----------|
| 1.1 | [Task description] | `path/to/file` | TBD |
| 1.2 | [Task description] | `path/to/file` | TBD |
| 1.3 | [Task description] | `path/to/file` | TBD |

### Phase 2: [Phase Name] (X hours)

| Task | Description | File(s) | Assignee |
|------|-------------|---------|----------|
| 2.1 | [Task description] | `path/to/file` | TBD |
| 2.2 | [Task description] | `path/to/file` | TBD |

### Phase 3: Client Library Integration (X hours)

| Task | Description | File(s) | Assignee |
|------|-------------|---------|----------|
| 3.1 | Create the resource class | `{{SDK_PKG}}` resources | TBD |
| 3.2 | Create the UI binding (hook, store, or composable) | `{{SDK_PKG}}` hooks | TBD |
| 3.3 | Export from the package entry point | `{{SDK_PKG}}` index | TBD |
| 3.4 | Add the types | `{{SDK_PKG}}` types | TBD |

### Phase 4: Frontend Implementation (X hours)

| Task | Description | File(s) | Assignee |
|------|-------------|---------|----------|
| 4.1 | Create UI components | `{{ADMIN_APP}}` components | TBD |
| 4.2 | Bind them to the client library | `{{ADMIN_APP}}` pages | TBD |
| 4.3 | Apply the design system | Component files | TBD |

### Phase 5: Behavioral Testing (X hours)

| Task | Description | File(s) | Assignee |
|------|-------------|---------|----------|
| 5.1 | Create test harness | `wo-XXXX-test-harness.md` | TBD |
| 5.2 | Execute tests | Terminal | TBD |
| 5.3 | Document evidence | `WO-XXXX-VERIFICATION.md` | TBD |
| 5.4 | Create the behavioural suite | `{{TESTING_DIR}}/suites/wo-XXXX-<feature>.sh` | TBD |

---

## Acceptance Criteria

### Functional Requirements

- [ ] [Specific behavior that must work]
- [ ] [Specific behavior that must work]
- [ ] [Edge case handling]

### Security Requirements

- [ ] [Security control 1]
- [ ] [Security control 2]
- [ ] [Activity/audit logging requirement]

### Performance Requirements

- [ ] [Latency target: < Xms]
- [ ] [Throughput target: X req/s]
- [ ] [No regression on existing features]

### Code Quality

- [ ] Unit test coverage > X%
- [ ] Type checker reports no errors
- [ ] Linter passes
- [ ] Build succeeds

### Client Library Compliance

- [ ] A client-library method exists for each endpoint this work order adds
- [ ] A UI binding exists for each piece of data the UI reads
- [ ] The client library's types match the server's contracts
- [ ] The UI calls the client library only — no direct transport calls

### UI Compliance (design system)

- [ ] Radius matches the token
- [ ] The shared hover treatment is applied to interactive elements
- [ ] Labels follow the typography scale
- [ ] Transition duration and easing come from the tokens
- [ ] Loading, error and empty states all implemented
- [ ] Responsive layout (narrow to wide)

---

## Behavioral Testing

<!--
MANDATORY: every work order carries behavioral testing. Tests are
evidence-based — no mocks, no assumptions.
Status values: NOT EXECUTED — PLAN ONLY | EXECUTED — PASS | EXECUTED — FAIL
-->

### Test Matrix

| Test ID | Category | Description | Status | Evidence |
|---------|----------|-------------|--------|----------|
| 1.1 | [Category] | [What this tests] | NOT EXECUTED | [section, or blank until it runs] |
| 1.2 | [Category] | [What this tests] | NOT EXECUTED | [section, or blank until it runs] |
| 2.1 | [Category] | [What this tests] | NOT EXECUTED | [section, or blank until it runs] |

### Test Harness (Quick Reference)

```bash
# Setup
API_URL="{{API_BASE_URL}}"
TOKEN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"<test account from the harness configuration>","password":"<from the environment, never written here>"}' \
  | jq -r '.access_token')

# Test 1.1: [Test Name]
curl -s -X GET "$API_URL/[endpoint]" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# Expected: HTTP 200, response contains [expected fields]
```

A credential written into a checked-in document is a credential leak. Take the
test account from the harness configuration.

### Automated Test Script Location

```
{{TESTING_DIR}}/suites/wo-XXXX-<feature>.sh
```

### Manual Verification Scenarios

| Scenario | Steps | Expected Result | Result |
|----------|-------|-----------------|--------|
| [Scenario 1] | 1. [Step]<br>2. [Step] | [Expected outcome] | NOT EXECUTED |
| [Scenario 2] | 1. [Step]<br>2. [Step] | [Expected outcome] | NOT EXECUTED |

---

## Files Modified/Created

### New Files

| File | Purpose |
|------|---------|
| `{{API_APP}}/[module]/` | [Purpose] |
| `{{SDK_PKG}}` resource for [feature] | Client-library resource |
| `{{SDK_PKG}}` binding for [feature] | UI binding |
| `{{ADMIN_APP}}/[feature]/` | UI components |
| `{{TESTING_DIR}}/suites/wo-XXXX-<feature>.sh` | Behavioural suite |

### Modified Files

| File | Changes |
|------|---------|
| `{{API_APP}}` module registry | Register the new module |
| `{{SDK_PKG}}` index | Export the new resources |
| [Other files] | [Changes] |

---

## Error Codes

| Code | HTTP Status | Message | Cause |
|------|-------------|---------|-------|
| `FEATURE_NOT_FOUND` | 404 | Feature not found | Invalid identifier |
| `FEATURE_LIMIT_EXCEEDED` | 400 | Feature limit exceeded | Account quota |
| `INSUFFICIENT_PERMISSIONS` | 403 | Insufficient permissions | Missing privilege |

---

## Rollback Plan

1. [Rollback step 1 - e.g., revert the migration]
2. [Rollback step 2 - e.g., unregister the module]
3. [Rollback step 3 - e.g., revert the client-library changes]

**WARNING:** [Any data loss or breaking change warnings]

---

## Competitor Comparison

Delete this section for internal work. Where it applies, name the real
alternatives a buyer is comparing against.

| Feature | [Competitor A] | [Competitor B] | [Competitor C] | {{PROJECT_NAME}} (After WO) |
|---------|----------------|----------------|----------------|------------------------------|
| [Feature 1] | [Status] | [Status] | [Status] | **[Our advantage]** |
| [Feature 2] | [Status] | [Status] | [Status] | **[Our advantage]** |

---

## Related Documentation

- [Link to design doc]
- [Link to API spec]
- [Link to security review]
- [Link to related WO]

---

## Verification Report Reference

After execution, update the verification report at:
```
WO-XXXX-VERIFICATION.md
```

`wo verify <n> --run <suite>` writes that document's status from the suite's
exit code. A status typed by hand is not evidence.

**Final Status Format:**
```
**Verification Status:**
- EXECUTED: X/Y tests
- PASSED: X/X tests
- FAILED: 0 tests
- Production Ready: YES/NO
```

---

## Closure Checklist

Before marking COMPLETE, verify:

- [ ] All acceptance criteria met
- [ ] Behavioral tests executed and passed
- [ ] Client-library integration complete
- [ ] The UI calls the client library only — no direct transport calls
- [ ] UI follows the project's design system
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Build passes
- [ ] Type checker reports no errors
- [ ] Linter passes

---

**Status:** Ready for implementation
**Estimated Effort:** X days
**Risk Level:** Low | Medium | High
**Impact:** [Business/security impact summary]
