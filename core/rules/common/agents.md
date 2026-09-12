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
| Build or type-check broken | `build-error-resolver` |
| Errors that hide (empty catches, bad fallbacks) | `silent-failure-hunter` |
| Designing or reviewing a data model's types | `type-design-analyzer` |
| Code works but reads badly, after a change lands | `code-simplifier` |
| Dead code, duplicates, unused dependencies | `refactor-cleaner` |
| Browser journey verification | `e2e-runner` |
| Undocumented module needs a baseline before changing it | `spec-miner` |
| Something is slow | `performance-optimizer` |

Technology specialists exist for every major stack; pick by description.

## Delegating a work order

`wo new --area <area>` records this on the work order and prints it. BACKEND,
UI, and DATA resolve to the detected stack's specialist.

| Area | Implement with | Backup | Validate with |
|---|---|---|---|
| backend | BACKEND | `architect` | `project-validator-expert` |
| api | `rest-expert` | BACKEND | `openapi-expert` |
| database | DATA | `postgres-expert` | `database-validator-expert` |
| auth | `jwt-expert` | BACKEND | `iam-rbac-expert` |
| rbac | `iam-rbac-expert` | `jwt-expert` | `project-validator-expert` |
| frontend / ui | UI | `ux-ui-designer-expert` | `frontend-validator-expert` |
| styling | `css-expert` | UI | `ux-ui-designer-expert` |
| testing | `tdd-guide` | `e2e-runner` | `project-validator-expert` |
| cicd | `github-actions-expert` | `docker-expert` | `project-validator-expert` |
| docker | `docker-expert` | `github-actions-expert` | `project-validator-expert` |
| security | `owasp-top10-expert` | `jwt-expert` | `project-validator-expert` |
| performance | `performance-optimizer` | BACKEND | `project-validator-expert` |
| analysis | `repo-analyst` | `code-explorer` | `factuality-validator` |
| integration | `e2e-runner` | BACKEND | `project-validator-expert` |
| docs | `documentation-expert` | `developer-experience-writer` | `critical-reviewer` |

The validator is never the agent that implemented. For bugs, see
`troubleshooting.md`.

## Delegation contract

- Independent work runs in parallel.
- If you delegate, you collect. A spawned task is not a finished task.
- Decompose only when the work does not fit one context.
- The subagent's final message is its deliverable; integrate it, then report.
