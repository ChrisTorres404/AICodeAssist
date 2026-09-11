#!/bin/bash
# WO-1301: Local Security Check Script
# Run this before committing to catch security issues early

set -e

echo "=============================================="
echo "    {{PROJECT_NAME}} Security Check"
echo "=============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# 1. npm audit
echo "1. Running npm audit..."
if npm audit --audit-level=high 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}: No high/critical vulnerabilities found"
else
    echo -e "${YELLOW}WARNING${NC}: npm audit found vulnerabilities"
    ((WARNINGS++))
fi
echo ""

# 2. Check for outdated packages
echo "2. Checking for outdated packages..."
OUTDATED=$(npm outdated --json 2>/dev/null | jq 'length')
if [ "$OUTDATED" = "0" ] || [ -z "$OUTDATED" ]; then
    echo -e "${GREEN}PASS${NC}: All packages are up to date"
else
    echo -e "${YELLOW}INFO${NC}: $OUTDATED packages have updates available"
fi
echo ""

# 3. License check
echo "3. Checking licenses..."
if npx license-checker --summary --failOn "GPL;AGPL;SSPL" 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}: No problematic licenses found"
else
    echo -e "${YELLOW}WARNING${NC}: Check license compliance manually"
    ((WARNINGS++))
fi
echo ""

# 4. Check for potential secrets in code
echo "4. Checking for potential secrets in code..."
SECRET_PATTERNS='(password|secret|api_key|apikey|access_token|private_key)\s*[:=]\s*["\x27][^"\x27]{8,}'
SECRETS_FOUND=$(grep -rn --include="*.ts" --include="*.js" --include="*.json" -iE "$SECRET_PATTERNS" . 2>/dev/null | grep -v node_modules | grep -v '.env.example' | grep -v 'package-lock.json' | wc -l)
if [ "$SECRETS_FOUND" -gt 0 ]; then
    echo -e "${YELLOW}WARNING${NC}: Found $SECRETS_FOUND potential hardcoded secrets"
    grep -rn --include="*.ts" --include="*.js" --include="*.json" -iE "$SECRET_PATTERNS" . 2>/dev/null | grep -v node_modules | grep -v '.env.example' | grep -v 'package-lock.json' | head -5
    ((WARNINGS++))
else
    echo -e "${GREEN}PASS${NC}: No obvious hardcoded secrets found"
fi
echo ""

# 5. Check for .env files that shouldn't be committed
echo "5. Checking for .env files..."
ENV_FILES=$(find . -name '.env' -not -name '.env.example' -not -path './node_modules/*' 2>/dev/null | wc -l)
if [ "$ENV_FILES" -gt 0 ]; then
    echo -e "${YELLOW}WARNING${NC}: Found .env files that may contain secrets"
    find . -name '.env' -not -name '.env.example' -not -path './node_modules/*' 2>/dev/null
    ((WARNINGS++))
else
    echo -e "${GREEN}PASS${NC}: No .env files found (good - use .env.example)"
fi
echo ""

# 6. Check TypeScript for type safety
echo "6. Checking TypeScript compilation..."
if npx tsc --noEmit 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}: TypeScript compiles without errors"
else
    echo -e "${RED}FAIL${NC}: TypeScript compilation errors found"
    ((ERRORS++))
fi
echo ""

# Summary
echo "=============================================="
echo "               Summary"
echo "=============================================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}ERRORS: $ERRORS${NC}"
fi
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}WARNINGS: $WARNINGS${NC}"
fi
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All security checks passed!${NC}"
fi
echo "=============================================="

exit $ERRORS