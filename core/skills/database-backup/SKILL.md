---
name: database-backup
description: Automated PostgreSQL backup and restore — numbered backup folders, binary and SQL dumps, checksum manifests, age-based retention, verification without a restore, and cron/launchd scheduling, with a portable backup.sh that runs on macOS and Linux. Use when setting up database backups, rotating or pruning them, verifying a dump, or restoring a database.
---

# Database Backup

A backup that has never been restored is a rumour. This skill ships a portable
`backup.sh` and the operating procedure around it: when to take a backup, how the
rotation works, how to prove a dump is good, and how to get the data back.

## When to Activate

- Setting up scheduled backups for a PostgreSQL database
- Before any destructive operation: a reseed, a data migration, a manual `UPDATE`, a schema drop
- Before deploying a migration that is hard to reverse
- Verifying that existing backups are readable and complete
- Restoring a database, or rehearsing a restore
- Tuning retention, disk usage, or backup scheduling
- Investigating a failed or silently empty backup

## The Script

`backup.sh` lives beside this file. It is bash 3.2 compatible, so it runs on the
macOS system bash and on Linux, with either a BSD or a GNU userland.

```bash
./backup.sh                 # Create a backup, then run cleanup
./backup.sh --cleanup       # Run cleanup only
./backup.sh --list          # List all backups
./backup.sh --verify        # Verify the newest backup
./backup.sh --verify 7      # Verify backup number 7
./backup.sh --help          # Show help and current configuration
```

Any unknown option prints the help and exits 2.

### Configuration

Every setting is an environment variable with a default. Nothing is hardcoded and
no password is ever read from the script.

| Variable | Default | Meaning |
|---|---|---|
| `DB_NAME` | `app_dev` | Database to dump |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `5432` | Database port |
| `DB_USER` | `$(id -un)` | Role to connect as |
| `BACKUP_DIR` | `./backups` | Root directory holding the numbered backup folders |
| `RETENTION_DAYS` | `30` | Age at which a backup is deleted; `0` keeps everything |
| `BACKUP_SQL` | `1` | `0` skips the plain-SQL dump and keeps only the binary one |
| `BACKUP_CHECKSUMS` | `1` | `0` skips the `SHA256SUMS` manifest |
| `STATS_TABLES` | `public.users public.accounts public.roles` | Tables counted into each backup's README |
| `PG_DUMP` / `PSQL` / `PG_RESTORE` | `pg_dump` / `psql` / `pg_restore` | Override to pin a client version |
| `NO_COLOR` | unset | Set to any value to disable ANSI colours |

Example invocation:

```bash
DB_NAME=app_production \
DB_HOST=db.example.com \
DB_USER=backup_agent \
BACKUP_DIR=/var/backups/app \
RETENTION_DAYS=14 \
  ./backup.sh
```

### Credentials

The script never contains a password and never accepts one on the command line,
where it would land in the process table and the shell history. Use one of:

```bash
# 1. Environment variable, exported by the scheduler or a secrets helper
export PGPASSWORD="$(cat /run/secrets/db_password)"
./backup.sh

# 2. A password file (preferred for cron)
printf '%s\n' 'db.example.com:5432:app_production:backup_agent:SECRET' >> ~/.pgpass
chmod 600 ~/.pgpass
./backup.sh

# 3. A named connection service
export PGSERVICE=app_backup
./backup.sh
```

A role that only needs to read for `pg_dump` does not need superuser:

```sql
CREATE ROLE backup_agent LOGIN;
GRANT CONNECT ON DATABASE app_production TO backup_agent;
GRANT USAGE ON SCHEMA public TO backup_agent;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_agent;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup_agent;
```

---

## When to Back Up

