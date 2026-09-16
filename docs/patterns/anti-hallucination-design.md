# Four-Layer Validation: Why the Design Looks Like This

An agent that writes code will, sooner or later, write code against something
that does not exist. A table it assumed. A component it was sure it had seen.
A directory convention it invented halfway through. The output compiles often
enough to get merged, and the cost lands on whoever reads it next.

This document is the reasoning behind the four layers the pipeline uses
against that, not the instructions for using them. It says what each layer
catches, what failure it was a response to, why each one is insufficient on
its own, how they compose, and what the whole thing costs.

---

## What is actually being prevented

"Hallucination" is too broad to design against. In practice it is four
distinct failures with four different fixes:

| Failure | What it looks like | Why the model does it |
|---|---|---|
| **Invented references** | Code imports a service, queries a column, or calls a method that does not exist | The name is plausible. Plausibility is what a language model optimizes for, and a plausible name is indistinguishable from a real one without looking |
| **Structural drift** | A feature lands in `src/components/<feature>/` when the project puts features in `src/features/<name>/` | The model knows many conventions and has no reason to prefer this project's unless told, every time |
| **Duplication** | A third `NotificationCard` appears beside two existing ones | Searching costs a tool call; writing from scratch does not. Left to itself, the cheaper path wins |
| **Untraceable change** | A diff arrives with no indication of why it exists or what asked for it | Nothing in the generation loop needs the reason, so nothing produces it |

Each layer below exists because one of these kept happening after the previous
layer was in place.

---

## The shape of the defense

```
Layer 1: Global context      -> one rules file, read before any work
Layer 2: Agent injection     -> every specialist carries the project's rules
Layer 3: Validator agents    -> specialists whose only job is to catch mistakes
Layer 4: Behavioral protocol -> a pre-work checklist the main agent runs itself
```

They are ordered by when they act, not by importance: Layer 1 before the
thinking, Layer 2 during it, Layer 4 before the writing, Layer 3 after it.

---

## Layer 1 — Global context

**What it is.** One file that is the single source of truth for how work is
done in this project: the golden rule, the directory conventions, the import
conventions, the database and API guards, the traceability requirement, the
pre-work checklist. In this pipeline that is
`.aicodepipeline/core/methodology/PROJECT-RULES.md`, with the per-topic
detail split into `.aicodepipeline/core/rules/common/`.

**What failure produced it.** Before it existed, the rules lived in whoever
was reviewing. Every session re-derived the conventions from whatever files it
happened to open, and the conventions it derived depended on which files those
were. Two sessions on the same repository produced two different architectures
and both were defensible.

**What it catches.** Structural drift, mostly. A model that has read "features
live in `src/features/<name>/`, a page is at most 150 lines, a component at
most 200, shared imports use the path alias and intra-feature imports are
relative" will follow it, because there is nothing it would rather do.

**Why it is not enough on its own.** Three reasons, and they are the reason
Layers 2 through 4 exist:

- **It is one file among many.** As a session grows, the rules file is one
  early message competing with thousands of tokens of code read since. Salience
  decays. The rule that was obvious at message three is a distant memory at
  message sixty.
- **Subagents do not inherit it.** Delegate to a specialist and the specialist
  starts with its own definition and the task text. It has never read the rules
  file unless something put them there.
- **It states rules; it does not check them.** A rule is a statement about what
  should happen. Nothing about having read it verifies that it did.

**Cost.** A few thousand tokens at the start of every session, and the
maintenance of one document. This is the cheapest layer by a wide margin and
should be the first one built.

### What the rules file actually contains

The contents matter more than the existence, because a rules file of
generalities is read and changes nothing. Every entry below is a rule an agent
can be wrong about in a way a reviewer can point at:

- **The golden rule:** never reference anything without verifying it exists
- **Frontend structure:** features live in `src/features/<name>/`, not in
  `src/components/<feature>/`
- **Extraction limits:** a page at most 150 lines, a component at most 200,
  a hook at most 100 — numbers, not "keep it small"
- **Import conventions:** the path alias for shared code, relative paths
  inside a feature
- **Database guards:** verify the table and the column exist before writing
  the query; no migration without an approved work order
- **API guards:** verify the entity and the data-transfer object exist before
  referencing them
- **Traceability:** every change carries its work order and its reason
- **The pre-work checklist:** what to do before writing anything

About nine kilobytes in total. Longer than that and the later rules stop being
read; shorter and it stops being specific enough to be checkable.

---

## Layer 2 — Injection into every specialist

