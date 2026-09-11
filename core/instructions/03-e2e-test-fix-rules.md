# SYSTEM INSTRUCTIONS — SYSTEMATIC TEST FIXING RULES

These are the authoritative rules for how to respond when the user enters the command:

```
fixTests
```

This document MUST be followed *exactly*.

---

# 1. Purpose of fixTests

The `fixTests` command initiates a **systematic test suite fixing session** that:

- Fixes large test suites with database schema mismatches
- Uses conservative, database-first approach
- Achieves 2-5% pass rate improvement per 90-minute session
- Prevents assumptions and validates incrementally
- Uses agents for complex investigations
- Documents all changes with metrics

---

# 2. Critical Principles

## 2.1 ABSOLUTE RULES

### ✅ ALWAYS:
1. **VERIFY DATABASE SCHEMA FIRST** - Never assume column names
2. **Use agents for complex investigations** - Don't manually search
3. **Test incrementally** - Fix → Verify → Measure → Repeat
4. **Conservative approach** - Fix 1 category at a time
5. **Document everything** - File:line references, metrics, findings

### ❌ NEVER:
1. **Never assume column names** - Database was standardized
2. **Don't batch fixes** without verification
3. **Don't skip verification** after changes
4. **Don't ignore user guidance** about database state
5. **Don't fix blindly** - Understand root cause first

---

# 3. Test Fixing Workflow (MANDATORY)

When user types `fixTests`, you MUST follow these phases EXACTLY:

## Phase 1: Initial Assessment (10 min)

### Step 1: Read Handoff Documentation
```bash
# Read the handoff document the user provides
# Extract: project name, databases, credentials, current pass rate, known issues
```

### Step 2: Check Database Infrastructure
```bash
# Verify database tables exist
psql -d [database] -c "\dt [schema].*"

# Check for missing tables mentioned in handoff
psql -d [database] -c "\dt [schema].[table]"
```

### Step 3: Review Previous Test Results
```bash
# Check existing test output
cat /tmp/batch1-results.txt
grep -E "Test Suites:|Tests:" /tmp/batch1-results.txt
```

### Step 4: Categorize Failures
Analyze test output and create categories:
- **TypeScript Compilation Errors** (CRITICAL - blocks execution)
- **Database Schema Mismatches** (CRITICAL - prevents initialization)
- **HTTP Status Code Mismatches** (HIGH - wrong expectations)
- **Authentication Flow Issues** (MEDIUM - requires investigation)

---

## Phase 2: Fix Critical Blockers (20 min)

### Step 5: Fix TypeScript Errors
```bash
# Find all TypeScript compilation errors
grep -E "error TS" /tmp/batch1-results.txt

# Fix each error
# Verify fix compiles
```

### Step 6: Verify Database Column Names
**CRITICAL: ALWAYS CHECK DATABASE FIRST**

```bash
# For EVERY error mentioning a column name:

# Step 1: Check actual table structure
psql -d [database] -c "\d [schema].[table]"

# Step 2: Extract exact column names
psql -d [database] -c "SELECT column_name FROM information_schema.columns
WHERE table_schema = '[schema]' AND table_name = '[table]'
ORDER BY ordinal_position;"

# Step 3: Compare with code
grep -r "column_name" src --include="*.ts"

# Step 4: Fix mismatches
# Step 5: Verify fix works
```

### Step 7: Fix Common Column Name Patterns

**Standard Lowercase Mappings:**
| Database Column | Code Should Use | Common Mistake |
|-----------------|-----------------|----------------|
| `routemethod` | routeMethod | route_method |
| `routepath` | routePath | route_path |
| `clientid` | clientId | client_id |
| `userid` | userId | user_id |
| `primaryemail` | primaryEmail | primary_email |
| `creatortype` | creatorType | creator_type |
| `modifiertype` | modifierType | modifier_type |
| `detectedat` | detectedAt | detected_at |
| `invitedby` | invitedBy | invited_by |

### Step 8: Run Targeted Test
```bash
# Run small test subset to verify blockers fixed
npm run test:e2e -- test/e2e/[category]/[test].e2e-spec.ts --maxWorkers=1 --forceExit
```

