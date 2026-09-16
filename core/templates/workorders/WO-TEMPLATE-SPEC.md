# WO-XXXX: [Title]

**Priority:** P0 | P1 | P2 | P3
**Effort:** [X hours/days]
**Dependencies:** [WO-<other>, WO-<other> or None]
**Blocks:** [WO-<other> or None]
**Related finding:** [Audit, security review, bug, or incident that prompted this, or None]

---

## Problem Statement

[1-2 paragraphs describing the problem this work order solves]

**Current State:**
```
// the current implementation, in the project's own language (if applicable)
```

**Impact:**
- [Impact 1 - e.g., security vulnerability, performance issue, UX problem]
- [Impact 2]
- [Impact 3]

---

## Solution

Write each component in the project's own language and idiom. Show real
signatures, not prose about them — a spec that cannot be implemented from its
own contents is not finished.

### 1. [Solution Component 1 — e.g. the data-model change]

**File:** `[path/to/file]`

```
// the changed model or schema definition
```

### 2. [Solution Component 2 — e.g. the migration]

**File:** `[path/to/migration]`

```sql
-- forward
-- rollback
```

Follow the naming and structure of the migrations already in that directory.

### 3. [Solution Component 3 — e.g. the service or handler]

**File:** `[path/to/file]`

```
// the new or changed function, with its real signature,
// its error handling, and its dependencies
```

### 4. [Solution Component 4 — e.g. the endpoint or entry point]

**File:** `[path/to/file]`

```
// how it is wired in, and what protects it
```

### 5. [Continue as needed...]

---

## Layer Compliance

Fill in every layer this work touches; write "N/A" for the ones it does not.
A layer that is skipped here is a layer nobody verified.

### Data Flow

```
[store] -> [model/entity] -> [service or handler] -> [transport] -> [client library] -> [UI]
```

Mark where this work order adds or changes a step.

### Data Layer

| Change | Table / Collection / Column | Description |
|--------|------------------------------|-------------|
| ADD | `[name]` | [Purpose] |
| MODIFY | `[name]` | [What changes] |
| MIGRATE | `[migration name]` | [What it does, and its rollback] |

### Service / API Layer

| Type | Name | Path / Signature | Description |
|------|------|------------------|-------------|
| Service | `[Name]` | — | [Business logic] |
| Handler | `[Name]` | `[METHOD] /v1/[path]` | [What it exposes] |
| Input type | `[Name]` | — | [Validation rules] |
| Access control | `[Name]` | — | [What it authorizes] |

### Client Library Layer

| Method | Signature | File | Description |
|--------|-----------|------|-------------|
| `[resource].[method]()` | `([input]) -> [Result]` | `{{SDK_PKG}}/[path]` | [Usage] |

### UI Layer

The UI consumes the client library. It does not call the transport directly:
a component issuing its own HTTP request bypasses the library's auth, retry,
error shaping, and types, and it will drift. If a screen needs something the
client library does not expose, the fix is a client-library method, not a
direct call.

---

## Files Created and Modified

### New Files

| File | Purpose |
|------|---------|
| `[path/to/new/file]` | [What it is] |
| `{{TESTING_DIR}}/suites/wo-XXXX-[feature].sh` | Behavioral suite |

### Modified Files

| File | Changes |
|------|---------|
| `[path/to/file1]` | [Description of changes] |
| `[path/to/file2]` | [Description of changes] |
| `[path/to/file3]` | [Description of changes] |
| `[path/to/migrations/]` | Register the new migration, if this project requires it |

---

## Environment Variables

Add to `.env` (if applicable):

```bash
# [Variable description]
[VARIABLE_NAME]=[example_value_or_description]
```

---

## Testing Requirements

### Unit Tests (the project's unit runner)
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Integration Tests
- [ ] [The module wired to its real collaborators — the seam the unit tests mocked]
- [ ] [The persistence path — what was written, and that it reads back]
- [ ] [The failure path across the seam — timeout, rejection, or rollback]

### Behavioral Tests (verification evidence)
Suite: `{{TESTING_DIR}}/suites/wo-XXXX-[feature].sh`
- [ ] [Journey 1 — request, response, and the state it changed]
- [ ] [Journey 2 — the error path, and that no state changed]
- [ ] [Journey 3]

A green unit suite is necessary and not sufficient. Only the behavioral suite
closes the work order.

### Security Tests (if applicable)
- [ ] [Security test 1]
- [ ] [Security test 2]

---

## Verification

```bash
# Step-by-step verification commands

# 1. [Description]
[command 1]

# 2. [Description]
[command 2]

# 3. [Description]
[command 3]

# 4. Verify expected behavior
[command 4]
# Expected output: [description]

# 5. Verify error cases
[command 5]
# Should return [expected error]
```