| Trigger | Command | Why |
|---|---|---|
| Scheduled, twice a day | `./backup.sh` from cron or launchd | Bounded data loss window |
| Before a reseed or `db:reset` | `./backup.sh` | Seeding is destructive by design |
| Before a data migration or manual DML | `./backup.sh` | The only cheap undo |
| Before a release that changes the schema | `./backup.sh` | Rollback needs the old shape |
| After a large import | `./backup.sh` | Cheaper than repeating the import |
| Before deleting a tenant or account | `./backup.sh` | Deletions are frequently regretted |

Take the backup, then **verify** it, then do the destructive thing. An unverified
backup taken thirty seconds before a `DROP` is not a safety net.

---

## What a Backup Contains

Each run creates one numbered folder:

```text
backups/
├── backup-001-20240101-000000/
│   ├── app_dev.dump      # pg_dump -Fc, custom format
│   ├── app_dev.sql       # pg_dump plain SQL
│   ├── SHA256SUMS        # checksums for the two dumps
│   └── README.md         # stats, file sizes, exact restore commands
├── backup-002-20240101-120000/
└── backup-003-20240102-000000/
```

The folder name is `backup-NNN-YYYYMMDD-HHMMSS`: a monotonically increasing
number for humans, and a sortable timestamp that the retention pass reads.

### Why Two Formats

| Format | Written by | Restored by | Good for |
|---|---|---|---|
| `.dump` (custom) | `pg_dump -Fc` | `pg_restore` | Fast, compressed, parallel restore, selective restore of one table |
| `.sql` (plain) | `pg_dump` | `psql` | Reading, grepping, diffing two backups, recovering one statement by hand |

The binary dump is the one to restore from. The SQL dump is the one to read when
answering "what did this column look like last Tuesday".

### The Per-Backup README

Every folder carries a `README.md` generated at backup time containing the backup
number, creation time, host, role, a row count per table in `STATS_TABLES`, file
sizes, and the restore commands already filled in with the right host, port, role
and database name. When restoring under pressure, the commands are in the folder;
nothing has to be reconstructed from memory.

---

## Rotation and Retention

Cleanup runs automatically after every successful backup, and on demand with
`--cleanup`.

```bash
# Delete backups older than RETENTION_DAYS (default 30)
./backup.sh --cleanup

# Keep everything: retention off
RETENTION_DAYS=0 ./backup.sh

# Aggressive rotation on a small disk
RETENTION_DAYS=7 ./backup.sh
```

How the cutoff is computed, portably:

```bash
cutoff_date="$(date -v-"${RETENTION_DAYS}"d +%Y%m%d 2>/dev/null ||
    date -d "${RETENTION_DAYS} days ago" +%Y%m%d)"
```

BSD `date` takes `-v`, GNU `date` takes `-d`, and neither accepts the other's
flag. The BSD form is tried first and the GNU form is the fallback, so one line
works on both systems. Folder dates and the cutoff are both `YYYYMMDD`, so a
numeric comparison is a date comparison — no date parsing is needed at all.

Numbering survives deletion: the next number is one past the highest number still
on disk, read with `printf '%03d'` for the folder name and `$((10#$num))` when
comparing, so `008` is eight rather than an invalid octal literal.

### Sizing the Retention Window

```bash
# What the backups cost today
du -sh backups

# Per-backup size, newest last
./backup.sh --list
```

A useful default is 30 days of twice-daily backups. Cut `RETENTION_DAYS` before
cutting frequency: recent backups are worth far more than old ones. If the
database is large, set `BACKUP_SQL=0` — the plain dump is usually the larger of
the two and the binary dump can restore everything.

### Off-Machine Copies

Retention on one disk is not a backup strategy. Whatever runs the schedule should
also copy finished folders somewhere else:

```bash
./backup.sh && rsync -a --delete backups/ /Volumes/backup-disk/app/
```

---

## Verify Without Restoring

```bash
./backup.sh --verify        # newest backup
./backup.sh --verify 12     # backup number 12
```

The check does three things and exits non-zero on any failure:

1. The binary dump exists and is non-empty
2. `pg_restore --list` parses the archive's table of contents, which fails on a truncated or corrupt file
3. `SHA256SUMS` matches, when the manifest is present