---

## Phase 3: Systematic Snake_Case Search (30 min)

### Step 9: Search Entities for Snake_Case
```bash
# Find all @Column definitions with underscores
grep -r "@Column({ name:" src --include="*.entity.ts" | grep "_" \
  | sed "s/.*name: '//" | sed "s/'.*//" | grep "_" | sort -u > /tmp/snake_case_columns.txt
```

### Step 10: Verify EACH Snake_Case Column Against Database
```bash
# For EACH column found in step 9:
psql -d [database] -c "SELECT column_name FROM information_schema.columns
WHERE column_name LIKE '%[columnpart]%';"

# Record: Database name vs Code name
# If mismatch → add to fix list
```

### Step 11: Search Services for Snake_Case
```bash
# Find query builder calls with underscores
grep -r "\.where.*_\|\.andWhere.*_" src --include="*.service.ts" \
  | grep -E "user_id|client_id|route_method"

# Find raw SQL with underscores
grep -r "queryRunner.query\|\.query(" src --include="*.ts" \
  | grep -iE "INSERT INTO|UPDATE|DELETE FROM" | grep "_"
```

### Step 12: Fix All Identified Mismatches
- Fix entities: `@Column({ name: 'columnname' })`
- Fix services: `.where('table.columnname = :value')`
- Fix raw SQL: Use verified column names

### Step 13: Verify No Snake_Case Remains
```bash
# Final verification
grep -r "_id'\|_type'\|_at'" src --include="*.ts" --include="*.service.ts" \
  | grep -v "migrations-archive\|node_modules"
```

### Step 14: Run Targeted Tests After Fixes
```bash
npm run test:e2e -- test/e2e/[affected-tests].e2e-spec.ts --maxWorkers=1
```

---

## Phase 4: Use Agents for Complex Issues (20 min)

### Step 15: Launch Explore Agent for Documentation

**When to use:** Need to find documentation or understand historical context

**Agent:** `subagent_type: Explore`
**Model:** `haiku` (fast, cost-effective)

**Prompt Template:**
```markdown
Search the codebase for documentation from [timeframe] about [topic]. I need to understand:

1. [Specific question 1]
2. [Specific question 2]
3. [Specific question 3]

Search locations:
- docs/1_internaldocs./[subdirectory]
- migrations/[number range]
- [specific file patterns]

Return the exact documentation with file paths and line numbers so I can understand [the business rules/technical requirements/schema changes].
```

### Step 16: Launch Support Engineer Agent for Debugging

**When to use:** Need to debug complex errors or trace data flow

**Agent:** `subagent_type: support-engineer-expert`
**Model:** `sonnet`

**Prompt Template:**
```markdown
I need deep troubleshooting for a [component] bug:

**Symptom:** [HTTP method] [endpoint] returns [status code] "[error message]"

**What I've already done:**
1. [Verification step 1]
2. [Fix attempt 1]
3. [Database check 1]

**The problem:** [Description of unexpected behavior]

**Files to investigate:**
- [File 1] ([specific method/class to check])
- [File 2] ([what to look for])
- [File 3] ([potential issue location])

**What I need:**
1. Root cause: [Specific technical question]
2. Data flow trace: [Request → Controller → Service → Entity → Database]
3. Exact fix needed with file:line references
4. Verification steps to confirm fix works

Use your elite debugging skills to trace the [data flow/logic/mapping] and find where [the issue] occurs.
```

### Step 17: Launch Database Validator Agent for Infrastructure

**When to use:** Need to verify database state, tables, migrations, seed data

**Agent:** `subagent_type: database-validator-expert`
**Model:** `sonnet`

