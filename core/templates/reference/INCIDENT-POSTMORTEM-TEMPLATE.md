# Incident Postmortem — Template and Worked Example

## How to use this template

An incident postmortem is written once, immediately after the system is back
up, while the shell history that produced the recovery is still on screen. It
has two jobs: to record what actually happened in enough detail that somebody
else could repeat the recovery, and to name the corrective actions that stop
the same incident happening twice.

1. Copy Part 1 into `{{DOCS_DIR}}/incidents/INCIDENT-YYYY-MM-DD-<slug>.md`.
2. Fill the header block first. `Status: IN PROGRESS` while you are still
   recovering; `COMPLETE` only after the verification section has real output
   pasted into it.
3. Paste the commands you actually ran, with their actual output. A command
   retyped from memory is a command that has never been tested.
4. Never write a recovery step you did not execute, and never write a
   verification result you did not read off the terminal.
5. Open a work order for each corrective action before you close the
   postmortem, and link it in section 10. A corrective action with no work
   order is a wish.

Part 2 is a worked example — a plausible development-database loss, filled in
end to end — so you can see what "enough detail" looks like. Every value in
it is an example. Replace them all.

Related templates: `{{PIPELINE_ROOT}}/core/templates/bugs/` for defect
tracking, and `{{PIPELINE_ROOT}}/core/templates/testing/` for the evidence a
corrective action needs before it can be closed.

---

# Part 1 — Blank Template

````markdown
# Incident Report: <system or database name>

**Date:** YYYY-MM-DD
**System:** <database, service, or environment affected>
**Environment:** <local development / staging / production> (<engine and version>)
**Severity:** <SEV1 total outage / SEV2 major degradation / SEV3 minor>
**Status:** IN PROGRESS | COMPLETE
**Work Order:** WO-NNNN (opened to track the corrective actions)

## 1. Incident summary

### Discovery

- **Time:** YYYY-MM-DD HH:MM (<what the person was doing when it surfaced>)
- **Symptom:** <the literal error message or observed behaviour>
- **Root cause:** <one sentence; the long version goes in section 5>

### System state before recovery

```
<the exact query or command output that shows the damaged state>
```

<One paragraph: what was present, what was missing, and why the two are
inconsistent with each other.>

## 2. Timeline

All times in a single timezone, stated once. Relative offsets ("T+00:14") are
acceptable when the wall clock adds nothing.

| Time | Event | Actor |
|------|-------|-------|
| YYYY-MM-DD HH:MM | <last known good state; the final successful operation> | <role> |
| YYYY-MM-DD HH:MM | <the change or event that caused the damage> | <role> |
| YYYY-MM-DD HH:MM | <first symptom observed> | <role> |
| YYYY-MM-DD HH:MM | <incident declared, recovery begins> | <role> |
| YYYY-MM-DD HH:MM | <restore starts> | <role> |
| YYYY-MM-DD HH:MM | <service verified working> | <role> |

## 3. Impact

| Dimension | Value |
|-----------|-------|
| Users affected | <count or "all local developers"> |
| Duration of outage | <HH:MM from first symptom to verified recovery> |
| Data loss window | <backup timestamp to incident timestamp> |
| Environments affected | <local / staging / production> |
| Customer-visible | <yes / no> |
| Revenue or SLA impact | <state it, or "none"> |

## 4. Detection

| Question | Answer |
|----------|--------|
| How was it detected? | <alert / failing request / manual observation> |
| Who or what detected it? | <monitor name, or the role of the person> |
| Time from cause to detection | <duration> |
| Should it have been detected sooner? | <yes/no, and what would have caught it> |
| Detection gap corrective action | <link to the action in section 10> |

## 5. Root cause

<What actually caused it, stated as a mechanism rather than a category. "The
migration runner recorded a migration as applied before the DDL committed" is
a root cause; "human error" is not.>

**Contributing factors:**

1. <a condition without which the incident could not have happened>
2. <another>
3. <another>

## 6. Recovery steps executed

Each step is a heading, the exact command, and the exact result.

