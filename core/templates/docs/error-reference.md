---
wo: WO-XXXX
title: "[Platform name] — Error Reference"
version: 1.0
status: DRAFT
created: YYYY-MM-DD
last-modified: YYYY-MM-DD
reviewed-by: N/A
audience: "Developers integrating with the platform"
---

# [Platform name] — Error Reference

<!-- Grouped by the scenario the reader is in when they hit the error, not by
     status code — a reader arrives here knowing what they were doing, not
     what number they got.

     Every entry has all four fields. A code with no cause is a code the
     reader cannot act on. Every error traces to the source: no error shape
     generalised from other systems. -->

---

## [Scenario — what the reader was doing]

| Status | Body | Cause | Fix |
|---|---|---|---|
|  |  |  |  |

<!-- SOURCE: [relative/path]:L[n] — [where these responses are produced] -->

---

<!-- Repeat per scenario. -->

---

## Retry Guidance

<!-- WRITING PROMPT: Which of these errors are worth retrying, which are
     permanent, and what backoff the platform expects. A reader who retries a
     permanent failure makes their own outage worse. -->

| Error | Retry? | Backoff |
|---|---|---|
|  |  |  |

---

## Still Stuck

<!-- WRITING PROMPT: What the reader should collect before asking for help —
     request id, timestamp, the exact body. Saves a round trip. -->
