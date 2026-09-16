# precommit-backstop

Checks that the rules run at commit time under any agent, catching what the driver cannot see.

A closeout written by hand and a work order never opened both bypass `wo close`. Git runs a
pre-commit hook regardless of who is typing, so the same checks run there. The hook is the
pipeline's only when it wrote it; an existing one is left alone; the minimal profile installs none.
