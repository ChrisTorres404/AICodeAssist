# Database Normalization and Relational Integrity Audit — Template

## Document Type: Architecture Audit
## Created: YYYY-MM-DD
## Scope: {{PROJECT_NAME}} — All Database Schemas

---

## How to use this template

This is a read-only audit. It records what the schema is, not what it should
become: every fix named here turns into a work order, and the work order — not
this document — changes anything.

1. Copy to `{{DOCS_DIR}}/database/DB-NORMALIZATION-AUDIT-YYYY-MM-DD.md`.
2. Work through "Audit questions" once per schema, then the normal-form checks
   per entity. Run the queries in "Finding violations" against a real database
   rather than reading the entity definitions — declarations drift from what
   was actually migrated.
3. Fill every section. A section with nothing in it says "audited, nothing
   found", which is a result; delete it only if the schema has no such
   construct at all.
4. Classify each finding P0 (correctness, security, or data-loss risk), P1
   (will hurt at production volume), or P2 (worth fixing when nearby).
5. Open the work orders in section 9 before the audit is considered done.

The findings below are a **worked example** on generic tables. They show the
level of specificity a finding needs — file, issue, risk, fix — and are not
claims about your schema. Replace all of them.

---

## Audit questions

Ask these of every schema. Each maps to a section below.

- [ ] Is every entity in third normal form, or is the departure deliberate and written down?
- [ ] Does every repeating group live in its own table rather than an array column?
- [ ] Does every many-to-many relationship have a junction table?
- [ ] Does every foreign key column have an actual FK constraint?
- [ ] Does every FK column reference a table that exists?
- [ ] Does every FK have a defined ON DELETE behaviour, chosen rather than defaulted?
- [ ] Is every FK column indexed?
- [ ] Is every column used in a WHERE clause by a background job indexed?
- [ ] Does every tenant-scoped table carry `tenant_id` directly, not through a join?
- [ ] Is uniqueness scoped correctly (globally unique, or unique per tenant)?
- [ ] Does every soft-deleted table have a partial index excluding deleted rows?
- [ ] Are enumerated values constrained at the database level, or only in application code?
- [ ] Does every JSONB column have a written justification?
- [ ] Is every denormalized copy of a value kept in step, and by what?
- [ ] Do timestamps exist on every entity (`created_at`, `updated_at`)?
- [ ] Are there orphan rows today? (Not "can there be" — run the query.)

---

## Normal form checks

Per entity, in order. Stop at the first failure and record it; a table that
fails 1NF has nothing to say about 3NF.

| Form | Check | How to spot a violation |
|------|-------|-------------------------|
| **1NF** | Every column holds a single atomic value; no repeating groups | Array or comma-joined text columns; columns named `field_1`, `field_2` |
| **2NF** | 1NF, and every non-key column depends on the *whole* primary key | On a composite key, a column that depends on only one half |
| **3NF** | 2NF, and no non-key column depends on another non-key column | `city` and `postal_code` both present and derivable from each other |
| **BCNF** | 3NF, and every determinant is a candidate key | An alternate key that determines part of the primary key |
| **4NF** | BCNF, and no independent multi-valued dependencies in one table | One table holding two unrelated one-to-many sets |

Each check records one of three outcomes: **compliant**, **violated** (goes in
sections 3 to 5), or **intentionally denormalized** (goes in section 2 with a
justification).

---

## Finding violations

Run these against the live database. They find what entity definitions hide.

### Foreign key columns with no constraint

```sql
-- Columns named like a foreign key that have no FK constraint behind them
SELECT c.table_schema, c.table_name, c.column_name
FROM information_schema.columns c
WHERE c.column_name LIKE '%\_id' ESCAPE '\'
  AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.key_column_usage k
    JOIN information_schema.table_constraints t
      ON t.constraint_name = k.constraint_name
     AND t.constraint_schema = k.constraint_schema
    WHERE t.constraint_type = 'FOREIGN KEY'
      AND k.table_schema = c.table_schema
      AND k.table_name = c.table_name
      AND k.column_name = c.column_name
  )
ORDER BY 1, 2, 3;
```

