# {{PROJECT_NAME}} UI Scenario Testing Methodology

> **Purpose**: Executable UI test scenarios for user journey verification and troubleshooting
> **Created**: 2026-01-02
> **Tool**: Chrome DevTools MCP

---

## Overview

These scenario tests are **executable runbooks** that:
1. Verify complete user journeys work end-to-end
2. Provide step-by-step troubleshooting when things break
3. Pinpoint exactly which step in a flow is failing

Each scenario is a real-world use case with executable Chrome DevTools commands.

---

## Scenario Index

| ID | Scenario | Description | Suite File |
|----|----------|-------------|------------|
| S-001 | New User Registration | Complete signup flow from landing to dashboard | `S-001-new-user-registration.md` |
| S-002 | User Login | Login with email/password, including error cases | `S-002-user-login.md` |
| S-003 | User Logout | Complete logout with session clearing | `S-003-user-logout.md` |
| S-004 | Password Reset | Forgot password → email → reset → login | `S-004-password-reset.md` |
| S-005 | Account Activation | Email verification and account activation | `S-005-account-activation.md` |
| S-006 | MFA Setup | Enable TOTP, backup codes, verify login | `S-006-mfa-setup.md` |
| S-007 | MFA Login | Login with MFA challenge | `S-007-mfa-login.md` |
| S-008 | Session Timeout | Idle timeout, refresh, re-authentication | `S-008-session-timeout.md` |
| S-009 | User Profile Update | Edit profile, change password | `S-009-user-profile-update.md` |
| S-010 | Admin User Management | Create, edit, disable users | `S-010-admin-user-management.md` |
| S-011 | Observability - Audit Logs | View, filter, search audit events | `S-011-observability-audit-logs.md` |
| S-012 | System Health | Infrastructure metrics, DB health, cache status | `S-012-system-health.md` |

---

## How to Use These Tests

### Running a Scenario Test

1. Open the scenario file (e.g., `S-002-user-login.md`)
2. Follow each step in order, executing the Chrome DevTools commands
3. Verify the expected result at each step
4. If a step fails, you've identified the breaking point

### Troubleshooting Mode

When a user reports "I can't login":
1. Open `S-002-user-login.md`
2. Execute each step
3. Step that fails = root cause location
4. Check the "If This Step Fails" section for diagnosis

---

## Scenario File Structure

Each scenario follows this format:

```markdown
# S-XXX: [Scenario Name]

## Scenario Overview
- **User Story**: As a [user], I want to [action] so that [outcome]
- **Preconditions**: What must be true before starting
- **Postconditions**: What should be true after completion
- **Test Data**: Credentials, URLs, etc.

## Test Steps

### Step 1: [Action Name]
**Action**: [What the user does]
**Execute**:
\`\`\`
[Chrome DevTools MCP command]
\`\`\`
**Expected**: [What should happen]
**If Fails**: [What to check / likely cause]

### Step 2: ...

## Edge Cases
- [Variation 1]: [How to test]
- [Variation 2]: [How to test]

## Execution Log
| Date | Tester | Result | Notes |
|------|--------|--------|-------|
```

---

## Test Data

### Standard Test Users

| Role | Email | Password | Notes |
|------|-------|----------|-------|
| Platform Owner | christian@{{PROJECT_DOMAIN}} | Admin123! | Full access |
| Tenant Admin | admin@tenant1.com | TenantAdmin1! | Tenant-scoped |
| Regular User | user@example.com | UserPass123! | Limited access |
| New User | (generate) | TestNewUser1! | For registration tests |

### Test URLs

| Environment | Admin Portal | Customer Portal | API |
|-------------|--------------|-----------------|-----|
| Local | http://localhost:8600 | http://localhost:8604 | http://localhost:8601 |
| Docker | http://localhost:4200 | http://localhost:4204 | http://localhost:4201 |

---

## Quick Reference: Chrome DevTools Commands

### Navigation
```
mcp__chrome-devtools__new_page(url="...")        # Open URL
mcp__chrome-devtools__navigate_page(type="reload") # Refresh
mcp__chrome-devtools__take_snapshot()            # Get page state + UIDs
```

### Interaction
```
mcp__chrome-devtools__fill(uid="X", value="...")  # Fill input
mcp__chrome-devtools__click(uid="X")              # Click element
mcp__chrome-devtools__wait_for(text="...")        # Wait for text
```

### Verification
```
mcp__chrome-devtools__list_network_requests()     # Check API calls
mcp__chrome-devtools__list_console_messages()     # Check for errors
mcp__chrome-devtools__take_screenshot()           # Visual capture
```

---

## Maintenance

- Update scenarios when UI changes
- Add new scenarios for new features
- Document all edge cases discovered during troubleshooting
- Keep execution logs for regression tracking
