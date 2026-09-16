# {{PROJECT_NAME}} UI Scenario Testing Methodology

> **Purpose:** executable UI test scenarios for user-journey verification and
> troubleshooting.
> **Tool:** a browser automation MCP server, driven by the `e2e-runner` agent.

---

## Overview

A scenario test is an **executable runbook**. It does three jobs:

1. Verifies a complete user journey works end to end
2. Gives whoever is debugging a step-by-step path through the same journey
3. Pinpoints which step in the flow is actually failing

Each scenario is a real use case written as a numbered sequence of browser
commands with an expected result after every one. A journey verified this way
counts as behavioral evidence; see
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` for how
it is recorded.

---

## Scenario Index (example set)

The table below is an **example** for an application that has accounts, a
resource people manage, and something they submit. Replace it with this
project's real journeys; keep the shape. The numbering is arbitrary and local
to the scenario directory.

| ID | Scenario | Description | Suite File |
|----|----------|-------------|------------|
| S-001 | New user registration | Signup from landing page through to first screen | `S-001-new-user-registration.md` |
| S-002 | Sign in | Sign in with valid credentials, plus the error cases | `S-002-sign-in.md` |
| S-003 | Sign out | Sign out and confirm the session is cleared | `S-003-sign-out.md` |
| S-004 | Password reset | Request reset, follow the link, set a new password, sign in | `S-004-password-reset.md` |
| S-005 | Profile update | Edit profile fields and confirm they persist | `S-005-profile-update.md` |
| S-006 | Create, edit, delete a record | The full lifecycle of the app's primary resource, including validation errors and the delete confirmation | `S-006-record-lifecycle.md` |
| S-007 | Search and filter a list | Filter, sort, paginate, and deep-link to a filtered view | `S-007-list-search-filter.md` |
| S-008 | Checkout or submission | Assemble a cart or form, submit it, confirm the receipt and the resulting record | `S-008-checkout.md` |
| S-009 | Bulk import | Upload a file, review the preview, commit, and verify what landed | `S-009-bulk-import.md` |
| S-010 | Administrative user management | Create, edit, and disable a user as an administrator | `S-010-admin-user-management.md` |
| S-011 | Audit and activity history | View, filter, and search recorded activity | `S-011-activity-history.md` |
| S-012 | System health | Health endpoints, dependency status, background job state | `S-012-system-health.md` |

Cover at least one journey of each kind: an entry journey (someone arrives and
gets in), a lifecycle journey (someone creates, changes, and removes a
record), and a transaction journey (someone submits something irreversible).
Those three catch different classes of failure.

### Journeys to add when the application has them

These are not in the base set because not every application has them, but each
is a journey that breaks in production more often than the happy path, and
each is worth a scenario of its own the moment the feature exists.

| ID | Scenario | Description |
|----|----------|-------------|
| S-013 | Account activation | Verification link from the message through to an activated account, including an expired link and a reused link |
| S-014 | Second-factor enrollment | Enable the second factor, store the recovery codes, confirm the next sign-in demands it |
| S-015 | Second-factor sign-in | Sign in through the challenge, including a wrong code and a recovery code |
| S-016 | Session timeout | Idle until the session expires, confirm the redirect, confirm silent renewal where it applies, re-authenticate |
| S-017 | Permission boundary | A restricted account attempts an administrative journey and is refused at every entry point, including a deep link straight to the page |

A journey that involves waiting — activation links, idle timeouts — is
scripted with the configured window read from the test configuration, not with
a literal number copied out of the code.

---

## How to Use These Tests

### Running a scenario

1. Open the scenario file, for example `S-002-sign-in.md`
2. Follow each step in order, executing its browser command
3. Verify the expected result at each step
4. The first step that does not produce its expected result is the breaking
   point

### Troubleshooting mode

When someone reports "I can't sign in":

1. Open `S-002-sign-in.md`
2. Execute each step
3. The step that fails locates the root cause
4. Read that step's "If this step fails" notes for the likely diagnosis

---

## Scenario File Structure

Each scenario follows this format:

```markdown
# S-XXX: [Scenario Name]

## Scenario Overview
- **User story**: As a [user], I want to [action] so that [outcome]
- **Preconditions**: what must be true before starting
- **Postconditions**: what must be true after completion
- **Test data**: accounts, fixtures, URLs

## Test Steps

### Step 1: [Action Name]
**Action**: what the user does
**Execute**:
\`\`\`
[browser automation command]
\`\`\`
**Expected**: what should happen
**If this step fails**: what to check, and the likely cause

### Step 2: ...

## Edge Cases
- [Variation]: how to test it

## Execution Log
| Date | Tester | Result | Notes |
|------|--------|--------|-------|
```

---

## Test Data

### Standard test accounts

Define one account per access level the application has, seeded by the
project's own fixture or seed command so the set is reproducible. Credentials
come from the test configuration, never from this document — a password
written into a checked-in runbook is a credential leak.

| Access level | Account | Notes |
|---|---|---|
| Administrator | from test config | Full access |
| Standard user | from test config | Normal access |
| Restricted user | from test config | Should be denied the administrative journeys |
| New user | generated per run | For registration scenarios |

### Test URLs

| Target | Value |
|---|---|
| Web application | `{{WEB_ORIGIN}}` |
| API | `{{API_BASE_URL}}` |

Both come from the harness configuration, so a scenario runs unchanged
against any environment. No scenario hardcodes a host or a port.

---

## Browser Command Reference

Commands come from whichever browser automation MCP server is configured for
this project; the shapes below are illustrative. Check the server's own tool
list for exact names before writing a scenario, and do not invent one.

| Purpose | Command shape |
|---|---|
| Open a URL | `new_page(url="...")` |
| Reload | `navigate_page(type="reload")` |
| Read page state and element ids | `take_snapshot()` |
| Fill an input | `fill(uid="...", value="...")` |
| Click | `click(uid="...")` |
| Wait for content | `wait_for(text="...")` |
| Inspect network calls | `list_network_requests()` |
| Inspect console errors | `list_console_messages()` |
| Capture the screen | `take_screenshot()` |

Every scenario ends by checking the console and network lists. A journey that
completes while throwing errors has not passed.

---

## Recording the Result

A scenario run is behavioral evidence and is recorded with the same vocabulary
as every other suite: `EXECUTED — PASS`, `EXECUTED — FAIL`, or
`NOT EXECUTED — PLAN ONLY`. A run is only PASS when every step produced its
expected result and the console and network checks at the end were clean.

Evidence for a UI scenario is:

- The screenshot or page snapshot at the step that matters
- The network entries for the calls that step made, with their status codes
- The console output, showing there were no errors
- Where the journey was supposed to change stored state, a read of that state
  confirming it did

Write the run into the scenario's execution log, and the report into
`{{TESTING_DIR}}/results/` alongside the other behavioral reports. Use
`{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-VERIFICATION-UI.md`
for the written verification.

A scenario that stopped halfway is `EXECUTED — FAIL` at the step it stopped on,
named. It is never reported as "mostly passed".

---

## Maintenance

- Update a scenario in the same change that alters the UI it describes
- Add a scenario with each new user-facing journey
- Record every edge case found during troubleshooting; that is where the
  value accumulates
- Keep the execution log; it is the regression history