### Foreign keys with no index

```sql
-- FK columns with no index: every parent delete and every join pays for this
SELECT t.relname AS table_name, a.attname AS column_name, con.conname
FROM pg_constraint con
JOIN pg_class t ON t.oid = con.conrelid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY (con.conkey)
WHERE con.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = t.oid AND a.attnum = i.indkey[0]
  )
ORDER BY 1, 2;
```

### Foreign keys with a defaulted delete rule

```sql
-- confdeltype 'a' is NO ACTION, the default nobody chose
SELECT con.conname, t.relname AS child, r.relname AS parent, con.confdeltype
FROM pg_constraint con
JOIN pg_class t ON t.oid = con.conrelid
JOIN pg_class r ON r.oid = con.confrelid
WHERE con.contype = 'f' AND con.confdeltype = 'a'
ORDER BY 2, 1;
```

### Tenant-scoped tables missing `tenant_id`

```sql
-- Any table in a tenant-scoped schema without a direct tenant_id column
SELECT table_schema, table_name
FROM information_schema.tables t
WHERE t.table_type = 'BASE TABLE'
  AND t.table_schema IN ('core', 'access', 'audit', 'webhooks', 'settings')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = t.table_schema
      AND c.table_name = t.table_name
      AND c.column_name = 'tenant_id'
  )
ORDER BY 1, 2;
```

### Array columns (1NF candidates)

```sql
-- Array-typed columns: each one is a junction table that was never written
SELECT table_schema, table_name, column_name, udt_name
FROM information_schema.columns
WHERE data_type = 'ARRAY'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
```

### Orphan rows behind a missing constraint

```sql
-- Substitute the child table, the column, and the parent it should reference
SELECT COUNT(*) AS orphans
FROM core.session s
LEFT JOIN core.user u ON u.id = s.created_by
WHERE s.created_by IS NOT NULL AND u.id IS NULL;
```

### Soft-delete tables with no partial index

```sql
-- Tables carrying deleted_at, and whether a partial index excludes the dead rows
SELECT c.table_schema, c.table_name,
       EXISTS (
         SELECT 1 FROM pg_indexes i
         WHERE i.schemaname = c.table_schema
           AND i.tablename = c.table_name
           AND i.indexdef ILIKE '%deleted_at is null%'
       ) AS has_partial_index
FROM information_schema.columns c
WHERE c.column_name = 'deleted_at'
  AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
```

### Unused and duplicate indexes

```sql
-- Indexes never scanned since the last statistics reset
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY 1, 2;
```

---

# Worked Example Audit

Everything from here down is an example audit over generic schemas, written
out in full so the format is unambiguous. Replace every finding.

## Executive Summary

This audit examined 27 entities across 6 schemas (core, access, federation,
audit, webhooks, settings) for normalization compliance, foreign key
integrity, index coverage, and multi-tenant isolation patterns.

### Overall Assessment

| Schema | Entities | Normalization | FK Coverage | Index Coverage | RLS Ready |
|--------|----------|---------------|-------------|----------------|-----------|
| core | 8 | 85% | 75% | 80% | 90% |
| access | 4 | 60% | 50% | 70% | **40%** |
| federation | 5 | 90% | 85% | 75% | 95% |
| audit | 3 | 95% | 80% | 90% | 100% |
| webhooks | 2 | 85% | 70% | **50%** | 90% |
| settings | 4 | 95% | 90% | 85% | 100% |

**Critical Issues Found: 8**
**High Priority Issues: 12**
**Medium Priority Issues: 12**

---

## 1. Properly Normalized Areas

### 1.1 Settings Schema (Excellent)
- `system_setting`, `tenant_setting`, `user_setting` follow proper 3NF
- Clear hierarchical cascade: system to tenant to user
- Proper FK relationships with ON DELETE CASCADE
- `settings_audit` tracks all changes with immutable records

### 1.2 Audit Schema (Excellent)
- `audit_event` is properly normalized with JSONB for flexible payload
- Tiered storage design (hot/warm/cold) is architecturally sound
- `audit_retention_policy` and `audit_legal_hold` properly separated
- All entities have explicit `tenant_id` for RLS