### Step 1: Diagnosis

```bash
<command>
# Result: <output>
```

**Finding:** <what this told you>

### Step 2: Backup identification

```bash
ls -la <backup directory>
```

**Available backups:**

| Filename | Date | Size | Notes |
|----------|------|------|-------|
| <file> | <date> | <size> | <age relative to the incident> |
| <file> | <date> | <size> | |
| <file> | <date> | <size> | |

**Selected:** `<file>` (<reason, and the resulting data loss window>)

### Step 3: Stop active connections

```bash
<command that stops the writers>
<command that terminates remaining connections>
```

### Step 4: Recreate the target

```bash
<command>
```

> Destructive. This is the only step in the document that destroys data, and
> it runs only after a backup has been selected and verified readable.

### Step 5: Restore from backup

```bash
<restore command, with the backup path>
```

### Step 6: Verification

```sql
-- <what this query proves>
<query>
```

**Result:**

| <dimension> | <count> |
|-------------|---------|
| <row> | <value> |
| **TOTAL** | **<value>** |

### Step 7: Application-level verification

```sql
<query that proves the application's own critical record is present>
```

**Result:** <what came back>

## 7. Migration or replay catch-up

<Everything that had been applied after the backup was taken and has to be
re-applied. Delete the section if it does not apply.>

| Migration | Status | Notes |
|-----------|--------|-------|
| <name> | EXECUTED | <date applied> |
| <name> | EXECUTED | |
| <name> | FAILED | See below |

### Replay error: <name>

**Error:**

```
<the literal error text>
```

**Root cause:**

1. <what the migration assumed>
2. <what was actually true>

**Fix required:**

```sql
<the corrected statement>
```

## 8. What was lost

**Backup timestamp:** YYYY-MM-DD HH:MM
**Recovery timestamp:** YYYY-MM-DD HH:MM

**Data written in the window and not recovered:**

- <category of record>
- <category of record>
- <category of record>
- <anything applied by hand and not captured in a migration>

**Confirmed not lost:** <what was verified present after the restore>

## 9. What saved us

The counterpart to the corrective actions: the controls that already existed
and worked. Name them so that nobody removes one later as dead weight.

- <control, and what it prevented>
- <control, and what it prevented>

## 10. Corrective actions

| # | Action | Type | Owner role | Work order | Status |
|---|--------|------|-----------|------------|--------|
| 1 | <action> | prevent / detect / mitigate | <role> | WO-NNNN | <open/done> |
| 2 | <action> | | <role> | WO-NNNN | |
| 3 | <action> | | <role> | WO-NNNN | |

## 11. Prevention measures

### Recommended actions

1. **<Automated backups>**

   ```bash
   <the scheduled command>
   ```

2. **<Retention policy>**
   - <tier>: keep <n>
   - <tier>: keep <n>
   - <tier>: keep <n>

3. **<Pre-change backups>**
   - <the rule>
   - <the naming convention>

4. **<Change testing>**
   - <the rule>
   - <the rule>

## 12. Related work orders

- WO-NNNN: <title> (<what it changed near the blast radius>)
- WO-NNNN: <title>

## 13. Commands reference

The commands a future responder needs, separated from the narrative.

### Backup commands

```bash
<create backup, preferred format>
<create backup, portable format>
```

### Restore commands

```bash
<restore, preferred format>
<restore, portable format>
```

### Connection management

```bash
<terminate connections>
<recreate target>
```

## 14. Sign-off

**Recovery performed by:** <role>
**Date:** YYYY-MM-DD
**Status:** COMPLETE

### Final recovery steps completed

1. <step>
2. <step>
3. <step>
4. <post-recovery backup taken, with its filename>

### Verified functionality

- <check> — verified
- <check> — verified
- <check> — verified
- <check> — verified
````

---

# Part 2 — Worked Example

Everything below is an example incident, written out in full. The values are
invented; the shape is the shape a real one should have.

# Incident Report: app_dev

