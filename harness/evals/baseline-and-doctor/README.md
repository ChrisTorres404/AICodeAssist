# baseline-and-doctor

Checks that the tool measures the project it adopts, and that doctor validates what it counts.

Structure checks pass on a codebase whose tests have been dead for a month. `acp baseline` runs the
project's own tests once, binds the result to the tree, and reports the record against the
measurement; doctor asks for it. Doctor also opens every agent and skill it counts, notices a
repository with no commits, notices instructions that no longer mention the configured layout, and
the installer names a workspace that moved rather than orphaning it silently.