### 1.3 Federation Schema (Good)
- `idp_provider`, `idp_identity`, `idp_session`, `idp_assertion_id` properly related
- Certificate storage in `idp_provider` is justified (1:1 with provider)
- `attribute_mapping` as JSONB is intentional denormalization (provider-specific)

### 1.4 Core Entities (Good)
- `tenant` to `user` to `session` hierarchy is clean
- `mfa_method` properly normalized per user
- `trusted_device` has proper fingerprint storage

---

## 2. Intentional Denormalization (Acceptable)

### 2.1 JSONB Columns (Design Decision)
These JSONB columns are intentionally denormalized for flexibility:

| Entity | Column | Justification |
|--------|--------|---------------|
| `idp_provider` | `attribute_mapping` | Provider-specific, rarely queried |
| `audit_event` | `event_data` | Flexible audit payload |
| `webhook_endpoint` | `headers` | Custom per-endpoint |
| `session` | `device_info` | Device fingerprinting |
| `tenant_setting` | `value` | Polymorphic settings |

A JSONB column without a row in this table is an undocumented denormalization
and belongs in section 5.

### 2.2 Timestamp Redundancy (Performance)
- `created_at`, `updated_at` on all entities is standard practice
- `last_login_at` on `user` duplicates audit data but enables fast queries

---

## 3. Critical Issues (P0 - Must Fix)

### 3.1 CRITICAL: RoutePrivilege Missing Tenant Scoping
**File**: `{{API_APP}}/src/entities/access/route-privilege.entity.ts`
**Issue**: No `tenant_id` column — routes can be accessed cross-tenant
**Risk**: Privilege escalation vulnerability
**Fix**: Add `tenant_id` FK with RLS policy

### 3.2 CRITICAL: Role.permissions Stored as TEXT[]
**File**: `{{API_APP}}/src/entities/access/role.entity.ts`
**Issue**: `permissions: string[]` stored as a PostgreSQL TEXT array
**Problems**:
- Cannot query "all roles with permission X" efficiently
- No referential integrity to privilege definitions
- Cannot add metadata to permission assignments
**Fix**: Create a `role_privilege` junction table

### 3.3 CRITICAL: Missing Organization Entity
**References Found In**: User, Session, UserRole entities
**Issue**: `organization_id` columns reference a non-existent table
**Risk**: Broken FK relationships, orphaned data
**Fix**: Either create the Organization entity or remove the references

### 3.4 CRITICAL: Identity Entity Missing tenant_id
**File**: `{{API_APP}}/src/entities/core/identity.entity.ts`
**Issue**: No explicit `tenant_id` — relies on a join through user
**Risk**: RLS bypass if queried directly
**Fix**: Add a denormalized `tenant_id` for direct RLS

---

## 4. High Priority Issues (P1)

### 4.1 WebhookDelivery Missing Critical Indexes
**File**: `{{API_APP}}/src/entities/webhooks/webhook-delivery.entity.ts`
**Missing**:
- Index on `status` (worker queries failed deliveries)
- Index on `next_retry_at` (worker finds due retries)
- Composite index `(endpoint_id, status)`
**Impact**: Worker queries will table scan as volume grows

### 4.2 MfaMethod Missing tenant_id
**File**: `{{API_APP}}/src/entities/core/mfa-method.entity.ts`
**Issue**: No `tenant_id` column
**Risk**: Cross-tenant MFA queries possible
**Fix**: Add a denormalized `tenant_id`

### 4.3 TrustedDevice Missing tenant_id
**File**: `{{API_APP}}/src/entities/core/trusted-device.entity.ts`
**Issue**: No `tenant_id` column
**Risk**: Device fingerprints queryable cross-tenant
**Fix**: Add a denormalized `tenant_id`

### 4.4 Token Entity Missing Indexes
**File**: `{{API_APP}}/src/entities/core/token.entity.ts`
**Missing**:
- Index on `expires_at` (cleanup job)
- Index on `revoked_at` (validation checks)
**Impact**: Token cleanup and validation performance degrades