**Date:** YYYY-MM-DD (referred to below as the incident day)
**System:** `{{DB_NAME}}` (example value: `app_dev`)
**Environment:** Local development (PostgreSQL 17.x)
**Severity:** SEV2 — all local development blocked, no customer impact
**Status:** COMPLETE
**Work Order:** WO-0001 (backup automation and pre-migration snapshots)

---

## 1. Incident summary

### Discovery

- **Time:** Incident day, 09:12 (during a routine login against the local API)
- **Symptom:** Login endpoint returned HTTP 500 with
  `Cannot read properties of null (reading 'forEach')`
- **Root cause:** Every application table was missing. Only the `migrations`
  bookkeeping table remained, so the migration runner believed the schema was
  fully applied and refused to recreate anything.

### System state before recovery

```
Schema: public
Tables: 1 (migrations only)
```

All application tables (`core.users`, `access.roles`, and the rest) were
missing despite complete migration records existing. The two facts are
inconsistent: the bookkeeping table said the schema existed, and the schema
did not.

---

## 2. Timeline

All times local, incident day unless dated otherwise.

| Time | Event | Actor |
|------|-------|-------|
| Day -5, 20:02 | Last pre-migration dump taken (`app_dev_pre_wo0011_YYYYMMDD.dump`) | developer |
| Day -5 to day 0 | Ten migrations applied; no further backups taken | developer |
| Day 0, 08:55 | Local database cluster restarted after a host upgrade | developer |
| Day 0, 09:12 | First symptom: login returns 500 | developer |
| Day 0, 09:20 | Incident declared; API process stopped | developer |
| Day 0, 09:34 | Restore from the day -5 dump starts | developer |
| Day 0, 09:41 | Restore complete, 129 tables present | developer |
| Day 0, 10:15 | Migration catch-up complete after one fix; login verified | developer |

---

## 3. Impact

| Dimension | Value |
|-----------|-------|
| Users affected | All local developers (no production or staging exposure) |
| Duration of outage | 01:03 (09:12 to 10:15) |
| Data loss window | 5 days (day -5 20:02 to day 0 09:12) |
| Environments affected | Local development only |
| Customer-visible | No |
| Revenue or SLA impact | None |

---

## 4. Detection

| Question | Answer |
|----------|--------|
| How was it detected? | A failing login request during ordinary development |
| Who or what detected it? | A developer, not a monitor |
| Time from cause to detection | ~17 minutes (restart at 08:55, symptom at 09:12) |
| Should it have been detected sooner? | Yes — a startup schema check would have failed immediately |
| Detection gap corrective action | Action 3 in section 10 |

---

## 5. Root cause

The database cluster's data directory was replaced during a host upgrade while
the `migrations` table happened to be restored from an older snapshot of the
`public` schema. The migration runner reads only that table to decide what to
apply, so on the next start it found every migration recorded as applied and
created nothing. The application then queried a table that did not exist, and
the null result reached code that assumed an array.

**Contributing factors:**

1. The migration runner trusts its bookkeeping table without verifying that
   the objects the migrations created still exist.
2. No backup had been taken in the five days since the last pre-migration
   snapshot, so the most recent recovery point was already stale.
3. The application code called `.forEach` on a query result without a null
   check, which turned a clear database error into an opaque 500.

---

## 6. Recovery steps executed

### Step 1: Diagnosis

```bash
# Verified the database existed but was empty
psql -h localhost -p 5432 -d app_dev -c "\dt public.*"
# Result: Only migrations table

# Confirmed the migrations table had records
psql -h localhost -p 5432 -d app_dev -c "SELECT COUNT(*) FROM migrations;"
# Result: Multiple migration records existed
```

**Finding:** The database was in an inconsistent state — migration records
existed but the tables they created did not.

### Step 2: Backup identification

```bash
ls -la ./backups/
```

**Available backups:**

