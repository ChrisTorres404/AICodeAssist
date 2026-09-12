#!/usr/bin/env bash
# run-hook.sh <hook-id> <profiles-csv> <command...>
#
# Every hook in settings.hooks.json is wrapped by this so it can be switched
# without editing JSON:
#
#   ACP_HOOKS_ENABLED=false            master switch
#   ACP_HOOK_PROFILE=minimal|standard|strict   (default: standard)
#   ACP_DISABLED_HOOKS=acp:post:quality-gate,acp:pre:wo-reference
#
# A hook runs only when its profile list contains the active profile. stdin is
# passed through to the command untouched.
set -uo pipefail
id="${1:?hook id}"; profiles="${2:?profiles}"; shift 2
case "$(printf '%s' "${ACP_HOOKS_ENABLED:-true}" | tr '[:upper:]' '[:lower:]')" in
  0|false|no|off) cat >/dev/null; exit 0;;
esac
profile="$(printf '%s' "${ACP_HOOK_PROFILE:-standard}" | tr '[:upper:]' '[:lower:]')"
case "$profile" in minimal|standard|strict) ;; *) profile=standard;; esac
case ",$profiles," in *",$profile,"*) ;; *) cat >/dev/null; exit 0;; esac
case ",$(printf '%s' "${ACP_DISABLED_HOOKS:-}" | tr -d ' ')," in *",$id,"*) cat >/dev/null; exit 0;; esac
[ "$profile" = "strict" ] && export ACP_STRICT=1
exec "$@"
