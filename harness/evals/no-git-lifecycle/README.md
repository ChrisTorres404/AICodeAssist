# no-git-lifecycle

Checks that the whole work-order lifecycle, including the rules at close, holds in a project with no git.

Git provides a moment the agent does not control. Without it the work-order tier is all there is,
so that tier has to be complete on its own: evidence bound to the tree, an interrupted run refused,
and the rules run over what the work order changed, which a manifest taken at `wo new` makes
possible without any version control.
