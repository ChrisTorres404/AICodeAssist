#!/usr/bin/env bash
# The manifest says both how central a suite is and what kind of test it is,
# and the two select independently. Older three-field lines still read.
set -uo pipefail
cd "$PIPELINE_ROOT" || { echo "no PIPELINE_ROOT"; exit 1; }

RUNNER=harness/runners/run-all-critical-tests.sh
REPORTER=harness/scripts/run-behavioral-tests.sh
fail() { echo "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2"; exit 1; }

# --- the shipped seed and the documentation teach the four-field form -------
grep -q 'tier|type|file|label' harness/config/suites.manifest \
  || fail "the manifest the installer renders still documents only tier|file|label"
grep -q 'tier|type|file|label' docs/harness.md \
  || fail "docs/harness.md still documents only tier|file|label"
grep -q -- '--type' docs/harness.md \
  || fail "docs/harness.md does not document --type"

# --- a manifest with both forms in it ---------------------------------------
W="$EVAL_TMP/ws"; mkdir -p "$W/suites"
cat > "$W/suites.manifest" <<'MANIFEST'
# a comment, and a blank line, are not suites

essential|unit|alpha.sh|Alpha unit
essential|browser|bravo.sh|Bravo browser
core|legacy.sh|Legacy three-field row
core|unit|charlie.sh|Charlie unit
security|static|delta.sh|Delta static
MANIFEST
for s in alpha bravo legacy charlie delta; do
  printf '#!/usr/bin/env bash\necho "ran %s"\nexit 0\n' "$s" > "$W/suites/$s.sh"
done

ran() { # <flags...> -> the labels that actually ran, one per line, sorted
  SUITES_DIR="$W/suites" bash "$RUNNER" --no-prep "$@" 2>&1 \
    | sed -n 's/.*PASS\(.*\)(.*/\1/p' | sed 's/[^A-Za-z ]//g' | tr -s ' ' | sed 's/^ *//;s/ *$//' | sort
}

got="$(ran --standard)"
for want in "Alpha unit" "Bravo browser" "Legacy threefield row" "Charlie unit"; do
  case "$got" in *"$want"*) ;; *) fail "a standard run did not include '$want'" "$got";; esac
done
case "$got" in *Delta*) fail "a standard run reached the security tier" "$got";; esac

# --- type narrows across tiers ---------------------------------------------
got="$(ran --standard --type unit)"
case "$got" in *"Alpha unit"*) ;; *) fail "--type unit missed an essential unit suite" "$got";; esac
case "$got" in *"Charlie unit"*) ;; *) fail "--type unit missed a core unit suite" "$got";; esac
case "$got" in *Bravo*) fail "--type unit ran a browser suite" "$got";; esac
case "$got" in *Legacy*) fail "--type unit selected a row that declares no type" "$got";; esac

# --- tier and type compose --------------------------------------------------
got="$(ran --standard --tier essential --type unit)"
case "$got" in *"Alpha unit"*) ;; *) fail "--tier essential --type unit ran nothing" "$got";; esac
case "$got" in *Charlie*) fail "--tier essential --type unit escaped its tier" "$got";; esac

# --- the three-field row keeps working, and keeps its label -----------------
got="$(ran --standard --tier core)"
case "$got" in *"Legacy threefield row"*) ;; *) fail "the older three-field line no longer runs" "$got";; esac

# --- the listing shows the type, and names unlisted files -------------------
printf '#!/usr/bin/env bash\nexit 0\n' > "$W/suites/orphan.sh"
list="$(SUITES_DIR="$W/suites" bash "$RUNNER" --list 2>&1)"
case "$list" in *"[unit]"*) ;; *) fail "--list does not show the type" "$list";; esac
case "$list" in *untyped*) ;; *) fail "--list does not mark a row that declares no type" "$list";; esac
case "$list" in *orphan.sh*) ;; *) fail "--list does not surface a suite file no manifest row names" "$list";; esac

# --- the report script speaks the same flags --------------------------------
# Two runners over one manifest must not have two vocabularies for one idea.
for flag in --quick --standard --full --type; do
  grep -q -- "$flag)" "$REPORTER" || fail "$REPORTER does not accept $flag"
done
out="$(SUITES_DIR="$W/suites" TEST_RESULTS_DIR="$W/out" bash "$REPORTER" --quick --type unit 2>&1)"
case "$out" in *"Alpha unit"*) ;; *) fail "the report script ignored --quick --type unit" "$out";; esac
case "$out" in *Bravo*) fail "the report script ran a browser suite under --type unit" "$out";; esac

exit 0
