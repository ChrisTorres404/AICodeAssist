# Test Fixing — Agent Prompt Library

Ready-to-use delegation prompts for a systematic test-fixing session. Used
with `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md`.

Every template is a shape. Replace the bracketed parts with real values from
this project and delete the lines that do not apply. A template sent with its
brackets still in it is worse than no template.

**All of these investigate. None of them edit.** Investigators return findings
with `file:line`; applying the fix is a separate step, and a different agent
validates it.

---

## Context: Exploration

**Use when** you need to understand what changed, what the conventions are, or
where something is documented — before forming a theory.

**Agent:** `code-explorer`, or the built-in `Explore` agent for a broad sweep

### Template — convention and schema history

```markdown
Search this repository for documentation and history about [the data model /
naming convention / API contract] for [area]. I need to understand:

1. What changed, and when?
2. What is the current convention?
3. Are there migration or decision notes explaining why?

Search:
- The data-model definitions under [source directory]
- The migration or schema-change directory
- Documentation under {{DOCS_DIR}}
- Work orders under {{WORKORDERS_DIR}}
- Session notes under {{SESSIONS_DIR}}

Return the exact text with file paths and line numbers. Do not summarize away
the specifics — I need to reconcile code against them.
```

### Template — field-level rules

```markdown
Find the definition and rules for [field] on [entity or table].

1. Is it required or optional? What is its type?
2. What business rules constrain it?
3. When was it last changed, and by which work order?

Search the data-model definitions, the migration history, and the
documentation. Return exact definitions with file:line references.
```

### Template — recent work on a component

```markdown
Find the recent work related to [feature or component]. I need:

1. What changed in [component]?
2. Why was [decision] made?
3. What problems were hit along the way?

Search {{SESSIONS_DIR}}/active/, {{WORKORDERS_DIR}}/, {{BUGS_DIR}}/, and the
commit history. Return a chronological summary with file references.
```

---

## Active Debugging

**Use when** you have a specific failure and need the root cause traced.

**Agent:** `support-engineer-expert`

### Template — an endpoint returns the wrong thing

```markdown
I need root-cause analysis for a failing endpoint.

**Symptom:** [METHOD] [path] returns [status] "[exact error message]"

**Already verified:**
1. The handler exists at [file:line]
2. [Registration / routing check performed]
3. [Data store check performed]

**The problem:** [what should happen versus what does]

**Files to investigate:**
- [handler file] — the route definition and signature
- [service file] — the logic and the queries it issues
- [model file] — the field mappings
- [wiring or configuration file] — registration

**What I need:**
1. The root cause: why does this return [status]?
2. A trace of the request from entry through to the data store
3. The exact fix, with file:line references
4. The verification step that would confirm it

Do not edit anything. Return findings.
```

### Template — a query fails

```markdown
Root-cause analysis for a failing data-store query.

**Symptom:** [operation] fails with "[exact error message]"

**Already verified:**
1. The table or collection exists
2. The real field name in the live schema is [actual name]
3. The model at [file:line] declares [declared name]

**The problem:** the code names [declared name]; the schema has [actual name].

**Files to investigate:**
- [model file:line] — the field declaration
- [service file:line] — query construction
- The migration that created it

**What I need:**
1. Every place this field is referenced — model, queries, raw statements,
   fixtures, test expectations
2. Why the code diverged from the schema
3. Exact fixes with file:line references
4. A query that verifies the fix

Do not edit anything. Return findings.
```

### Template — a test and the code disagree

```markdown
Test [test file] fails: it expects [X] and gets [Y].

**Already verified:**
1. [credentials / fixtures / preconditions confirmed working]
2. The endpoint returns [status]
3. The relevant state is [description]

**Files to investigate:**
- [test file] — the expectation
- [handler] — what is actually returned
- [response model] — the declared shape
- [service] — the logic that produces it

**What I need:**
1. Why does the test expect [X] when the code produces [Y]?
2. **Which one is right** — the expectation or the behavior? I need your
   reasoning, not a preference.
3. The root cause of the divergence
4. The fix, with file:line, on whichever side is actually wrong

Do not edit anything. Return findings.
```

---

## Infrastructure Verification

**Use when** you need to know whether the thing the tests depend on actually
exists.

**Agent:** `database-validator-expert`

### Template — is it wired up

