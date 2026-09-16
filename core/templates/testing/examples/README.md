# Example behavioural suites

Two complete suites in the shape every behavioural suite has. Copy one, change the
endpoints and table names at the top, and you have a suite `wo verify --run` can record.

| File | What it shows |
|---|---|
| `crud-with-state-verification.sh` | create, read, update, refuse, delete; every check on the actual value that came back, then the actual row in the database |
| `auth-flow.sh` | register, sign in, use the token, refuse the wrong password and a forged token, sign out, confirm the token is dead and the session row says why |

What makes them behavioural, and not end-to-end tests with stubs:

- **Nothing is mocked.** Every request goes to the running service; every query goes to the real
  database. A suite that passes against a stub has proven the stub.
- **The value is the assertion.** The title that was sent is the title expected back; the id
  that was returned is the id looked up. "The call succeeded" is not a check.
- **State is verified where it lives.** A created record is confirmed in the table, not inferred
  from a 201. A revoked session is confirmed as a row marked revoked, not as a 401 alone.
- **Refusals are checked as carefully as successes,** with the exact status and no side effect.
- **The suite creates what it needs and removes it.** It runs for anyone, on any machine.
- **Preconditions exit 77.** No service, no base URL: nothing was asserted, and the driver
  records that as `NOT EXECUTED — PRECONDITION FAILED`, never as a failure of the code.
