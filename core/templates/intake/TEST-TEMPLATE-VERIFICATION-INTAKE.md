# WO-XXXX: [Title] - Verification Report

**Work Order:** WO-XXXX
**Step:** Intake
**Verification Date:** YYYY-MM-DD
**Verified By:** the driver, from the suite's exit code

---

## What this step verifies

This is an intake work order: one of the six steps a project completes before the pipeline
counts it as operational. Its specification says what the step is for and what the shipped
suite checks, and the suite is the whole of the verification. Every check it prints is a
statement about this project as it stands right now — a file that exists, a command that
answers, a record bound to the tree on disk — and the suite exits 0 only when all of them
pass, 1 when any fails, and 77 when it could not run at all.

## How it was run

The driver executed the shipped suite for this step with `wo verify` and wrote the result
from its exit code; nobody typed a status. The Execution Record below is the evidence: the
status, the command, the exit code, the check counts, the fingerprint of the source the run
was bound to, and the tail of the log. Re-running the suite appends another record and
updates the status line. If the source changes afterwards, the pass is stale and `wo close`
says so rather than accepting it.

**Notes:** [Any notes]
