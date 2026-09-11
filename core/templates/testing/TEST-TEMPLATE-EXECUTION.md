# WO-XXXX: [Feature Name] - Execution Results

**Work Order:** WO-XXXX
**Feature:** [Feature Name]
**Execution Date:** YYYY-MM-DD HH:MM:SS
**Executed By:** [Name/Agent]
**Environment:** [Development/Staging/Production]

---

## Execution Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | [N] |
| **Passed** | [N] |
| **Failed** | [N] |
| **Skipped** | [N] |
| **Pass Rate** | [N%] |
| **Duration** | [Xm Ys] |

---

## Environment Details

```bash
# API Version
curl -s http://localhost:3001/health | jq '.version'
# Output: "X.Y.Z"

# Database
psql -d {{PROJECT_NAME}}Dev -c "SELECT version();"
# Output: PostgreSQL X.Y.Z

# Node Version
node --version
# Output: vX.Y.Z
```

---

## Test Results

### PASSED Tests

#### Test 1.1: [Test Name] — EXECUTED — PASS

**Command:**
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "Password123!"}'
```

**Actual Response:**
```json
{
  "user": {
    "id": 1,
    "uuid": "ab7dd517-07ea-4242-8a18-3f924327ebe6",
    "email": "test@example.com"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**HTTP Status:** 200 OK

**Verification:** Response contains user data and access_token as expected.

---

#### Test 1.2: [Test Name] — EXECUTED — PASS

**Command:**
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "WrongPassword"}'
```

**Actual Response:**
```json
{
  "statusCode": 401,
  "message": "Invalid credentials",
  "error": "Unauthorized"
}
```

**HTTP Status:** 401 Unauthorized

**Verification:** Invalid password correctly rejected with 401.

---

### FAILED Tests

#### Test 2.1: [Test Name] — EXECUTED — FAIL

**Command:**
```bash
curl -X GET http://localhost:3001/api/v1/users/me \
  -H "Authorization: Bearer [TOKEN]"
```

**Expected Response:**
```json
{
  "id": 1,
  "email": "test@example.com"
}
```

**Actual Response:**
```json
{
  "statusCode": 500,
  "message": "Internal server error"
}
```

**HTTP Status:** 500 Internal Server Error

**Failure Reason:** Server returned 500 instead of 200. Check logs for error details.

**Related Issue:** [BUG-XXXX or investigation needed]

---

### SKIPPED Tests

#### Test 3.1: [Test Name] — NOT EXECUTED — SKIP

**Reason:** MFA not configured for test user. Requires manual setup.

**Action Required:** Configure MFA for test account before re-executing.

---

## Database Verification

### Query 1: Session Created

```sql
SELECT id, user_id, created_at, expires_at
FROM auth.sessions
WHERE user_id = 1
ORDER BY created_at DESC
LIMIT 1;
```

**Output:**
```
  id   | user_id |       created_at        |       expires_at
-------+---------+-------------------------+-------------------------
 12345 |       1 | 2025-12-19 10:30:00+00 | 2025-12-19 18:30:00+00
```

**Status:** VERIFIED — Session created with correct expiry.

---

### Query 2: Audit Log Entry

```sql
SELECT event_type, user_id, ip_address, created_at
FROM audit.audit_events
WHERE user_id = 1 AND event_type = 'LOGIN_SUCCESS'
ORDER BY created_at DESC
LIMIT 1;
```

**Output:**
```
   event_type   | user_id |  ip_address  |       created_at
----------------+---------+--------------+-------------------------
 LOGIN_SUCCESS  |       1 | 127.0.0.1    | 2025-12-19 10:30:00+00
```

**Status:** VERIFIED — Audit log captured login event.

---

## Issues Discovered

### Issue 1: [Brief Description]

**Test:** Test 2.1
**Severity:** [Critical/High/Medium/Low]
**Description:** [Detailed description of the issue]
**Related:** [BUG-XXXX if filed]

---

## Recommendations

1. [Any recommendations based on test results]
2. [Follow-up actions needed]
3. [Improvements to test coverage]

---

## Execution Log

```
[Timestamp] Starting WO-XXXX test execution
[Timestamp] Test 1.1: PASS
[Timestamp] Test 1.2: PASS
[Timestamp] Test 2.1: FAIL - HTTP 500
[Timestamp] Test 3.1: SKIP - MFA not configured
[Timestamp] Execution complete: 2 passed, 1 failed, 1 skipped
```

---

## Sign-Off

- [ ] All PASS tests have evidence captured
- [ ] All FAIL tests have failure reason documented
- [ ] All SKIP tests have reason and action noted
- [ ] Database verifications complete
- [ ] Issues filed for failures (if applicable)

**Execution Complete:** YYYY-MM-DD HH:MM:SS
