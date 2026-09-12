# install-failure-recovery

Checks that a failed install leaves the project intact, and that retrying restores what it held.

Replacing the installed trees means removing them. Doing that before the replacement is in hand
leaves a window where a failure destroys the installation, and holding the project's own authored
files in an anonymous temporary directory means the retry has nothing left to put back.
