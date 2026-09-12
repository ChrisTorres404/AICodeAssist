# commit-msg-traceability

Checks that a commit citing a work order nobody opened is refused however the message reaches git.

The tool hook only sees the command a session is about to run, so a message supplied with `-F`,
on stdin, or through an editor never passes through it. Git's own commit-msg hook sees the final
message in every case. This drives real commits through each route and asserts on what the log
actually records, because a hook that prints a complaint and lets the commit through has not
refused anything.