```text
[INFO]    2024-01-02 00:00:05 - Verifying backup-003-20240102-000000
[SUCCESS] 2024-01-02 00:00:05 - Archive readable, 412 table-of-contents entries
[INFO]    2024-01-02 00:00:05 - Checking checksums...
[SUCCESS] 2024-01-02 00:00:06 - Checksums match
[SUCCESS] 2024-01-02 00:00:06 - Backup backup-003-20240102-000000 verified
```

Manual equivalents:

```bash
# Table of contents, one line per object
pg_restore --list backups/backup-003-*/app_dev.dump | head -20

# Checksums (macOS ships shasum, GNU coreutils ships sha256sum)
cd backups/backup-003-* && shasum -a 256 -c SHA256SUMS
```

Verification proves the file is readable. Only a restore proves the data is
complete, so rehearse one on a schedule — monthly is a reasonable floor.

---

## Restore

### Restore Into a New Database (always do this first)

```bash
createdb -h localhost -p 5432 -U app app_dev_restore
pg_restore -h localhost -p 5432 -U app -d app_dev_restore \
  --no-owner --no-privileges backups/backup-003-*/app_dev.dump
```

`--no-owner --no-privileges` drops ownership and grant statements that reference
roles which may not exist on the target machine. Add `-j 4` to restore with four
worker processes on a large dump.

### Check the Restore

```bash
psql -h localhost -p 5432 -U app -d app_dev_restore -c "
SELECT 'users' AS table_name, COUNT(*) FROM public.users
UNION ALL SELECT 'accounts', COUNT(*) FROM public.accounts
UNION ALL SELECT 'roles', COUNT(*) FROM public.roles;
"
```

```text
 table_name | count
------------+-------
 users      |  1284
 accounts   |    37
 roles      |    16
(3 rows)
```

Compare those numbers against the `## Database Statistics` table in the backup
folder's README. They should match exactly.

### Restore From the SQL Dump

```bash
createdb -h localhost -p 5432 -U app app_dev_restore
psql -h localhost -p 5432 -U app -d app_dev_restore < backups/backup-003-*/app_dev.sql
```

### Restore a Single Table

```bash
# Find the entry
pg_restore --list backups/backup-003-*/app_dev.dump | grep ' users'

# Restore just that table's data into a live database
pg_restore -h localhost -p 5432 -U app -d app_dev \
  --data-only --table=users backups/backup-003-*/app_dev.dump
```

### Replace the Live Database (destructive)

Only after the check above passed, and only with a fresh backup in hand.

```bash
dropdb -h localhost -p 5432 -U app app_dev
createdb -h localhost -p 5432 -U app app_dev
pg_restore -h localhost -p 5432 -U app -d app_dev \
  --no-owner --no-privileges backups/backup-003-*/app_dev.dump
```

`dropdb` fails while sessions are connected. Stop the application first; if
something still holds a connection:

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'app_dev' AND pid <> pg_backend_pid();
```

### Restore Checklist

- [ ] A fresh backup of the current state exists before restoring over anything
- [ ] The dump verified (`./backup.sh --verify`) before the restore started
- [ ] Restored into a scratch database first, never straight over the live one
- [ ] Row counts compared against the backup folder's README
- [ ] Application stopped, or in maintenance mode, during a destructive restore
- [ ] Migrations re-checked after restore (`npm run migration:show`)
- [ ] Sequences and extensions present (`\ds`, `\dx` in psql)
- [ ] Scratch database dropped afterwards

---

## Scheduling

### cron (Linux, and macOS if cron is enabled)

```bash
crontab -e
```

```text
# Every 12 hours, at midnight and noon
0 0,12 * * * BACKUP_DIR=/var/backups/app DB_NAME=app_production /opt/app/backup.sh >> /var/log/db-backup.log 2>&1
```

cron runs with a minimal environment: no shell profile, and frequently a `PATH`
that does not include the PostgreSQL client binaries. Set what the job needs
explicitly:

```text
PATH=/usr/local/bin:/usr/bin:/bin
PGPASSFILE=/var/lib/app/.pgpass
0 0,12 * * * BACKUP_DIR=/var/backups/app /opt/app/backup.sh >> /var/log/db-backup.log 2>&1
```

### launchd (macOS)

`~/Library/LaunchAgents/db-backup.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Label</key><string>db-backup</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/app/backup.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <key>BACKUP_DIR</key><string>/Volumes/backups/app</string>
    <key>DB_NAME</key><string>app_dev</string>
  </dict>
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Hour</key><integer>0</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>0</integer></dict>
  </array>
  <key>StandardOutPath</key><string>/tmp/db-backup.log</string>
  <key>StandardErrorPath</key><string>/tmp/db-backup.err</string>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/db-backup.plist
