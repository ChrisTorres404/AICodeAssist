# Database Gold Standard Methodology

> How {{PROJECT_NAME}} keeps a known-good database baseline, and how that
> baseline is captured, documented, restored, and verified.

A behavioral suite is only meaningful when it starts from a state you can name.
The gold standard is that state: a captured, versioned, documented snapshot of
the development database, taken at a point where the schema and the seed data
were known to be correct. Suites restore to it; a developer whose local
database has drifted restores to it; an investigation that needs a clean
comparison restores to it.

This is the companion to
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`, which
requires that prior test state be cleared before a run. This document is how
that is done reproducibly.

Time to produce a new baseline: roughly twenty minutes, most of it writing the
record rather than taking the backup.

---

## Prerequisites

Have these before starting; each of them is a failure five steps in if it is
missing.

- The database engine's client tools on the machine taking the backup — for
  PostgreSQL, `pg_dump`, `pg_restore`, `psql`, and `pg_isready`
- Credentials for the database: user, password, host, and port, supplied through
  the environment or the shared test configuration, never typed into a file that
  gets committed
- Read access to every schema in the database, including the ones the
  application does not own
- Write access to the baseline directory, `{{TESTING_DIR}}/baselines/`
- Enough free disk for both dumps; the plain-text dump is several times the size
  of the compressed one

```bash
pg_dump --version
psql --version
pg_isready -h "$DB_HOST" -p "$DB_PORT"
```

---

## What a Baseline Is

A baseline version is a directory containing three things. All three are
required; a dump with no record of what is in it is not a baseline, because
nobody can tell whether a restored database matches it.

| Artifact | Purpose |
|---|---|
| A binary or engine-native dump | Fast, exact restore |
| A plain-text dump | Human readable, diffable, greppable when you need to know whether something was present |
| A README | The statistics, the changes since the previous version, the restore commands, and the verification query with its expected output |

### Where baselines live

```
{{TESTING_DIR}}/baselines/
├── README.md                  # index: version history, current version, quick restore
├── v1-YYYYMMDD/
│   ├── README.md
│   ├── <baseline>.dump        # engine-native
│   └── <baseline>.sql         # plain text
└── v2-YYYYMMDD/
    └── ...
```

Dumps can be large and may contain seed data you do not want in version
control. Check the project's ignore rules before committing one; if the dumps
are held outside the repository, the README stays in the repository and says
where they are.

### When to cut a new version

- A schema migration lands that changes the shape the suites depend on
- Seed data that features require changes: roles, permissions, templates,
  reference data
- A release is tagged and you want the database state that shipped with it
- The current baseline no longer restores cleanly

Do not cut one for a day's experimenting. A baseline is a claim that this state
was correct.

---

## The Method

### Step 1 — determine the version number

List the existing versions and take the next one. The format is
`vN-YYYYMMDD`.

```bash
ls -1 {{TESTING_DIR}}/baselines/
```

### Step 2 — create the version directory

```bash
VERSION="v2"                  # the next number
DATE=$(date +%Y%m%d)
BASELINE_DIR="{{TESTING_DIR}}/baselines/${VERSION}-${DATE}"
mkdir -p "$BASELINE_DIR"
```

### Step 3 — take both dumps

One engine-native dump for fast restores, one plain-text dump for reading. Both
name the database, the version, and the date, so a file that has been moved is
still identifiable.

Credentials come from the environment or the project's configuration. A
methodology document never contains a password, and neither does a checked-in
script.

### Step 4 — gather the statistics

These are what the README records and what a verification compares against.
Every engine can answer all of them; the queries differ.

| Statistic | Why it is recorded |
|---|---|
| Database size | A restored database that is a fraction of the size is missing data |
| Engine version | A dump does not always restore across major versions |
| Tables per schema | The fastest signal that a restore was partial |
| Row counts for the key tables | Accounts, tenants or organizations, roles, permissions, reference data, migrations |
| Views, including materialized views | Materialized views restore empty in some engines; note which need refreshing |
| Triggers | The behavior most easily lost in a restore that skipped ownership |
| Routines per schema | Functions and procedures the application calls |
| Indexes per schema | A restore that dropped indexes still answers queries, slowly |
| Row-level security or equivalent policies | Silently absent after a restore that skipped privileges |
| Applied migrations, and the most recent ones | The single most useful number: it says exactly where the schema stands |

Record the totals, and record the last ten migrations by name. Those two facts
identify a baseline better than any prose description.

### Step 5 — write the version README

Use the template below. Fill in every statistic; leave no placeholder in a
document that is going to be used as a reference. State what changed since the
previous version, and why this one was cut.

### Step 6 — update the index README

In `{{TESTING_DIR}}/baselines/README.md`:

1. Add the new version to the version history table
2. Update the current-version section with the new statistics
3. Update the quick-restore command to name the new files

A baselines directory whose index still points at a version from two schema
changes ago is how people end up restoring the wrong one.

### Step 7 — verify before you declare it

- [ ] Both dumps exist and are non-empty
- [ ] The engine-native dump lists its contents without error
- [ ] The README carries every statistic, with no placeholders left
- [ ] Everything new since the previous version is described
- [ ] The restore commands were run, into a scratch database, and worked
- [ ] The verification query was run against that restored database and matched
      the expected output in the README
- [ ] The index README names the new version
- [ ] File sizes are noted, so a truncated copy is obvious

The sixth item is the one that gets skipped and the one that matters. A
baseline nobody has restored is a hope, not a baseline.

---

## For PostgreSQL

The commands below are the PostgreSQL form of steps 3, 4, and the restore. The
method above is the same for any engine; substitute its dump, restore, and
catalogue queries.

### Taking the dumps

```bash
VERSION="v2"
DATE=$(date +%Y%m%d)
BASELINE_DIR="{{TESTING_DIR}}/baselines/${VERSION}-${DATE}"

