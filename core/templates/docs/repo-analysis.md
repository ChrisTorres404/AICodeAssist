---
wo: WO-XXXX
title: "[Repository name] — Repository Analysis"
version: 1.0
status: DRAFT
created: YYYY-MM-DD
last-modified: YYYY-MM-DD
reviewed-by: N/A
---

# [Repository name] — Repository Analysis

**Analysed at revision:** [commit or tag the analysis was performed against]
**Phases completed:** [record the actual time each phase took]

<!-- Read-only analysis. Record what exists. Do not recommend changes — the
     single exception is the Critical Findings section at the end. -->

---

## 1. Repository Structure and Technology Stack

<!-- PHASE 1 (10 min): Directory map three levels deep, language and version,
     framework, data store, migration tool, job runner, auth libraries, build
     and deploy configuration. Close with the counts: route handlers,
     services, models, tests, migrations. -->

---

## 2. Feature Inventory

<!-- PHASE 2 (20 min): Every capability, typed internal or consumer-facing.
     This table is the input to the status matrix and to FAQ domain
     discovery, so completeness beats elegance. -->

| Feature | Type | Location | Requires | Exposes |
|---|---|---|---|---|
|  |  |  |  |  |

---

## 3. API Surface

<!-- PHASE 3 (15 min): Every entry point exactly as declared in the source —
     method, path, auth requirement, request shape, success and error
     response shapes, any limit applied. Group by module. A path recorded
     from memory is a fabricated endpoint. -->

---

## 4. Data Models

<!-- PHASE 4 (15 min): Every entity — storage name, fields with declared
     types, relationships, constraints, indexes. Then migration history, then
     the read/write map of which services touch which entities. -->

---

## 5. Authentication and Authorization

<!-- PHASE 5 (15 min): Middleware and guards in execution order, credential
     and token types with lifetimes, the role or policy model, session
     handling, transport and origin configuration, encryption where
     declared. -->

---

## 6. Dependencies and Integrations

<!-- PHASE 6 (10 min): Libraries with pinned versions, external services
     called, internal services depended on, required environment variables
     and secrets, health and telemetry integrations. For each external call,
     say whether failure is fatal or degraded. -->

| Dependency | Type | Version | Failure mode |
|---|---|---|---|
|  |  |  |  |

---

## 7. Feature Profiles

<!-- PHASE 7 (20 min): A nine-part profile per feature, grouped by capability
     domain. Use the feature-profile template. When there are more than a
     dozen features, put the profiles in a companion document in the same
     work order and link it here. -->

---

## 8. Cross-Feature Dependency Map

<!-- PHASE 8 (10 min): Upstream dependencies and downstream consumers per
     feature, then the critical path — the features whose failure takes the
     system down. -->

| Feature | Upstream | Downstream | Critical path |
|---|---|---|---|
|  |  |  |  |

---

## 9. Source References

<!-- Every file opened, with line ranges. Maintain the full index in the
     work order's source-references document and summarise or link here. -->

---

## Critical Findings

<!-- Delete this heading entirely when there are none.

     Only a serious security vulnerability or a defect that can cause data
     loss, unauthorised access, or system failure belongs here. For each:
     classification (CRITICAL-SECURITY or CRITICAL-DEFECT), the exact file and
     line range, and a factual description of what was observed. No
     remediation plan — open a bug for that. -->
