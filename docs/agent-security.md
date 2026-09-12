# Running Agents Safely

Everything an agent reads is executable context. A pull request, a PDF, a web
page, a tool description, a memory file: once text enters the context window
there is no reliable line between data and instruction. The runtime has to
assume the model will eventually read something hostile while holding
something valuable, and make that survivable.

This pipeline ships the mechanical parts. The rest is how you run it.

## What the pipeline enforces

| Risk | Mechanism |
|---|---|
| Credentials, personal data, or host paths leaving with your work | `bin/sanitize` on every share; `wo promote` and `new-project --pack` refuse on FAIL |
| Invisible or bidirectional unicode hiding instructions in agents, skills, or rules | `acp lint` rejects it |
| Secrets committed | `commit-quality` hook blocks credential-like staged lines |
| Agents weakening lint, format, or strictness config to pass checks | `config-protection` hook blocks edits to existing config |
| Destructive shell and git operations | markdown hook rules block database drops, force-push to shared branches, `--no-verify` |
| Security code commented out | `warn-commented-security` rule |
| Reading secret-bearing paths, piping the network to a shell | permission deny baseline installed into `.claude/settings.json` |
| Work "done" without evidence | `wo close` refuses without executed verification; the Stop hook checks |

## The minimum bar

Do these before running anything autonomous:

1. **Separate identities.** The agent gets its own email, its own bot account, its own short-lived scoped tokens. If it holds your accounts, a compromised agent is you.
2. **Isolate untrusted work.** Foreign repositories, attachment-heavy jobs, anything that reads the open web: run in a container or VM with no network by default.
   ```yaml
   services:
     agent:
       build: .
       user: "1000:1000"
       working_dir: /workspace
       volumes: ["./workspace:/workspace:rw"]
       cap_drop: [ALL]
       security_opt: ["no-new-privileges:true"]
       networks: [agent-internal]
   networks:
     agent-internal: { internal: true }
   ```
   Add egress only as an explicit, allow-listed exception. A container shares the host kernel; a VM is the stronger boundary when the stakes justify it.
3. **Deny by default.** The installed permission baseline denies reads of `~/.ssh`, `~/.aws`, and `.env*`, and blocks `curl | bash`, `ssh`, `scp`, and `nc`. Extend it for your project; never remove it to make a task easier.
4. **Least agency.** The model is not the final authority for unsandboxed shell, network egress, secret reads, writes outside the repository, or deployment. Those get an approval boundary between the model and the action. If a workflow auto-approves all of them, it is not autonomy; it is the brakes cut.
5. **Sanitise before a privileged agent reads.** Extract text from documents in a restricted step; strip comments and metadata; feed the cleaned summary, not the live link, to the agent that can act.
6. **Log what matters.** Tool name, input summary, files touched, approval decisions, network attempts, session id. Hijacked runs look odd in the trace before they look malicious.
7. **Have a real stop.** Kill the process group, not the parent. For unattended loops, a heartbeat with a supervisor that kills on stall. `loop-operator` describes the pattern.
8. **Keep memory narrow.** No secrets in memory files; project memory separate from user memory; reset after untrusted runs; none at all for high-risk workflows.
9. **Treat skills, hooks, agents, and MCP configuration as supply chain.** Read what you install. Run `acp lint` and `bin/sanitize` on anything that arrives from outside; the lint catches the unicode tricks a human cannot see.

## Trust boundaries in this pipeline

- **Project configuration is executable.** `.claude/settings.json`, hooks, and MCP configuration ship with the repository. Cloning a repository and opening the tool runs them once the directory is trusted. Review them like code in every pull request.
- **Hook rules are policy.** They live in the repository and in `.claude/hook-rules/`. A change to a `block` rule is a security change and is reviewed as one.
- **Packs are content.** They are read by agents as precedent. A poisoned pack is a poisoned context. `wo promote` sanitises what goes in; review what you import from elsewhere.

## When something goes wrong

1. Stop the process group.
2. Rotate every credential the session could have reached, whether or not you have evidence it was used.
3. Read the log for the first anomalous tool call and everything after it.
4. Open a bug with `--category security`; the routing brings in the right reviewers.
5. Add the pattern as a hook rule so it blocks next time.

## Build as if

Malicious text will get into context. A tool description can lie. A
repository can be poisoned. Memory can persist the wrong thing. The model will
occasionally lose the argument.

Then make losing survivable. One rule covers most of it: never let the
convenience layer outrun the isolation layer.
