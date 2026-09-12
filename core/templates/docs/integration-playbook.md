---
wo: WO-XXXX
title: "[Platform name] — Integration Playbook"
version: 1.0
status: DRAFT
created: YYYY-MM-DD
last-modified: YYYY-MM-DD
reviewed-by: N/A
audience: "Engineers on a consuming team"
---

# [Platform name] — Integration Playbook

<!-- Every sentence is written as if the reader will never see this
     platform's source code. Class names, file paths and internal service
     names in body text all fail the consumer perspective test. -->

---

## 1. What This Platform Does For You

<!-- WRITING PROMPT: Three or four sentences on what a consuming system GETS.
     Not how it is built. Focus on what the reader stops having to build
     themselves. -->

---

## 2. Where Your System Fits

<!-- WRITING PROMPT: A simple flow showing what calls the reader's system
     makes to the platform and what comes back. Name the direction of every
     arrow. -->

---

## 3. Prerequisites

<!-- Only real prerequisites, each verifiable by the reader before they
     start. -->

- [ ]
- [ ]

---

## 4. [Use case: stated as the reader's own goal]

<!-- Repeat one section per use case, ordered by the integration sequence.
     A use case whose capabilities are not implemented gets NO section here —
     it appears in the decision matrix with an honest badge. -->

**Status:** [badge from the feature status matrix]
**Complexity:** Simple | Moderate | Complex

### Step 1 — [action]

<!-- SOURCE: [relative/path]:L[n] — [what was confirmed] -->

**What you send**

```
[request, with YOUR_ placeholders and a sourcing comment for each]
```

**What you get back**

```
[response shape, from the source]
```

**How to use it**

1.

### Step 2 — [action]

---

## 5. Client Setup

<!-- Installation and configuration if a client library exists; otherwise the
     base URL, required headers, and how requests are authenticated. Every
     configuration item traces to a declaration in the source. -->

| Setting | Purpose | Where the value comes from |
|---|---|---|
|  |  |  |

---

## 6. Testing Your Integration

<!-- WRITING PROMPT: The sandbox or test environment, how credentials are
     obtained, and a verification checklist the reader can work through
     before go-live. -->

- [ ]

---

## 7. Go-Live Checklist

- [ ]

---

## 8. Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
|  |  |  |

---

## 9. Source References

<!-- Traceability appendix. Stripped from the published copy per the
     placement manifest. -->

---

## 10. Related Documents

| Document | Purpose |
|---|---|
| PM integration brief |  |
| API quick reference |  |
| Integration decision matrix |  |
