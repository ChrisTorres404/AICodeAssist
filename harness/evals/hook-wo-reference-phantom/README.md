# hook-wo-reference-phantom

Checks that the traceability hook refuses a commit citing a work order or bug that was never opened.

A reference to something nobody opened is worse than no reference at all: it reads as traceable
and leads nowhere. The hook has to resolve the citation against the work-order and bug directories
of the repository the commit is being made in, block when it does not resolve, and stay quiet when
it does.