# Connection details come from the environment or the test configuration.
# Never write a password into a script or a document.
: "${DB_HOST:?set DB_HOST}" "${DB_PORT:?set DB_PORT}" "${DB_USER:?set DB_USER}"

# Engine-native, compressed, restores fastest
PGPASSWORD="${DB_PASS}" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  -d {{DB_NAME}} -Fc \
  -f "${BASELINE_DIR}/{{DB_NAME}}_baseline_${VERSION}_${DATE}.dump"

# Plain text, readable and diffable
PGPASSWORD="${DB_PASS}" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  -d {{DB_NAME}} \
  -f "${BASELINE_DIR}/{{DB_NAME}}_baseline_${VERSION}_${DATE}.sql"

ls -la "$BASELINE_DIR"
```

### Statistics queries

Each query is numbered so the version README can cite the one it was filled
from.

**4.1 — size and engine version:**

```sql
SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;
SELECT version();
```

**4.2 — tables per schema.** This excludes the engine's own schemas, so what
remains is the application's schemas:

```sql
SELECT table_schema AS schema, COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT LIKE 'pg_%'
  AND table_schema <> 'information_schema'
GROUP BY table_schema
ORDER BY table_schema;
```

**4.3 — row counts for the tables that matter.** Replace the list with this
project's identity, authorization, and reference tables — the ones whose
absence would make the application unusable:

```sql
SELECT '<schema>.<accounts>'    AS table_name, COUNT(*) FROM <schema>.<accounts>
UNION ALL SELECT '<schema>.<organizations>', COUNT(*) FROM <schema>.<organizations>
UNION ALL SELECT '<schema>.<roles>',         COUNT(*) FROM <schema>.<roles>
UNION ALL SELECT '<schema>.<permissions>',   COUNT(*) FROM <schema>.<permissions>
UNION ALL SELECT '<schema>.<role_permissions>', COUNT(*) FROM <schema>.<role_permissions>
UNION ALL SELECT '<schema>.<user_roles>',    COUNT(*) FROM <schema>.<user_roles>
UNION ALL SELECT '<schema>.<sessions>',      COUNT(*) FROM <schema>.<sessions>
UNION ALL SELECT '<schema>.<audit_events>',  COUNT(*) FROM <schema>.<audit_events>
UNION ALL SELECT '<schema>.<notification_templates>', COUNT(*) FROM <schema>.<notification_templates>
UNION ALL SELECT '<schema>.<notification_providers>', COUNT(*) FROM <schema>.<notification_providers>
UNION ALL SELECT '<schema>.<policies>',      COUNT(*) FROM <schema>.<policies>
UNION ALL SELECT 'migrations',               COUNT(*) FROM migrations
ORDER BY table_name;
```

**4.4 — views, regular and materialized:**

```sql
SELECT schemaname AS schema, viewname AS view_name, 'regular' AS type
FROM pg_views
WHERE schemaname NOT LIKE 'pg_%' AND schemaname <> 'information_schema'
UNION ALL
SELECT schemaname, matviewname, 'materialized'
FROM pg_matviews
WHERE schemaname NOT LIKE 'pg_%'
ORDER BY schema, view_name;
```

**4.5 — triggers:**

```sql
SELECT trigger_schema AS schema,
       trigger_name,
       event_object_table AS table_name,
       action_timing || ' ' || event_manipulation AS trigger_event
