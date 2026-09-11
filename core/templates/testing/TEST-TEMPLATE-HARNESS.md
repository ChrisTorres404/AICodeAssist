# WO-XXXX: [Feature Name] - Test Harness

**Work Order:** WO-XXXX
**Feature:** [Feature Name]
**Date Created:** YYYY-MM-DD
**Status:** NOT EXECUTED — PLAN ONLY

---

## Overview

**Purpose:** [Describe what this test harness validates]

**Prerequisites:**
- API server running at `http://localhost:3001`
- Database accessible via `psql -d {{PROJECT_NAME}}Dev`
- Test user account created
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
# Start API server
cd apps/{{API_APP}} && npm run start:dev

# Verify API is running
curl -s http://localhost:3001/health | jq
```

### Create Test Data

```bash
# Create test user
curl -X POST http://localhost:3001/api/v1/auth/register \
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
curl -X [METHOD] http://localhost:3001/api/v1/[endpoint] \
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

**SQL Verification (if applicable):**
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
curl -X [METHOD] http://localhost:3001/api/v1/[endpoint] \
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
curl -X [METHOD] http://localhost:3001/api/v1/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response:**
```json
{}
```

**Expected HTTP Status:** [200]

**SQL Verification:**
```sql
-- Verify database state
SELECT * FROM schema.table WHERE id = [ID];
```

**Expected SQL Output:**
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

1. **Copy all curl commands** to a terminal
2. **Execute each test** in order
3. **Capture actual output** and paste into Evidence section
4. **Update status** for each test:
   - `EXECUTED — PASS` if actual matches expected
   - `EXECUTED — FAIL` if actual differs from expected
5. **Update Summary** counts

---

## Notes

[Any additional notes, known issues, or special considerations]