**What it is.** Every specialist agent definition carries a project-context
section: the database rules, the API rules, the frontend rules, and the golden
rule that nothing may be referenced without being verified to exist. It is not
a link to the rules file — it is the rules, in the agent's own definition,
because a link is only followed by an agent that decides to follow it.

**What failure produced it.** Layer 1 was in place and the main agent
respected it. Then the work was delegated — "have the backend specialist add
the endpoint" — and the specialist, which had never seen the rules file,
produced an entity in the wrong place with a naming convention from a
different project. The rules had been read by the wrong participant.

**What it catches.** Every failure mode, but only inside a delegated task. A
specialist that carries "verify the table and column exist before writing a
query" checks before writing the query, in the same way the main agent does.

**Why it is not enough on its own.** It has the same weakness as Layer 1 — it
is instruction, not verification — and it adds one of its own: **drift across
definitions.** Twenty-five agent definitions each carrying a copy of the rules
is twenty-five copies to update when a rule changes. Six months in, some of
them say something different, and nobody knows which. Mitigate it by keeping
the injected section short and generated rather than hand-edited, and by
linting that every definition has one.

**Cost.** A section in each agent definition, paid on every delegation, plus
the maintenance burden above. The maintenance is the real cost and it grows
with the number of agents.

### Which definitions carry it

All of them. A specialist without the project context is the one that will be
handed the task where the context mattered. In a typical deployment that is
twenty-five specialists, one per domain the project actually touches:

| | | |
|---|---|---|
| backend framework | frontend framework | type system |
| object-relational mapping | relational database | cache and key-value store |
| queueing | pub/sub messaging | document store |
| cloud platform | containers | continuous integration |
| API schema and documentation | REST design | GraphQL |
| identity and access | token handling | payments |
| unit testing | styling and utility CSS | markup and semantics |
| runtime and performance | user experience | interface design |
| business analysis | | |

The list is the project's, not a standard one. A domain the project does not
touch does not need a specialist, and a specialist nobody delegates to is a
definition to keep current for no return.

---

## Layer 3 — Validator agents

**What it is.** Specialists whose only output is a verdict. Three of them, at
different points in the work:

| Validator | Runs | Model | What it verifies |
|---|---|---|---|
| `database-validator-expert` | Before any database code is written | A fast model — this is a lookup, not a judgement | Tables and columns exist; entity definitions match the schema; the project's naming convention is used; no unauthorized migration; relationships and constraints are right |
| `frontend-validator-expert` | Before any component is created | A fast model — a structure check | The feature is in the right directory; no duplicate component is being created; line limits are respected; import paths follow the convention |
| `project-validator-expert` | Before the task is declared done | A thorough model — this is the final gate | No hallucinated file, component, or entity; every reference actually exists; structural rules were followed; traceability comments are present; nothing was duplicated |

In this pipeline they are `.aicodepipeline/core/agents/roles/database-validator-expert.md`,
`.../frontend-validator-expert.md`, and `.../project-validator-expert.md`.

#### The schema pre-flight

Runs before a line of database code is written. It checks that the tables and
columns exist, that the entity definitions match the schema that is actually
deployed, that the project's own column-naming convention is used — a project
that spells its key `userid` will get `user_id` from a model that has seen a
thousand other projects, and the query will fail at runtime rather than at
review — that no migration is being introduced without authorization, and that
relationships and constraints are as declared. A fast model is the right tier:
every question it asks has a factual answer.

#### The structure pre-flight

Runs before a component is created. It checks the target directory against the
convention, searches for an existing component that already does the job, and
enforces the line limits and the import-path rules. Also a fast model, and
also for the same reason.

#### The final gate

Runs before the task is declared complete, over the finished diff. It checks
that no file, component or entity was invented; that every reference resolves;
that the structural rules held; that the traceability comments are present;
and that nothing was duplicated. This one needs the thorough tier, because
"is this a duplicate in substance" is a judgement and not a lookup.

**What failure produced it.** Layers 1 and 2 were both in place. The agent had
read the rules, the specialist had carried the rules, and the code still
referenced a `NotificationTemplate` entity that had never existed. The model
was not ignoring the rules; it was following them from a belief about the
codebase that was wrong. No amount of instruction fixes a wrong belief — only
a lookup does.

**What it catches.** Invented references, which is the failure the other three
layers structurally cannot catch, because they all operate on what the model
believes rather than on what is there.

**Why the split into three.** Two reasons, and both are about cost:

