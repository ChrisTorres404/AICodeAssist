---
wo: WO-XXXX
title: "[Feature name] — Feature Profile"
version: 1.0
status: DRAFT
created: YYYY-MM-DD
last-modified: YYYY-MM-DD
reviewed-by: N/A
---

# [Feature name] — Feature Profile

<!-- Every claim below ends with a traceability comment, `<!-- SOURCE: path:L12 -->`,
     naming the file and line that proves it. A hook checks that the file and line
     exist. A claim with no source is omitted, never invented. -->

**Capability domain:** [domain this feature belongs to]
**Type:** Internal | Consumer-facing
**Status:** [badge from the feature status matrix]

---

## 1. In One Sentence

<!-- WRITING PROMPT: One jargon-free sentence covering the mechanism and the
     stake. If you cannot write it, re-read the source — you do not yet
     understand the feature. Do not restate the feature's name. -->

---

## 2. The Full Picture

<!-- WRITING PROMPT: Two or three sentences that add technical substance to
     part 1 — the key mechanism, the scope of what it covers, and one concrete
     detail that makes the reader want to keep going. Adjectives are not
     substance. -->

---

## 3. The Problem It Solves

<!-- WRITING PROMPT: Two or three sentences describing life WITHOUT this
     feature. What breaks, what is at risk, who feels it. Be concrete about
     the failure, not abstract about the need. -->

---

## 4. How It Works

<!-- WRITING PROMPT: A numbered walkthrough of the happy path, from the
     trigger event to the outcome. Name the components. If there is a queue,
     a retry, or a cache in the middle, it is a step. -->

1.
2.
3.

---

## 5. Use Case Scenarios

<!-- WRITING PROMPT: Two or three named scenarios with realistic actors and
     quantities. A reader should recognise their own situation in one of them.
     Two to three sentences each. -->

- **[Scenario name]:**
- **[Scenario name]:**

---

## 6. Edge Cases and Gotchas

<!-- WRITING PROMPT: The warnings an experienced colleague gives unprompted.
     Bold label, then the consequence. At least two, at least one of which is
     a real limitation rather than a configuration note. -->

- **[Label]:**
- **[Label]:**

---

## 7. How It Connects

<!-- WRITING PROMPT: Upstream — what must work for this to work. Downstream —
     what consumes it and breaks without it. Position — where it sits in the
     request or event lifecycle. Take these from the cross-feature map, do not
     invent relationships. -->

| Direction | Feature | Nature of the dependency |
|---|---|---|
|  |  |  |

---

## 8. What It Enables

<!-- WRITING PROMPT: The "so what?", in the reader's terms rather than the
     implementer's. Name the audience: an integrating team, security and
     compliance, or operations. -->

---

## 9. Quick Reference

| Item | Value |
|---|---|
| Module |  |
| Source paths |  |
| Configuration keys |  |
| Dependencies |  |
| Administrative surface |  |
| Status |  |

<!-- Every source path here must also appear in the work order's
     source-reference index. -->
