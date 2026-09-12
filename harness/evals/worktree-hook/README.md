# worktree-hook

Checks that the traceability hook is installed where git will actually run it.

A linked worktree has its own git directory, and git does not look there for hooks. A
configured hooks path moves them again. Writing to the obvious place produces a file that
exists, that doctor can find, and that git never executes.
