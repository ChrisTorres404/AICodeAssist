# Methodology

The long-form documents. `{{PIPELINE_ROOT}}/core/rules/common/` states each rule
once and is always loaded; these documents carry the reasoning, the worked
examples, and the checklists behind those rules. Where the two could be read as
disagreeing, the short rule wins.

Read a methodology when you are about to do the thing it governs, not before
every task.

| Document | Read it when |
|---|---|
| `PROJECT-RULES.md` | Starting on the project. The global rules, in full: implementation order, local-first development, code quality standards, database safety, documentation placement. |
| `MANDATORY-WO-METHODOLOGY.md` | Opening, running, or closing a work order. Sizes, required documents, code comment standards, UI component standards, testing before closeout. |
| `MANDATORY-BUG-METHODOLOGY.md` | Recording or fixing a bug. Categories, routing, the required documents, closeout evidence. |
| `MANDATORY-TESTING-METHODOLOGY.md` | Writing or running any test that is meant to count as evidence. Why behavioural tests against the running system replaced mocked end-to-end suites, the four phases, the honest status vocabulary. |
| `SCENARIO-TESTING-METHODOLOGY.md` | Verifying a user journey through the interface rather than the API. |
| `DATABASE-GOLD-STANDARD-METHODOLOGY.md` | Establishing or restoring the known-good database baseline that behavioural suites start from. |
| `SYSTEMATIC-TEST-FIXING-METHODOLOGY.md` | A test suite is failing at scale and guessing has stopped converging. The long form of the `/fix-tests` rules. |
| `TEST-INVENTORY-AND-GAP-ANALYSIS.md` | A behavioural suite exists and nobody knows what it covers. How to derive the feature catalogue from the suites, classify coverage, and rank the gaps by risk, with a worked example. |
| `AGENT-OUTPUT-STANDARDS.md` | An agent is about to write a file. Where each kind of output goes, and what it must contain. |
| `KNOWLEDGE-EXTRACTION-METHODOLOGY.md` | Documenting a codebase, yours or one you are analysing. Citation rules, feature profiles, the source index. |

## Instructions

`{{PIPELINE_ROOT}}/core/instructions/` holds the operating instructions that
these methodologies stand behind — what to do, step by step, when a particular
command is invoked:

| File | Covers |
|---|---|
| `00-test-fixing-quick-start.md` | First systematic test-fixing session: what to prepare, what to expect. |
| `01-create-work-orders.md` | The work-order lifecycle: create, start, update, complete. |
| `02-next-session-rules.md` | The session handoff document: filename, structure, and the rules for producing one. |
| `03-e2e-test-fix-rules.md` | The authoritative rules for the systematic test-fixing command. |
| `04-test-fixing-agent-prompts.md` | Delegation prompts used inside a test-fixing session. |
| `05-reusable-test-fixing-prompts.md` | Whole-session prompts for running the method under any agent tool. |
| `README-TEST-FIXING-SYSTEM.md` | How the test-fixing files fit together. |