- **Placement.** A database check is worth nothing after the code is written —
  by then the wrong query exists and will be patched rather than rethought.
  The pre-flight validators exist to be cheap enough to run *before* the
  writing. The final validator exists because some failures only exist in the
  finished diff.
- **Model tier.** A lookup ("does this column exist?") is a fast-model job. A
  judgement ("is this a duplicate of an existing component, in substance?") is
  not. Running everything on the thorough tier makes validation expensive
  enough that people stop doing it, which is the same as not having it.

**Why it is not enough on its own.** A validator only runs when it is called.
That is the entire weakness, and it is a large one: the agent most likely to
skip the validator is the agent that is confidently wrong, which is exactly
the case the validator exists for. Layer 4 is the response, and hooks are the
eventual response when Layer 4 is not enough either.

**Cost.** The highest of the four. Three extra agent invocations per
substantial task, each with its own context window. On a small change this can
double the token cost. It is worth it in proportion to how expensive the
mistake is: database work and anything with a security boundary, always;
copy-editing a README, never. Make the placement rules explicit or the cost
will get cut by someone who cuts the wrong ones.

---

## Layer 4 — Behavioral protocol

**What it is.** A checklist the main agent runs on itself before writing
anything:

- [ ] Search for an existing implementation before creating a new one
- [ ] Verify every file, table, column, entity and method that will be referenced
- [ ] Confirm the target directory matches the structural convention
- [ ] Call the pre-flight validator for the layer being touched
- [ ] Add the traceability comment to every change
- [ ] Call the final validator before declaring the task complete

**What failure produced it.** The validators existed and were not being
called. Not out of defiance — the model simply reached the end of a task that
felt finished and declared it finished. Nothing in the loop prompted the
question "should I check this?"

**What it catches.** Duplication, above all. "Search before creating" is the
single highest-value line in the list, because duplication is the one failure
mode the other layers do not address: a duplicate component violates no rule,
references nothing that does not exist, and passes a schema check.

**Why it is not enough on its own.** It is self-policing. An agent that
forgets the checklist also forgets that it forgot. Self-policing degrades
exactly when the context is long and the task is complicated, which is when
mistakes happen.

**Cost.** A handful of tool calls per task. Cheap, and the cheapest place to
add a new check.

---

## Why no single layer is enough

The layers are not redundant. Each catches something the others structurally
cannot:

| Failure | L1 Context | L2 Injection | L3 Validators | L4 Protocol |
|---|---|---|---|---|
| Invented database column | no — it is a rule, not a lookup | no — same | **yes** | partly — if the checklist is followed |
| Invented component or service | no | no | **yes** | partly |
| Wrong directory for a feature | **yes** | **yes** | yes, after the fact | yes |
| Import path convention broken | **yes** | **yes** | yes | no |
| Duplicate of an existing component | no | no | yes, in the final pass | **yes** |
| Missing traceability comment | states the rule | states the rule | **yes** | **yes** |
| Rules ignored inside a delegated task | no | **yes** | yes | no |
| Component over the line limit | states the rule | states the rule | **yes** | no |

Read the columns rather than the rows. Layers 1 and 2 are strong on
convention and blind to fact. Layer 3 is the only one that establishes fact.
Layer 4 is the only one that reliably prevents duplication. Remove any column
and a row goes uncovered.

---

## How they compose

### Before the layers

```
User: "Add a notification feature"

Agent: creates src/components/notifications/         (wrong structure)
Agent: references a NotificationTemplate entity      (does not exist)
Agent: no traceability comment on any change
Agent: "Done."

User: "This is in the wrong place and that entity isn't real."
```

Three failures in one task, none of them detectable from the transcript
without knowing the project.

### After the layers

```
User: "Add a notification feature"

[Layer 1] Agent reads the project rules file
[Layer 2] The backend specialist carries the same rules in its definition
[Layer 2] The frontend specialist carries the structural conventions
[Layer 4] Agent searches for an existing NotificationCard before creating one
Agent:    "Found an existing NotificationCard — extending it rather than adding a second."
[Layer 3] Agent calls the database validator on the entities it plans to use
Agent:    "NotificationTemplate does not exist. Using NotificationSetting, which does."
[Layer 3] Agent calls the frontend validator on the target path
Agent:    "Creating src/features/notifications/components/ ..."
Agent:    adds the [WO-0001] traceability comment to each change
[Layer 3] Agent calls the project validator before finishing
Agent:    "Validation passed."
```

