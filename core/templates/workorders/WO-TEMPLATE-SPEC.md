# WO-XXXX: [Title]

**Priority:** P0 | P1 | P2 | P3
**Effort:** [X hours/days]
**Dependencies:** [WO-XXXX, WO-YYYY or None]
**Blocks:** [WO-ZZZZ or None]

---

## Problem Statement

[1-2 paragraphs describing the problem this work order solves]

**Current State:**
```typescript
// Code showing the current problematic implementation (if applicable)
```

**Impact:**
- [Impact 1 - e.g., security vulnerability, performance issue, UX problem]
- [Impact 2]
- [Impact 3]

---

## Solution

### 1. [Solution Component 1 - e.g., Database Changes]

**File:** `[path/to/file.ts]`

```typescript
// Code showing the solution implementation
```

### 2. [Solution Component 2 - e.g., Create Migration]

**File:** `[path/to/migration.ts]`

```typescript
import { MigrationInterface, QueryRunner } from 'typeorm';

export class [MigrationName]TIMESTAMP implements MigrationInterface {
  name = '[MigrationName]TIMESTAMP';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      -- SQL here
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      -- Rollback SQL here
    `);
  }
}
```

### 3. [Solution Component 3 - e.g., Service Implementation]

**File:** `[path/to/service.ts]`

```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class [ServiceName] {
  constructor(
    // Dependencies
  ) {}

  /**
   * [Method description]
   */
  async [methodName]([params]): Promise<[ReturnType]> {
    // Implementation
  }
}
```

### 4. [Solution Component 4 - e.g., Guard/Controller Update]

**File:** `[path/to/file.ts]`

```typescript
// Code showing the implementation
```

### 5. [Continue as needed...]

---

## Files to Modify

| File | Changes |
|------|---------|
| `[path/to/file1.ts]` | [Description of changes] |
| `[path/to/file2.ts]` | [Description of changes] |
| `[path/to/file3.ts]` | [Description of changes] |
| `[path/to/migrations/index.ts]` | Register new migration |

---

## Environment Variables

Add to `.env` (if applicable):

```bash
# [Variable description]
[VARIABLE_NAME]=[example_value_or_description]
```

---

## Testing Requirements

### Unit Tests
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Integration Tests
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

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

---

## SDK Changes (if applicable)

### New Methods

```typescript
// packages/{{SDK_PKG}}/src/[path]/[file].ts

/**
 * [Method description]
 */
async [methodName]([params]: [ParamType]): Promise<[ReturnType]> {
  // Implementation
}
```

### Type Definitions

```typescript
export interface [TypeName] {
  [field]: [type];
}
```

---

## UI Changes (if applicable)

### Components to Create/Modify

| Component | Location | Changes |
|-----------|----------|---------|
| `[ComponentName]` | `[path/to/component.tsx]` | [Description] |

### User Flow

1. [User action 1] → [System response]
2. [User action 2] → [System response]
3. [etc.]

---

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] [Criterion 4]
- [ ] All existing tests pass
- [ ] New tests pass
