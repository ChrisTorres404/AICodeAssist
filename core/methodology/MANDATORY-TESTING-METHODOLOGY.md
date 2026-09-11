# MANDATORY Behavioral Testing Methodology

> **THIS IS NON-NEGOTIABLE. ALL AI AGENTS MUST FOLLOW THIS METHODOLOGY.**

---

## Core Rule

**Every test suite MUST verify real system behavior through actual execution — NOT mocked responses.**

Jest unit tests are for isolated logic only. Behavioral tests verify production behavior.

---

## What is Behavioral Testing?

**Behavioral Testing** validates software through **real execution** against a **live system** (API + database), capturing **actual evidence**.

### The Absolute Honesty Clause

Tests are ONLY valid with one of these statuses:

| Status | Meaning | Evidence Required |
|--------|---------|-------------------|
| `EXECUTED — PASS` | Test ran, behavior verified | Actual HTTP response + SQL output |
| `EXECUTED — FAIL` | Test ran, behavior incorrect | Error details captured |
| `NOT EXECUTED — PLAN ONLY` | Test not yet run | None (placeholder) |

**NEVER mark PASS without real evidence. This is intellectual dishonesty.**

---

## Core Principles

1. **Real Execution Only**
   - No mocked responses
   - No simulated database states
   - No "should work" assumptions

2. **Evidence-Based Verification**
   - Every test requires proof
   - HTTP request + response captured
   - SQL query + output captured

3. **Human-Executable**
   - All commands copy/pasteable
   - Runs on any machine with `curl` + `psql`
   - No complex test framework setup

4. **Transparent Results**
   - Anyone can see EXACTLY what happened
   - Actual outputs in the documentation
   - Debugging by copy/paste

---

## Test Suite Structure

```
{{TESTING_DIR}}/
├── MANDATORY-TESTING-METHODOLOGY.md   # This file (REQUIRED READING)
├── _TEMPLATES/                         # Test templates
│   ├── README.md                       # Template usage guide
│   ├── TEST-TEMPLATE-HARNESS.md        # Test harness template
│   ├── TEST-TEMPLATE-EXECUTION.md      # Execution results template
│   └── TEST-TEMPLATE-VERIFICATION.md   # Verification report template
├── suites/                             # Test suite scripts
│   ├── wo-XXXX-feature-name.sh         # Shell script test suites
│   └── comprehensive/                  # Domain-specific test suites
├── scripts/                            # Test execution helpers
│   ├── test-runner.sh                  # Main test runner
│   └── test-helpers.sh                 # Common helper functions
├── test-results/                       # Execution results archive
│   └── behavioral-test-report_*.md     # Timestamped reports
└── lib/                                # Shared libraries
    └── verbose-test-framework.sh       # Framework functions
```

---

## Templates Location

All templates are in:
```
{{PIPELINE_ROOT}}/core/templates/testing/
├── README.md                           # Template usage guide
├── TEST-TEMPLATE-HARNESS.md            # Test harness template
├── TEST-TEMPLATE-EXECUTION.md          # Execution results template
└── TEST-TEMPLATE-VERIFICATION.md       # Verification report template
```

---

## Test Suite Naming Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `wo-XXXX-feature-name.sh` | Work order specific tests | `wo-0102-login-critical-path.sh` |
| `wo-XXXX-*-critical-path.sh` | Critical path tests | `wo-0310-websocket-critical-path.sh` |
| `category-tests.sh` | Domain tests | `auth-login-tests.sh` |

---

## Test Status Tracking

### In Shell Scripts

```bash
test_pass() {
    echo -e "${GREEN}├─ RESULT: $1${NC}"
    echo -e "${GREEN}└─ STATUS: EXECUTED — PASS${NC}"
    PASSED=$((PASSED + 1))
}

test_fail() {
    echo -e "${RED}├─ RESULT: $1${NC}"
    echo -e "${RED}└─ STATUS: EXECUTED — FAIL${NC}"
    FAILED=$((FAILED + 1))
}

test_skip() {
    echo -e "${YELLOW}├─ RESULT: $1${NC}"
    echo -e "${YELLOW}└─ STATUS: NOT EXECUTED — SKIP${NC}"
    SKIPPED=$((SKIPPED + 1))
}
```

### In Documentation

```markdown
| Test ID | Description | Status | Evidence |
|---------|-------------|--------|----------|
| 1.1 | Login returns 200 | EXECUTED — PASS | HTTP 200, session cookie set |
| 1.2 | Invalid password rejected | EXECUTED — PASS | HTTP 401 |
| 1.3 | MFA challenge flow | NOT EXECUTED | - |
```