FROM information_schema.triggers
WHERE trigger_schema NOT LIKE 'pg_%'
ORDER BY trigger_schema, event_object_table, trigger_name;
```

**4.6 — routines (functions and procedures) per schema:**

```sql
SELECT n.nspname AS schema, COUNT(*) AS function_count
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'
GROUP BY n.nspname
ORDER BY function_count DESC;
```

**4.7 — indexes per schema:**

```sql
SELECT schemaname AS schema, COUNT(*) AS index_count
FROM pg_indexes
WHERE schemaname NOT LIKE 'pg_%' AND schemaname <> 'information_schema'
GROUP BY schemaname
ORDER BY index_count DESC;
```

**4.8 — row-level security policies, in total and by table:**

```sql
SELECT COUNT(*) AS total_policies FROM pg_policies;

SELECT schemaname AS schema, tablename AS table_name, COUNT(*) AS policy_count
FROM pg_policies
GROUP BY schemaname, tablename
ORDER BY schemaname, tablename;
```

**4.9 — applied migrations.** Adjust the table name to whatever the project's
migration tool uses:

```sql
SELECT COUNT(*) AS migrations_applied FROM migrations;
SELECT timestamp, name FROM migrations ORDER BY timestamp DESC LIMIT 10;
```

### One pass for all of it

```bash
PGPASSWORD="${DB_PASS}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d {{DB_NAME}} <<'SQL'
\echo '=== SIZE ==='
SELECT pg_size_pretty(pg_database_size(current_database())) AS size;
\echo '=== TABLES BY SCHEMA ==='
SELECT table_schema, COUNT(*) AS tables FROM information_schema.tables
WHERE table_type = 'BASE TABLE' AND table_schema NOT LIKE 'pg_%'
  AND table_schema <> 'information_schema'
GROUP BY table_schema ORDER BY table_schema;
\echo '=== KEY COUNTS ==='
SELECT '<accounts>' AS t, COUNT(*) FROM <schema>.<accounts>
UNION ALL SELECT '<organizations>',    COUNT(*) FROM <schema>.<organizations>
UNION ALL SELECT '<roles>',            COUNT(*) FROM <schema>.<roles>
UNION ALL SELECT '<permissions>',      COUNT(*) FROM <schema>.<permissions>
UNION ALL SELECT '<role_permissions>', COUNT(*) FROM <schema>.<role_permissions>
UNION ALL SELECT '<user_roles>',       COUNT(*) FROM <schema>.<user_roles>
UNION ALL SELECT 'migrations',         COUNT(*) FROM migrations;
\echo '=== TRIGGERS ==='
SELECT trigger_schema, trigger_name, event_object_table
FROM information_schema.triggers WHERE trigger_schema NOT LIKE 'pg_%'
ORDER BY trigger_schema;
\echo '=== FUNCTIONS BY SCHEMA ==='
SELECT n.nspname, COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'
GROUP BY n.nspname ORDER BY COUNT(*) DESC;
\echo '=== INDEXES BY SCHEMA ==='
SELECT schemaname, COUNT(*) FROM pg_indexes WHERE schemaname NOT LIKE 'pg_%'
GROUP BY schemaname ORDER BY COUNT(*) DESC;
\echo '=== POLICIES ==='
SELECT COUNT(*) AS total_policies FROM pg_policies;
\echo '=== RECENT MIGRATIONS ==='
SELECT timestamp, name FROM migrations ORDER BY timestamp DESC LIMIT 10;
SQL
```

---

## Restoring

### Into a new database — the default

This is the safe path and the one to use unless there is a reason not to.

```bash
createdb -h "$DB_HOST" -p "$DB_PORT" {{DB_NAME}}_restored

# From the engine-native dump
pg_restore -h "$DB_HOST" -p "$DB_PORT" -d {{DB_NAME}}_restored \
  --no-owner --no-privileges \
  "${BASELINE_DIR}/{{DB_NAME}}_baseline_${VERSION}_${DATE}.dump"

# Or from the plain-text dump, slower but more forgiving across versions
psql -h "$DB_HOST" -p "$DB_PORT" -d {{DB_NAME}}_restored \
  -f "${BASELINE_DIR}/{{DB_NAME}}_baseline_${VERSION}_${DATE}.sql"
