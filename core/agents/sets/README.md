# Agent sets

Optional agents for a domain, installed on request:

```bash
# pipeline.config.sh
export AGENT_SETS="identity"
```

or `new-project --agent-set identity`. Everything in a set lands in
`.claude/agents/` beside the base fleet.

| Set | Agents | For |
|---|---|---|
| `identity` | `clerk-architect`, `clerk-architect-mythic`, `supabase-architect`, `supabase-architect-mythic`, `oauth-oidc-mythic`, `fusion-facilitator`, `sdk-chief-architect`, `sdk-expert` | Authentication, authorization, multi-tenant, OAuth/OIDC, and client-SDK platforms |
| `ml` | `mle-reviewer`, `rag-pipeline-reviewer`, `pytorch-build-resolver` | Production ML pipelines, retrieval systems, PyTorch training and serving |
| `network` | `network-architect`, `network-troubleshooter`, `network-config-reviewer`, `homelab-architect` | Network design, diagnostics, and device configuration review |
| `healthcare` | `healthcare-reviewer` | Clinical safety, PHI handling, and compliance in healthcare software |
| `gan` | `gan-planner`, `gan-generator`, `gan-evaluator` | A generate-and-evaluate build loop: expand a brief into a spec, implement, evaluate against it, iterate |

The two architect styles deliberately disagree: API-first versus
database-first. `fusion-facilitator` exists to reconcile them into one
design. The mythic tier holds both stacks at once and is the agent to use
for a full identity architecture review.