### 4.5 ApiKey Missing Soft Delete Cascade
**File**: `{{API_APP}}/src/entities/core/api-key.entity.ts`
**Issue**: Has `deleted_at` but no index for soft-delete queries
**Fix**: Add a partial index `WHERE deleted_at IS NULL`

### 4.6 Session Missing Compound Indexes
**File**: `{{API_APP}}/src/entities/core/session.entity.ts`
**Missing**:
- Compound index `(user_id, status, expires_at)` for active session lookups
- Index on `device_fingerprint` for device-based queries

---

## 5. Medium Priority Issues (P2)

### 5.1 Privilege Entity has Orphan-Risk
**File**: `{{API_APP}}/src/entities/access/privilege.entity.ts`
**Issue**: No cascade behaviour defined — orphans possible on deletion
**Fix**: Add ON DELETE RESTRICT or CASCADE as appropriate

### 5.2 AuditEvent Schema Detection
**File**: `{{API_APP}}/src/entities/audit/audit-event.entity.ts`
**Issue**: `event_type` as a string lacks enum validation at the DB level
**Fix**: Consider a PostgreSQL ENUM type or a CHECK constraint

### 5.3 WebhookEndpoint Secret Rotation
**File**: `{{API_APP}}/src/entities/webhooks/webhook-endpoint.entity.ts`
**Issue**: Single `signing_secret` column — no rotation support
**Fix**: Add `signing_secret_rotated_at` and `previous_signing_secret`

### 5.4 User Email Uniqueness Scope
**File**: `{{API_APP}}/src/entities/core/user.entity.ts`
**Issue**: Email unique per-tenant needs a compound unique constraint
**Current**: May have an application-level check only
**Fix**: Add a `UNIQUE(tenant_id, email)` constraint

### 5.5 IdpSession Missing Cleanup Index
**File**: `{{API_APP}}/src/entities/federation/idp-session.entity.ts`
**Issue**: No index on `created_at` for cleanup jobs
**Fix**: Add an index for session cleanup queries

---

## 6. Missing Foreign Key Constraints

Produced by the "Foreign key columns with no constraint" query above.

| From Entity | Column | Should Reference | Status |
|-------------|--------|------------------|--------|
| `session` | `created_by` | `user.id` | Missing FK |
| `session` | `updated_by` | `user.id` | Missing FK |
| `user_role` | `granted_by` | `user.id` | Missing FK |
| `audit_event` | `actor_id` | `user.id` | Missing FK |
| `webhook_delivery` | `triggered_by` | `user.id` | Missing FK |
| `api_key` | `created_by` | `user.id` | Missing FK |

Before adding any of these, count the orphans that already exist with the
orphan query above — the constraint will not apply while they are there.

---

## 7. Cascade Behavior Analysis

### Correct Cascades
- `tenant` to `user`: ON DELETE CASCADE (correct)
- `user` to `session`: ON DELETE CASCADE (correct)
- `idp_provider` to `idp_identity`: ON DELETE CASCADE (correct)

### Risky Cascades (Need Review)
- `user` to `audit_event`: should be RESTRICT (preserve the audit trail)
- `tenant` to `role`: should be RESTRICT (prevent accidental role deletion)
- `role` to `user_role`: CASCADE is acceptable, but RESTRICT may be safer

### Missing Cascades
- `webhook_endpoint` to `webhook_delivery`: should be CASCADE
- `idp_provider` to `idp_session`: should be CASCADE

---

## 8. Multi-Tenant Row-Level Security Alignment

### Entities Ready for RLS (Have tenant_id)
- tenant (is tenant)
- user
- session
- role
- privilege
- idp_provider
- idp_identity
- audit_event
- webhook_endpoint
- system_setting
- tenant_setting
- user_setting

### Entities Needing tenant_id for RLS

| Entity | Current State | Required Action |
|--------|---------------|-----------------|
| route_privilege | **No tenant_id** | Add column + FK |
| identity | Via user join only | Add denormalized |
| mfa_method | Via user join only | Add denormalized |
| trusted_device | Via user join only | Add denormalized |
| webhook_delivery | Via endpoint join | Add denormalized |
| idp_session | Via identity join | Add denormalized |
| api_key | Via user join only | Add denormalized |

