#!/usr/bin/env bash
set -uo pipefail
# The bound is the subject here, so it is exercised directly rather than through a
# two-minute suite run.
sed -n '/^run_bounded()/,/^}/p' "$PIPELINE_ROOT/bin/acp" > "$EVAL_TMP/run_bounded.sh"
[ -s "$EVAL_TMP/run_bounded.sh" ] || { echo "could not find run_bounded in bin/acp"; exit 1; }
. "$EVAL_TMP/run_bounded.sh"

# a command that returns is passed through untouched, status and all
run_bounded 20 true || { echo "a successful command was not reported as successful"; exit 1; }
rc=0; run_bounded 20 false || rc=$?
[ "$rc" -eq 1 ] || { echo "a failing command reported $rc rather than its own status"; exit 1; }

# a command that does not return is killed, and says so distinctly
t0=$SECONDS; rc=0; run_bounded 2 sleep 30 || rc=$?
[ "$rc" -eq 124 ] || { echo "a hanging command reported $rc rather than a timeout"; exit 1; }
[ $((SECONDS - t0)) -lt 15 ] || { echo "the bound did not stop a hanging command promptly"; exit 1; }

# everything the command started goes with it; a bound that returns while the work
# continues has not bounded anything
marker="$EVAL_TMP/descendant-ran"; rm -f "$marker"
printf '#!/usr/bin/env bash\nbash -c "sleep 4; touch %s" &\nsleep 30\n' "$marker" > "$EVAL_TMP/parent.sh"
chmod +x "$EVAL_TMP/parent.sh"
rc=0; run_bounded 1 "$EVAL_TMP/parent.sh" || rc=$?
[ "$rc" -eq 124 ] || { echo "the descendant probe did not time out (exit $rc)"; exit 1; }
sleep 6
[ -f "$marker" ] && { echo "a descendant outlived the bound and kept running after it returned"; exit 1; }

# a bound that is not a number of seconds is refused, and nothing is started: quietly
# substituting a default would run a long command under a bound nobody asked for
ran="$EVAL_TMP/should-not-run"
for bad in invalid "" 0 -5 3x; do
  rm -f "$ran"; t0=$SECONDS; rc=0
  run_bounded "$bad" bash -c "touch '$ran'; sleep 30" 2>/dev/null || rc=$?
  [ "$rc" -eq 2 ] || { echo "bound [$bad] returned $rc; an unusable bound must be refused"; exit 1; }
  [ $((SECONDS - t0)) -lt 5 ] || { echo "bound [$bad] did not return promptly"; exit 1; }
  [ -f "$ran" ] && { echo "bound [$bad] started the command anyway"; exit 1; }
done

# the driver rejects a malformed bound out loud rather than acting on it. This is
# checked directly: an evaluation that ran the suite would be running itself.
sed -n '/^bound_seconds()/,/^}/p' "$PIPELINE_ROOT/bin/acp" > "$EVAL_TMP/bound_seconds.sh"
[ -s "$EVAL_TMP/bound_seconds.sh" ] || { echo "could not find bound_seconds in bin/acp"; exit 1; }
. "$EVAL_TMP/bound_seconds.sh"
[ "$(bound_seconds 30 ACP_PLUGIN_TIMEOUT | tail -1)" = 30 ] || { echo "a good value was not passed through"; exit 1; }
for bad in abc "" 0 -5 3x; do
  out="$(bound_seconds "$bad" ACP_PLUGIN_TIMEOUT)"
  [ "$(printf '%s' "$out" | tail -1)" = 120 ] || { echo "[$bad] did not fall back to the default"; exit 1; }
  case "$out" in *"not a positive number"*) ;; *) echo "[$bad] was replaced silently; a rejected setting has to be said out loud"; exit 1;; esac
done
exit 0
