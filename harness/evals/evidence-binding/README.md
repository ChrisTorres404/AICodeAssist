# evidence-binding

Checks that a pass is bound to the content of the source and of the suite that ran, and to nothing else.

Hashing index entries for tracked files and raw bytes for untracked ones made `git add` change the
fingerprint of a file whose content had not changed, so committing your work staled the evidence you
had just produced. Writing a second suite staled the first one's pass. Both are fixed by binding to
content: every file the same way, and the suite that ran bound on its own rather than through the
directory it lives in.
