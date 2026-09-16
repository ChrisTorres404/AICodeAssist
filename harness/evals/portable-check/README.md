# portable-check

Checks that the rules run over a set of files from anywhere, with or without git, and block on the right things.

The session hooks only run inside Claude Code. `acp check` is the same rules over a named, staged,
manifest-derived or git-derived set of files, so the driver, a git hook and CI can all call one
implementation. Credentials, a weakened configuration and a closeout without an executed pass
block everywhere; debug logging and stubs warn, and block under strict.
