#!/usr/bin/env bash
# ============================================================================
# Shared path resolution for every harness runner and script
# ============================================================================
# Sourced, never executed. It answers three questions once, in one place:
#
#   SUITES_DIR        where the project's behavioural suites live
#   SUITES_MANIFEST   which manifest lists them
#   TEST_RESULTS_DIR  where anything a run produces is written
#
# Why one file rather than a copy of the same resolution in each script: the
# results directory is the one the installer creates ({{TESTING_DIR}}/results)
# and the one the drivers exclude from the source fingerprint. A script that
# invents its own path writes evidence into the fingerprinted tree, and every
# recorded PASS goes stale the moment it does. Resolution lives here so that
# cannot drift apart again.
#
# Every value is an override-friendly default: exporting SUITES_DIR,
# SUITES_MANIFEST or TEST_RESULTS_DIR in the shell or in CI wins.
# ============================================================================

_harness_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
HARNESS_ROOT="$(cd "$_harness_lib_dir/.." && pwd)"
unset _harness_lib_dir

# --- suites ----------------------------------------------------------------
# The harness sits under the pipeline root; the suites belong to the project
# beside it. Both nesting depths are tried before falling back to a suites
# directory inside the harness itself.
if [ -z "${SUITES_DIR:-}" ]; then
  for _harness_candidate in \
      "$HARNESS_ROOT/../../{{TESTING_DIR}}/suites" \
      "$HARNESS_ROOT/../{{TESTING_DIR}}/suites" \
      "$HARNESS_ROOT/suites"; do
    [ -d "$_harness_candidate" ] && { SUITES_DIR="$_harness_candidate"; break; }
  done
  SUITES_DIR="${SUITES_DIR:-$HARNESS_ROOT/suites}"
  unset _harness_candidate
fi

# --- manifest --------------------------------------------------------------
# The project-owned manifest beside the suites wins over the shipped seed: the
# installer copies the seed once and never overwrites it again.
if [ -z "${SUITES_MANIFEST:-}" ]; then
  if [ -f "$SUITES_DIR/../suites.manifest" ]; then
    SUITES_MANIFEST="$SUITES_DIR/../suites.manifest"
  else
    SUITES_MANIFEST="$HARNESS_ROOT/config/suites.manifest"
  fi
fi

# --- results ---------------------------------------------------------------
# Beside the suites, never inside them: the installer creates this directory
# and the drivers exclude it from the fingerprint, so writing a report here
# does not invalidate the evidence the report is about.
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-$(dirname "$SUITES_DIR")/results}"

export SUITES_DIR SUITES_MANIFEST TEST_RESULTS_DIR HARNESS_ROOT

# ============================================================================
# Manifest lines
# ============================================================================
# Format:  tier|type|file|label
#
#   tier   how central the suite is       essential, core, extended, security,
#                                         integration, performance,
#                                         infrastructure, recent
#   type   what kind of test it is        free-form; conventionally unit, e2e,
#                                         static, backend, ui, browser, api
#   file   path relative to SUITES_DIR
#   label  human name, optional
#
# The older three-field form `tier|file|label` still reads, with an empty type.
# bash 3.2 has no namerefs, so the fields come back in globals.
#
#   parse_manifest_line "$line" || continue   # false for blanks and comments
#   ... "$MF_TIER" "$MF_TYPE" "$MF_FILE" "$MF_LABEL"
# ============================================================================
parse_manifest_line() {
  local line="${1:-}" a b c d
  MF_TIER=""; MF_TYPE=""; MF_FILE=""; MF_LABEL=""

  case "$line" in ''|\#*|[[:space:]]*\#*) return 1;; esac

  IFS='|' read -r a b c d <<< "$line"

  # Three pipes means all four fields are present. With two, the second field
  # decides: a suite file names itself (*.sh), anything else is a type whose
  # label was left off.
  case "$line" in
    *'|'*'|'*'|'*) MF_TIER="$a"; MF_TYPE="$b"; MF_FILE="$c"; MF_LABEL="$d";;
    *)
      case "$b" in
        *.sh) MF_TIER="$a"; MF_TYPE="";   MF_FILE="$b"; MF_LABEL="$c";;
        *)    MF_TIER="$a"; MF_TYPE="$b"; MF_FILE="$c"; MF_LABEL="";;
      esac
      ;;
  esac

  MF_TIER="$(printf '%s' "$MF_TIER" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  MF_TYPE="$(printf '%s' "$MF_TYPE" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  [ -n "$MF_TIER" ] || return 1
  [ -n "$MF_FILE" ] || return 1
  MF_LABEL="${MF_LABEL:-$MF_FILE}"
  return 0
}

# ============================================================================
# Unlisted suite files
# ============================================================================
# The suite files on disk that no manifest row names. They never run in a
# regression, and an unlisted suite is the commonest way for a check to be
# written once and then quietly stop being evidence for anything. Every runner
# asks the same question, so it is answered once here.
#
#   unlisted_suite_files [<manifest>]   # one relative path per line
#
# Files whose name begins with _ and anything named like a helper are skipped:
# they are libraries a suite sources, not suites.
# Note: this uses parse_manifest_line, so MF_* hold the last line parsed when
# it returns.
unlisted_suite_files() {
  local manifest="${1:-$SUITES_MANIFEST}"
  [ -d "$SUITES_DIR" ] || return 0
  local path rel listed line
  for path in "$SUITES_DIR"/*.sh "$SUITES_DIR"/*/*.sh; do
    [ -f "$path" ] || continue
    rel="${path#"$SUITES_DIR"/}"
    case "$rel" in _*|*/_*|*helpers*) continue;; esac
    listed=false
    if [ -f "$manifest" ]; then
      while IFS= read -r line || [ -n "$line" ]; do
        parse_manifest_line "$line" || continue
        [ "$MF_FILE" = "$rel" ] && { listed=true; break; }
      done < "$manifest"
    fi
    [ "$listed" = false ] && echo "$rel"
  done
  return 0
}