```

### Over an existing database — destructive, and guarded

Replacing an existing database means destroying what is in it. The pipeline's
`block-database-drop` hook rule refuses these commands, and that guard exists
on purpose: it has to be the user's explicit instruction in the session, not an
agent's decision, and never a reflex after a failed migration. If migrations
failed, stop and ask how to proceed.

When it has been asked for, the shape is: drop, create, restore — and then run
the verification below, because a half-restored database that nobody checked is
worse than the broken one it replaced.

```bash
# Drop and recreate — only on the user's explicit instruction in this session
dropdb   -h "$DB_HOST" -p "$DB_PORT" {{DB_NAME}}
createdb -h "$DB_HOST" -p "$DB_PORT" {{DB_NAME}}

# Restore
pg_restore -h "$DB_HOST" -p "$DB_PORT" -d {{DB_NAME}} \
  --no-owner --no-privileges \
  "${BASELINE_DIR}/{{DB_NAME}}_baseline_${VERSION}_${DATE}.dump"
```

### After any restore

- Refresh materialized views; some engines restore their definitions without
  their contents
- Confirm sequences are positioned past the highest existing key, or the first
  insert collides
- Re-apply any grants that `--no-owner --no-privileges` deliberately skipped
- Run the application's migration command; it should report nothing to do

---

## Verifying a Restore

Every version README carries this query and its expected output. Run it against
the restored database and compare.

```bash
psql -h "$DB_HOST" -p "$DB_PORT" -d <restored-database> -c "
SELECT '<roles>'            AS table_name, COUNT(*) FROM <schema>.<roles>
UNION ALL SELECT '<permissions>',      COUNT(*) FROM <schema>.<permissions>
UNION ALL SELECT '<role_permissions>', COUNT(*) FROM <schema>.<role_permissions>
UNION ALL SELECT '<user_roles>',       COUNT(*) FROM <schema>.<user_roles>
UNION ALL SELECT '<accounts>',         COUNT(*) FROM <schema>.<accounts>
UNION ALL SELECT '<organizations>',    COUNT(*) FROM <schema>.<organizations>
UNION ALL SELECT 'migrations',         COUNT(*) FROM migrations;
"
```

Expected output — the version README carries the filled-in version of this, and
a restore is verified by comparing against it, not by reading the restore
command's exit code:

```
    table_name     | count
-------------------+-------
 <accounts>        |    12
 <organizations>   |     3
 <permissions>     |   146
 <role_permissions>|   412
 <roles>           |    14
 <user_roles>      |    18
 migrations        |   231
(7 rows)
```

Counts that match, and a migration count that matches, mean the restore is the
baseline. Counts that do not match mean it is not, whatever the restore command
printed.

For a stronger check, re-run the statistics queries from step 4 against the
restored database and compare them to the README. Tables per schema, trigger
count, and policy count catch the restores that lost structure rather than rows.

---

## Version README Template

```markdown
# {{PROJECT_NAME}} Database Baseline vN

> Created: YYYY-MM-DD
> Database: {{DB_NAME}}
> Engine version: ...
> Status: ...
> Previous version: vN-1 (YYYY-MM-DD)

## Summary

Why this baseline was cut and what it contains.

### Key metrics

| Metric | Value |
|--------|-------|
| Database size | |
| Total tables | |
| Total schemas | |
| Total indexes | |
| Total routines | |
| Total triggers | |
| Total policies | |
| Applied migrations | |
| Views | (materialized / regular) |

## Files

| File | Format | Size | Use |
|------|--------|------|-----|
| ...dump | engine-native, compressed | | Fast restore |
| ...sql | plain text | | Reading, diffing, version control |

## What changed since vN-1

### Security enhancements

What changed in access control, policies, credential handling, or auditing.
This subsection comes first because it is the one a reviewer reads.

### New features

What the application can now do that it could not at vN-1, in terms of the
database objects that support it.

### Database changes

#### Migrations applied

| Timestamp | Name | What it does |
|-----------|------|--------------|

#### New tables

| Schema | Table | Purpose |
|--------|-------|---------|

#### New triggers

| Schema | Trigger | Table | Purpose |
|--------|---------|-------|---------|

#### New routines

| Schema | Routine | Purpose |
|--------|---------|---------|

### Seed and reference data

What changed in the data every environment is expected to have.

## Schema overview

### Tables by schema

| Schema | Tables | Purpose |
|--------|--------|---------|
| [FILL FROM QUERY 4.2] | | |

### Key row counts

| Table | Count |
|-------|-------|
| [FILL FROM QUERY 4.3] | |

### Materialized views

| Schema | View | Purpose |
|--------|------|---------|
| [FILL FROM QUERY 4.4 — materialized only] | | |

### Regular views

