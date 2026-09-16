# Reference Templates

Long-form reference documents a project fills in once and then maintains: a
standard it commits to, a registry it keeps current, an audit it repeats, a
report it writes after an incident.

They differ from the templates in [`../docs/`](../docs/README.md) in one way that
matters. A documentation template ships no claims at all, because anything
plausible left inside one eventually ships into a published document. These
carry deliberate **worked examples** — filled tables, real-looking output, real
commands — because the shape of a finished one is the instruction. Every value
in them is generic by construction: `example.com` hosts, `app_dev` databases,
`tenant-one` tenants, `example-pass-1` placeholders, `YYYY-MM-DD` dates. Replace
the worked example with your own content; do not publish it as fact.

---

## Available Templates

| Template | Purpose | When to use |
|---|---|---|
| `DB-NORMALIZATION-AUDIT-TEMPLATE.md` | Schema audit against 1NF-4NF, with SQL that finds each violation class | Before a schema freeze, after a fast-growing feature, or on a recurring cadence |
| `DOCUMENTATION-INDEX-TEMPLATE.md` | Whole-project documentation index: taxonomy, ownership, freshness, maintenance procedure | When docs have outgrown the point where people can find them by searching |
| `INCIDENT-POSTMORTEM-TEMPLATE.md` | Blank postmortem structure plus a filled worked example of a database-loss incident | After any incident with data loss, downtime, or a recovery that had to be improvised |
| `PORT-ALLOCATION-STANDARD.md` | Method for allocating a contiguous port block per environment, plus conflict detection | When a second environment, service, or container stack joins the project |
| `QA-SMOKETEST-TEMPLATE.md` | Manual smoke-test pass over the critical paths, with pass/fail and issue capture | Before a release, after a risky merge, or when automated coverage does not reach the UI |
| `TEST-ACCOUNTS-REGISTRY-TEMPLATE.md` | Registry of the accounts and roles test suites log in as | As soon as more than one suite needs a known account |

---

## Using one

1. Copy it into the project, under `{{DOCS_DIR}}` or `{{TESTING_DIR}}` as the
   template's own header says.
2. Delete the worked example, or keep it alongside your content clearly labelled
   as an example. Never leave it in place as if it described your system.
3. Replace every placeholder: `{{PROJECT_NAME}}`, `{{DOCS_DIR}}`,
   `{{WORKORDERS_DIR}}`, `{{TESTING_DIR}}`, `{{API_APP}}`, `{{DB_NAME}}`.
4. Put a review date and an owner on it. A reference document nobody owns is
   wrong within a quarter, and a wrong one costs more than none.

## Rules that apply to all of them

- No real credentials, ever — not in the test-account registry, not in an
  incident timeline, not in a connection string. Passwords in these files use
  the obviously-fake `example-pass-N` shape on purpose.
- No real customer, tenant, or person names in a worked example.
- Every command in a filled document must be one you actually ran.
