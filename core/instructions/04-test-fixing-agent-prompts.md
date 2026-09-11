# TEST FIXING AGENT PROMPT LIBRARY

**Purpose:** Ready-to-use agent prompts for systematic test fixing sessions

---

## Agent 1: Explore Agent - Documentation Search

**Use When:** Need to find documentation, understand historical context, or search for patterns

**Agent Type:** `Explore`
**Model:** `haiku` (fast and cost-effective)
**Expected Time:** 5-10 minutes

### Template 1: Database Schema Documentation

```markdown
Search the codebase for documentation from [November 2025 / last week / etc.] about database schema changes. I need to understand:

1. What columns were renamed or changed?
2. What is the naming convention (snake_case vs camelCase)?
3. Are there any migration notes about the standardization?

Search locations:
- docs/1_internaldocs./New_Schema_Update_ToDos/
- migrations/
- Database migration files (*.ts)
- Session summaries

Return the exact documentation with file paths and line numbers so I can understand the database standardization rules.
```

### Template 2: Find Column Name Conventions

```markdown
Search the codebase for documentation about the column naming convention for [table_name]. I need to understand:

1. Is [column_name] nullable or NOT NULL?
2. What are the business rules for [column_name]?
3. When was this column last modified?

Search locations:
- Entity files: src/**/*.entity.ts
- Migration files: migrations/**/*.ts
- Documentation: docs/**/*.md
- Work orders: {{WORKORDERS_DIR}}/*.md

Return exact column definitions with file:line references.
```

### Template 3: Historical Context Search

```markdown
Search for recent work (past 2 weeks) related to [feature/component]. I need to understand:

1. What changes were made to [component]?
2. Why was [decision] made?
3. What issues were encountered?

Search locations:
- Session summaries: {{SESSIONS_DIR}}/active/
- Work orders: {{WORKORDERS_DIR}}/
- Commit messages (if available)

Provide a chronological summary with file references.
```

---

## Agent 2: Support Engineer Agent - Bug Diagnosis

**Use When:** Need to debug complex errors, trace data flow, or understand why something isn't working

**Agent Type:** `support-engineer-expert`
**Model:** `sonnet`
**Expected Time:** 10-20 minutes

### Template 1: HTTP Error Debugging

```markdown
I need deep troubleshooting for a [component/endpoint] bug:

**Symptom:** [POST/GET/PUT/DELETE] [/api/endpoint/path] returns [404/500/401] "[error message]"

**What I've already done:**
1. Verified the controller exists in [file path]
2. Checked the module is imported in AppModule
3. Verified database table [table_name] exists
4. Checked [other verification]

**The problem:** [Description - e.g., "The endpoint should exist but returns 404"]

**Files to investigate:**
- [ControllerFile.ts] - Check route decorator and method signature
- [ServiceFile.ts] - Check business logic and database queries
- [EntityFile.ts] - Check column mappings
- [app.module.ts] - Check module registration

**What I need:**
1. Root cause: Why is this endpoint returning [status code]?
2. Data flow trace: Request → Controller → Service → Entity → Database
3. Exact fix needed with file:line references
4. Verification steps to confirm fix works

Use your elite debugging skills to trace the complete request flow and identify where it breaks.
```

### Template 2: Database Query Error

```markdown
Deep troubleshooting needed for database query error:

**Symptom:** Query fails with "[error message]" when trying to [action]

**What I've already done:**
1. Verified table exists: SELECT * FROM [schema].[table] LIMIT 1;
2. Verified column exists in database: \d [schema].[table]
3. Checked entity definition in [EntityFile.ts]
4. Database shows column as: [actual_column_name]

**The problem:** Entity/Service is using [column_name] but database has [actual_column_name]

**Files to investigate:**
- [Entity.entity.ts] - Line [X] - @Column definition
- [Service.service.ts] - Line [Y] - Query builder
- Migration that created table: migrations/[timestamp]-[name].ts

**What I need:**
1. Complete list of all places this column is referenced
2. Root cause: Why does the code use [column_name] when DB has [actual_name]?
3. Exact fixes with file:line references for:
   - Entity @Column decorators
   - Service query builders
   - Any raw SQL queries
4. Verification query to test fix

Trace all code paths that reference this column.
```

### Template 3: Test Failure Analysis

```markdown
Test [test-name.e2e-spec.ts] is failing with unexpected behavior:

**Symptom:** Test expects [X] but gets [Y]

**Test File:** test/e2e/[path]/[test-name].e2e-spec.ts

**What I've already done:**
1. Verified test credentials work: [email]/[password]
2. Checked endpoint exists and returns [status]
3. Database state: [description]

**The problem:** [Describe mismatch between expected and actual]

**Files to investigate:**
- Test file: [test.e2e-spec.ts] - Check expectations
- Controller: [controller.ts] - Check what it actually returns
- DTO: [dto.ts] - Check response structure
- Service: [service.ts] - Check business logic

**What I need:**
1. Why does the test expect [X] when the code returns [Y]?
2. Which is correct - the test expectation or the code behavior?
3. Root cause of the mismatch
4. Fix with file:line (either fix test OR fix code, with reasoning)

Analyze the complete flow and determine the source of truth.
```

---

## Agent 3: Database Validator Agent - Infrastructure Verification

**Use When:** Need to verify database state, check migrations, validate table/column existence

**Agent Type:** `database-validator-expert`
**Model:** `sonnet`
**Expected Time:** 10-15 minutes

### Template 1: Module Registration Check