| Schema | View | Purpose |
|--------|------|---------|
| [FILL FROM QUERY 4.4 — regular only] | | |

## Triggers (N total)

Triggers are listed in three groups, because the three carry very different
risk. A missing updated-at trigger is a nuisance; a missing security trigger is
a vulnerability that a restore silently introduced.

### Security triggers (critical)

Triggers that enforce access, tenancy, immutability, or auditing. Verify every
one of these after a restore.

| Schema | Trigger | Table | Event | Purpose |
|--------|---------|-------|-------|---------|
| [FILL FROM QUERY 4.5 — security-related] | | | | |

### Validation triggers

Triggers that enforce an invariant the application also enforces — referential
rules, state machines, computed constraints.

| Schema | Trigger | Table | Event | Purpose |
|--------|---------|-------|-------|---------|
| [FILL FROM QUERY 4.5 — validation-related] | | | | |

### Updated-at triggers

The bookkeeping triggers that maintain timestamps. Listed for completeness so
that the total reconciles.

| Schema | Trigger | Table |
|--------|---------|-------|
| [FILL FROM QUERY 4.5 — updated-at triggers] | | |

## Routines and indexes by schema

### Routines

| Schema | Count | Key routines |
|--------|-------|--------------|
| [FILL FROM QUERY 4.6] | | |

### Indexes

| Schema | Count | Notes |
|--------|-------|-------|
| [FILL FROM QUERY 4.7] | | |

## Access policies

How row-level access is enforced, and the total policy count. Describe the
strategy in prose, and give the total from query 4.8.

## Restore

The commands, copy-pasteable, naming these files.

## Verification

The query, and the exact output a correct restore produces.

## Migration history (last 10)

| Timestamp | Migration | What it does |
|-----------|-----------|--------------|
| [FILL FROM QUERY 4.9] | | |

## Changelog from vN-1

### Added
### Changed
### Fixed
### Security

## Related work orders

| WO | Title | Status |
|----|-------|--------|
```

---

## Troubleshooting

### Permission denied on the dump

Confirm the server is reachable and the credentials work with a trivial query
before blaming the dump. Most failures here are connection failures wearing a
different message.

```bash
# Is the server up at all
pg_isready -h "$DB_HOST" -p "$DB_PORT"

# Do these credentials work
PGPASSWORD="${DB_PASS}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d {{DB_NAME}} -c "SELECT 1;"
```

### The dump file is too large

Use the engine-native compressed format, which is compressed already, and
compress the plain-text dump separately. Do not solve the problem by dumping
less; a partial baseline is not a baseline.

```bash
# Compress the plain-text dump
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d {{DB_NAME}} | gzip > baseline.sql.gz

# Or take the custom format, which is already compressed
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d {{DB_NAME}} -Fc -f baseline.dump
```

### The restore fails with role or ownership errors

Restore without ownership and privileges, then apply the project's own grants
afterwards. The roles on a developer machine are rarely the roles in the
environment the dump came from.

```bash
pg_restore --no-owner --no-privileges -h "$DB_HOST" -p "$DB_PORT" \
  -d <restored-database> baseline.dump
```

### The restore succeeded but the application will not start

Check the migration table first. A database restored from an older baseline
needs the migrations since then applied, and the application usually says so
badly.

### The counts are close but not equal

Something wrote to the database between
the dump and the statistics, or between the restore and the check. Take both
from the same moment, and take the statistics from the restored database rather
than from the one you dumped.

---

## Prompt for an Agent

```
Create a new database baseline for {{DB_NAME}}:

1. Create the version directory {{TESTING_DIR}}/baselines/vN-YYYYMMDD
2. Take both dumps: engine-native and plain text
3. Run every statistics query and capture the real output
4. Write the version README from the template: summary, what changed since the
   previous version, schema overview, triggers, routines and indexes by schema,
   policy count, restore commands, verification query with expected output
5. Restore into a scratch database, run the verification query, and record the
   real result
6. Update {{TESTING_DIR}}/baselines/README.md with the new version

The previous version was vN-1 from YYYY-MM-DD. Changes since then: [list].

Paste real command output. Do not fill any statistic from memory or estimate,
and do not report the restore as verified unless you ran it.
```

---

## Relationship to the Rest of the Methodology

- Behavioral suites that need a known starting state restore this baseline
  first; see `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`
- A work order that changes the schema or the seed data says in its closeout
  whether a new baseline was cut, and names it
- The baseline README is documentation subject to the same rule as every other
  record here: the numbers in it are the numbers that came back from the
  database, or they are not written down
