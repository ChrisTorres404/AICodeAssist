# parity-without-claude

Proves the rules hold with nothing Claude-specific present: git and `acp check` enforce them under any agent.

Most of the pipeline's rules began as Claude Code session hooks. A session hook sees one tool call,
inside one client; an agent that is not Claude Code, or a person at a terminal, never meets it. This
scaffolds a project, deletes `.claude/` outright, clears every `ACP_*` variable, and then puts a real
repository and a real bare remote through the whole set: secrets, weakened configuration, a hand-written
closeout, phantom citations by file and inline, advisory findings that report without blocking and block
under strict, and force pushes and branch deletions at a shared branch. The same sequence runs again with
`.claude/` in place, and must come out identical — that equality is the parity being claimed.