**Prompt Template:**
```markdown
[Component] endpoints are returning [status code] "[error]" but the code exists. I need you to verify:

**1. Module Registration:**
- Is [ModuleName]Module imported in AppModule?
- Check src/app.module.ts imports array
- Verify controllers are exported from module

**2. Database Infrastructure:**
- Verify tables exist: [table1], [table2], [table3]
- Database: [database name]
- Check: I created these earlier - verify they're actually there
- Run: SELECT * FROM [table] LIMIT 1;

**3. Migration Status:**
- Was migration [timestamp-name] fully executed?
- Check migrations_history table
- Verify all tables from migration exist

**4. Seed Data:**
- Are required privileges seeded?
- Check for [privilege codes] in auth.privilege
- Verify [reference data] exists in [table]

**What I need:**
1. Exact reason why [endpoint] returns [status]
2. What's missing (module import, table, data, etc.)
3. Specific fix needed with file:line references
4. SQL verification queries to confirm fix

Use database queries to verify everything exists as expected.
```

---

## Phase 5: Validation & Measurement (10 min)

### Step 18: Run Targeted Tests After Each Agent Fix
```bash
npm run test:e2e -- test/e2e/[specific-test].e2e-spec.ts --maxWorkers=1
```

### Step 19: Run Full Test Suite
```bash
npm run test:e2e -- --maxWorkers=4 --forceExit 2>&1 | tee /tmp/fulltest-after-fixes.txt
```

### Step 20: Extract and Compare Metrics
```bash
# Extract current metrics
grep -E "Test Suites:|Tests:" /tmp/fulltest-after-fixes.txt

# Compare with baseline
# Calculate improvement percentage
# Document duration change
```

---

# 4. Expected Outputs (MANDATORY)

After completing all phases, you MUST create:

## 4.1 Session Summary Document

**File:** `{{SESSIONS_DIR}}/active/[date]-test-fixing-session.md`

**Contents:**
- All fixes applied with file:line references
- Before/after metrics
- Agent findings summary
- Time spent on each phase
- Verification results

## 4.2 Remaining Issues Document

**File:** `{{SESSIONS_DIR}}/active/[date]-remaining-issues.md`

**Contents:**
- Categorized list of unfixed issues
- Estimated effort for each
- Recommended next steps
- Priority ordering

## 4.3 Database Schema Verification Document

**File:** `{{SESSIONS_DIR}}/active/[date]-database-schema-verification.md`

**Contents:**
- All tables verified
- Column name mapping reference
- Migration status
- Known discrepancies

---

# 5. Agent Usage Strategy

## 5.1 When to Use Each Agent

| Need | Agent | Model | When |
|------|-------|-------|------|
| Find documentation | `Explore` | haiku | Historical context, patterns, documentation search |
| Debug errors | `support-engineer-expert` | sonnet | Root cause analysis, data flow tracing |
| Verify DB state | `database-validator-expert` | sonnet | Infrastructure, tables, migrations, seed data |

## 5.2 Agent Prompt Best Practices

### ✅ DO:
1. State the problem clearly (symptom + what you tried)
2. List specific files to investigate
3. Ask for exact fixes with file:line references
4. Request verification commands
5. Provide context (database name, credentials, etc.)

### ❌ DON'T:
1. Ask agents to make changes (they only investigate)
2. Use vague prompts
3. Skip context
4. Forget to request verification steps

---

# 6. Progressive Fix Strategy

