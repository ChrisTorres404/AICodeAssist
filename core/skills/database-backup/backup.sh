#!/usr/bin/env bash
# =============================================================================
# Database Backup Script
# =============================================================================
#
# Purpose: automated PostgreSQL backups with a retention policy.
#
# Features:
# - Sequential numbered backup folders
# - Both binary (.dump) and plain SQL (.sql) formats
# - Checksum manifest per backup
# - Per-backup README with the exact restore commands
# - Age-based retention with automatic cleanup
# - Designed for 12-hour cron or launchd scheduling
#
# Usage:
#   ./backup.sh                 # Run backup (then cleanup)
#   ./backup.sh --cleanup       # Run cleanup only
#   ./backup.sh --list          # List all backups
#   ./backup.sh --verify [N]    # Verify a backup (default: the newest)
#   ./backup.sh --help          # Show help
#
# Configuration is entirely by environment variable; see the block below.
# The password is never read from this file. Use one of:
#   PGPASSWORD=...            (exported by the caller, not stored here)
#   ~/.pgpass                 (chmod 600, host:port:db:user:password)
#   PGSERVICEFILE / PGSERVICE (a named connection service)
#
# Cron setup (every 12 hours):
#   0 0,12 * * * BACKUP_DIR=/var/backups/db /path/to/backup.sh >> /var/log/db-backup.log 2>&1
#
# Portability: bash 3.2 (macOS default) and bash 5 (Linux), BSD and GNU
# userlands. No associative arrays, no mapfile, no GNU-only flags.
# =============================================================================

set -euo pipefail

# --- Configuration (all overridable from the environment) --------------------
DB_NAME="${DB_NAME:-app_dev}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$(id -un)}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"     # 0 disables cleanup
BACKUP_SQL="${BACKUP_SQL:-1}"              # 0 skips the plain-SQL dump
BACKUP_CHECKSUMS="${BACKUP_CHECKSUMS:-1}"  # 0 skips the SHA256SUMS manifest
PG_DUMP="${PG_DUMP:-pg_dump}"
PSQL="${PSQL:-psql}"
PG_RESTORE="${PG_RESTORE:-pg_restore}"

# Tables counted into each backup's README, space separated.
STATS_TABLES="${STATS_TABLES:-public.users public.accounts public.roles}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DATE_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"

# --- Colors (suppressed when stdout is not a terminal or NO_COLOR is set) ----
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

# --- Logging -----------------------------------------------------------------
log_info() {
    printf '%s[INFO]%s %s - %s\n' "$BLUE" "$NC" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

log_success() {
    printf '%s[SUCCESS]%s %s - %s\n' "$GREEN" "$NC" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

log_warn() {
    printf '%s[WARN]%s %s - %s\n' "$YELLOW" "$NC" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >&2
}

log_error() {
    printf '%s[ERROR]%s %s - %s\n' "$RED" "$NC" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >&2
}

# --- Small helpers -----------------------------------------------------------

# Split backup-NNN-YYYYMMDD-HHMMSS without sed, so BSD and GNU behave alike.
backup_number_of() {  # $1 = folder basename
    local rest="${1#backup-}"
    local num="${rest%%-*}"
    case "$num" in ''|*[!0-9]*) return 1;; esac
    printf '%s\n' "$num"
}

backup_date_of() {    # $1 = folder basename -> YYYYMMDD
    local rest="${1#backup-}"
    rest="${rest#*-}"
    local d="${rest%%-*}"
    case "$d" in ''|*[!0-9]*) return 1;; esac
    printf '%s\n' "$d"
}

# Human-readable size of one file, or N/A when it is missing.
file_size() {
    [ -f "$1" ] || { printf 'N/A\n'; return 0; }
    du -h "$1" | cut -f1
}

# SHA-256 over the files named on stdin's argument list. macOS ships shasum,
# GNU coreutils ships sha256sum; neither is present on both.
sha256_write() {  # $1 = directory, rest = file names relative to it
    local dir="$1"; shift
    if command -v shasum >/dev/null 2>&1; then
        ( cd "$dir" && shasum -a 256 "$@" > SHA256SUMS )
    else
        ( cd "$dir" && sha256sum "$@" > SHA256SUMS )  # portability-ok: gnu-digests — shasum branch above runs on BSD
    fi
}

sha256_check() {  # $1 = directory holding SHA256SUMS
    local dir="$1"
    if command -v shasum >/dev/null 2>&1; then
        ( cd "$dir" && shasum -a 256 -c SHA256SUMS )
    else
        ( cd "$dir" && sha256sum -c SHA256SUMS )  # portability-ok: gnu-digests — shasum branch above runs on BSD
    fi
}

