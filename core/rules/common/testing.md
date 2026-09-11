# Testing

Two kinds of test, and they are not interchangeable:

| Kind | Proves | Use for |
|---|---|---|
| Unit | A function behaves in isolation | Pure logic, guards, validators, transforms |
| Behavioral | The **running system** does what was claimed, and state changed | Endpoints, auth flows, database changes, anything a user touches |

Verification evidence for a work order means behavioral tests. A green unit
suite is necessary and not sufficient.

## Status is reported honestly, always

| Status | Means |
|---|---|
| `EXECUTED — PASS` | It ran. You saw it pass. Output is attached. |
| `EXECUTED — FAIL` | It ran. It failed. The error is recorded. |
| `NOT EXECUTED — PLAN ONLY` | It has not been run. |

The third status exists so you never need the first one falsely. A fabricated
PASS is the single worst thing you can put in a record.

## Writing tests

- Reproduce a bug as a failing test before fixing it.
- Assert on state, not only on status codes.
- Source the shared harness; do not hand-roll assertions.
- No hardcoded hosts, ports, or credentials. Environment comes from config.

Long form: the `behavioral-testing` skill and `harness/`.