A denormalized `tenant_id` is a copy, and a copy can diverge. Each one added
here needs a trigger or an application invariant that keeps it equal to the
parent's, plus a check query in the behavioural suite.

---

## 9. Recommended Work Orders

Based on this audit, the following work orders are recommended:

### WO-0001: DB Normalization Hardening
- Create the `role_privilege` junction table
- Create or remove the Organization entity references
- Normalize the `Role.permissions` array

### WO-0002: Missing FK and Index Hardening
- Add missing FKs on `created_by` and `updated_by` columns
- Add indexes on WebhookDelivery, Token, Session
- Add `tenant_id` to 7 entities for RLS readiness

Each work order carries a behavioural suite that re-runs the queries in
"Finding violations" and asserts an empty result, so the audit does not have
to be repeated by hand to know it held.

---

## 10. Schema Diagrams

### Core Schema Relationships

```
tenant (1) ─────┬───── (*) user
                │
                └───── (*) role
                       │
user (1) ──────────────┼───── (*) session
                       │
                       ├───── (*) mfa_method
                       │
                       ├───── (*) trusted_device
                       │
                       ├───── (*) identity
                       │
                       └───── (*) api_key

role (*) ──────────────────── (*) privilege  [MISSING JUNCTION]
```

### Federation Schema Relationships

```
idp_provider (1) ─────┬───── (*) idp_identity
                      │
                      └───── (*) idp_session
                             │
                             └───── (*) idp_assertion_id
```

---

## Appendix: Entity Inventory

One row per entity. `tenant_id` is the RLS-readiness column: YES means the
column exists on the table itself, not on something it joins to.

| Schema | Entity | Columns | Indexes | FKs | tenant_id |
|--------|--------|---------|---------|-----|-----------|
| core | tenant | 12 | 3 | 0 | IS tenant |
| core | user | 18 | 5 | 1 | YES |
| core | session | 22 | 4 | 2 | YES |
| core | identity | 8 | 2 | 1 | NO |
| core | mfa_method | 10 | 2 | 1 | NO |
| core | trusted_device | 9 | 2 | 1 | NO |
| core | api_key | 14 | 3 | 1 | NO |
| core | token | 8 | 2 | 1 | YES |
| access | role | 9 | 2 | 1 | YES |
| access | privilege | 6 | 2 | 0 | YES |
| access | user_role | 6 | 2 | 3 | YES |
| access | route_privilege | 5 | 1 | 1 | **NO** |
| federation | idp_provider | 24 | 3 | 1 | YES |
| federation | idp_identity | 12 | 3 | 2 | NO |
| federation | idp_session | 10 | 2 | 2 | NO |
| federation | idp_assertion_id | 5 | 2 | 1 | NO |
| audit | audit_event | 14 | 5 | 1 | YES |
| audit | audit_retention_policy | 8 | 2 | 1 | YES |
| audit | audit_legal_hold | 7 | 2 | 1 | YES |
| webhooks | webhook_endpoint | 16 | 3 | 1 | YES |
| webhooks | webhook_delivery | 12 | 2 | 1 | NO |
| settings | system_setting | 8 | 2 | 0 | N/A |
| settings | tenant_setting | 9 | 3 | 1 | YES |
| settings | user_setting | 9 | 3 | 2 | YES |
| settings | settings_audit | 10 | 3 | 2 | YES |

Generate the counts rather than typing them:

```sql
SELECT t.table_schema, t.table_name,
       (SELECT COUNT(*) FROM information_schema.columns c
         WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS columns,
       (SELECT COUNT(*) FROM pg_indexes i
         WHERE i.schemaname = t.table_schema AND i.tablename = t.table_name) AS indexes,
       (SELECT COUNT(*) FROM information_schema.table_constraints tc
         WHERE tc.table_schema = t.table_schema AND tc.table_name = t.table_name
           AND tc.constraint_type = 'FOREIGN KEY') AS fks
FROM information_schema.tables t
WHERE t.table_type = 'BASE TABLE'
  AND t.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
```

---

*End of Audit Document*