# --- Backup numbering --------------------------------------------------------

# Get next backup number
get_next_backup_number() {
    local max_num=0 dir num
    for dir in "$BACKUP_DIR"/backup-*; do
        if [ -d "$dir" ]; then
            # Extract number from backup-NNN-YYYYMMDD-HHMMSS
            num="$(backup_number_of "$(basename "$dir")")" || continue
            # 10# forces base 10: 008 is eight, not an octal error.
            if [ "$((10#$num))" -gt "$max_num" ]; then
                max_num="$((10#$num))"
            fi
        fi
    done
    echo "$((max_num + 1))"
}

# Format backup number with leading zeros
format_backup_number() {
    printf "%03d" "$1"
}

# Newest backup directory, or empty when there is none.
latest_backup_dir() {
    local dir best="" best_num=0 num
    for dir in "$BACKUP_DIR"/backup-*; do
        [ -d "$dir" ] || continue
        num="$(backup_number_of "$(basename "$dir")")" || continue
        if [ "$((10#$num))" -ge "$best_num" ]; then
            best_num="$((10#$num))"
            best="$dir"
        fi
    done
    printf '%s\n' "$best"
}

# Directory for a given backup number, or empty.
backup_dir_for_number() {  # $1 = number, with or without leading zeros
    local want="$1" dir num
    case "$want" in ''|*[!0-9]*) return 1;; esac
    for dir in "$BACKUP_DIR"/backup-*; do
        [ -d "$dir" ] || continue
        num="$(backup_number_of "$(basename "$dir")")" || continue
        if [ "$((10#$num))" -eq "$((10#$want))" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
    done
    return 1
}

# --- Create backup -----------------------------------------------------------
create_backup() {
    log_info "Starting database backup..."

    mkdir -p "$BACKUP_DIR"

    # Get next backup number
    local backup_num backup_num_formatted backup_folder backup_path
    backup_num="$(get_next_backup_number)"
    backup_num_formatted="$(format_backup_number "$backup_num")"
    backup_folder="backup-${backup_num_formatted}-${TIMESTAMP}"
    backup_path="${BACKUP_DIR}/${backup_folder}"

    log_info "Creating backup #${backup_num}: ${backup_folder}"

    # Create backup directory
    mkdir -p "$backup_path"

    # Check database connectivity
    log_info "Checking database connectivity..."
    if ! "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "SELECT 1" > /dev/null 2>&1; then
        log_error "Cannot connect to database. Check credentials and database status."
        rmdir "$backup_path" 2>/dev/null || true
        exit 1
    fi

    # Get table counts for verification
    log_info "Getting database statistics..."
    local stats_rows="" verify_sql="" tbl count keyword="SELECT"
    for tbl in $STATS_TABLES; do
        count="$("$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
                    -t -A -c "SELECT COUNT(*) FROM ${tbl}" 2>/dev/null || true)"
        [ -n "$count" ] || count="N/A"
        stats_rows="${stats_rows}| ${tbl} | ${count} |
"
        # First line is a plain SELECT, the rest are UNION ALL SELECT.
        verify_sql="${verify_sql}${keyword} '${tbl}' AS table_name, COUNT(*) FROM ${tbl}
"
        keyword="UNION ALL SELECT"
        log_info "  ${tbl}: ${count}"
    done
    verify_sql="${verify_sql%?};"

    # Create binary dump (faster restore, selective restore possible)
    log_info "Creating binary dump (.dump)..."
    local dump_file="${backup_path}/${DB_NAME}.dump"
    if "$PG_DUMP" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc -f "$dump_file" "$DB_NAME"; then
        local dump_size
        dump_size="$(file_size "$dump_file")"
        log_success "Binary dump created: ${dump_size}"
    else
        log_error "Failed to create binary dump"
        exit 1
    fi

    # Create SQL dump (human-readable, greppable, diffable)
    local sql_file="${backup_path}/${DB_NAME}.sql"
    local sql_size="skipped"
    if [ "$BACKUP_SQL" != "0" ]; then
        log_info "Creating SQL dump (.sql)..."
        if "$PG_DUMP" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -f "$sql_file" "$DB_NAME"; then
            sql_size="$(file_size "$sql_file")"
            log_success "SQL dump created: ${sql_size}"
        else
            log_error "Failed to create SQL dump"
            exit 1
        fi
    fi

    # Checksum manifest, so a silent corruption is detectable later
    if [ "$BACKUP_CHECKSUMS" != "0" ]; then
        log_info "Writing checksum manifest..."
        if [ -f "$sql_file" ]; then
            sha256_write "$backup_path" "${DB_NAME}.dump" "${DB_NAME}.sql"
        else
            sha256_write "$backup_path" "${DB_NAME}.dump"
        fi
    fi

    # Create README for this backup
    cat > "${backup_path}/README.md" << EOF
