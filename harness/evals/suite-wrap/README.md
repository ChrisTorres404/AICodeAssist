# suite-wrap

Checks that a project which already tests itself can keep its runner.

The shipped suite template is an HTTP suite. `wo suite --wrap '<command>'`, or SUITE_COMMAND in the
project's configuration, scaffolds a thin wrapper instead: it finds the project root, leaves room
for preconditions that exit 77, and delegates to the command, whose exit code is the verdict.