---

## Rollback Plan

1. [Rollback step 1]
2. [Rollback step 2]
3. [Impact of rollback]
4. [Data considerations]

**Warning:** [Any data loss, breaking change, or one-way migration this
rollback cannot undo. Write "None" only after checking.]

---

## API Changes (if applicable)

### New Endpoints

```
[METHOD] /v1/[path]
Authorization: [Bearer token | API Key | None]

Request:
{
  "[field]": "[type]"
}

Response (200):
{
  "[field]": "[type]"
}

Response ([error_status]):
{
  "error": "[error_code]",
  "message": "[error_message]"
}
```

### Modified Endpoints

| Endpoint | Change |
|----------|--------|
| `[METHOD] /v1/[path]` | [Description of change] |

### Error Codes

| Code | Status | Message | Cause |
|------|--------|---------|-------|
| `[CODE_NOT_FOUND]` | 404 | [User-facing message] | [What produces it] |
| `[CODE_LIMIT_EXCEEDED]` | 400 | [User-facing message] | [What produces it] |
| `[CODE_FORBIDDEN]` | 403 | [User-facing message] | [What produces it] |

Every error path the behavioral suite exercises appears here.

---

## SDK Changes (if applicable)

### New Methods

```
// {{SDK_PKG}}/[path]/[file]

// [Method description]
[methodName]([params]) -> [ReturnType]
```

### Type Definitions

```
[TypeName] {
  [field]: [type]
}
```

---

## UI Changes (if applicable)

### Components to Create/Modify

| Component | Location | Changes |
|-----------|----------|---------|
| `[ComponentName]` | `[feature directory]/components/[Name]` | [Description] |

### User Flow

1. [User action 1] → [System response]
2. [User action 2] → [System response]
3. [etc.]

### Design System Compliance

- [ ] Built from the project's existing component primitives
- [ ] Styled with the project's design tokens — no ad-hoc values
- [ ] Follows the nearest existing component of the same kind: `[name it]`
- [ ] Loading, empty, and error states implemented
- [ ] Every theme the project ships, dark mode included
- [ ] Accessible: labelled controls, keyboard reachable, meaningful roles
- [ ] Responsive from phone width upward
- [ ] Carries the `WO-XXXX` comment block

---

## Acceptance Criteria

Each criterion must be testable by someone who did not write it.

### Functional
- [ ] [Specific behavior that must work]
- [ ] [Specific behavior that must work]
- [ ] [Edge case handling]

### Security
- [ ] [What authenticates the new surface]
- [ ] [What authorizes it]
- [ ] [What is recorded in the audit trail]

### Performance
- [ ] [Latency target]
- [ ] [Throughput or volume target]
- [ ] No regression on [the existing path this shares code with]

### Code Quality
- [ ] Build succeeds
- [ ] Type check and linter clean
- [ ] Unit coverage at or above the project's threshold for changed files

### Layer Compliance
- [ ] A client-library method exists for every new endpoint
- [ ] Types on both sides of the boundary match
- [ ] The UI uses the client library only

### Regression
- [ ] All existing tests pass
- [ ] New tests pass

---

## Related Documentation

- [Design note, architecture decision record, or prior spec]
- [API or schema reference]
- [Security or compliance review]
- [Related work order, and how it relates]

---

## Prior Art and Alternatives (if applicable)

| Capability | [Alternative A] | [Alternative B] | {{PROJECT_NAME}} after this WO |
|------------|-----------------|-----------------|-------------------------------|
| [Capability 1] | [How they do it] | [How they do it] | [What we do, and why] |
| [Capability 2] | [How they do it] | [How they do it] | [What we do, and why] |

Use this only when the design is a deliberate divergence worth recording.

---

## Cross-Cutting Checks

Answer each; "N/A" is an answer, blank is not. Every item here is a bug that shipped once.

- **Contract:** if a client and an API both change, which is the source of truth, and is the other generated or contract-tested against it?
- **Scoping:** which queries are scoped to the caller's data, and where is that filter enforced — in one place, or repeated per query?
- **Security:** machine auth is opt-in per endpoint; every new endpoint names what authenticates it and what authorizes it; any credential set as a cookie is absent from response bodies.
- **Dependencies:** what must be registered or imported for this code's dependencies to resolve at runtime?
- **Data:** does seed or reference data need a migration and a bootstrap change as well as a dev insert? Any partitioned or mirrored tables involved?
- **Failure:** for multi-step operations, what is rolled back or compensated when a step fails mid-way?
- **Time:** timezone behaviour and units for any date or duration.
- **UI:** light, dark, and system themes; loading, empty, and error states; list and detail parity; phone width.
- **Deletion:** if this extracts or clones code, what is removed?
- **Tests:** which existing suites must run in addition to new ones?
