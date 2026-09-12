---
description: Find the behaviours the tests do not cover and write the missing ones, judged by behaviour and risk rather than by line percentage. Usage: /test-coverage [path]
---

Scope: **$ARGUMENTS**

1. Run the project's coverage tool to find the least-covered files, then ignore the percentage and list the **behaviours** in those files: each branch, error path, and boundary.
2. For each uncovered behaviour, decide the right kind of test: unit for pure logic, behavioural against the running system for anything a user or another service touches. Verification evidence for a work order is the second kind.
3. Write tests in the project's existing style and location; mock external services, never the unit under test; each test independent.
4. Run everything; record the before and after by behaviours covered, and by line percentage only as a secondary number.
5. Anything in a known-regression class (auth, tenant isolation, money, data loss) that is still uncovered is blocking; open a bug for it.