```markdown
[Component] endpoints return [status] although the code exists. Verify the
wiring:

**1. Registration**
- Is [component] registered wherever this project wires components together?
- File to check: [entry point or module file]

**2. Route definition**
- Is the handler declared at the path the test calls?
- File: [handler file]
- Does the declared path match the failing request exactly, prefixes included?

**3. Guards and middleware**
- Is anything in front of this route rejecting the request before it arrives?

**Environment:** [which environment and data store]
**Failing request:** [METHOD path]

**What I need:**
1. The exact reason for [status]
2. What is missing — registration, export, path, middleware
3. The fix, with file:line references
4. The check that would confirm it

Do not edit anything. Return findings.
```

### Template — schema and migration state

```markdown
Full infrastructure verification for [feature].

**1. Tables or collections**
- Verify these exist: [list]
- Environment: [name]
- If any are missing, identify which migration should have created it

**2. Migration state**
- Did migration [name] run completely?
- Check the project's migration-history table
- Verify every object that migration should have created

**3. Field verification**
- For each table, list the real field names and types from the live schema
- Compare against the model definitions at [paths]

**4. Required data**
- Is the reference or seed data present?
- Counts for [tables]

**What I need:**
1. The complete state: objects, fields, data
2. What is missing or misconfigured
3. The statements that would fix missing structure or data
4. The code fixes, if the models are the side that is wrong
5. Verification queries

Do not edit anything. Return findings.
```

### Template — systematic mismatch inventory

```markdown
Comprehensive schema verification for [schema or namespace].

**Background:** the tests fail with [class of error], which suggests a
systematic mismatch between the live schema and the code that names it.

**Investigation:**

1. **Object names.** List everything in [schema or namespace] and flag any
   that do not follow the convention.
2. **Field names.** For [tables with failures], list every field. Flag the
   ones the code names differently.
3. **Model mapping.** For each model under [directory], verify the declared
   field name against the live schema, including relationship and join fields.
4. **Query construction.** Find every query — builder calls and raw statements
   alike — that names these objects, and check each name.

**Environment:** [name]

**What I need:**
1. A complete inventory: schema name versus code name, side by side
2. Every mismatch, with exact locations
3. Recommended fixes with file:line references
4. How to confirm the inventory is exhaustive

Do not edit anything. Return findings.
```

---

## Usage

### Escalation order

Most failures resolve at the step people skip. Go in this order:

1. **Context first.** What changed? What is the convention? Where is it
   documented? — `code-explorer` or `Explore`
2. **Then active debugging.** Why does this specific thing fail? —
   `support-engineer-expert`
3. **Then infrastructure.** Does it exist? Did the migration run? Is it wired
   up? — `database-validator-expert`

Two more, when the symptom fits:

- Data is missing or wrong and nothing threw — `silent-failure-hunter`
- The build or type-check itself is broken — `build-error-resolver`

### The loop

```
1. Identify the problem precisely
2. Choose the agent whose description matches
3. Fill in the template completely
4. Delegate; independent investigations run in parallel
5. Read the findings and check them against the system yourself
6. Apply the fix
7. Re-run the affected tests
8. Record it in the session document
```

**If you delegate, you collect.** A spawned investigation is not a finished
one. The subagent's final message is its deliverable; integrate it, then
report.

### Example sequence

A test failing because an endpoint returns "not found":

1. `database-validator-expert` — do the tables the feature needs exist?
2. `database-validator-expert` — is the component registered?
3. `support-engineer-expert` — why is the route not resolving?
4. `code-explorer` — what does the documentation say this path should be?

---

## Prompt Quality

### Do

- Name specific files and line numbers to start from
- Say what you already ruled out, and how
- Quote error messages verbatim
- Ask for `file:line` in the response
- Ask for the verification step
- Name the environment and data store

### Do not

- Describe the problem vaguely
- Ask an investigator to make the change
- Omit what you already tried — it will be tried again
- Bundle unrelated questions into one delegation
- Paraphrase an error message

---

## Short Checks

Not everything needs a full template.

```markdown
Verify the real field name for [table].[field] in [environment], and compare
it with the model definition at [path]. Return the exact name and the
mismatch, if any.
```

```markdown
Is [component] registered where this project wires components together?
Check [entry point file]. Return yes or no, with the line number if found.
```

```markdown
Did migration [name] run completely in [environment]? Check the migration
history table and verify every object it should have created. Return the
status and anything missing.
```
