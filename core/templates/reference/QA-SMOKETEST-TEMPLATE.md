# Smoke Test Checklist — Template

## How to use this template

A smoke test is the shortest sequence of manual checks that proves a build is
worth testing further. It is not a substitute for the behavioural suites under
`{{TESTING_DIR}}/suites/` — those run unattended and produce evidence. This
document covers what a person has to look at: rendering, navigation, the shape
of a response in the network tab, and whether the thing feels broken.

1. Copy this file to `{{TESTING_DIR}}/smoketest/smoketest-YYYY-MM-DD.md`, one
   copy per run. The completed copy is the record of that run.
2. Fill the header block before you start, not after.
3. Delete whole sections that do not apply to this project, and add sections
   for the areas it has that this template does not list. The section list is
   a starting taxonomy, not a fixed set.
4. Tick `Pass` or `Fail` for every row. A row with neither ticked reads as
   "not run", which is a legitimate outcome — write why in Notes.
5. Every Fail becomes a bug document before the run is signed off. Put the bug
   number in the Notes column and in the Issues Found table.

Replace `WO-NNNN` references with the work orders this build actually
contains. `{{ADMIN_APP}}`, `{{API_APP}}` and the ports below are placeholders;
the example values are the generic local block documented in
`PORT-ALLOCATION-STANDARD.md` in this directory.

---

# {{PROJECT_NAME}} Admin Console — Smoke Test Checklist

**Date:** _______________
**Tester:** _______________
**Build/Commit:** _______________
**Environment:** [ ] Local [ ] Staging [ ] Production

---

## Quick Start

```bash
# Start services
cd {{API_APP}} && npm run dev
cd {{ADMIN_APP}} && npm run dev

# URLs
# Admin UI: http://localhost:3000
# API: http://localhost:3001
```

Confirm both processes are actually serving before ticking anything:

```bash
curl -s -o /dev/null -w "admin %{http_code}\n" http://localhost:3000
curl -s -o /dev/null -w "api   %{http_code}\n" http://localhost:3001/api/v1/health
```

---

## Auth and Session

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Login as platform owner works | [ ] | [ ] | |
| Dashboard loads with metrics | [ ] | [ ] | |
| Logout works; redirects to login | [ ] | [ ] | |
| Session persists across page refresh | [ ] | [ ] | |
| MFA challenge works (if enabled) | [ ] | [ ] | |
| Token refresh automatic (after ~10 min) | [ ] | [ ] | Check Network tab |
| `/auth/refresh` returns `privileges` array | [ ] | [ ] | WO-0001 |
| `/auth/refresh` returns `roles` array | [ ] | [ ] | WO-0001 |
| `/auth/session` returns `privileges` array | [ ] | [ ] | |

---

## Tenants

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Tenant list loads | [ ] | [ ] | |
| Pagination works | [ ] | [ ] | |
| Search tenants works | [ ] | [ ] | |
| Filter by status works | [ ] | [ ] | |
| Create new tenant succeeds | [ ] | [ ] | |
| Tenant detail page loads | [ ] | [ ] | |
| All 8 tabs render without error | [ ] | [ ] | |
| Suspend tenant works | [ ] | [ ] | |
| Reactivate tenant works | [ ] | [ ] | |
| Delete tenant (soft) works | [ ] | [ ] | |

---

## Tenant-Scoped Resources (WO-0002)

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Tenant Integrations: API keys are tenant-only | [ ] | [ ] | Not global list |
| Tenant Integrations: Webhooks are tenant-only | [ ] | [ ] | Not global list |
| Tenant Audit Logs: Shows tenant events only | [ ] | [ ] | Critical fix |
| Create API key in tenant-one, not visible in tenant-two | [ ] | [ ] | |

---

## Users

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| User list loads (infinite scroll) | [ ] | [ ] | |
| Search users by email works | [ ] | [ ] | |
| Filter by status works | [ ] | [ ] | |
| Filter by MFA status works | [ ] | [ ] | |
| Create new user succeeds | [ ] | [ ] | |
| User detail page loads | [ ] | [ ] | |
| Details tab: Can edit profile | [ ] | [ ] | |
| Security tab: Shows MFA status | [ ] | [ ] | |
| Sessions tab: Lists active sessions | [ ] | [ ] | |
| Sessions tab: Terminate session works | [ ] | [ ] | |
| Audit Log tab: Shows user activity | [ ] | [ ] | |
| Lock user works; status updates | [ ] | [ ] | |
| Unlock user works; status updates | [ ] | [ ] | |
| Force password reset works | [ ] | [ ] | |
| Delete user (soft) works | [ ] | [ ] | |

---

## RBAC - Roles (WO-0001)

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Role list loads | [ ] | [ ] | |
| Pagination works | [ ] | [ ] | |
| Create new role succeeds | [ ] | [ ] | |
| Role detail page loads | [ ] | [ ] | |
| Privileges section visible | [ ] | [ ] | |
| Current privileges displayed correctly | [ ] | [ ] | |
| "Manage Privileges" button opens dialog | [ ] | [ ] | |
| Privilege search works in dialog | [ ] | [ ] | |
| Privileges grouped by category | [ ] | [ ] | |
| Can select/deselect privileges | [ ] | [ ] | |
| Save privileges succeeds (no error) | [ ] | [ ] | |
| Privileges persist after save | [ ] | [ ] | Refresh page |
| System roles: privileges read-only | [ ] | [ ] | Cannot modify |
| Add member to role works | [ ] | [ ] | |
| Remove member from role works | [ ] | [ ] | |
| Duplicate role works | [ ] | [ ] | |
| Delete custom role works | [ ] | [ ] | |
| Cannot delete system role | [ ] | [ ] | Should show error |

