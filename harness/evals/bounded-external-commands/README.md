# bounded-external-commands

Checks that the wait around external commands is a real bound, including when someone hands it a bad value.

An external tool that never returns turns a test run into a test run that never finishes, which is
worse than a failure because nothing reports it. The bound also has to survive a malformed
`ACP_PLUGIN_TIMEOUT`: a value that is not a positive integer makes the comparison error on every
pass, and a loop that errors quietly is a loop that waits forever.