The second transcript is longer, and the length is the product. Each of those
lines is a place where the first transcript went wrong silently.

---

## The traceability requirement

Every change carries a comment naming the work order that asked for it, the
date, what changed, and why. It is not a layer of its own — it is what makes
the layers auditable, because a change nobody can trace cannot be validated
against an intent.

```typescript
// [WO-0001] YYYY-MM-DD
// Added notification routing for per-tenant mail configuration
// Reason: support per-tenant configuration overrides
// Related: WO-0002
```

```sql
-- [WO-0003] YYYY-MM-DD
-- Backfilled the is_active flag for existing tenants
-- Reason: align with the activation workflow
```

```jsx
{/* [WO-0004] YYYY-MM-DD
    Created TenantActivityCard for the dashboard
    Reason: reusable activity display
*/}
```

Two things this buys that are not obvious:

- **A reviewer can check the change against its stated reason.** Most reviews
  check whether the code works. This lets a review check whether the code is
  the thing that was asked for, which catches a different and larger class of
  problem.
- **The final validator has something to validate against.** "Traceability
  comments present" is a mechanical check; "does this change belong to any
  request anyone made" is not, unless the answer is written in the diff.

The cost is a comment per change and the discipline to keep it truthful. A
traceability comment naming a work order that does not exist is worse than
none, because it reads as evidence. The pipeline checks this mechanically:
`.aicodepipeline/core/hooks/doc-claims-check.py` refuses traceability
references that point at nothing.

---

## What it costs, honestly

| Cost | Scale | Mitigation |
|---|---|---|
| Context spent on rules | A few thousand tokens per session, plus a section per agent definition | Keep the rules file tight; split detail into per-topic files loaded on demand |
| Extra agent invocations | Up to three per substantial task, each with its own context | Tier the models; make the placement rules explicit so validation is skipped where it cannot pay |
| Latency | Each validator is a round trip; the final one is the slowest | Run pre-flight validators in parallel when they touch different layers |
| Maintenance | One rules file plus a copy of the rules in every agent definition | Generate the injected section; lint that every definition has one |
| False positives | A validator reporting a problem that is not one costs trust, and a distrusted validator is a skipped validator | Make validators report specifics — the file, the line, the missing symbol — never a verdict alone |
| Slower first draft | The second transcript above is longer than the first | This is the product, not the cost. Compare against the rework, not against the first draft |

The honest summary: this design trades tokens and latency for a lower rate of
confidently wrong output. On work where being wrong is cheap — a prototype, a
script nobody will run twice — the trade is bad. On work touching a schema, a
permission boundary, or anything that writes state, it pays for itself the
first time it catches something.

---

## What changes when it is working

### What stops happening

- Hallucinated files, components and entities
- Features in the wrong directory
- A third copy of a component that already existed twice
- Changes with no traceable origin
- Queries against tables and columns that are not there
- Import paths that violate the project convention

### What starts happening

- Search before assuming: existence is verified, not inferred
- Correct structure without being reminded
- Existing components extended rather than reimplemented
- Every change carrying its work order and its reason
- Database assumptions checked before code is generated, not after
- A final verification pass before anything is declared complete

Both lists are observable. If the first list is still happening after the
layers are in place, a layer is being skipped rather than failing — find out
which, before adding a fifth.

---

## The shape of a deployment

```
Agents:                   28
├── Validators:            3
├── Specialists:          25
└── Carrying project rules: 25

Documentation:
├── Project rules file:   one, about 9 KB
└── Per-topic rule files: one per topic, loaded on demand

Layers of defense:         4
Validation checkpoints:    3 (two pre-flight, one final)
```

The counts are illustrative, not prescriptive. What matters is the ratio: a
small number of validators against a large number of specialists, and exactly
one place where a rule is authored.

---

## Maintenance

### When to update the rules file

- A new structural convention emerges and is agreed
- The traceability requirement changes
- A new class of mistake needs a rule

### When to update the agent definitions

- The project's conventions change
- The technology stack changes
- A new compliance requirement lands

### When to add a validator

- A new layer of the stack appears that nothing currently checks
  (infrastructure, for example)
- A specific domain needs a depth of verification the general validator cannot
  reach
- A pattern of violation recurs after the existing layers were in place

That last trigger is the important one and it is worth being strict about:
**add a layer only in response to a failure that got through the existing
ones.** Layers added speculatively cost their full price and catch nothing,
and they dilute the ones that work.

---

## Where this design goes next