# Database Backup #${backup_num}

## Backup Details
| Property | Value |
|----------|-------|
| **Backup Number** | ${backup_num} |
| **Created** | ${DATE_HUMAN} |
| **Database** | ${DB_NAME} |
| **Host** | ${DB_HOST}:${DB_PORT} |
| **Role** | ${DB_USER} |

## Database Statistics
| Table | Count |
|-------|-------|
${stats_rows}
## Files
| File | Description | Size |
|------|-------------|------|
| ${DB_NAME}.dump | Binary pg_dump format (fast, selective restore) | ${dump_size} |
| ${DB_NAME}.sql | Plain SQL format (human-readable) | ${sql_size} |
| SHA256SUMS | Checksum manifest for the files above | - |

## Recovery Commands

Restore into a NEW database first and check it before touching the live one.

### Quick Restore (Binary)
\`\`\`bash
createdb -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} ${DB_NAME}_restore
pg_restore -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}_restore \\
  --no-owner --no-privileges ${DB_NAME}.dump
\`\`\`

### SQL Restore
\`\`\`bash
createdb -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} ${DB_NAME}_restore
psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}_restore < ${DB_NAME}.sql
\`\`\`

### Restore Over the Existing Database (destructive)
\`\`\`bash
# Only after the check above succeeded, and only with a fresh backup in hand.
dropdb -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} ${DB_NAME}
createdb -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} ${DB_NAME}
pg_restore -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} \\
  --no-owner --no-privileges ${DB_NAME}.dump
\`\`\`

## Verification
After restore, verify with:
\`\`\`bash
psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}_restore -c "
${verify_sql}
"
\`\`\`

Checksums:
\`\`\`bash
shasum -a 256 -c SHA256SUMS
\`\`\`

---
Automated backup created by backup.sh
EOF

    log_success "Backup #${backup_num} completed successfully"
    log_info "Location: ${backup_path}"

    # Run cleanup after a successful backup
    cleanup_old_backups
}

# --- Cleanup old backups -----------------------------------------------------
cleanup_old_backups() {
    if [ "$RETENTION_DAYS" = "0" ]; then
        log_info "Retention disabled (RETENTION_DAYS=0); keeping every backup"
        return 0
    fi

    log_info "Checking for backups older than ${RETENTION_DAYS} days..."

    local deleted_count=0 cutoff_date dir backup_date
    # BSD date takes -v, GNU date takes -d. Try BSD first, fall back to GNU.
    cutoff_date="$(date -v-"${RETENTION_DAYS}"d +%Y%m%d 2>/dev/null ||
        date -d "${RETENTION_DAYS} days ago" +%Y%m%d)"  # portability-ok: date-flags — BSD -v above runs first

    for dir in "$BACKUP_DIR"/backup-*; do
        if [ -d "$dir" ]; then
            # Extract date from backup-NNN-YYYYMMDD-HHMMSS
            backup_date="$(backup_date_of "$(basename "$dir")")" || continue

            # Both sides are YYYYMMDD, so a numeric comparison is a date comparison.
            if [ "$backup_date" -lt "$cutoff_date" ]; then
                log_warn "Deleting old backup: $(basename "$dir")"
                rm -rf "$dir"
                deleted_count="$((deleted_count + 1))"
            fi
        fi
    done

    if [ "$deleted_count" -gt 0 ]; then
        log_success "Cleaned up ${deleted_count} old backup(s)"
    else
        log_info "No old backups to clean up"
    fi
}

# --- List all backups --------------------------------------------------------
list_backups() {
    echo ""
    echo "=== Database Backups (${DB_NAME}) ==="
    echo ""
    printf "%-8s %-25s %-12s %-12s\n" "NUMBER" "FOLDER" "DUMP SIZE" "SQL SIZE"
    printf "%-8s %-25s %-12s %-12s\n" "------" "-------------------------" "----------" "----------"

    local dir folder num dump_size sql_size backup_count=0
    for dir in "$BACKUP_DIR"/backup-*; do
        if [ -d "$dir" ]; then
            folder="$(basename "$dir")"
            num="$(backup_number_of "$folder")" || continue

            dump_size="$(file_size "$dir/${DB_NAME}.dump")"
            sql_size="$(file_size "$dir/${DB_NAME}.sql")"

            printf "%-8s %-25s %-12s %-12s\n" "$num" "$folder" "$dump_size" "$sql_size"
            backup_count="$((backup_count + 1))"
        fi
    done

    echo ""

    # Show total count and disk usage
    local total_size="N/A"
    if [ -d "$BACKUP_DIR" ]; then
        total_size="$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
    fi

    echo "Total backups: ${backup_count}"
    echo "Total size: ${total_size}"
    echo "Retention: ${RETENTION_DAYS} days"
    echo "Location: ${BACKUP_DIR}"
    echo ""
}

# --- Verify a backup ---------------------------------------------------------
verify_backup() {  # $1 = optional backup number
    local dir
    if [ -n "${1:-}" ]; then
        dir="$(backup_dir_for_number "$1")" || {
            log_error "No backup numbered $1 under ${BACKUP_DIR}"
            exit 1
        }
    else
        dir="$(latest_backup_dir)"
    fi

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        log_error "No backups found under ${BACKUP_DIR}"
        exit 1
    fi

    log_info "Verifying $(basename "$dir")"

    local dump_file="${dir}/${DB_NAME}.dump"
    if [ ! -f "$dump_file" ]; then
        log_error "Binary dump missing: ${dump_file}"
        exit 1
    fi

    if [ ! -s "$dump_file" ]; then
        log_error "Binary dump is empty: ${dump_file}"
        exit 1
    fi

    # pg_restore --list parses the archive's table of contents without writing
    # anything. A corrupt or truncated archive fails here.
    local objects
    if ! objects="$("$PG_RESTORE" --list "$dump_file" 2>/dev/null | grep -c ';' )"; then
        log_error "pg_restore could not read the archive: ${dump_file}"
        exit 1
    fi
    log_success "Archive readable, ${objects} table-of-contents entries"

    if [ -f "${dir}/SHA256SUMS" ]; then
        log_info "Checking checksums..."
        if sha256_check "$dir" > /dev/null 2>&1; then
            log_success "Checksums match"
        else
            log_error "Checksum mismatch in $(basename "$dir")"
            exit 1
        fi
    else
        log_warn "No SHA256SUMS manifest in $(basename "$dir")"
    fi

    log_success "Backup $(basename "$dir") verified"
}

# --- Help --------------------------------------------------------------------
show_help() {
    echo ""
    echo "Database Backup Script"
    echo "======================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no option)     Create a new backup, then run cleanup"
    echo "  --cleanup       Run cleanup only (remove backups older than ${RETENTION_DAYS} days)"
    echo "  --list          List all backups"
    echo "  --verify [N]    Verify backup N, or the newest backup"
    echo "  --help          Show this help message"
    echo ""
    echo "Configuration (environment variables):"
    echo "  DB_NAME           Database name            (current: ${DB_NAME})"
    echo "  DB_HOST           Database host            (current: ${DB_HOST})"
    echo "  DB_PORT           Database port            (current: ${DB_PORT})"
    echo "  DB_USER           Database role            (current: ${DB_USER})"
    echo "  BACKUP_DIR        Backup root directory    (current: ${BACKUP_DIR})"
    echo "  RETENTION_DAYS    Days to keep, 0 = keep all (current: ${RETENTION_DAYS})"
    echo "  BACKUP_SQL        1 to also write a .sql dump (current: ${BACKUP_SQL})"
    echo "  BACKUP_CHECKSUMS  1 to write SHA256SUMS      (current: ${BACKUP_CHECKSUMS})"
    echo "  STATS_TABLES      Tables counted per backup  (current: ${STATS_TABLES})"
    echo ""
    echo "Passwords are never read from this script. Use PGPASSWORD in the"
    echo "environment, a ~/.pgpass file with mode 600, or a PGSERVICE entry."
    echo ""
    echo "Cron Setup (every 12 hours):"
    echo "  0 0,12 * * * BACKUP_DIR=${BACKUP_DIR} $0 >> /var/log/db-backup.log 2>&1"
    echo ""
}

# --- Main --------------------------------------------------------------------
main() {
    case "${1:-}" in
        --cleanup)
            cleanup_old_backups
            ;;
        --list)
            list_backups
            ;;
        --verify)
            verify_backup "${2:-}"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            create_backup
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
}

main "$@"
