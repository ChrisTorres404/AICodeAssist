# Code Review

Review is mandatory after writing or modifying code, before any shared commit,
and before closing a work order.

## Checklist

- [ ] Readable, well named, focused functions, no deep nesting
- [ ] Errors handled explicitly; messages useful; no silent catches
- [ ] No secrets, no debug logging, no stubs, no unverified references
- [ ] Behavioral tests exist for the change and were **executed**
- [ ] The work order is referenced and its SPEC still matches what shipped

## Severity

| Level | Meaning | Action |
|---|---|---|
| CRITICAL | Security, data loss, or a false claim of verification | Block |
| HIGH | A bug or a significant quality problem | Fix before merge |
| MEDIUM | Maintainability | Fix when practical |
| LOW | Style | Optional |

## Security triggers

Stop and bring in the security role when a change touches authentication,
authorization, user input, database queries, file paths, external calls,
cryptography, secrets, or money.

## Anti-patterns that have caused rework

- **Tests-pass tunnel vision.** Green tests are not a review.
- **Incremental patching.** Fix the symptom, then step back and review the whole.
- **Expedience.** Debug lines left in, values copy-pasted, cleanup skipped.