```markdown
[ComponentName] endpoints are returning 404 but the code exists. Verify infrastructure:

**1. Module Registration:**
- Is [ModuleName]Module imported in AppModule?
- File to check: src/app.module.ts
- Verify it's in the imports array
- Check controllers are exported from [ModuleName]Module

**2. Controller Registration:**
- Is [ControllerName] decorated with @Controller('[path]')?
- File: src/modules/[module]/controllers/[controller].ts
- Verify the path matches the failing endpoint

**3. Route Configuration:**
- Check method decorators: @Get(), @Post(), etc.
- Verify route paths match test expectations
- Check for any @UseGuards() that might block requests

**Database:** [DatabaseName]
**Endpoint failing:** [METHOD /api/path]

**What I need:**
1. Exact reason why [endpoint] returns 404
2. What's missing (module import, controller export, route decorator, etc.)
3. Specific fix with file:line references
4. Verification steps to confirm fix
```

### Template 2: Database Table & Migration Verification

```markdown
Need complete database infrastructure verification for [feature/component]:

**1. Database Tables:**
- Verify these tables exist: [table1], [table2], [table3]
- Database: [DatabaseName]
- Run: SELECT * FROM [schema].[table] LIMIT 1; for each
- If missing, check what migration should have created them

**2. Migration Status:**
- Was migration [timestamp-name].ts fully executed?
- Check: SELECT * FROM migrations_history WHERE name LIKE '%[name]%';
- Verify all tables from this migration exist
- Check for any partial execution

**3. Column Verification:**
- For each table, verify actual column names
- Run: SELECT column_name FROM information_schema.columns
       WHERE table_schema = '[schema]' AND table_name = '[table]'
       ORDER BY ordinal_position;
- Compare with entity definitions in [Entity.entity.ts]

**4. Required Data:**
- Check seed data for [reference tables]
- Verify privileges/permissions exist if needed
- Run: SELECT COUNT(*) FROM [schema].[table];

**What I need:**
1. Complete infrastructure status (tables, columns, data)
2. What's missing or misconfigured
3. Specific SQL to fix (if tables/data missing)
4. Specific code fixes (if entity definitions wrong)
5. Verification queries to confirm everything works
```

### Template 3: Schema Mismatch Investigation

```markdown
Need comprehensive schema verification for [schema_name] schema:

**Background:**
The database was recently standardized to lowercase/camelCase naming.
Tests are failing with column reference errors.

**Investigation Required:**

**1. Table Names:**
- List all tables in [schema_name] schema
- Run: \dt [schema_name].*
- Check for any snake_case table names
- Standard should be: all lowercase, no underscores

**2. Column Names for Each Table:**
- For tables: [list of tables with issues]
- Extract all column names
- Identify any with underscores
- Compare with entity @Column decorators

**3. Entity-Database Mapping:**
- For each entity in src/modules/[module]/entities/
- Verify @Column({ name: 'columnname' }) matches database
- Check JoinColumn references
- Verify relationship column names

**4. Service Query Verification:**
- Search services for queries using these tables
- Check .where() and .andWhere() clauses
- Verify column names in QueryBuilder calls
- Find any raw SQL queries

**Database:** [DatabaseName]
**Schema:** [schema_name]

**What I need:**
1. Complete column name inventory (database vs code)
2. List of all mismatches with exact locations
3. Recommended fixes with file:line references
4. Verification approach to ensure all are found
```

---

## Usage Guidelines

### When to Use Each Agent

1. **Start with Explore Agent** if you need context
   - What changed recently?
   - What's the naming convention?
   - Where is the documentation?

2. **Use Support Engineer Agent** for active debugging
   - Why is this endpoint failing?
   - Why is the test expecting different behavior?
   - Trace the data flow

3. **Use Database Validator Agent** for infrastructure
   - Do the tables exist?
   - Are columns named correctly?
   - Did the migration run?

### Agent Call Pattern

```markdown
1. Identify the problem
2. Choose the right agent
3. Fill in the template
4. Launch agent via Task tool
5. Review agent findings
6. Apply recommended fixes
7. Verify fixes work
8. Document in session summary
```

### Example Agent Call Sequence

For a test failing due to 404 on a portal endpoint:

1. **Database Validator Agent** → Verify portal tables exist
2. **Database Validator Agent** → Check module registration
3. **Support Engineer Agent** → Debug why route not found
4. **Explore Agent** → Find documentation on portal setup

---

## Agent Prompt Best Practices

### ✅ DO:
- Provide specific file paths to investigate
- Include what you've already tried
- Ask for file:line references in response
- Request verification steps
- Give database credentials when needed
- Include error messages verbatim

### ❌ DON'T:
- Use vague descriptions
- Ask agent to make changes (they investigate only)
- Skip context about what you've done
- Forget to specify database name
- Leave out error messages
- Ask multiple unrelated questions

---

## Copy-Paste Ready Prompts

### Quick Database Column Check
```markdown
Verify the actual column name for [table_name].[column_name]:

Database: [DatabaseName]
Run: SELECT column_name FROM information_schema.columns
     WHERE table_schema = '[schema]' AND table_name = '[table]';

Return the exact column name and compare with entity in [Entity.entity.ts].
```

### Quick Module Check
```markdown
Is [ModuleName]Module registered in AppModule?

Check: src/app.module.ts
Look for: import { [ModuleName]Module } and in imports array
Return: Yes/No with line number if found
```

### Quick Migration Status
```markdown
Did migration [timestamp-name].ts execute successfully?

Database: [DatabaseName]
Check: SELECT * FROM migrations_history WHERE name LIKE '%[name]%';
Verify: All tables from this migration exist
Return: Status + any missing tables
```

---

**Last Updated:** 2025-11-14
**Usage:** Import these templates when running `fixTests` command
**Customization:** Replace [placeholders] with your project values
