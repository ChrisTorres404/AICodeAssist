# WO-XXXX: Task Breakdown

**Estimated Effort:** ~X-Y hours (Z days)

---

## Tasks

Every task names the file it lands in and who owns it. A task with no file is
not yet a task; a task with no owner is not yet scheduled.

### Phase 1: [Phase Name] (X hours)

| # | Task | Effort | Description | File(s) | Assignee |
|---|------|--------|-------------|---------|----------|
| 1 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |
| 2 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |
| 3 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |

### Phase 2: [Phase Name] (X hours)

| # | Task | Effort | Description | File(s) | Assignee |
|---|------|--------|-------------|---------|----------|
| 4 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |
| 5 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |
| 6 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |

### Phase 3: [Phase Name] (X hours)

| # | Task | Effort | Description | File(s) | Assignee |
|---|------|--------|-------------|---------|----------|
| 7 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |
| 8 | [Task name] | Xh | [Brief description] | `path/to/file` | TBD |

### Phase 4: Testing & Polish (X hours)

| # | Task | Effort | Description | File(s) | Assignee |
|---|------|--------|-------------|---------|----------|
| 9 | Write unit and integration tests | Xh | The isolated checks, with dependencies mocked | `path/to/the unit tests` | TBD |
| 10 | Polish & edge cases | Xh | Error handling, loading states | `path/to/file` | TBD |

### Phase 5: Behavioral Testing (X hours)

The evidence phase. These four tasks run against the running system, not
against mocks, and they are what `wo close` is refused without.

| # | Task | Effort | Description | File(s) | Assignee |
|---|------|--------|-------------|---------|----------|
| 11 | Create test harness | Xh | Plan every check: request, expected response, expected state change | `{{WORKORDERS_DIR}}/WO-XXXX-<name>/wo-XXXX-test-harness.md` | TBD |
| 12 | Execute tests | Xh | Run them against the running system and capture the real output | Terminal | TBD |
| 13 | Document evidence | Xh | Record what actually happened, status per check | `{{WORKORDERS_DIR}}/WO-XXXX-<name>/WO-XXXX-VERIFICATION.md` | TBD |
| 14 | Create the behavioural suite | Xh | The repeatable script, so the evidence can be reproduced | `{{TESTING_DIR}}/suites/wo-XXXX-<feature>.sh` | TBD |

---

## Dependencies Graph

```
[Component A]
       ↓
[Component B] ← [Service C]
       ↓
[Component D]
       ↓
[Final Integration]
```

---

## File Creation Order

1. `[path/to/foundational/file]` - [Why first]
2. `[path/to/second/file]` - [Depends on 1]
3. `[path/to/third/file]` - [Depends on 1, 2]
4. `[path/to/integration/file]` - [Brings it together]
5. `[path/to/the behavioural suite]` - [Verify everything]

---

## Risk Factors

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | High/Med/Low | [How to mitigate] |
| [Risk 2] | High/Med/Low | [How to mitigate] |
| [Risk 3] | High/Med/Low | [How to mitigate] |

---

## Blockers

- [ ] [Blocker 1 - e.g., "Waiting on API endpoint"]
- [ ] [Blocker 2 - e.g., "Need design approval"]

---

## Notes

[Additional context, assumptions, or clarifications]
