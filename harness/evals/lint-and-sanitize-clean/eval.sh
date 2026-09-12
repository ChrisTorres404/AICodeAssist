#!/usr/bin/env bash
set -uo pipefail
cd "$PIPELINE_ROOT"; bin/lint | grep -q "^0 error(s)" || { bin/lint | tail -3; exit 1; }
for d in core bin docs packs harness; do bin/sanitize "$d" --quiet; rc=$?; [ "$rc" -lt 2 ] || { echo "sanitize FAIL in $d"; bin/sanitize "$d" | grep -A5 "^## Critical"; exit 1; }; done