| Filename | Date | Size | Notes |
|----------|------|------|-------|
| app_dev_pre_wo0011_YYYYMMDD.dump | Day -5 | 1.5MB | Most recent — 5 days old |
| app_dev_full_YYYYMMDD.dump | Day -11 | 1.2MB | 11 days old |
| app_dev_full_YYYYMMDD_180639.dump | Day -17 | 963KB | 17 days old |

**Selected:** `app_dev_pre_wo0011_YYYYMMDD.dump` (most recent; accepts 5 days
of data loss)

### Step 3: Stop active connections

```bash
# Kill the API process holding connections
pkill -f "node.*3001"

# Terminate remaining database connections
psql -h localhost -p 5432 -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'app_dev';"

# The scheduled-job extension was holding a connection — terminated specifically
psql -h localhost -p 5432 -d postgres -c "SELECT pg_terminate_backend(62087);"
```

### Step 4: Database recreation

```bash
dropdb -h localhost -p 5432 app_dev
createdb -h localhost -p 5432 app_dev
```

> Destructive. Run only after the selected dump has been confirmed readable
> with `pg_restore --list`.

### Step 5: Restore from backup

```bash
pg_restore -h localhost -p 5432 -d app_dev --no-owner \
  ./backups/app_dev_pre_wo0011_YYYYMMDD.dump
```

### Step 6: Verification

```sql
-- Verify table counts by schema
SELECT schemaname, COUNT(*) as tables
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
GROUP BY schemaname;
```

**Result:**

| Schema | Tables |
|--------|--------|
| analytics | 5 |
| audit | 44 |
| core | 42 |
| cron | 2 |
| health | 3 |
| notifications | 5 |
| oauth | 3 |
| org | 4 |
| platform | 6 |
| portals | 2 |
| public | 1 |
| access | 5 |
| reporting | 1 |
| settings | 7 |
| webhooks | 2 |
| **TOTAL** | **129** |

### Step 7: Application-level verification

```sql
SELECT id, email, username FROM core.users WHERE email = $1;
```

**Result:** The platform owner account exists (id: 18) and its role assignment
survived the restore.

---

## 7. Migration or replay catch-up

After restoring from the day -5 backup, the following migrations had to run
again.

| Migration | Status | Notes |
|-----------|--------|-------|
| WO0011CreateIntegerApiUsageLogs | EXECUTED | Day -5 |
| WO0011MigrateApiUsageData | EXECUTED | Day -5 |
| WO0011SwapApiUsageTables | EXECUTED | Day -5 |
| WO0011DropOldApiUsageLogs | EXECUTED | Day -5 |
| WO0002TenantPromotionFields | EXECUTED | Day -4 |
| WO0002AddDeploymentPrivileges | EXECUTED | Day -4 |
| WO0002Phase10SslColumns | EXECUTED | Day -3 |
| WO0003CreateLicensingTables | EXECUTED | Day -1 |
| WO0003SeedFeatureRegistry | EXECUTED | Day -1 |
| WO0003UpdateLicenseLimits | EXECUTED | Day -1 |
| WO0004AddLicensingPrivileges | FAILED | See below |

### Replay error: WO0004AddLicensingPrivileges

**Error:**

```
ERROR: column "granted_at" of relation "role_privileges" does not exist
```

**Root cause:**

The migration was written against a schema that never shipped:

1. Used `granted_at` instead of `created_at`
2. Used `r.code` instead of `r.key`
3. Used `'platform_owner'` instead of `'platform-owner'`
4. Referenced `tenant_id IS NULL`, but the column is NOT NULL

It had been applied by hand on one machine and never re-run from a clean
database, so nobody had seen it fail.

**Fix required:**

```sql
-- Correct INSERT statement
INSERT INTO access.role_privileges (role_id, privilege_id, tenant_id, created_at)
SELECT r.id, p.id, r.tenant_id, NOW()
FROM access.roles r
CROSS JOIN access.privileges p
WHERE r.key = 'platform-owner'
  AND p.code IN (...)
```

---

## 8. What was lost

**Backup timestamp:** Day -5, 20:02
**Recovery timestamp:** Day 0, 10:15

**Data written in the window and not recovered (5 days):**

