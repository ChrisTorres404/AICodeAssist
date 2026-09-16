# wo-paths-scope

Checks that a work order can bind its evidence to the part of the tree it touches.

In a monorepo, whole-tree binding means an unrelated commit invalidates every open work order's
evidence. `wo new --paths` narrows what the fingerprint, the manifest and the close-time checks
look at, so only changes inside the declared scope count.
