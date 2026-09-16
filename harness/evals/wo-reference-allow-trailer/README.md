# wo-reference-allow-trailer

Proves an `Acp-Allow-Reference` trailer lets a commit write about a work-order identifier without
claiming it, in both forms of the traceability hook, while an undeclared phantom still blocks.

A commit documenting a traceability test has to quote the identifier the test uses, and that
identifier is deliberately one nobody opened. Without a declaration the hook cannot tell a citation
from writing about one, and the commit is unlandable. The trailer keeps the declaration in the
recorded message, where a reader sees it later — so it has to be honoured by the tool hook that
reads the command and by the commit-msg hook that reads the message file, and the refusal has to
name it.
