# Test Inventory and Gap Analysis Methodology

> How to derive a feature catalogue from a suite of behavioral tests, map
> suites to features, classify the coverage, rank what is missing by risk, and
> keep the whole thing from going stale.

The companion to `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`.
That document says how one suite must be written and what its results are
allowed to claim. This one works at the level above: given every suite the
project already has, what does the project actually know about itself, and
what does it only believe.

---

## Table of Contents

1. [Why an Inventory Exists](#why-an-inventory-exists)
2. [The Three Artifacts](#the-three-artifacts)
3. [The Suite Header Convention](#the-suite-header-convention)
4. [The Procedure](#the-procedure)
5. [Coverage Classes](#coverage-classes)
6. [Ranking the Gaps by Risk](#ranking-the-gaps-by-risk)
7. [Keeping the Inventory Fresh](#keeping-the-inventory-fresh)
8. [The Regeneration Script](#the-regeneration-script)
9. [Anti-Patterns](#anti-patterns)
10. [Checklist Before Publishing an Inventory](#checklist-before-publishing-an-inventory)
11. [Worked Example](#worked-example)
12. [Relationship to the Other Methodology Documents](#relationship-to-the-other-methodology-documents)

---

## Why an Inventory Exists

A project accumulates test suites one work order at a time. Each suite knows
what it covers. Nothing knows what all of them cover together, and nothing at
all knows what none of them cover.

That produces four specific failures, and the inventory exists to answer each:

| Failure | The question the inventory answers |
|---|---|
| A feature is demonstrated to a stakeholder and breaks, because nothing tested it | Which features have evidence, and which have only code? |
| Two suites test the same behavior under different names, and both are maintained forever | Which features are verified more than once, and by which suites? |
| A suite is deleted or renamed and its behaviors silently lose their only coverage | Which features would become uncovered if this suite went away? |
| A green run is treated as proof, when half the assertions only checked that a file exists | Which "covered" features are covered by behavior, and which by file shape? |

The inventory is not a test report. It is a map of what the test estate
claims, cross-referenced against what the product is supposed to do. It is
worth building the moment the suite count passes about twenty, and worth
regenerating whenever the suite count changes.

---

## The Three Artifacts

An inventory exercise produces three documents, and they are different things.
Keep them separate; merge them and each stops being usable.

| Artifact | Answers | Shape | Regenerated |
|---|---|---|---|
| **Feature catalogue** | What does the test estate claim to verify? | Feature name, what the system actually does, the suites that verify it | Mechanically, from the suites |
| **Coverage matrix** | For each feature, how good is that claim? | Feature, coverage class, evidence type, last executed | Mechanically, from the suites plus the last results |
| **Gap ranking** | What is not covered, and in what order should that be fixed? | Area, missing behavior, risk score, priority, proposed suite | By hand, reviewed by a person |

The first two are derived and must never be hand-edited: if the catalogue is
wrong, the suite headers are wrong, and the fix belongs there. The third is a
judgement call and is the only one a person writes directly.

Where they live:

```
{{TESTING_DIR}}/
├── suites/                          the suites themselves
├── suites.manifest                  tier | type | file | label, one line per suite
├── inventory/
│   ├── FEATURE-CATALOGUE.md         derived; do not hand-edit
│   ├── COVERAGE-MATRIX.md           derived; do not hand-edit
│   ├── GAP-ANALYSIS.md              written by a person, reviewed by a person
│   └── .fingerprint                 the hash the freshness check compares against
└── results/                         execution evidence
```

---

## The Suite Header Convention

The whole method rests on one convention: **every suite declares, in its own
header, the features it verifies.** A suite without that block cannot be
inventoried mechanically, and section 3 of the procedure exists only because
suites written before the convention do not have one.

```bash
#!/usr/bin/env bash
# ============================================================================
# WO-NNNN: <Feature Area> — Behavioral Test Suite
# ============================================================================
# Features Tested:
# - Account lockout after threshold: locked_until set, 423 returned
# - Counter reset on successful login: failed_login_attempts back to 0
# - Manual unlock: admin endpoint clears the lock and writes an audit row
#
# Evidence:
# - HTTP: real requests to $API_BASE_URL
# - State: SQL read-back against the real database
#
# Preconditions:
# - The application answers on $API_BASE_URL
# - The database is reachable with the configured credentials
# - Seed data has been applied
# ============================================================================
```

Three rules make the block machine-readable and worth reading:

1. One feature per `# - ` line, in the form `<feature name>: <what it proves>`.
   The name before the colon is the catalogue key, so it must be stable —
   renaming it orphans the feature's history.
2. The feature is a **behavior**, not a file. "Account lockout after
   threshold" is a feature. "`AccountLockService` exists" is not; it is a
   structural assertion, and the classification in
   [Coverage Classes](#coverage-classes) treats it as such.
3. The `Evidence:` lines say which kinds of assertion the suite actually
   makes. This is what separates a covered feature from an asserted one, and
   it cannot be inferred reliably from the code.

Suites that orchestrate other suites — the ones whose whole body is a list of
`bash other-suite.sh` calls — declare no features on purpose. Record them in
the inventory as orchestrators so that "missing header" does not read as a
defect.

---

## The Procedure

Ten steps. Steps 1 through 7 are mechanical and belong in a script; steps 8
and 9 are judgement; step 10 is automation again.

### Step 1 — Enumerate the suites

Two enumerations, and they must agree. The filesystem is what exists; the
manifest is what the runner will actually execute. A suite in one and not the
other is a finding before any feature work starts.

```bash
cd "$PROJECT_ROOT"

# What exists on disk
ls -1 {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##' | sort > /tmp/inv-disk.txt
wc -l < /tmp/inv-disk.txt

# What the runner will execute, from the manifest (tier|type|file|label)
grep -v '^\s*#' {{TESTING_DIR}}/suites.manifest | grep -v '^\s*$' \
  | awk -F'|' '{print $3}' | sort > /tmp/inv-manifest.txt
wc -l < /tmp/inv-manifest.txt

# The disagreement, in both directions
comm -23 /tmp/inv-disk.txt /tmp/inv-manifest.txt   # on disk, never run
comm -13 /tmp/inv-disk.txt /tmp/inv-manifest.txt   # listed, does not exist
```

A suite that is on disk and not in the manifest is dead weight that still
looks like coverage in a directory listing. A suite in the manifest that is
not on disk is reported by the runner as SKIP, never as a pass — but it is
easy to read a run summary and not notice.

Record the tier and type while you are here; the ranking in step 9 uses them.

```bash
grep -v '^\s*#' {{TESTING_DIR}}/suites.manifest | grep -v '^\s*$' \
  | awk -F'|' '{printf "%-14s %-10s %s\n", $1, $2, $3}' | sort
```

### Step 2 — Extract the declared features

One pass over the headers produces the raw inventory: one line per
feature-suite pair.

```bash
: > /tmp/inv-raw.tsv
for f in {{TESTING_DIR}}/suites/*.sh; do
  suite=$(basename "$f" .sh)
  awk '
    /^# *Features Tested:/ { inblock = 1; next }
    /^# *=====/            { inblock = 0 }
    /^# *(Evidence|Preconditions|Prerequisites):/ { inblock = 0 }
    inblock && /^# *- / {
      sub(/^# *- /, "");
      print
    }
  ' "$f" | sed "s#\$#\t${suite}#" >> /tmp/inv-raw.tsv
done

wc -l < /tmp/inv-raw.tsv                      # total feature entries
cut -f1 /tmp/inv-raw.tsv | sed 's/:.*//' | sort -u | wc -l   # unique features
```

Split the feature name from its proof clause, because only the name is the key:

```bash
awk -F'\t' '{
  name = $1; sub(/:.*/, "", name);
  proof = $1; sub(/^[^:]*:[[:space:]]*/, "", proof);
  printf "%s\t%s\t%s\n", name, proof, $2
}' /tmp/inv-raw.tsv > /tmp/inv-parsed.tsv
```

### Step 3 — Recover features from suites that declare none

List the suites with no header block. Expect two populations: orchestrators
(fine) and suites written before the convention (not fine).

```bash
grep -L '^# *Features Tested:' {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##'
```

For the second population, recover the features from the assertion labels the
suite already writes. Every suite built on the shared helpers announces each
test with `test_start "<label>"`, and those labels are, in practice, feature
names written by the person who knew what the suite was for.

```bash
suite={{TESTING_DIR}}/suites/wo-NNNN-example.sh

# The labels the suite announces
grep -oE 'test_start "[^"]+"' "$suite" | sed 's/test_start "//; s/"$//'

# The labels its assertions carry, for suites that skip test_start
grep -oE 'assert_(http_code|http_status|json_equals|sql_equals|sql_contains|contains|not_empty|gte) [^#]*"[^"]+"' "$suite" \
  | sed 's/.*"\([^"]*\)"$/\1/'
```

This is recovery, not authorship. Write the recovered list back into the
suite's own header as a `Features Tested:` block in the same commit, so the
recovery never has to be done twice. An inventory that keeps a private list of
features the suites do not declare is a second source of truth, and it will
drift within a month.

Mark every recovered entry in the inventory so a reader knows the provenance
differs:

```bash
# Suites whose feature list was recovered rather than declared
printf '%s\n' wo-NNNN-example wo-NNNN-other > {{TESTING_DIR}}/inventory/.recovered
```

### Step 4 — Deduplicate into the master catalogue

The same behavior gets declared by several suites under slightly different
words. Collapse on a normalized key, keep the longest human name, and union
the suite lists — never drop the second suite, because the point of the
catalogue is to show that a feature has two independent proofs.

```bash
awk -F'\t' '
  { key = tolower($1); gsub(/[^a-z0-9]/, "", key);
    if (!(key in name) || length($1) > length(name[key])) name[key] = $1;
    if (index(suites[key], $3) == 0)
      suites[key] = (suites[key] == "" ? $3 : suites[key] ", " $3);
  }
  END { for (k in name) printf "%s\t%s\n", name[k], suites[k] }
' /tmp/inv-parsed.tsv | sort > /tmp/inv-catalogue.tsv

wc -l < /tmp/inv-catalogue.tsv
```

Then group the rows into feature areas. The areas are the product's own
vocabulary — authentication, session lifecycle, authorization, tenant
isolation, account lifecycle, notifications, audit trail, rate limiting, data
export, webhooks — not the test estate's. Grouping by work-order series
instead produces a catalogue that is organized by the order the work happened
to be done in, which is useless to anyone asking "is sign-in covered?"

Two counts fall out of this step and both belong in the published statistics:
**feature entries** (before dedup) and **unique features** (after). The ratio
is a rough measure of redundancy in the estate.

### Step 5 — Describe each feature

A catalogue of names is nearly worthless six months later, when the person who
wrote "Grace period acceptance" has moved on. Each row gets one paragraph
answering three questions:

- **What triggers it** — the request, the schedule, the event
- **Which components handle it** — the service, the guard, the table
- **How the data flows** — what is read, what is written, what is returned

```
| Grace period acceptance | During the grace window, `SessionRenewalService.verifyRefreshToken()`
  tries the current hash first; if there is no match and the request is inside
  the window, it tries `previous_token_hash`. If that matches and the timestamp
  is within the window, the refresh succeeds. | wo-NNNN-refresh-comprehensive |
```

Write these from the code, not from memory, and do it at inventory time rather
than at suite-writing time — the description is about the system, not about the
test, and it is the artifact that survives the suite being rewritten.

A row whose description cannot be written is a finding in itself: nobody
currently knows what the feature is, and its suite is verifying something
nobody can state. Leave the cell explicitly empty rather than inventing a
description, and count the empty cells.

### Step 6 — Classify coverage

Every catalogue row gets exactly one class. The classes are defined in
[Coverage Classes](#coverage-classes); the mechanics are here.

The class depends on two inputs: what kind of assertion the suite makes, and
whether the suite was actually executed.

```bash
# Which suites make real HTTP requests at all
grep -l -E 'curl|http_get|http_post|assert_http' {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##' | sort > /tmp/inv-http.txt

# Which suites read state back out of the data store
grep -l -E 'assert_sql|psql|sql_query' {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##' | sort > /tmp/inv-state.txt

# Which suites assert only on the shape of the source tree
comm -23 <(ls -1 {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##' | sort) /tmp/inv-http.txt > /tmp/inv-structural.txt
cat /tmp/inv-structural.txt
```

That last list is the important one. A suite that never sends a request cannot
have verified a behavior, whatever its feature header says. Its features are
`ASSERTED` at best — the file exists, the symbol is exported, the column is in
the schema — and the inventory has to say so, because a reader scanning a
column of "covered" will otherwise take them for behavior.

Then join against the last recorded execution:

```bash
# Latest result file per suite, and the status it recorded
for s in $(cut -f1 -d' ' /tmp/inv-disk.txt); do
  latest=$(ls -1t {{TESTING_DIR}}/results/*"${s%.sh}"* 2>/dev/null | head -1)
  if [ -z "$latest" ]; then
    printf '%s\tNEVER EXECUTED\t-\n' "$s"
  else
    status=$(grep -oE 'EXECUTED — (PASS|FAIL)|NOT EXECUTED — (PLAN ONLY|PRECONDITION FAILED)' "$latest" | head -1)
    printf '%s\t%s\t%s\n' "$s" "${status:-UNKNOWN}" "$latest"
  fi
done
```

The statuses come from `MANDATORY-TESTING-METHODOLOGY.md` and are the same
five words used everywhere else. Do not invent a sixth for the inventory.

### Step 7 — Build the reverse index

The catalogue maps feature to suites. The reverse index maps suite to features
and to a count, and it is what tells you the blast radius of deleting or
skipping a suite.

```bash
awk -F'\t' '{ c[$3]++ } END { for (s in c) printf "%s\t%d\n", s, c[s] }' \
  /tmp/inv-parsed.tsv | sort -k2 -rn
```

Two readings matter:

- A suite with a very high feature count is usually a suite that asserts on
  structure. Thirty "features" in one file is a shape check, not thirty
  behaviors.
- A feature verified by exactly one suite has a single point of failure. If
  that suite is in the `recent` tier, or is on the structural list, the
  feature is effectively uncovered.

### Step 8 — Find the gaps

Up to here the inventory has only looked at tests. A gap analysis needs the
other catalogue: what the product is supposed to do. That comes from the work
order record, not from the code.

```bash
# Every work order that has ever been opened
ls -1d {{WORKORDERS_DIR}}/*/ | sed 's#.*/\([^/]*\)/#\1#' | sort > /tmp/inv-wos.txt
wc -l < /tmp/inv-wos.txt

# Every work order prefix that has at least one suite
ls -1 {{TESTING_DIR}}/suites/*.sh | sed 's#.*/##' | grep -oE '^wo-[0-9]+' | sort -u > /tmp/inv-tested.txt
wc -l < /tmp/inv-tested.txt

# The gap
comm -23 <(sed 's/^\(WO-[0-9]*\).*/\1/' /tmp/inv-wos.txt | tr 'A-Z' 'a-z' | sort -u) /tmp/inv-tested.txt
```

Express the result as a percentage and do not soften it. "About three quarters
of the work orders have no behavioral test" is a true and useful sentence; "we
have good coverage of the core" is neither.

Then, for each untested area, write one row per behavior that a suite would
have to prove. This is where the judgement is: a work order with no suite is
not automatically a gap — it may have been superseded, may be documentation
only, may be covered incidentally by a suite filed under another number. Check
before you list it.

### Step 9 — Rank the gaps by risk

See [Ranking the Gaps by Risk](#ranking-the-gaps-by-risk) for the formula. The
output is a single ordered list with a priority column, and it is the only
part of the inventory anyone will act on. Keep it short enough to act on:
roughly the top twenty.

### Step 10 — Keep it fresh

See [Keeping the Inventory Fresh](#keeping-the-inventory-fresh). Automate the
staleness check or the inventory will be a snapshot of a Tuesday in a quarter
nobody remembers.

---

## Coverage Classes

Five classes. Every catalogue row is exactly one of them, and the fourth is
the one the whole exercise exists to surface.

| Class | Definition | Evidence required | Reads as |
|---|---|---|---|
| `COVERED` | A suite sends a real request and reads the resulting state back out of the real store, and the suite's last run was `EXECUTED — PASS` | Response plus state query plus a dated result file | The behavior works |
| `PARTIAL` | The behavior is exercised but one half of the proof is missing — the request is made and the response checked, but the state is never read back; or the state is checked but the trigger was simulated | Whatever exists, plus a note of what is missing | The behavior probably works |
| `ASSERTED` | The only assertions are structural: a file exists, a symbol is exported, a column is in the schema, a string appears in the source | The grep or file check | The code is shaped correctly. Nothing about behavior |
| `UNCOVERED` | No suite declares it, or the only suite that does has never been executed | None | Nothing is known |
| `MANUAL` | It can be verified, but not by this harness — it needs a browser, a real mail server, a physical device, a third-party sandbox | A runbook naming the steps and who ran them last | Someone has to do it by hand |

Two rules about the classes:

- **`ASSERTED` is not a kind of covered.** It is closer to uncovered, and the
  published statistics must count it separately. A feature that is only
  asserted is a feature whose implementation could be entirely wrong while the
  suite stays green. A structural assertion is still worth having — it catches
  a deleted export, a dropped column, a renamed file — but it is a build check
  wearing a test's name.
- **`MANUAL` is honest, not a failure.** Some things genuinely cannot be
  automated with the tools at hand, and writing `MANUAL` beside them with a
  runbook reference is better than an automated suite that pretends. What is
  not acceptable is `MANUAL` with no runbook: that is `UNCOVERED` with better
  manners.

### Example classification decisions

| Feature as declared | Class | Why |
|---|---|---|
| Account lockout after threshold — request returns 423 and `locked_until` is set in the row | `COVERED` | Real request, real state read-back |
| Token rotation on refresh — response carries a new token | `PARTIAL` | The new token is checked; the old one is never replayed, so rotation is not proven to have invalidated anything |
| Password service structure (hash, verify, needsRehash) | `ASSERTED` | A grep over the source file; no password is ever hashed |
| SDK directory structure | `ASSERTED` | A directory listing |
| Cross-site request forgery: cookie and header must match | `MANUAL` | The harness's client does not enforce same-origin policy; needs a browser |
| Concurrent session limit | `UNCOVERED` | No suite declares it |

---

## Ranking the Gaps by Risk

Ordering gaps by how loudly someone complained produces a list that gets
reordered every week. Score them instead, on three axes that a reviewer can
argue about with evidence.

| Axis | 1 | 3 | 5 |
|---|---|---|---|
| **Impact** — what happens if this regresses silently | Cosmetic; a user notices and works around it | A workflow is blocked; support can unblock it | Data loss, a security boundary crossed, or money moves wrongly |
| **Exposure** — who can reach it | Internal tooling behind an operator login | Any authenticated user | Unauthenticated, internet-facing |
| **Latency of detection** — how long before anyone notices without a test | Immediate; the screen is blank | Days; a report looks odd | Indefinite; it fails silently and correctly-looking data is written |

```
risk = impact x exposure x detection      (1 .. 125)

P0   risk >= 60     blocks the next release
P1   risk 30 .. 59  scheduled this cycle
P2   risk < 30      backlog
```

Two adjustments, applied after the multiplication:

- **Single-suite features promote by one level.** If the only proof is one
  suite and that suite is in the `recent` tier or on the structural list, the
  feature is one rename away from uncovered.
- **Reversibility demotes by one level.** A gap in something that can be
  undone with a redeploy is less urgent than the same score in something that
  writes irreversible state.

Record the three scores in the gap table, not just the product. A reviewer who
disagrees needs to see which axis they disagree on.

---

## Keeping the Inventory Fresh

A derived document that is regenerated by hand is regenerated once. Bind it to
the thing it describes.

### The fingerprint

Hash the inputs — the suites and the manifest — and store the hash in the
inventory. Anything that changes a suite changes the hash.

```bash
fingerprint() {
  { cat {{TESTING_DIR}}/suites.manifest
    find {{TESTING_DIR}}/suites -name '*.sh' -type f -exec shasum -a 256 {} + | sort
  } | shasum -a 256 | cut -d' ' -f1
}

fingerprint > {{TESTING_DIR}}/inventory/.fingerprint
```

### The staleness check

```bash
#!/usr/bin/env bash
# inventory-freshness — exit 1 when the catalogue no longer describes the suites
set -euo pipefail

recorded=$(cat {{TESTING_DIR}}/inventory/.fingerprint 2>/dev/null || echo none)
current=$(fingerprint)

if [ "$recorded" != "$current" ]; then
  echo "Inventory is stale: the suites changed since it was generated."
  echo "  recorded: $recorded"
  echo "  current:  $current"
  echo "Regenerate with: {{TESTING_DIR}}/inventory/regenerate.sh"
  exit 1
fi
echo "Inventory is current."
```

Wire it in at the two points where staleness costs something:

| Point | What it does |
|---|---|
| Pre-commit, when a file under `suites/` is staged | Warns that the inventory needs regenerating; does not block |
| CI, on every pull request | Fails the job, because a merged suite with no catalogue entry is invisible from then on |
| Work order close | The closeout references the catalogue; a stale catalogue means the closeout cites a document that no longer describes the estate |

### What "fresh" does not mean

A current fingerprint says the catalogue matches the suites. It says nothing
about whether the suites match the product. The gap analysis — step 8 — is not
covered by the fingerprint and has to be revisited deliberately, once a
release cycle, by a person. Put the review date in the document header and
treat a gap analysis older than a cycle as unreviewed rather than as agreed.

---

## The Regeneration Script

Everything mechanical, in one runnable file. Put it at
`{{TESTING_DIR}}/inventory/regenerate.sh` and never hand-edit its outputs.

```bash
#!/usr/bin/env bash
# regenerate — rebuild the derived halves of the test inventory
set -euo pipefail

SUITES="{{TESTING_DIR}}/suites"
MANIFEST="{{TESTING_DIR}}/suites.manifest"
OUT="{{TESTING_DIR}}/inventory"
mkdir -p "$OUT"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# --- 1. enumerate -----------------------------------------------------------
ls -1 "$SUITES"/*.sh | sed 's#.*/##' | sort > "$tmp/disk.txt"
grep -v '^\s*#' "$MANIFEST" | grep -v '^\s*$' | awk -F'|' '{print $3}' | sort > "$tmp/manifest.txt"

# --- 2. extract declared features -------------------------------------------
: > "$tmp/raw.tsv"
for f in "$SUITES"/*.sh; do
  suite=$(basename "$f" .sh)
  awk '
    /^# *Features Tested:/ { inblock = 1; next }
    /^# *=====/ { inblock = 0 }
    /^# *(Evidence|Preconditions|Prerequisites):/ { inblock = 0 }
    inblock && /^# *- / { sub(/^# *- /, ""); print }
  ' "$f" | sed "s#\$#\t${suite}#" >> "$tmp/raw.tsv"
done

awk -F'\t' '{
  name = $1; sub(/:.*/, "", name);
  proof = $1; sub(/^[^:]*:[[:space:]]*/, "", proof);
  printf "%s\t%s\t%s\n", name, proof, $2
}' "$tmp/raw.tsv" > "$tmp/parsed.tsv"

# --- 3. suites with no header ------------------------------------------------
grep -L '^# *Features Tested:' "$SUITES"/*.sh | sed 's#.*/##' | sort > "$tmp/noheader.txt"

# --- 4. evidence classes -----------------------------------------------------
grep -l -E 'curl|http_get|http_post|assert_http' "$SUITES"/*.sh | sed 's#.*/##' | sort > "$tmp/http.txt"
grep -l -E 'assert_sql|psql'                     "$SUITES"/*.sh | sed 's#.*/##' | sort > "$tmp/state.txt"
comm -23 "$tmp/disk.txt" "$tmp/http.txt" > "$tmp/structural.txt"

# --- 5. dedupe into the catalogue -------------------------------------------
awk -F'\t' '
  { key = tolower($1); gsub(/[^a-z0-9]/, "", key);
    if (!(key in name) || length($1) > length(name[key])) name[key] = $1;
    if (index(suites[key], $3) == 0)
      suites[key] = (suites[key] == "" ? $3 : suites[key] ", " $3);
  }
  END { for (k in name) printf "%s\t%s\n", name[k], suites[k] }
' "$tmp/parsed.tsv" | sort > "$tmp/catalogue.tsv"

# --- 6. write the catalogue --------------------------------------------------
{
  echo "# Feature Catalogue (derived — do not hand-edit)"
  echo
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Suites: $(wc -l < "$tmp/disk.txt" | tr -d ' ')"
  echo "Feature entries: $(wc -l < "$tmp/raw.tsv" | tr -d ' ')"
  echo "Unique features: $(wc -l < "$tmp/catalogue.tsv" | tr -d ' ')"
  echo
  echo '| Feature | Verified by |'
  echo '|---|---|'
  awk -F'\t' '{printf "| %s | %s |\n", $1, $2}' "$tmp/catalogue.tsv"
} > "$OUT/FEATURE-CATALOGUE.md"

# --- 7. write the coverage matrix -------------------------------------------
{
  echo "# Coverage Matrix (derived — do not hand-edit)"
  echo
  echo '| Suite | In manifest | Evidence | Last status |'
  echo '|---|---|---|---|'
  while read -r s; do
    inman=no;  grep -qxF "$s" "$tmp/manifest.txt" && inman=yes
    ev=structural
    grep -qxF "$s" "$tmp/http.txt"  && ev=http
    grep -qxF "$s" "$tmp/state.txt" && ev="http + state"
    latest=$(ls -1t {{TESTING_DIR}}/results/*"${s%.sh}"* 2>/dev/null | head -1 || true)
    if [ -z "$latest" ]; then
      status="NEVER EXECUTED"
    else
      status=$(grep -oE 'EXECUTED — (PASS|FAIL)|NOT EXECUTED — (PLAN ONLY|PRECONDITION FAILED)' "$latest" | head -1)
      status=${status:-UNKNOWN}
    fi
    printf '| %s | %s | %s | %s |\n' "$s" "$inman" "$ev" "$status"
  done < "$tmp/disk.txt"
} > "$OUT/COVERAGE-MATRIX.md"

# --- 8. fingerprint ----------------------------------------------------------
{ cat "$MANIFEST"; find "$SUITES" -name '*.sh' -type f -exec shasum -a 256 {} + | sort; } \
  | shasum -a 256 | cut -d' ' -f1 > "$OUT/.fingerprint"

echo "Catalogue:      $OUT/FEATURE-CATALOGUE.md"
echo "Coverage:       $OUT/COVERAGE-MATRIX.md"
echo "Suites on disk: $(wc -l < "$tmp/disk.txt" | tr -d ' ')"
echo "No header:      $(wc -l < "$tmp/noheader.txt" | tr -d ' ')"
echo "Structural:     $(wc -l < "$tmp/structural.txt" | tr -d ' ')"
```

Coverage as a percentage of a verification document — a different and narrower
question — is already answered by
`{{PIPELINE_ROOT}}/harness/scripts/calculate-coverage.js`, which reads one
verification document and reports how much of it was actually executed. The
inventory is the estate-wide view; that script is the per-work-order view. Use
both; do not reimplement either.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Instead |
|---|---|---|
| Hand-maintaining the catalogue | It is correct for one week and then quietly lies | Derive it; fix the suite headers |
| Counting `ASSERTED` features as covered | Turns a shape check into a claim about behavior | Count the classes separately and publish both numbers |
| Organizing the catalogue by work-order series | Organizes by the order work happened in, not by what the product does | Group by feature area |
| One row per assertion | Produces a catalogue with three hundred rows for one feature | One row per behavior; the assertions are the suite's business |
| A gap list of a hundred items | Nobody acts on it | Rank, cut to the top twenty, revisit next cycle |
| "Coverage: 86%" with no denominator stated | The number means nothing; 86% of what? | State the denominator every time: features, behaviors, or work orders |
| Marking a gap closed when the suite is written | The suite exists; nothing says it passed | Closed when the suite's last run is `EXECUTED — PASS` |
| Inventing a description for a feature nobody understands | Puts a plausible sentence where a finding belongs | Leave the cell empty and count it |

---

## Checklist Before Publishing an Inventory

- [ ] Every suite on disk appears in the manifest, or is listed as deliberately excluded
- [ ] Every suite in the manifest exists on disk
- [ ] Every suite has a `Features Tested:` header, or is recorded as an orchestrator
- [ ] Features recovered from assertion labels were written back into the suite header in the same change
- [ ] The catalogue was generated by the script, not edited by hand
- [ ] Feature entries and unique features are both reported, with the difference explained
- [ ] Every catalogue row carries exactly one coverage class
- [ ] `ASSERTED` features are counted separately from `COVERED` and the difference is stated in the summary
- [ ] Every `MANUAL` row names the runbook and who last ran it
- [ ] Every coverage percentage states its denominator
- [ ] The gap list is ranked, with impact, exposure and detection recorded per row
- [ ] The fingerprint was written and the freshness check passes
- [ ] The gap analysis carries a review date inside the current release cycle

---
## Worked Example

Everything below is invented: a fictional order-management service, its suites,
its counts and its rankings were written for this document and describe no real
system. It is here because the procedure above is easy to agree with and hard
to picture, and because a worked example has to carry real arithmetic to be
worth reading — every count, percentage and risk score below is computed from
the tables that follow it.

The example platform sells things: accounts, a catalogue, orders, payments,
refunds, outbound messages, an audit trail and a reporting surface. Substitute
your own feature areas; the shape of the output does not change.

### The example at a glance

| Metric | Count |
|---|---|
| Total suite files | 24 |
| Suites with a `Features Tested:` header | 16 (66.7%) |
| Suites with no header | 8 (33.3%) |
| Feature entries declared (before dedup) | 82 |
| Unique features after dedup | 72 |
| Features recovered from suite code (step 3) | 8 |
| Rows in the master catalogue | 80 |
| Catalogue rows with no description on record | 2 |
| Items requiring manual verification | 5 |
| Work orders opened, all time | 60 |
| Work orders with at least one suite | 22 unique prefixes |
| Work orders with no suite | 38 |
| **Coverage gap** | **63.3% of work orders have no behavioral test** |

The two feature counts are the ones people misread. 82 is how many times a
suite claimed a feature; 72 is how many distinct features those claims cover.
The difference — 10 — is the redundancy in the estate, and it is small, which
in this example is a bad sign rather than a good one: almost nothing is
verified twice, so almost every feature has a single point of failure.

The catalogue holds 80 rows rather than 72 because step 3 recovered 8 further
features from three suites that declare no header. Two of those rows carry
_"Declared in the suite header; no description on record"_ rather than an
invented sentence, which is the rule from step 5: a feature that is verified
but undocumented is recorded as exactly that.

### The example numbering

Suites are named after the work order that produced them, and the series carry
meaning. This is the mapping used throughout the example:

| Series | Area | Suites |
|---|---|---|
| WO-0100 | Accounts and sign-in | 5 |
| WO-0200 | Access control | 3 |
| WO-0300 | Catalogue and inventory | 2 |
| WO-0400 | Orders | 6 |
| WO-0500 | Payments and refunds | 3 |
| WO-0600 | Messaging | 1 |
| WO-0700 | Audit trail | 2 |
| WO-0800 | Reporting and export | 2 |
| WO-0900 | Account data isolation | 0 |
| WO-1000 | Administrative console | 0 |

Twenty-four suite files, but only 22 distinct work-order prefixes: WO-0402
produced three of them.

---

### Master feature catalogue

One row per feature, grouped by feature area. The description column answers
what triggers the feature, which components handle it, and how the data flows.
A row whose description reads _"Declared in the suite header; no description
on record"_ is a step-5 finding, not an oversight in transcription: the feature
is verified by a suite, and nobody has written down what it does.

### Account registration

| Feature | What the system actually does | Verified by |
|---|---|---|
| Account creation | `POST /accounts` with `{email, name}` calls `BuyerService.create()`, which inserts into `org.accounts` with `status = 'pending'` and returns the new identifier. A duplicate email returns 409 without creating a second row. | wo-0101-account-create |
| Email uniqueness | `org.accounts.email` carries a unique index. `BuyerService.create()` catches the constraint violation and converts it into a 409 with code `ACCOUNT_EXISTS`, so the caller cannot distinguish a race from a plain duplicate. | wo-0101-account-create |
| Activation link is single-use | `BuyerService.activate()` clears `activation_token` in the same statement that sets `status = 'active'`. A second call with the same token finds no matching row and returns 410. | wo-0101-account-create |
| Activation link expiry | `activation_expires_at` is set to `NOW() + ACTIVATION_WINDOW_HOURS` (default 24). Past that, activation returns 410 and the row stays `pending`. | wo-0101-account-create |
| Account closure | `DELETE /accounts/:id` sets `status = 'closed'` and `closed_at`; the row is never removed, because orders reference it. Closed accounts cannot sign in. | wo-0101-account-create |
| Registration rate limit | Registration is capped at 3 per hour per source address. The fourth attempt returns 429 with a `Retry-After` header. The limit is read from configuration, not written into the handler. | wo-0101-account-create |
| Account name normalisation | Declared in the suite header; no description on record. | wo-0101-account-create |

### Sign-in and session

| Feature | What the system actually does | Verified by |
|---|---|---|
| Happy path sign-in | `POST /sessions` with valid credentials returns 200, a session identifier, and an expiry. A row appears in `org.sessions` with `status = 'active'`. | wo-0102-account-signin |
| Invalid credentials | A wrong secret returns 401 with a single generic message, and no session row is written. The message is identical whether the account exists or not. | wo-0102-account-signin |
| Failure counter increments | Each failure runs `UPDATE org.accounts SET signin_failures = signin_failures + 1`. The counter is read back out of the database, not inferred from the response. | wo-0103-signin-lockout |
| Counter resets on success | A successful sign-in sets `signin_failures = 0` and `locked_until = NULL` in the same statement that creates the session. | wo-0103-signin-lockout |
| Lock after the failure limit | When `signin_failures` reaches `SIGNIN_FAILURE_LIMIT` (default 10), `BuyerService.lock()` writes `locked_until = NOW() + SIGNIN_LOCK_MINUTES`. Further attempts return 423 before the secret is checked. | wo-0103-signin-lockout |
| Lock expiry | Once `locked_until` is in the past, sign-in is attempted normally again. The lock is not cleared by a background job; it is cleared by the next successful sign-in. | wo-0103-signin-lockout |
| Administrative unlock | `POST /admin/accounts/:id/unlock` clears both fields and writes an `account.unlocked` row to the audit trail carrying the acting identity. | wo-0103-signin-lockout |
| Session expiry | `org.sessions.expires_at` is enforced on every read. An expired session returns 401 and is marked `status = 'expired'` on the next sweep. | wo-0104-session-lifecycle |
| Sign-out revokes | `DELETE /sessions/current` sets `status = 'revoked'` and `revoked_at`. A request replaying the old session identifier returns 401. | wo-0104-session-lifecycle |
| Active sessions are preserved | The cleanup sweep only touches rows where `expires_at < NOW()` or `status <> 'active'`. A session with a future expiry is never archived. | wo-0104-session-lifecycle |

### Access control

| Feature | What the system actually does | Verified by |
|---|---|---|
| Role assignment | `POST /accounts/:id/roles` calls `AccessPolicyService.assignRole()`, which inserts into `org.account_roles` and invalidates the cached decision for that account. | wo-0201-role-assignment |
| Role removal takes effect immediately | Removing a role deletes the join row and drops the cache entry in the same request, so the next call by that account is refused without waiting for a cache expiry. | wo-0201-role-assignment |
| Unknown role is rejected | Assigning a role key that does not exist returns 422 and writes nothing, rather than creating the role implicitly. | wo-0201-role-assignment |
| Permission check on a protected route | Every protected handler declares the permission it needs. `AccessPolicyService.can()` resolves the account's roles to a permission set and returns 403 when the permission is absent. | wo-0202-permission-checks |
| Deny wins over allow | When one role grants `orders:write` and another denies it, the deny is applied. The resolution order is asserted in both directions. | wo-0202-permission-checks |
| Permission inheritance through role groups | A group's roles are unioned into the member's permission set, and the union is asserted rather than the group membership alone. | wo-0201-role-assignment |
| Anonymous access is refused | A request with no session to a protected route returns 401, not 403, and is not recorded as a permission failure. | wo-0202-permission-checks |

### Catalogue and inventory

| Feature | What the system actually does | Verified by |
|---|---|---|
| Catalogue listing | `GET /catalog` calls `StoreCatalogService.list()` with pagination. The response carries a total count that matches `SELECT count(*) FROM catalog_items WHERE published`. | wo-0301-catalog-read |
| Unpublished items are hidden | `published = false` rows are excluded from the public listing and return 404 on direct read, so an identifier cannot be used to probe for unreleased items. | wo-0301-catalog-read |
| Price is read from the catalogue, not the request | `PricingService.quote()` ignores any price in the request body and reads `catalog_items.unit_price` server-side. A tampered price is asserted to have no effect. | wo-0301-catalog-read |
| Currency consistency | An order may not mix currencies. `PricingService.quote()` returns 422 when the requested items disagree. | wo-0301-catalog-read |
| Inventory hold on add-to-order | `InventoryService.hold()` inserts into `inventory_holds` with `expires_at = NOW() + ORDER_HOLD_MINUTES` and decrements the available count in the same transaction. | wo-0302-inventory-reservation (recovered) |
| Hold expiry returns stock | Expired holds are swept and the available count is restored. The count is read back out of the database after the sweep. | wo-0302-inventory-reservation (recovered) |
| Oversell is refused | When the held plus requested quantity exceeds stock on hand, the request returns 409 and no hold row is written. | wo-0302-inventory-reservation (recovered) |

### Order creation

| Feature | What the system actually does | Verified by |
|---|---|---|
| Order creation | `POST /orders` calls `OrderService.create()`, which writes one `orders` row with `status = 'draft'` and one `order_items` row per line, inside a single transaction. | wo-0401-order-create |
| Empty order is refused | An order with no lines returns 422 and writes nothing. The absence of an `orders` row is asserted, not assumed. | wo-0401-order-create |
| Line totals are computed server-side | `OrderService.create()` recomputes `order_items.line_total` from quantity and the catalogue price, and `orders.total` from the lines. A client-supplied total is discarded. | wo-0401-order-create |
| Order number allocation | Each order receives a sequential, non-guessable public number from `OrderService.allocateNumber()`. Two orders created concurrently are asserted to receive different numbers. | wo-0401-order-create |
| Draft orders are invisible to fulfilment | A `draft` order does not appear in the fulfilment queue. The queue read is asserted directly rather than through the user interface. | wo-0401-order-create |
| Submission moves the order to `placed` | `POST /orders/:id/submit` transitions `draft` to `placed`, stamps `placed_at`, and converts the inventory holds into allocations. | wo-0401-order-create |
| Quantity bounds | A line quantity of zero, a negative quantity, or one above the per-line maximum returns 422 with the offending field named. | wo-0403-order-items-pricing |
| Discount application | `PricingService.applyDiscount()` reduces the order total and records the discount code on the order, so the reduction can be explained later from the row alone. | wo-0403-order-items-pricing |

### Order lifecycle

| Feature | What the system actually does | Verified by |
|---|---|---|
| Legal transitions only | `OrderService.transition()` consults a transition table. `placed → packed → shipped → delivered` is permitted; `placed → delivered` returns 409 and leaves `status` untouched. | wo-0402-order-lifecycle |
| Transition writes history | Every accepted transition inserts an `order_events` row carrying the previous status, the new status, and the acting identity. | wo-0402-order-lifecycle |
| Shipment creation | Moving to `shipped` calls `ShipmentService.create()`, which writes a `shipments` row with a carrier reference and links it to the order. | wo-0402-order-lifecycle |
| Delivery is terminal | A delivered order refuses every further transition except a refund, which is modelled separately rather than as a status change. | wo-0402-order-lifecycle |
| Concurrent transition is serialised | Two simultaneous transitions on one order are asserted to produce exactly one status change; the loser receives 409. | wo-0402-order-lifecycle |
| Cancellation before shipment | `POST /orders/:id/cancel` on a `draft` or `placed` order sets `status = 'cancelled'`, releases the allocations, and returns the stock. | wo-0402-order-cancel |
| Cancellation after shipment is refused | A `shipped` order returns 409 on cancel; the suite asserts the status is still `shipped` afterwards. | wo-0402-order-cancel |
| Cancellation reason is required | Cancelling without a reason returns 422. The stored reason is read back from the `orders` row. | wo-0402-order-cancel |
| Cancelled orders leave the fulfilment queue | The queue is re-read after cancellation and asserted not to contain the order. | wo-0402-order-cancel |

### Payments and refunds

| Feature | What the system actually does | Verified by |
|---|---|---|
| Authorisation on submit | Submitting an order calls `PaymentGatewayService.authorize()` and writes a `payments` row with `status = 'authorized'` and the gateway reference. | wo-0501-payment-capture |
| Capture on shipment | Moving to `shipped` calls `PaymentGatewayService.capture()`. The `payments` row moves to `captured` and `captured_at` is stamped. | wo-0501-payment-capture |
| Capture is idempotent | A repeated capture with the same idempotency key returns the original result and does not write a second `payments` row. The row count is asserted. | wo-0501-payment-capture |
| Declined authorisation blocks submission | A declined authorisation leaves the order in `draft`, returns 402, and records the decline reason on the `payments` row. | wo-0501-payment-capture |
| Gateway timeout does not double-charge | A timed-out authorisation is reconciled on the next sweep against the gateway reference rather than retried blindly. | wo-0501-payment-capture |
| Amount matches the order total | The captured amount is asserted equal to `orders.total` at the moment of capture, so a later order edit cannot silently change what was charged. | wo-0501-payment-capture |
| Refund creation | `POST /orders/:id/refunds` calls `RefundService.create()`, which writes a `refunds` row and calls the gateway. The order gains a `refunded_total`. | wo-0502-refund-flow |
| Partial refunds accumulate | Two partial refunds sum into `refunded_total`; the suite reads the column rather than adding the responses. | wo-0502-refund-flow |
| Over-refund is refused | A refund that would take `refunded_total` above `orders.total` returns 422 and writes no `refunds` row. | wo-0502-refund-flow |
| Refund of an uncaptured payment | Refunding an authorised-but-uncaptured payment voids the authorisation instead of issuing a refund, and the `payments` row moves to `voided`. | wo-0502-refund-flow |

### Messaging

| Feature | What the system actually does | Verified by |
|---|---|---|
| Order confirmation is dispatched | Submission enqueues a confirmation through `MessageDispatchService.send()`. A `messages` row appears with `status = 'queued'` and the template key. | wo-0601-message-dispatch |
| Template renders its variables | The rendered body is read back from the `messages` row and asserted to contain the order number, not the placeholder. | wo-0601-message-dispatch |
| Delivery status is recorded | The provider callback moves the `messages` row to `delivered` or `failed` and records the provider identifier. | wo-0601-message-dispatch |
| Failed sends are retried with a budget | A failed send is retried up to the configured attempt limit, and the attempt count is read from the row. Past the budget the row stays `failed`. | wo-0601-message-dispatch |
| Unsubscribed recipients are skipped | A recipient who has opted out produces no `messages` row at all, rather than a suppressed send. | wo-0601-message-dispatch |
| Dispatch is asynchronous | The submission response does not wait on the provider; the suite asserts the response time is unaffected by a slow provider. | wo-0601-message-dispatch |
| Link in the message resolves | MANUAL — a person opens the mailbox and follows the link. See the manual items table below. | wo-0601-message-dispatch |

### Audit trail

| Feature | What the system actually does | Verified by |
|---|---|---|
| Administrative actions are recorded | Every administrative write inserts an `audit.activity_log` row with the action, the target, the acting identity and the source address. | wo-0701-audit-trail |
| The acting identity is the human, not the service | When an administrator acts, the row carries the administrator's identifier; the service account is recorded separately as the channel. | wo-0701-audit-trail |
| Failed authorisation is recorded | A 403 writes an `access.denied` row, so a probe leaves a trace even though it changed nothing. | wo-0701-audit-trail |
| Audit rows are append-only | The application role holds no `UPDATE` or `DELETE` grant on `audit.activity_log`. The suite attempts an update and asserts it is refused. | wo-0701-audit-trail |
| Payload redaction | Secrets and payment details are redacted before the row is written. The suite asserts the stored payload does not contain the submitted secret. | wo-0701-audit-trail |
| Retention sweep | Rows past the retention window are archived rather than deleted, and the archive count is asserted to match the removed count. | wo-0702-audit-retention (recovered) |
| Retention respects a legal hold | An account under hold is skipped by the sweep; its rows are asserted still present afterwards. | wo-0702-audit-retention (recovered) |

### Reporting and export

| Feature | What the system actually does | Verified by |
|---|---|---|
| Report build | `ReportBuilderService.build()` aggregates orders over a date range into `reporting.order_summary` and returns a report identifier. | wo-0801-report-build |
| Totals reconcile with the source | The report total is asserted equal to `SELECT sum(total) FROM orders` over the same range, so an aggregation bug cannot pass. | wo-0801-report-build |
| Empty range returns an empty report | A range with no orders produces a report with zero rows and a zero total, not an error. | wo-0801-report-build |
| Report generation is bounded | A range wider than the configured maximum returns 422 rather than attempting the query. | wo-0801-report-build |
| Reports are scoped to the requesting account | Declared in the suite header; no description on record. | wo-0801-report-build |
| Export download | `GET /exports/:id` streams the built file once the report is `ready`, and returns 409 while it is still building. | wo-0802-export-download (recovered) |
| Export links expire | A download link past `expires_at` returns 410. The suite asserts the row is still present, so the expiry is enforced and not a deletion. | wo-0802-export-download (recovered) |
| Export contains only the requester's rows | The exported file is parsed and every row is asserted to belong to the requesting account. | wo-0802-export-download (recovered) |

---

### Suite reference index

The reverse index from step 7: one row per suite that declares a header, the
area it covers, and how many features it declares. Read the feature count as a
warning as much as a credit — a suite declaring far more features than its
neighbours is usually asserting on structure rather than behavior.

| Suite file | Feature area | Features declared |
|---|---|---|
| wo-0101-account-create.sh | Account registration | 6 |
| wo-0102-account-signin.sh | Sign-in | 6 |
| wo-0103-signin-lockout.sh | Sign-in lockout | 5 |
| wo-0104-session-lifecycle.sh | Session lifecycle | 5 |
| wo-0201-role-assignment.sh | Role assignment | 5 |
| wo-0202-permission-checks.sh | Permission checks | 5 |
| wo-0301-catalog-read.sh | Catalogue reads | 4 |
| wo-0401-order-create.sh | Order creation | 6 |
| wo-0402-order-lifecycle.sh | Order lifecycle | 5 |
| wo-0402-order-cancel.sh | Order cancellation | 4 |
| wo-0403-order-items-pricing.sh | Lines and pricing | 5 |
| wo-0501-payment-capture.sh | Payment capture | 6 |
| wo-0502-refund-flow.sh | Refunds | 5 |
| wo-0601-message-dispatch.sh | Messaging | 5 |
| wo-0701-audit-trail.sh | Audit trail | 5 |
| wo-0801-report-build.sh | Reporting | 5 |

Sixteen suites, 82 declared entries, 72 of them distinct.

---

### Global notes

#### Items that require manual verification

These are the `MANUAL` class from [Coverage Classes](#coverage-classes). Each
one names the suite it belongs to and what a person has to do, because a
command-line client cannot open a mailbox, cannot enforce a browser's
same-origin policy, and cannot read a printed document.

| Suite | What has to be done by hand |
|---|---|
| WO-0102 | Confirm the sign-in form rejects a stale cross-origin submission in a real browser |
| WO-0301 | Confirm the catalogue renders its prices in the browser's locale, not the server's |
| WO-0601 | Open the mailbox, confirm the message arrived, that the template rendered, and that the link in it works |
| WO-0801 | Open the generated report and confirm the printed layout is legible and paginated |
| WO-0802 | Download the export in a browser and confirm the file opens in a spreadsheet application |

#### Configuration hardcoded into suites

A step-1 finding that has nothing to do with features and everything to do
with whether the estate can be pointed at a second environment. Three
different base URLs and two different origins were embedded across the suites,
which means the estate can only ever run against one machine.

| Setting | Values found across the suites |
|---|---|
| `API_BASE` | `http://localhost:3001/api/v1` (most suites), `http://localhost:3001`, `http://localhost:8080` |
| `ORIGIN` | `http://localhost:3000`, `http://localhost:4000` |

The fix is the one the harness already provides: every suite reads
`$API_BASE_URL` and the rest from `{{PIPELINE_ROOT}}/harness/config/test-config.env`,
and nothing is written into a suite body.

#### Suites with no feature header

Two populations, and only the second is a defect.

**Orchestrators — no features expected, no action:**

- wo-0100-account-suite.sh
- wo-0200-access-suite.sh
- wo-0400-order-suite.sh
- wo-0500-payment-suite.sh

**Newer or still-settling suites — a header has to be added:**

- wo-0302-inventory-reservation.sh
- wo-0402-order-schema.sh
- wo-0702-audit-retention.sh
- wo-0802-export-download.sh

**Features recovered from the suite code (step 3), not yet written back into
the suite header:**

| Suite | Features recovered |
|---|---|
| wo-0302-inventory-reservation.sh | 3 |
| wo-0702-audit-retention.sh | 2 |
| wo-0802-export-download.sh | 3 |

Eight recovered features, which is why the catalogue holds 80 rows against 72
distinct declarations. wo-0402-order-schema.sh is not in this table: its
assertions are all `STRUCTURAL`, so there was nothing behavioral to recover.

#### Catalogue gaps by area

| Area | Gap |
|---|---|
| WO-0300 series | Inventory features are recovered but the suite header is still missing |
| WO-0400 series | wo-0402-order-schema.sh asserts only on structure; no behavioral coverage of the schema it checks |
| WO-0700 series | Retention features are recovered but the suite header is still missing |
| WO-0800 series | Export features are recovered but the suite header is still missing |
| WO-0900 series | Account data isolation has no suite at all |
| WO-1000 series | Administrative console has no suite at all |

---

### Gap analysis: areas with no coverage

The other half of step 8. Every row is a work order that exists in the record
and has no suite. The priority column is the pre-scoring judgement that the
ranking in the next section replaces.

#### WO-0900 series — account data isolation (no suites)

| Work order | Description | Priority |
|---|---|---|
| WO-0901 | Row scoping on every order read | P0 |
| WO-0902 | Scoping on aggregate and report queries | P0 |
| WO-0903 | Forged account identifier in the request body | P0 |
| WO-0904 | Cross-account reference in a nested resource | P1 |
| WO-0905 | Scoping on bulk and batch endpoints | P1 |
| WO-0906 | Scoping on the search index | P1 |

#### WO-1000 series — administrative console (no suites)

| Work order | Description | Priority |
|---|---|---|
| WO-1001 | Administrative account management | P0 |
| WO-1002 | Administrative order search and edit | P0 |
| WO-1003 | Administrative refund issuance | P0 |
| WO-1004 | Role and permission editor | P1 |
| WO-1005 | Catalogue editor | P1 |
| WO-1006 | Audit trail viewer | P1 |
| WO-1007 | Report scheduling | P2 |
| WO-1008 | Console settings page | P2 |

#### WO-0600 series — messaging (partial, 1 suite)

| Work order | Description | Has a suite? |
|---|---|---|
| WO-0600 | Messaging master plan | N/A — planning document |
| WO-0601 | Outbound dispatch | yes — wo-0601 |
| WO-0602 | Template management | no |
| WO-0603 | Provider failover | no |
| WO-0604 | Delivery log and statistics | no |
| WO-0605 | Recipient preferences and opt-out | no |

> This table predates the additions listed under
> [Progress since the first pass](#progress-since-the-first-pass): WO-0602 and
> WO-0605 have suites now. It is left as it was rather than quietly corrected,
> because a gap table that is edited in place loses the only thing that makes
> it useful — the ability to see what moved.

---

### Gap analysis: areas with coverage

The counterweight. Publishing only the gaps produces a document that reads as
though nothing is tested, which is both wrong and demoralizing.

#### WO-0100 series — accounts and sign-in (best coverage)

| Suite file | Features covered |
|---|---|
| wo-0100-account-suite.sh | Orchestrator for the series |
| wo-0101-account-create.sh | Registration, activation, closure |
| wo-0102-account-signin.sh | Credential validation, generic failure message |
| wo-0103-signin-lockout.sh | Failure counting, lock, expiry, administrative unlock |
| wo-0104-session-lifecycle.sh | Creation, expiry, revocation, cleanup safety |

#### WO-0400 series — orders (good coverage)

| Suite file | Features covered |
|---|---|
| wo-0400-order-suite.sh | Orchestrator for the series |
| wo-0401-order-create.sh | Creation, server-side totals, submission |
| wo-0402-order-lifecycle.sh | Transition table, history, shipment, concurrency |
| wo-0402-order-cancel.sh | Cancellation windows, stock release, reason capture |
| wo-0402-order-schema.sh | Structural only — tables, columns, indexes |
| wo-0403-order-items-pricing.sh | Line bounds, discounts |

#### WO-0500 series — payments and refunds (good coverage)

| Suite file | Features covered |
|---|---|
| wo-0500-payment-suite.sh | Orchestrator for the series |
| wo-0501-payment-capture.sh | Authorisation, capture, idempotency, decline, reconciliation |
| wo-0502-refund-flow.sh | Full and partial refunds, over-refund guard, void |

---

### The ranked gap list

Step 9 applied to the tables above. Impact, exposure and detection are scored
1, 3 or 5 from the table in [Ranking the Gaps by Risk](#ranking-the-gaps-by-risk);
risk is their product; priority follows the thresholds, with the two
adjustments applied afterwards.

| # | Area | Missing behavior | I | E | D | Risk | Priority | Proposed suite |
|---|---|---|---|---|---|---|---|---|
| 1 | Data isolation | An order read cannot return another account's rows, even with a forged identifier in the body | 5 | 5 | 5 | 125 | P0 | wo-0901-order-scoping-critical-path.sh |
| 2 | Data isolation | Aggregates and reports are scoped; a total cannot include another account's orders | 5 | 5 | 5 | 125 | P0 | wo-0902-aggregate-scoping.sh |
| 3 | Administrative console | Administrative refund issuance refuses a caller without the permission | 5 | 5 | 3 | 75 | P0 | wo-1003-admin-refund-critical-path.sh |
| 4 | Administrative console | Administrative order edit refuses a caller without the permission and is audited | 5 | 3 | 5 | 75 | P0 | wo-1002-admin-order-edit.sh |
| 5 | Administrative console | Administrative account management refuses a caller without the permission | 5 | 3 | 5 | 75 | P0 | wo-1001-admin-accounts.sh |
| 6 | Messaging | Provider failover sends through the secondary provider and records which one delivered | 3 | 5 | 3 | 45 | P1 | wo-0603-provider-failover.sh |
| 7 | Messaging | Recipient opt-out suppresses every category it claims to suppress | 5 | 3 | 3 | 45 | P1 | wo-0605-recipient-preferences.sh |
| 8 | Data isolation | Nested resources cannot reference another account's order | 3 | 3 | 5 | 45 | P1 | wo-0904-nested-reference-scoping.sh |
| 9 | Catalogue | Inventory holds expire and return stock under concurrent load | 3 | 5 | 3 | 45 | P1 | wo-0302-inventory-concurrency.sh |
| 10 | Messaging | Template edits are versioned and a send records which version rendered | 3 | 3 | 3 | 27 | P2 → P1 | wo-0602-template-versioning.sh |
| 11 | Audit trail | Administrative actions land in the audit trail with the acting identity | 5 | 1 | 5 | 25 | P2 → P1 | wo-1006-admin-audit-completeness.sh |
| 12 | Reporting | Report scheduling runs on time and does not overlap itself | 3 | 1 | 3 | 9 | P2 | wo-1007-report-scheduling.sh |

Rows 10 and 11 show the single-suite promotion: each scores in the P2 band,
and each is promoted a level because the behavior it covers is either
irreversible (a message sent from the wrong template version cannot be
recalled) or invisible until an auditor asks.

---

### Progress since the first pass

What the first cycle of the plan actually produced. This is the only honest
measure of whether a gap analysis is working: the count of gaps that closed,
not the count of gaps that were identified.

| Suite created | Work order | Features covered |
|---|---|---|
| `wo-0901-order-scoping-critical-path.sh` | WO-0901 | Scoped reads, forged identifier, nested reference |
| `wo-0902-aggregate-scoping.sh` | WO-0902 | Scoped totals, scoped report ranges |
| `wo-0602-template-versioning.sh` | WO-0602 | Template edit, version stamp on send |
| `wo-0605-recipient-preferences.sh` | WO-0605 | Opt-out per category, suppression on send |

Unique suite prefixes went from 22 to 26; work orders with no suite went from
38 to 34, and the coverage gap from 63.3% to 56.7%.

---

### The phased plan

#### Phase 1 — the paths that have to be demonstrable (cycle 1)

1. **wo-0901-order-scoping-critical-path.sh** (P0)
   - A read scoped to the caller's account
   - The same read with a forged account identifier in the body
   - The same read with a forged identifier in the query string
2. **wo-0902-aggregate-scoping.sh** (P0)
   - A total over the caller's orders
   - The same total with another account's orders present in the table
3. **wo-1003-admin-refund-critical-path.sh** (P0)
   - Refund issued by a permitted administrator
   - Refund refused for a caller without the permission
   - The audit row that both cases produce
4. **wo-0602-template-versioning.sh** (P1)
   - Edit a template
   - Send, and read the version stamp back off the message row
5. **wo-0605-recipient-preferences.sh** (P1)
   - Opt out of a category
   - Trigger a send in that category and assert no message row appears

#### Phase 2 — platform completeness (cycle 2)

6. **wo-1001-admin-accounts.sh** (P1)
   - Administrative account list, search and edit
   - Permission refusal on each
7. **wo-1002-admin-order-edit.sh** (P1)
   - Administrative order edit
   - The edit history row it writes
8. **wo-0603-provider-failover.sh** (P1)
   - Primary provider fails
   - Secondary delivers
   - The delivering provider is recorded on the row
9. **wo-0302-inventory-concurrency.sh** (P1)
   - Concurrent holds against the last unit
   - Exactly one succeeds
   - Stock returns when the hold expires
10. **wo-0904-nested-reference-scoping.sh** (P1)
    - A nested create referencing another account's order
    - The refusal, and the absence of a written row

#### Phase 3 — the harder surfaces (cycle 3)

11. **wo-0906-search-index-scoping.sh** (P1)
    - Index contents per account
    - A search that must not surface another account's order
12. **wo-1004-role-editor.sh** (P1)
    - Role creation and permission attachment
    - Immediate effect on a live session
13. **wo-1006-admin-audit-completeness.sh** (P1)
    - Every administrative endpoint writes an audit row
    - The acting identity on each
14. **wo-1007-report-scheduling.sh** (P2)
    - A schedule fires
    - A second run does not overlap the first

---

### The template each new suite starts from

```bash
#!/usr/bin/env bash
# ============================================================================
# WO-NNNN: <Feature Name> — Behavioral Test Suite
# ============================================================================
# Features Tested:
# - <Feature 1>: what it proves
# - <Feature 2>: what it proves
# - <Feature 3>: what it proves
#
# Evidence:
# - HTTP: real requests to $API_BASE_URL
# - State: SQL read-back against the real database
#
# Preconditions:
# - The application answers on $API_BASE_URL
# - The database is reachable
# - Seed data has been applied
# ============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/test-helpers.sh"

section_header "WO-NNNN: <Feature Name>"

# Test 1: the happy path
test_start "<Feature> behaves correctly with valid input"
# ... real request, real state read-back ...
test_pass "<Feature> behaved as expected"

# Test 2: the error path
test_start "<Feature> rejects invalid input"
# ... real request, assert the status and the message ...
test_pass "Errors handled correctly"

# Test 3: the edge case
test_start "<Feature> handles the boundary condition"
# ... real request at the boundary ...
test_pass "Boundary handled"

print_summary "WO-NNNN <Feature Name>"
```

---

### Tracking

**Where the estate stands:**

| Measure | Value |
|---|---|
| Suites with a feature header | 16 files |
| Unique suite prefixes | 22 (26 after phase 1) |
| Work orders with no suite | 38 |
| Feature entries declared | 82 |
| Unique features declared | 72 |
| Catalogue rows | 80 |

**Where it should stand:**

| Target | Value |
|---|---|
| P0 work orders with a behavioral suite | 100% |
| P1 work orders with a behavioral suite | 80% |
| Critical-path execution time | under 10 minutes |
| Features whose only evidence is structural | falling, cycle over cycle |

**Demonstrability criteria — the point at which the gap list has done its job:**

- [ ] Account registration and sign-in work end to end, proven by a suite
- [ ] Order creation through delivery works end to end, proven by a suite
- [ ] Payment capture and refund reconcile with the order total, proven by a suite
- [ ] No read, aggregate or export can cross an account boundary, proven by a suite
- [ ] Message delivery is proven by a suite that observes the send, not the intent
- [ ] Every administrative endpoint refuses an unpermitted caller and writes an audit row, proven by a suite

**Recommendations carried out of the first pass:**

1. Add a `Features Tested` section to all 4 non-orchestrator suites that lack one
2. Move the hardcoded ports and origins into the shared test configuration
3. Add browser-driven suites for the checks a command-line client cannot make
4. Write the manual procedures into a runbook rather than leaving them as
   comments in a suite
5. Split wo-0402-order-schema.sh into a structural check and a behavioral
   suite, so the behavioral half can be trusted on its own

**What to do next, in order:**

1. **Immediately:** review the gap list, decide which demonstrations matter
   most, and confirm which features are actually implemented rather than
   planned — a gap in an unimplemented feature is not a testing gap
2. **This cycle:** create the phase-1 suites, confirm the existing suites
   still pass, and record any endpoint the gap analysis assumed but that does
   not exist
3. **This quarter:** complete phase 2, wire the estate into continuous
   integration (see
   `{{PIPELINE_ROOT}}/docs/patterns/behavioral-testing-in-ci.md`), and build
   the demonstration script out of the suites rather than beside them

---

## Relationship to the Other Methodology Documents

| Document | What it governs | Where this one meets it |
|---|---|---|
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` | How one suite is written, and what its result is allowed to claim | The five execution statuses, and the definition of behavioral evidence that the coverage classes rest on |
| `{{PIPELINE_ROOT}}/core/methodology/SCENARIO-TESTING-METHODOLOGY.md` | User journeys driven through a browser | Supplies the `MANUAL` class its runbooks: a journey verified there is evidence here |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md` | The work order record the gap analysis is measured against | Step 8 reads the work order directory; a gap is a work order with no suite |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md` | Defects and their verification | A defect found in an uncovered area is a gap with evidence attached; it promotes the gap |
| `{{PIPELINE_ROOT}}/docs/patterns/behavioral-testing-in-ci.md` | Running the estate automatically and publishing the result | Where the coverage matrix gets its "last executed" column from |
| `{{PIPELINE_ROOT}}/harness/scripts/calculate-coverage.js` | Coverage of one verification document | The per-work-order view; the inventory is the estate-wide view |

---

**The one-sentence version:** derive the catalogue from the suites, classify
every row honestly — especially the rows that only prove a file exists — rank
what is missing by what it would cost to be wrong, and bind the whole thing to
a fingerprint so it cannot quietly stop being true.
