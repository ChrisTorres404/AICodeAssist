# verify-results

Checks that a verification records what the suite actually said, not only whether it exited zero.

Exit 77 is reserved for "I could not run": a suite whose environment never came up has asserted
nothing, and recording that as a failure would put the tool's authority behind a claim no check ever
made. And when the runner printed a count, the count is kept beside the verdict, so 42 of 43 and
0 of 15 stop reading identically.
