# Security

## Before any commit

- [ ] No hardcoded secrets: keys, passwords, tokens, connection strings
- [ ] User input validated at the boundary
- [ ] Parameterized queries only
- [ ] Output escaped where it meets a browser
- [ ] CSRF protection on state-changing requests
- [ ] Authentication and authorization checked on every protected path
- [ ] Rate limiting where abuse is possible
- [ ] Error messages reveal nothing internal

## Secrets

Environment variables or a secret manager. Validate presence at startup.
Anything that may have leaked gets rotated, not just deleted.

## When something is found

1. Stop.
2. Bring in the security role.
3. Fix CRITICAL before anything else.
4. Rotate what was exposed.
5. Search the codebase for the same pattern elsewhere.

## Before anything leaves the machine

Run `bin/sanitize` on it. A FAIL is a FAIL.
