# Troubleshooting

Route a problem to the right specialist before theorising about it. The
category decides who investigates, who fixes, and who validates.

| Category | Investigate with | Fix with | Validate with |
|---|---|---|---|
| Auth, sessions, tokens | `support-engineer-expert` + `jwt-expert` | `jwt-expert`, `oauth-oidc-expert`, or `iam-rbac-expert` | `owasp-top10-expert`, then `project-validator-expert` |
| API, SDK, contracts | `support-engineer-expert` + `rest-expert` | the stack's backend specialist | `project-validator-expert` |
| Database, migrations | `database-validator-expert` + `postgres-expert` | `postgres-expert` or `typeorm-expert` | `database-validator-expert` |
| UI, frontend | `support-engineer-expert` + `react-expert` | the stack's UI specialist | `frontend-validator-expert` |
| Observability, metrics | `support-engineer-expert` + `prometheus-expert` | `prometheus-expert` or `grafana-expert` | `project-validator-expert` |
| Security | `owasp-top10-expert` + `support-engineer-expert` | `jwt-expert`, `iam-rbac-expert`, or `owasp-top10-expert` | `owasp-top10-expert`, then `project-validator-expert` |
| Performance | `performance-optimizer` + `postgres-expert` | `nodejs-expert`, `postgres-expert`, or `redis-expert` | `project-validator-expert` |
| Integration, webhooks, realtime | `support-engineer-expert` + `rest-expert` | the stack's backend specialist or `websocket-expert` | `project-validator-expert` |
| Configuration, deployment | `support-engineer-expert` + `docker-expert` | `docker-expert` or `github-actions-expert` | `project-validator-expert` |
| Documentation | `documentation-expert` | `documentation-expert` | `documentation-expert` |
| A failing test suite | Explore for context, then `support-engineer-expert`, then `database-validator-expert` | the fixing agent for the failure's category | `project-validator-expert` |
| A failing build or type-check | `build-error-resolver` (fixes, minimal diff) | `build-error-resolver` | `project-validator-expert` |
| Data missing or wrong with no error | `silent-failure-hunter` | the fixing agent for the area | `project-validator-expert` |
| Browser flow broken | `e2e-runner` reproduces | the stack's UI specialist | `frontend-validator-expert` |

"The stack's specialist" is resolved by `bin/stack-specialist` from the detected
stack: `nestjs-expert`, `python-expert`, `react-expert`, and so on.

## How investigation is delegated

- **Investigators investigate.** They do not edit. They return findings with
  `file:line` references, what they verified, and what would disprove their
  theory. The fix is a separate delegation.
- **Give them the error verbatim**, the file paths involved, what has already
  been tried, and the database name when data is in question.
- **Escalate in order for test failures:** context first (what changed, what
  the conventions are), then active debugging (why this endpoint or test
  fails), then infrastructure (does the table exist, did the migration run,
  is the module registered). Most failures resolve at the step people skip.
- **Database before theory.** Verify a column, table, or enum against the
  real database before assuming the entity is right. Entities drift.
- **One validator signs off**, and it is never the agent that wrote the fix.

`bug new --category <name>` records the routing on the bug and numbers it in
the category's series.
