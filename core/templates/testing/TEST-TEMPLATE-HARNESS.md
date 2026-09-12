# WO-XXXX: [Feature Name] - Test Harness

**Work Order:** WO-XXXX
**Feature:** [Feature Name]
**Date Created:** YYYY-MM-DD
**Status:** NOT EXECUTED — PLAN ONLY

---

## Overview

**Purpose:** [Describe what this test harness validates]

**Prerequisites:**
- The application is running and reachable at `{{API_BASE_URL}}`
- The data store is reachable with the project's database client
- Test accounts or fixtures exist, created by the project's own seed path
- [Any other prerequisites]

**Related Work Order:** [Link to WO-XXXX spec/folder]

---

## Test Matrix

| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| 1.1 | [Category] | [Description] | NOT EXECUTED |
| 1.2 | [Category] | [Description] | NOT EXECUTED |
| 2.1 | [Category] | [Description] | NOT EXECUTED |
| 2.2 | [Category] | [Description] | NOT EXECUTED |

---

## Environment Setup

### Start Services

```bash
# Start the application with the project's own run command
# (recorded in the project CLAUDE.md)

# Verify it is answering
curl -s {{API_BASE_URL}}/health | jq
```

### Create Test Data

```bash
# Create a test account
curl -X POST {{API_BASE_URL}}/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test-wo-XXXX@example.com",
    "password": "TestPassword123!",
    "first_name": "Test",
    "last_name": "User"
  }'
```

---

## Test Cases

### Category 1: [Category Name]

#### Test 1.1: [Test Name]

**Goal:** [What this test verifies]

**Status:** NOT EXECUTED — PLAN ONLY

**HTTP Request:**
```bash
curl -X [METHOD] {{API_BASE_URL}}/[endpoint] \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [TOKEN]" \
  -d '{
    "key": "value"
  }'
```

**Expected Response:**
```json
{
  "status": "expected",
  "data": {}
}
```

**Expected HTTP Status:** [200/201/400/401/etc.]

**State Verification (if applicable):**
```sql
SELECT column1, column2
FROM schema.table
WHERE condition;
```

**Execution Evidence:**
```
[PASTE ACTUAL OUTPUT HERE AFTER EXECUTION]
```

**Result:** NOT EXECUTED

---

#### Test 1.2: [Test Name]

**Goal:** [What this test verifies]

**Status:** NOT EXECUTED — PLAN ONLY

**HTTP Request:**
```bash
curl -X [METHOD] {{API_BASE_URL}}/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{
    "key": "value"
  }'
```

**Expected Response:**
```json
{
  "error": "expected error"
}
```

**Expected HTTP Status:** [400/401/403/etc.]

**Execution Evidence:**
```
[PASTE ACTUAL OUTPUT HERE AFTER EXECUTION]
```

**Result:** NOT EXECUTED

---

### Category 2: [Category Name]

#### Test 2.1: [Test Name]

**Goal:** [What this test verifies]

**Status:** NOT EXECUTED — PLAN ONLY

**HTTP Request:**
```bash
curl -X [METHOD] {{API_BASE_URL}}/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response:**
```json
{}
```

**Expected HTTP Status:** [200]

**State Verification:**
```sql
-- Verify database state
SELECT * FROM schema.table WHERE id = [ID];
```

**Expected Output:**
```
 column1 | column2
---------+---------
 value1  | value2
```

**Execution Evidence:**
```
[PASTE ACTUAL OUTPUT HERE AFTER EXECUTION]
```

**Result:** NOT EXECUTED

---

## Summary

| Status | Count |
|--------|-------|
| EXECUTED — PASS | 0 |
| EXECUTED — FAIL | 0 |
| NOT EXECUTED | [TOTAL] |

---

## Execution Instructions

1. **Copy each command** to a terminal
2. **Execute the tests** in order
3. **Capture the actual output** and paste it into the Evidence section
4. **Set the status** for each test from what actually happened:
   - `EXECUTED — PASS` if the actual result matches the expected one
   - `EXECUTED — FAIL` if it differs
   - `NOT EXECUTED — SKIP` with the environmental reason, if a prerequisite
     is not configured
5. **Update the Summary** counts

Never set a status from expectation. If a test was not run, it stays
`NOT EXECUTED — PLAN ONLY`.

---

## Notes

[Any additional notes, known issues, or special considerations]
