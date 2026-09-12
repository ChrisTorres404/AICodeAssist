#!/usr/bin/env bash
# security-check.sh — local pre-commit security sweep for {{PROJECT_NAME}}.
#
# Detects the stack from what is in the directory and runs what applies:
#   dependency audit   npm audit | pip-audit | cargo audit | govulncheck
#   secrets            the pipeline's sanitizer (bin/sanitize) over the tree
#   committed .env     any .env that is not an example file
#   type safety        tsc --noEmit when a tsconfig.json is present
# Exit 1 on errors; warnings are printed but do not fail.
set -uo pipefail
ROOT="${1:-.}"; cd "$ROOT"
PIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ERRORS=0; WARNINGS=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; }
warn() { echo -e "${YELLOW}WARN${NC}: $1"; WARNINGS=$((WARNINGS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; ERRORS=$((ERRORS+1)); }
echo "== {{PROJECT_NAME}} security check ($ROOT)"

echo "1. dependency audit"
ran=0
if [ -f package.json ] && command -v npm >/dev/null; then ran=1; npm audit --audit-level=high >/dev/null 2>&1 && pass "npm audit: no high or critical advisories" || warn "npm audit reported advisories (run: npm audit)"; fi
if { [ -f requirements.txt ] || [ -f pyproject.toml ]; } && command -v pip-audit >/dev/null; then ran=1; pip-audit -q >/dev/null 2>&1 && pass "pip-audit clean" || warn "pip-audit reported advisories"; fi
if [ -f Cargo.toml ] && command -v cargo-audit >/dev/null; then ran=1; cargo audit -q >/dev/null 2>&1 && pass "cargo audit clean" || warn "cargo audit reported advisories"; fi
if [ -f go.mod ] && command -v govulncheck >/dev/null; then ran=1; govulncheck ./... >/dev/null 2>&1 && pass "govulncheck clean" || warn "govulncheck reported vulnerabilities"; fi
[ "$ran" -eq 1 ] || warn "no dependency auditor found for this stack (install npm/pip-audit/cargo-audit/govulncheck)"

echo "2. secrets and personal data"
if [ -x "$PIPE/bin/sanitize" ]; then
  rc=0; "$PIPE/bin/sanitize" . --quiet >/dev/null 2>&1 || rc=$?
  case "$rc" in 0) pass "sanitizer clean";; 1) warn "sanitizer warnings (run: $PIPE/bin/sanitize .)";; *) fail "sanitizer found critical findings (run: $PIPE/bin/sanitize .)";; esac
else warn "sanitizer not found at $PIPE/bin/sanitize"; fi

echo "3. environment files"
envs="$(find . -name '.env' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null)"
if [ -n "$envs" ]; then
  tracked="$(git ls-files --error-unmatch $envs 2>/dev/null || true)"
  [ -z "$tracked" ] && pass ".env files present but not tracked by git" || fail ".env tracked by git: $tracked"
else pass "no .env files in the tree"; fi

echo "4. type safety"
if [ -f tsconfig.json ]; then
  if [ -x node_modules/.bin/tsc ]; then node_modules/.bin/tsc --noEmit >/dev/null 2>&1 && pass "TypeScript compiles" || fail "TypeScript errors (run: npx tsc --noEmit)"; else warn "tsconfig.json present but tsc not installed"; fi
else echo "  (no tsconfig.json; skipped)"; fi

echo "== summary: $ERRORS error(s), $WARNINGS warning(s)"
[ "$ERRORS" -eq 0 ]