Four layers of instruction and verification are all soft: every one of them
depends on an agent choosing to comply. The natural fifth layer is mechanical
enforcement that does not ask — hooks that run whether or not the agent
remembered:

| Mechanism | What it enforces without being asked |
|---|---|
| `.aicodepipeline/core/hooks/doc-claims-check.py` | Traceability references must point at a file that exists; over-claim language is flagged |
| `.aicodepipeline/core/hooks/evidence-gate.py` | A closeout without an executed verification is refused |
| `.aicodepipeline/core/hooks/config-protection.py` | Lint, format and strictness configuration cannot be weakened to make a check pass |
| `.aicodepipeline/core/hooks/commit-quality.py` | Credential-like staged lines are blocked |
| `.aicodepipeline/core/hooks/rules/` | Destructive shell and version-control operations are blocked by pattern |

A hook is strictly stronger than a checklist item, so anything that can be
moved from Layer 4 into a hook should be. What cannot be moved is judgement:
no hook can tell whether a new component duplicates an existing one in
substance. That is why the soft layers do not go away.

---

## Practical notes

### For the agent, at the start of a session

1. Read the project rules file first
2. Search before assuming anything exists
3. Call the validators before declaring anything complete
4. Add the traceability comment to every change

### For the person running it

1. Remind the agent to read the rules if it clearly has not
2. Ask for a validator explicitly when one is skipped
3. Update the rules as the project changes — a stale rule teaches the wrong
   thing with full confidence
4. Trust but verify: the validators are a safety net, not a guarantee

### One operational detail worth knowing

Agent definitions are loaded when the session starts. Editing a definition
mid-session changes nothing until the session is restarted. More than one
confusing afternoon has been spent watching an agent ignore a rule that had
been added an hour earlier and never loaded.

```bash
# After adding or editing an agent definition, a validator, or the rules file:
# 1. exit the agent runtime completely
# 2. start it again
# 3. begin a new session
#
# Agents are loaded at startup, not dynamically. Nothing short of a restart
# picks up a changed definition.
```

### Checking that the layers are actually running

Do not assume. Verify each layer once, deliberately, on a task you can afford
to have go wrong:

Ask for the validator by name the first few times, so you can see whether it
fires at all before you start relying on it firing by itself:

```text
Create a notification feature, then use the project validator to verify it.
```

1. Give a task that touches a table you know does not exist, and confirm the
   schema pre-flight refuses it rather than generating the query
2. Give a task whose obvious implementation is a duplicate of something that
   already exists, and confirm the search happens before the file is created
3. Ask for a component in a deliberately wrong directory, and confirm the
   structure pre-flight moves it
4. Check the diff for traceability comments before accepting the work

If a layer does not fire, the fault is nearly always that the definitions were
edited without a restart, or that the task never reached the agent carrying
the rules.

---

## Checklist for adopting this

- [ ] One rules file exists and is the single source of truth
- [ ] Every specialist agent definition carries the project-context section
- [ ] The injected section is generated or linted, not hand-maintained in twenty-five places
- [ ] A pre-flight validator exists for each layer where invented references are expensive
- [ ] A final validator runs before any task is declared complete
- [ ] Validator model tiers match the work: lookups on a fast tier, judgement on a thorough one
- [ ] The pre-work checklist begins with "search for an existing implementation"
- [ ] Every change carries a traceability comment naming its work order and reason
- [ ] Anything mechanically checkable has been moved from the checklist into a hook
- [ ] Each layer can be traced to the specific failure that caused it to be added
- [ ] No layer was added speculatively

---

## Bottom line

Before: an agent that was confidently wrong at a rate nobody was measuring,
and a person whose job was to find out which parts of each diff were real.

After: four layers that force the agent to read the rules, search before
assuming, check facts against the system rather than against its own belief,
validate before declaring anything finished, and leave a trace of why every
change exists.

The result is not a model that stops being wrong. It is a system in which
being wrong is caught by something other than the reader.

---

## Related

- `.aicodepipeline/core/methodology/PROJECT-RULES.md` — the Layer 1 rules file
- `.aicodepipeline/core/rules/common/` — the per-topic rules the layers inject
- `.aicodepipeline/core/agents/roles/project-validator-expert.md` — the final gate
- `.aicodepipeline/core/agents/roles/database-validator-expert.md` — the pre-flight schema check
- `.aicodepipeline/core/agents/roles/frontend-validator-expert.md` — the pre-flight structure check
- `.aicodepipeline/docs/agent-security.md` — the adjacent question: not "is this true" but "is this safe"