---

## RBAC - Privilege Enforcement

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| User without privilege sees BlockedState | [ ] | [ ] | |
| BlockedState shows required privilege name | [ ] | [ ] | |
| Create button hidden when lacking create privilege | [ ] | [ ] | |
| Edit button hidden when lacking update privilege | [ ] | [ ] | |
| Delete button hidden when lacking delete privilege | [ ] | [ ] | |
| API rejects unauthorized request (401/403) | [ ] | [ ] | |
| `useHasPrivilege()` returns correct boolean | [ ] | [ ] | |

Hiding a control is a convenience, not a control. The API rejection row is the
one that matters; if the button is hidden but the endpoint accepts the call,
the row fails.

---

## Settings

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Settings page loads | [ ] | [ ] | |
| Category grid displays | [ ] | [ ] | |
| Can navigate to category detail | [ ] | [ ] | |
| Tenant settings override works | [ ] | [ ] | |

---

## Webhooks

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Webhook list loads | [ ] | [ ] | |
| Create webhook succeeds | [ ] | [ ] | |
| Test webhook sends payload | [ ] | [ ] | Use a request-capture endpoint you control |
| Delivery history loads | [ ] | [ ] | |
| Delete webhook works | [ ] | [ ] | |

---

## API Keys

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| API key list loads | [ ] | [ ] | |
| Create API key shows secret once | [ ] | [ ] | |
| Secret not retrievable after creation | [ ] | [ ] | |
| Revoke API key works | [ ] | [ ] | |

---

## Audit Logs

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Audit log page loads | [ ] | [ ] | |
| Feed view displays events | [ ] | [ ] | |
| Ledger view with expandable rows | [ ] | [ ] | |
| Timeline view groups by day | [ ] | [ ] | |
| Filter by category works | [ ] | [ ] | |
| Filter by severity works | [ ] | [ ] | |
| Filter by date range works | [ ] | [ ] | |
| Forensic snapshot shows stats | [ ] | [ ] | |
| Diff modal shows old/new values | [ ] | [ ] | |

---

## Error Handling

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| ErrorState displays on API failure | [ ] | [ ] | |
| Retry button triggers refetch | [ ] | [ ] | |
| EmptyState displays when no data | [ ] | [ ] | |
| LoadingState displays during fetch | [ ] | [ ] | |
| Toast notifications appear on success | [ ] | [ ] | |
| Toast notifications appear on error | [ ] | [ ] | |

---

## Token Refresh Privileges Verification (WO-0001)

**Manual Verification Steps:**

1. Open DevTools, Network tab
2. Login as platform owner
3. Wait 10+ minutes OR manually trigger refresh
4. Find the `/auth/refresh` request
5. Check Response body:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "privileges": ["admin:users:read", "admin:roles:read", "..."],
  "roles": ["Platform Owner", "..."]
}
```

| Check | Pass | Fail |
|-------|------|------|
| `privileges` array present in refresh response | [ ] | [ ] |
| `roles` array present in refresh response | [ ] | [ ] |
| Privilege changes reflected after refresh | [ ] | [ ] |

---

## Browser and Console Checks

Run once per build, on the browser the project supports.

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| No uncaught errors in the console on any visited page | [ ] | [ ] | |
| No failed network requests other than the ones under test | [ ] | [ ] | |
| Page usable at the narrowest supported viewport | [ ] | [ ] | |
| Primary actions reachable from the keyboard | [ ] | [ ] | |

---

## Performance Checks

| Test | Target | Actual | Pass |
|------|--------|--------|------|
| Dashboard load time | < 2s | ___ms | [ ] |
| Tenant list load time | < 1s | ___ms | [ ] |
| User list (first page) load time | < 1s | ___ms | [ ] |
| Role list load time | < 1s | ___ms | [ ] |
| Audit log load time | < 2s | ___ms | [ ] |

Measure from the Network tab's total time for the page's own document plus its
data requests, on a warm cache, three times, and record the median.

---

## Summary

| Category | Passed | Failed | Skipped |
|----------|--------|--------|---------|
| Auth and Session | ___ | ___ | ___ |
| Tenants | ___ | ___ | ___ |
| Tenant-Scoped | ___ | ___ | ___ |
| Users | ___ | ___ | ___ |
| RBAC Roles | ___ | ___ | ___ |
| RBAC Enforcement | ___ | ___ | ___ |
| Settings | ___ | ___ | ___ |
| Webhooks | ___ | ___ | ___ |
| API Keys | ___ | ___ | ___ |
| Audit Logs | ___ | ___ | ___ |
| Error Handling | ___ | ___ | ___ |
| Browser and Console | ___ | ___ | ___ |
| **TOTAL** | ___ | ___ | ___ |

---

## Issues Found

| # | Description | Severity | Steps to Reproduce |
|---|-------------|----------|-------------------|
| 1 | | [ ] Critical [ ] High [ ] Medium [ ] Low | |
| 2 | | [ ] Critical [ ] High [ ] Medium [ ] Low | |
| 3 | | [ ] Critical [ ] High [ ] Medium [ ] Low | |

Each row above becomes a bug document:

```bash
bug new "<description>"     # opens {{BUGS_DIR}}/BUG-NNNN-<slug>/
```

---

## Sign-Off

- [ ] All critical tests passed
- [ ] No blocking issues found
- [ ] Ready for demo / release
- [ ] Every Fail row has a bug number in Notes
- [ ] This completed copy is saved under `{{TESTING_DIR}}/smoketest/`

**Tester Signature:** _______________
**Date:** _______________
