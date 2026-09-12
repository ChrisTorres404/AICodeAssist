# BUG-XXXX: [Short Title] - CLOSEOUT

## Closeout Metadata

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-XXXX |
| **Status** | Closed |
| **Closed Date** | YYYY-MM-DD |
| **Fixed In Version** | v0.0.0 |
| **Deployed To** | Local / Dev / Stage / Prod |
| **Related WO(s)** | WO-XXXX, WO-YYYY |
| **PR/Commit** | #123 or `abc1234` |
| **Time to Fix** | X hours / X days |

---

## Fix Summary

Brief description of what was fixed and how. Include:
- What the root cause was
- What approach was taken
- What files were changed

---

## Verification Checklist

### Code Changes
- [ ] All code changes committed
- [ ] Code annotations added (WO + BUG comments)
- [ ] No regressions introduced
- [ ] Code review completed

### Testing Completed
- [ ] Manual testing passed
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Behavioral tests passed
- [ ] CI pipeline passing

### Documentation Updated
- [ ] Bug document complete (`BUG-XXXX-[slug].md`)
- [ ] Changelog updated (if applicable)
- [ ] API docs updated (if applicable)
- [ ] User-facing docs updated (if applicable)

### Deployment
- [ ] Deployed to Dev
- [ ] Deployed to Stage
- [ ] Deployed to Prod
- [ ] Monitored for issues post-deploy (minimum 24 hours)

---

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `[path/to/file]` | Modified | [what changed] |
| `[path/to/file]` | Added | [what changed] |
| `path/to/<unit test file>` | Added | New test coverage |

---

## Test Results

### Unit Tests
```
Test Suites: X passed, X total
Tests:       X passed, X total
```

### Integration Tests
```
[Test output or summary]
```

### Behavioral Tests
```
[Test output or summary]
```

---

## Final Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| **Developer** | __________ | YYYY-MM-DD | [ ] |
| **Code Reviewer** | __________ | YYYY-MM-DD | [ ] |
| **QA Verifier** | __________ | YYYY-MM-DD | [ ] |
| **Product Owner** | __________ | YYYY-MM-DD | [ ] |

---

## Post-Mortem (Required for High/Critical Bugs)

### Timeline
| Time | Event |
|------|-------|
| YYYY-MM-DD HH:MM | Bug reported |
| YYYY-MM-DD HH:MM | Investigation started |
| YYYY-MM-DD HH:MM | Root cause identified |
| YYYY-MM-DD HH:MM | Fix implemented |
| YYYY-MM-DD HH:MM | Fix deployed |
| YYYY-MM-DD HH:MM | Fix verified |

### What Went Well
- Item 1
- Item 2

### What Could Be Improved
- Item 1
- Item 2

### Action Items for Prevention

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action to prevent recurrence] | Name | YYYY-MM-DD | Pending / Done |
| [Process improvement] | Name | YYYY-MM-DD | Pending / Done |

---

## Linked Artifacts

| Type | Link/Path |
|------|-----------|
| Bug Document | `./BUG-XXXX-[slug].md` |
| Work Order(s) | `/{{WORKORDERS_DIR}}/WO-XXXX-*/` |
| PR | `#123` |
| Commit | `abc1234` |
| CI Run | [Link to CI run] |
| Test Results | [Link to test report] |

---

## Closure Statement

[State what was verified, by which suite and run, and where the fix is deployed. Do not write this sentence until it is true.]

**Root Cause:** [One sentence summary]

**Resolution:** [One sentence summary]

**Closed by:** __________
**Date:** YYYY-MM-DD
