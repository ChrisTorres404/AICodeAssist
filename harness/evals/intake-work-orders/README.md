# intake-work-orders

Checks that installing opens the six intake work orders, that each step's shipped suite proves it, and that the project is operational only when all six have closed on executed evidence.

The pipeline's own rule applied to its own setup: nobody types PASS. A step that is not done fails its
suite and names the command; a step that is done passes; `acp intake status` and doctor report the count.