---

## When to Use Jest vs Behavioral Tests

### Jest Unit Tests (Pure Logic)

Use Jest for testing **isolated logic** with no external dependencies:

- Pure functions (math, string manipulation, parsing)
- Guards and pipes (input validation)
- Service method logic (with mocked repositories)
- Type transformations (DTOs, mappers)
- Utility functions

**Example:**
```typescript
describe('WsJwtGuard', () => {
  it('should convert string payload to integer IDs', () => {
    const payload = { sub: '123', tenantId: '456' };
    expect(Number(payload.sub)).toBe(123);
  });
});
```

### Behavioral Tests (System Behavior)

Use Behavioral Testing for **production verification**:

- API endpoint responses (HTTP status, response body)
- Database state changes (INSERT, UPDATE, DELETE)
- Authentication flows (login, logout, session)
- Multi-step workflows (MFA, password reset)
- Integration between services

**Example:**
```bash
# Test login endpoint returns 200 with valid credentials
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "Password123!"}'
# Expected: HTTP 200, JSON body with access_token
```

---

## Test Harness Format

Every behavioral test follows this structure:

```markdown
### Test X.Y: [Name]

**Goal:** [What this test verifies]

**Status:** NOT EXECUTED — PLAN ONLY

**HTTP Request:**
\`\`\`bash
curl -X POST http://localhost:3001/api/v1/endpoint \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
\`\`\`

**Expected Response:**
\`\`\`json
{
  "result": "expected value"
}
\`\`\`

**SQL Verification:**
\`\`\`sql
SELECT column FROM table WHERE condition;
\`\`\`

**Execution Evidence:**
\`\`\`
[PASTE REAL OUTPUT HERE]
\`\`\`

**Result:** [EXECUTED — PASS / EXECUTED — FAIL / NOT EXECUTED]
```

---

## Test Execution Process

### Phase 1: Preparation

1. Ensure API server running: `http://localhost:3001`
2. Ensure database accessible: `psql -d {{PROJECT_NAME}}Dev`
3. Create test user if needed
4. Clear previous test state

### Phase 2: Execute Tests

```bash
# Run a specific test suite
./{{TESTING_DIR}}/suites/wo-0102-login-critical-path.sh

# Or run all tests
./{{TESTING_DIR}}/test-runner.sh
```

### Phase 3: Capture Evidence

For each test:
1. Copy the curl command
2. Execute and capture response
3. Execute SQL verification if applicable
4. Update status: EXECUTED — PASS or EXECUTED — FAIL
5. Paste actual output as evidence

### Phase 4: Document Results

Create execution report in `test-results/`:
```
behavioral-test-report_YYYYMMDD_HHMMSS.md
```

---

## Shell Script Test Template

```bash
#!/bin/bash
# ============================================================================
# WO-XXXX: [Feature Name] - Behavioral Test Suite
# ============================================================================
# Tests: [Brief description of what's being tested]
# Prerequisites:
# - API server running at localhost:3001
# - Database accessible
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3001/api/v1}"
ORIGIN="http://localhost:3000"

# Counters
PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

# Helper functions
test_start() {
    TOTAL=$((TOTAL + 1))
    echo -e "${BLUE}TEST $TOTAL: $1${NC}"
}

test_pass() {
    echo -e "${GREEN}STATUS: EXECUTED — PASS${NC}"
    PASSED=$((PASSED + 1))
}

test_fail() {
    echo -e "${RED}STATUS: EXECUTED — FAIL: $1${NC}"
    FAILED=$((FAILED + 1))
}

test_skip() {
    echo -e "${YELLOW}STATUS: NOT EXECUTED — SKIP: $1${NC}"
    SKIPPED=$((SKIPPED + 1))
}

# ============================================================================
# TEST SUITE
# ============================================================================

echo "WO-XXXX: [Feature Name] - Behavioral Test Suite"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# Test 1
test_start "Description of test"
RESPONSE=$(curl -s -w "\n---HTTP_STATUS:%{http_code}---" -X GET "${BASE_URL}/endpoint")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_STATUS" | sed 's/.*HTTP_STATUS:\([0-9]*\).*/\1/')
if [ "$HTTP_CODE" = "200" ]; then
    test_pass
else
    test_fail "Expected 200, got $HTTP_CODE"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "SUMMARY"
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED | Skipped: $SKIPPED"

[ $FAILED -gt 0 ] && exit 1 || exit 0
```

---

## Gold Standard Examples

When in doubt, reference these properly structured test suites:

