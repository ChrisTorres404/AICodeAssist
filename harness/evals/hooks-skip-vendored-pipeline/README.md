# hooks-skip-vendored-pipeline

Proves the commit and quality hooks report the project's code and not the pipeline vendored inside
it, while still reporting the pipeline's own code when the pipeline is the project.

The pipeline installs into the project it serves. Its rule tables quote the literals the rules look
for and its shipped scripts log to the console for real, so on the first commit after an install
every finding came from inside the installed copy — under the strict profile, that blocks every
commit forever. The hooks therefore skip anything under their own pipeline root, and under
`.claude/`, and `check` has to skip the same set or the two disagree. The exception that keeps the
rule honest: a checkout of the pipeline is itself a project, and there the rules must still run.