- New user registrations
- Session and refresh tokens
- Audit events
- API key usage logs
- Any data modified by hand rather than by a migration

**Confirmed not lost:** all schema objects, seeded reference data, role and
privilege assignments, and the platform owner account, each verified in
step 6 and step 7.

---

## 9. What saved us

- **Pre-migration dumps were a standing habit.** The selected backup existed
  only because somebody took a snapshot before a risky migration five days
  earlier. Without it the oldest recovery point was seventeen days old.
- **Custom-format dumps.** `pg_restore` restored the full multi-schema
  database in seven minutes; a plain SQL dump of the same database would have
  taken substantially longer and failed on ownership.
- **Migrations were in version control.** The catch-up was a replay, not a
  reconstruction, and the one bad migration was fixed in the file rather than
  patched in the database.

---

## 10. Corrective actions

| # | Action | Type | Owner role | Work order | Status |
|---|--------|------|-----------|------------|--------|
| 1 | Daily automated dump with retention, for every developer machine | prevent | platform | WO-0001 | done |
| 2 | Mandatory pre-migration snapshot in the migration wrapper script | prevent | platform | WO-0001 | done |
| 3 | Startup schema check: compare applied migrations against `information_schema` and refuse to boot on mismatch | detect | API | WO-0002 | open |
| 4 | Null-check the query result that produced the opaque 500 | mitigate | API | BUG-0001 | done |
| 5 | Run every migration once against a freshly created database in CI | detect | CI | WO-0002 | open |

---

## 11. Prevention measures

### Recommended actions

1. **Daily automated backups**

   ```bash
   # Add to crontab or a systemd timer
   0 2 * * * pg_dump -h localhost -p 5432 -Fc app_dev > \
     /path/to/backups/app_dev_$(date +%Y%m%d).dump
   ```

2. **Backup retention policy**
   - Daily backups: keep 7 days
   - Weekly backups: keep 4 weeks
   - Monthly backups: keep 12 months

3. **Pre-migration backups**
   - ALWAYS create a backup before running migrations
   - Label it with the work order number:
     `{{DB_NAME}}_pre_WONNNN_YYYYMMDD.dump`

4. **Migration testing**
   - Test migrations against a copy of the database first
   - Wrap each migration in a transaction so a failure rolls back

---

## 12. Related work orders

- WO-0001: Backup automation and retention (opened by this incident)
- WO-0002: Startup schema verification and CI migration replay (opened by
  this incident)
- WO-0003: Licensing feature registry (the migrations being replayed)
- WO-0011: Usage log integer migration (the change the selected backup
  preceded)

---

## 13. Commands reference

### Backup commands

```bash
# Create backup (custom format - recommended)
pg_dump -h localhost -p 5432 -Fc -f backup.dump app_dev

# Create backup (SQL format)
pg_dump -h localhost -p 5432 -f backup.sql app_dev
```

### Restore commands

```bash
# Restore from custom format
pg_restore -h localhost -p 5432 -d app_dev --no-owner backup.dump

# Restore from SQL format
psql -h localhost -p 5432 -d app_dev < backup.sql
```

### Connection management

```bash
# Terminate all connections to a database
psql -h localhost -p 5432 -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'app_dev' AND pid <> pg_backend_pid();"

# Drop and recreate database
dropdb -h localhost -p 5432 app_dev
createdb -h localhost -p 5432 app_dev
```

### Verify a dump before trusting it

```bash
# List the contents without restoring; fails loudly on a truncated file
pg_restore --list backup.dump | head -20
```

---

## 14. Sign-off

**Recovery performed by:** local development owner
**Date:** incident day
**Status:** COMPLETE

### Final recovery steps completed

1. Fixed the WO-0004 migration (corrected column and key names)
2. Ran the migration successfully
3. Verified login works for the platform owner account
4. Created a post-recovery backup: `app_dev_post_recovery_YYYYMMDD.dump`

### Verified functionality

- User authentication working
- Platform owner role assigned correctly
- Session creation successful
- CSRF token generation working