1. **wo-0102-login-critical-path.sh** - Authentication flow testing
2. **wo-0310-websocket-critical-path.sh** - WebSocket testing
3. **wo-0201-csrf-defense.sh** - Security testing
4. **wo-0301-fk-index-hardening.sh** - Database testing

---

## Validation Checklist

Before considering a test suite complete, verify:

### Structure
- [ ] Test suite file exists in `suites/` folder
- [ ] Follows naming convention: `wo-XXXX-feature-name.sh`
- [ ] Has proper header comments explaining purpose
- [ ] Uses standard helper functions

### Execution
- [ ] All tests have clear descriptions
- [ ] All tests capture HTTP status codes
- [ ] All tests have pass/fail/skip logic
- [ ] Summary shows total/passed/failed/skipped

### Evidence
- [ ] Tests marked PASS have actual execution evidence
- [ ] Tests marked FAIL have error details
- [ ] Tests marked SKIP have reason documented

---

## AI Agent Instructions

When asked to create or run behavioral tests:

1. **READ THIS FILE FIRST** - Understand the methodology
2. **USE TEMPLATES** - Use templates from `_TEMPLATES/`
3. **REAL EXECUTION** - Only mark PASS with real evidence
4. **HONEST STATUS** - Use correct status (EXECUTED vs NOT EXECUTED)
5. **CAPTURE EVIDENCE** - Paste actual curl/psql output
6. **NEVER HALLUCINATE** - Don't invent test results

### Creating a New Test Suite

```bash
# 1. Create the test file
touch {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
chmod +x {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh

# 2. Use the shell script template from this doc

# 3. Run and verify
./{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

### Documenting Test Results

```bash
# Create execution report
touch {{TESTING_DIR}}/test-results/wo-XXXX-execution-$(date +%Y%m%d).md

# Follow TEST-TEMPLATE-EXECUTION.md format
```

---

## Relationship to Work Orders

Every test suite should reference the Work Order it validates:

```
WO-0102 (Login Flow) → wo-0102-login-critical-path.sh
WO-0310 (WebSocket) → wo-0310-websocket-critical-path.sh
```

Test execution proves work order completion:
```
WO-XXXX-CLOSEOUT.md references → Test suite execution evidence
```

---

## Why Not Jest E2E?

| Issue | Jest E2E | Behavioral Testing |
|-------|----------|-------------------|
| Hidden failures | Tests pass with mocks | Tests require real responses |
| Opaque results | Can't see actual HTTP | Actual response in doc |
| Environment coupling | Requires test DB setup | Uses real database |
| Trust issues | "Passed" != production works | What you see is production |
| Debugging | Framework magic | Copy/paste curl |

---

## CRITICAL: Tests Passing ≠ Production-Ready

> **This is the most important lesson learned: Passing tests do NOT mean the code is production-ready.**

### The Anti-Pattern

```
1. Write code to make tests pass
2. Tests pass → "I'm done!"
3. Ship code with console.logs, magic numbers, dev fallbacks
4. User finds issues → rework required
```

### The Correct Pattern

```
1. Write production-quality code from the start
2. Tests pass → "Now let me review the implementation"
3. Self-review: console.logs? magic numbers? proper error handling?
4. Clean up any issues found
5. THEN declare done
```

### Code Quality Verification Checklist

**After tests pass, before declaring done:**

- [ ] **Read through ALL changed files** — Line by line review
- [ ] **No console.log statements** — Uses Logger service
- [ ] **No magic numbers** — Extracted to configuration or constants
- [ ] **No dev fallbacks** — Removed temporary workarounds
- [ ] **Proper typing** — No `any` types, proper validation
- [ ] **Error handling complete** — Clear messages, proper exception types
- [ ] **Follows existing patterns** — Consistent with codebase conventions

### Anti-Patterns That Cause Rework

These have caused actual rework on this project:

1. **Test-Driven Tunnel Vision**
   - Focused only on making tests pass
   - Didn't review implementation quality
   - Tests passed with bandaid code

2. **Incremental Patching**
   - Fixed immediate problems without cleanup
   - Left debug code in place
   - Never stepped back to review the whole picture

3. **Expedience Over Quality**
   - Hardcoded values instead of using configuration
   - Left console.log statements for debugging
   - Copied code instead of abstracting properly

4. **Ignoring Project Standards**
   - Didn't re-read CLAUDE.md before declaring done
   - Skipped the self-review checklist
   - Assumed "tests pass = done"

---

## What Happens If You Don't Follow This

1. Tests will be rejected
2. You will need to provide real evidence
3. Work order closeouts will be incomplete
4. Production bugs will slip through

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**