## Iteration 1: Critical Blockers
- Fix TypeScript errors (can't run without these)
- Fix critical database blockers (app won't initialize)
- Run 5-10 targeted tests
- **Expected:** 5-15% pass rate

## Iteration 2: Systematic Fixes
- Fix all snake_case references
- Apply documented schema changes
- Run 20-30 targeted tests
- **Expected:** 15-25% pass rate

## Iteration 3: Infrastructure
- Fix missing modules/imports
- Fix DTO/Entity alignment issues
- Run 50-100 tests
- **Expected:** 25-35% pass rate

## Iteration 4: Business Logic
- Fix authentication issues
- Fix privilege grants
- Run full suite
- **Expected:** 35-50% pass rate

**Goal:** 70%+ pass rate after 4-6 iterations (6-9 hours)

---

# 7. Verification Checklist

Before marking session complete, verify:

- [ ] All TypeScript errors resolved
- [ ] No snake_case in entity column names
- [ ] No snake_case in service queries
- [ ] No snake_case in raw SQL
- [ ] Database schema verified against all entities
- [ ] Missing modules registered in AppModule
- [ ] DTO fields align with entity properties
- [ ] Targeted tests run for each fix category
- [ ] Full test suite run with metrics captured
- [ ] Improvement documented (before → after)
- [ ] Agent findings documented
- [ ] Remaining issues categorized
- [ ] Next session prompt created

---

# 8. Success Metrics

## Session Success Criteria
- ✅ Pass rate improved by 2%+
- ✅ Critical blockers resolved (app initializes)
- ✅ At least 1 agent used successfully
- ✅ Database schema verified
- ✅ Fixes documented with file:line

## Project Success Criteria
- ✅ 70%+ pass rate achieved
- ✅ All critical endpoints tested
- ✅ Database schema 100% aligned with code
- ✅ No snake_case in active codebase
- ✅ All modules registered correctly

---

# 9. Quick Reference Commands

## Database Verification
```bash
# List all tables in schema
psql -d [DB] -c "\dt [schema].*"

# Show table structure
psql -d [DB] -c "\d [schema].[table]"

# Get column names
psql -d [DB] -c "SELECT column_name FROM information_schema.columns
WHERE table_schema = '[schema]' AND table_name = '[table]';"

# Check if column exists
psql -d [DB] -c "SELECT column_name FROM information_schema.columns
WHERE column_name = '[columnname]';"
```

## Code Search
```bash
# Find entity column definitions
grep -r "@Column.*name:" src --include="*.entity.ts"

# Find snake_case in entities
grep -r "@Column({ name: '[a-z]*_[a-z]*'" src --include="*.entity.ts"

# Find snake_case in services
grep -r "\.where\|\.andWhere" src --include="*.service.ts" | grep "_"

# Find raw SQL with snake_case
grep -r "queryRunner.query" src --include="*.ts" -A5 | grep "_"
```

## Testing
```bash
# Run targeted test subset
npm run test:e2e -- test/e2e/[category]/[test].e2e-spec.ts --maxWorkers=1 --forceExit

# Run full suite with output
npm run test:e2e -- --maxWorkers=4 --forceExit 2>&1 | tee /tmp/test-results.txt

# Extract summary
grep -E "Test Suites:|Tests:" /tmp/test-results.txt
```

---

# 10. Sample Interaction Flow

**User:** `fixTests`

**Claude:**
1. Reads handoff documentation (if provided)
2. Checks database table existence
3. Reviews test results (if available)
4. Creates TodoList with phases
5. Proposes action plan
6. **WAITS for approval**

**User:** "Proceed with conservative approach"

**Claude:**
1. Fixes TypeScript errors
2. Verifies database schemas
3. Fixes critical blocker (e.g., RouteDiscovery crash)
4. Runs targeted test
5. Shows improvement (X% → Y%)
6. Proposes next step

**User:** "Continue with systematic search"

**Claude:**
1. Searches for all snake_case
2. Verifies each against database
3. Fixes all mismatches
4. Shows list of fixes
5. Runs verification

**User:** "Use agents to investigate [issue]"

**Claude:**
1. Launches appropriate agent
2. Shows agent findings
3. Applies recommended fixes
4. Verifies with tests
5. Reports results

---

# 11. Expected Timeline

**Session 1 (90 min):**
- Assessment: 10 min
- Critical blockers: 20 min
- Systematic search: 30 min
- Agent investigations: 20 min
- Validation: 10 min
- **Result:** 2-5% improvement

**Total for 70%+ pass rate:** 4-6 sessions (6-9 hours)

---

# 12. Customization for Your Project

When using `fixTests`, replace these placeholders:

- `[Project Name]` → Your project name
- `[DatabaseDev]` → Your dev database name
- `[DatabaseTest]` → Your test database name
- `[email] / [password]` → Your test credentials
- `[path]` → Your project working directory
- `[schema]` → Your database schema (e.g., acct, auth, org)

---

# 13. End of System Instructions

Use this exact methodology every time the user types `fixTests`.

**Remember:**
- Database verification FIRST
- Incremental validation
- Agent-driven investigation
- Conservative approach
- Document everything

---
