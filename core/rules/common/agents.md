# Agents

Delegate to a specialist when the work has a domain. Descriptions say when.

| Situation | Role |
|---|---|
| Multi-system coordination, work-order management | `orchestrator` |
| Before declaring any work complete | `project-validator-expert` |
| Any database change | `database-validator-expert` |
| Any UI change | `frontend-validator-expert` |
| Something is broken | route by category — see `troubleshooting.md` |
| Security-sensitive change | `owasp-top10-expert` |
| Documentation placement | `documentation-expert` |
| Before sharing anything outside the project | `release-sanitizer` |
| Full-platform audit | `build-audit-supreme` |

Technology specialists exist for every major stack; pick by description.

## Delegation contract

- Independent work runs in parallel.
- If you delegate, you collect. A spawned task is not a finished task.
- Decompose only when the work does not fit one context.
- The subagent's final message is its deliverable; integrate it, then report.