launchctl start db-backup
tail -f /tmp/db-backup.log
```

### systemd timer (Linux)

`/etc/systemd/system/db-backup.service`:

```ini
[Unit]
Description=Database backup

[Service]
Type=oneshot
User=appuser
Environment=BACKUP_DIR=/var/backups/app
Environment=DB_NAME=app_production
ExecStart=/opt/app/backup.sh
```

`/etc/systemd/system/db-backup.timer`:

```ini
[Unit]
Description=Run the database backup twice a day

[Timer]
OnCalendar=00,12:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl enable --now db-backup.timer
systemctl list-timers db-backup.timer
journalctl -u db-backup.service -n 50
```

### CI

```bash
# Before a migration job touches a shared database
BACKUP_DIR="$CI_ARTIFACTS/backups" RETENTION_DAYS=0 ./backup.sh
./backup.sh --verify
```

---

## Failure Modes

### "Cannot connect to database"

The connectivity probe (`psql -c "SELECT 1"`) failed, the empty backup folder was
removed, and the script exited 1 without writing a partial backup.

```bash
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1"
```

Causes: the server is down, the role cannot authenticate, `PGPASSWORD` is not
exported into the scheduler's environment, or `pg_hba.conf` rejects the host.

### "Failed to create binary dump"

`pg_dump` exited non-zero. The most common causes:

- **Version mismatch** — a client older than the server refuses to dump. Check `pg_dump --version` against `psql -c 'SHOW server_version'`, and pin with `PG_DUMP=/usr/lib/postgresql/16/bin/pg_dump`.
- **Permission denied on a table** — the role cannot `SELECT` everything. Re-grant, as in the role setup above.
- **Disk full** — `df -h "$BACKUP_DIR"`.

### The backup exists but is suspiciously small

Compare against the previous run:

```bash
./backup.sh --list
```

A dump that shrank by an order of magnitude usually means the role lost `SELECT`
on most tables and dumped only the schema. `pg_restore --list` on the archive
shows whether `TABLE DATA` entries are present.

### Cron runs but nothing is written

Almost always `PATH`. cron does not read a shell profile, so `pg_dump` is not
found and the failure goes to a mail spool nobody reads. Redirect both streams to
a log file, as the crontab line above does, and set `PATH` in the crontab.

### "value too great for base" during numbering

A folder numbered `008` or `009` parsed as octal. The script forces base 10 with
`$((10#$num))`; this is what that guard is for. Non-numeric folders under
`BACKUP_DIR` are skipped rather than crashing the run.

### Checksum mismatch on verify

The dump changed after it was written: bit rot, an interrupted copy to another
disk, or a partially synced network volume. Treat that backup as lost, take a new
one immediately, and verify the neighbours:

```bash
for n in 1 2 3; do ./backup.sh --verify "$n" || echo "backup $n is bad"; done
```

### Retention deleted more than expected

`RETENTION_DAYS` is read from the environment, so an empty value in a scheduler
would make the cutoff meaningless. The script treats `0` as "keep everything"; an
unset variable falls back to `30`. Check what the job actually sees:

```bash
RETENTION_DAYS= ./backup.sh --help | grep RETENTION
```

---

## Command Reference

Everything the script runs, and why.

| Command | Where | Purpose |
|---|---|---|
| `id -un` | config | Default database role: the current user |
| `date +%Y%m%d-%H%M%S` | config | Folder timestamp |
| `date '+%Y-%m-%d %H:%M:%S'` | logging | Human timestamps in the log and README |
| `psql -h .. -p .. -U .. -d .. -c "SELECT 1"` | `create_backup` | Connectivity probe before anything is written |
| `psql -t -A -c "SELECT COUNT(*) FROM <table>"` | `create_backup` | Row counts per `STATS_TABLES` entry for the README |
| `pg_dump -Fc -f <file> <db>` | `create_backup` | Binary custom-format dump |
| `pg_dump -f <file> <db>` | `create_backup` | Plain SQL dump, skipped when `BACKUP_SQL=0` |
| `du -h <file>` | `file_size` | Per-file size for the listing and README |
| `du -sh <dir>` | `list_backups` | Total disk used by all backups |
| `shasum -a 256` / `sha256sum` | `sha256_write`, `sha256_check` | Checksum manifest; macOS has the first, GNU the second |
| `mkdir -p` | `create_backup` | Create the backup root and the numbered folder |
| `rmdir` | `create_backup` | Remove the empty folder when the connectivity probe fails |
| `cat > README.md << EOF` | `create_backup` | Write the per-backup README |
| `date -v-Nd` / `date -d "N days ago"` | `cleanup_old_backups` | Retention cutoff, BSD then GNU |
| `rm -rf <dir>` | `cleanup_old_backups` | Delete an expired backup folder |
| `basename` | several | Folder name from a path |
| `printf "%03d"` | `format_backup_number` | Zero-padded backup number |
| `pg_restore --list <dump>` | `verify_backup` | Read the archive's table of contents without restoring |
| `command -v shasum` | `sha256_write`, `sha256_check` | Pick the available checksum tool |

Commands documented here for restore, which the script prints but never executes:
`createdb`, `dropdb`, `pg_restore -d`, `pg_restore --data-only --table`,
`psql -d <db> < dump.sql`, `pg_terminate_backend`.

---

## Portability Notes

The script is checked against both target platforms, so any edit must keep:

- `set -euo pipefail` at the top
- No `declare -A` (bash 4), no `mapfile` or `readarray` (bash 4), no `${var,,}` or `${var^^}` (bash 4)
- No `sed -i`, `stat -c`, `find -printf`, `readlink -f`, `realpath`, `timeout`, `nproc`
- `date -v` first with a `date -d` fallback, never one alone
- `shasum` first with a `sha256sum` fallback, never one alone
- String splitting with parameter expansion (`${x#prefix}`, `${x%%-*}`) rather than `sed`, which differs between BSD and GNU

```bash
bash -n backup.sh                      # syntax only, runs nothing
bash --version                         # 3.2 on stock macOS
./backup.sh --help                     # prints the effective configuration
```

---

## Best Practices

### DO

- Verify every backup, and rehearse a restore on a schedule
- Keep backups on a different disk, and ideally a different machine, from the database
- Take an ad-hoc backup before anything destructive, including reseeds
- Keep the per-backup README with the dump; it is the restore runbook
- Give the backup job its own least-privilege role
- Log the scheduled run to a file and check that the file is growing

### DON'T

- Trust a backup that has never been read back
- Put a password in the script, in the crontab, or on the command line
- Restore straight over a live database before checking a scratch restore
- Let retention be the only copy policy — rotation is not replication
- Ignore a shrinking dump size
- Run the scheduled job as a superuser role

---

## Related Skills

- [database-seeding](../database-seeding/SKILL.md) — take a backup before any reseed or `db:reset`
- [database-migrations](../database-migrations/SKILL.md) — back up before a migration that is hard to reverse
- [postgres-patterns](../postgres-patterns/SKILL.md) — the query and schema side of the same database
