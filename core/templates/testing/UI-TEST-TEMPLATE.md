# UI Test Suite: [FEATURE-NAME]

> **Suite ID**: ui-[feature-slug]
> **Created**: YYYY-MM-DD
> **Related WO/BUG**: WO-XXXX / BUG-XXXX
> **Application**: {{ADMIN_APP}} | {{PORTAL_APP}}
> **Base URL**: http://localhost:8600 | http://localhost:8604

---

## Overview

**Purpose**: [What this test suite verifies]

**Prerequisites**:
- [ ] Application running at base URL
- [ ] Database seeded with test data
- [ ] Test user credentials available

**Test User**:
- Email: `test@example.com`
- Password: `TestPass123!`

---

## Test Cases

### TEST 1: [Test Name]

**Objective**: [What this specific test verifies]

#### Steps

| Step | Action | MCP Command | Expected Result |
|------|--------|-------------|-----------------|
| 1 | Navigate to page | `new_page(url="...")` | Page loads |
| 2 | Take snapshot | `take_snapshot()` | Get element UIDs |
| 3 | Fill form field | `fill(uid="X", value="...")` | Input populated |
| 4 | Click button | `click(uid="Y")` | Action triggered |
| 5 | Wait for result | `wait_for(text="...")` | Text appears |
| 6 | Verify network | `list_network_requests()` | API call succeeded |

#### Assertions

- [ ] Page URL matches expected
- [ ] Element [X] is visible with correct text
- [ ] Network request [Y] returns 200
- [ ] No console errors logged
- [ ] No 500 errors in network

#### Execution Record

| Run | Date | Status | Notes |
|-----|------|--------|-------|
| 1 | YYYY-MM-DD HH:MM | PASS/FAIL/BLOCKED | [Notes] |

---

### TEST 2: [Test Name]

**Objective**: [What this specific test verifies]

#### Steps

| Step | Action | MCP Command | Expected Result |
|------|--------|-------------|-----------------|
| 1 | ... | ... | ... |

#### Assertions

- [ ] ...

#### Execution Record

| Run | Date | Status | Notes |
|-----|------|--------|-------|
| 1 | ... | ... | ... |

---

## Error Scenarios

### ERROR TEST 1: [Error Condition]

**Objective**: Verify proper handling of [error condition]

#### Steps

| Step | Action | MCP Command | Expected Result |
|------|--------|-------------|-----------------|
| 1 | Trigger error condition | ... | Error displayed |
| 2 | Verify error message | `take_snapshot()` | Error text visible |
| 3 | Check console | `list_console_messages()` | Error logged |

#### Assertions

- [ ] User-friendly error message displayed
- [ ] No unhandled exceptions
- [ ] Recovery path available

---

## Summary

| Test | Status | Last Run |
|------|--------|----------|
| TEST 1: [Name] | NOT EXECUTED | - |
| TEST 2: [Name] | NOT EXECUTED | - |
| ERROR TEST 1: [Name] | NOT EXECUTED | - |

**Overall Suite Status**: NOT EXECUTED

---

## Notes

[Any additional observations or follow-up items]