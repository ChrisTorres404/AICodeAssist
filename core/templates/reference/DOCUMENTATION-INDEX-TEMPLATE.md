<!--
[Platform Documentation] YYYY-MM-DD
{{PROJECT_NAME}} - Complete Documentation Index
Reason: Central navigation point for all platform documentation
-->

# {{PROJECT_NAME}} - Complete Documentation Index

**Platform Version:** vX.Y.Z
**Last Updated:** YYYY-MM-DD
**Status:** <Draft / Active / Production-Ready>

---

## How to use this template

One index for the whole project, maintained as a document rather than
generated, because the value is in the judgement: which document is
authoritative, which is stale, who owns it, and what to read in what order.

1. Copy to `{{DOCS_DIR}}/DOCUMENTATION-INDEX.md`. There is exactly one of
   these per project.
2. Keep the section taxonomy below: specs, security, testing, work orders,
   topic reference, architecture, learning paths, search guide, document
   types, quality, rules, resources, statistics, maintenance, support,
   external references, appendix. Delete a section only when the project has
   no documents of that kind at all.
3. Every entry table uses the same columns: **Document, Description, Status,
   Owner, Last Reviewed**. Owner is a role, never a person's name. Last
   Reviewed is the date somebody last read it and confirmed it still true —
   not the date it was last edited.
4. Link with repository-relative paths built from `{{DOCS_DIR}}`,
   `{{WORKORDERS_DIR}}` and `{{TESTING_DIR}}`. An absolute path on one
   machine is a broken link on every other.
5. Add the entry in the same commit as the document. An index updated later
   is an index that is wrong in between.
6. Work through "Maintenance" on the stated schedule. An index nobody prunes
   becomes a list of files that no longer exist.

All entries below are placeholders showing the shape of a row.

---

## Quick Start

**New to the platform?** Start here:

1. **[Platform Overview]({{DOCS_DIR}}/platform/README.md)** - Start here
2. **[Platform Master Spec]({{DOCS_DIR}}/platform/MASTER-SPEC.md)** - Complete specification
3. **[Version History]({{DOCS_DIR}}/platform/VERSION-HISTORY.md)** - Platform evolution
4. **[vX.Y.Z Release Notes]({{DOCS_DIR}}/platform/RELEASE-NOTES-vX.Y.Z.md)** - Latest changes

---

## Platform Documentation

### Platform Specs (Authoritative)

| Document | Description | Status | Owner | Last Reviewed |
|----------|-------------|--------|-------|---------------|
| [README.md]({{DOCS_DIR}}/platform/README.md) | Platform overview and navigation | Current | platform | YYYY-MM-DD |
| [MASTER-SPEC.md]({{DOCS_DIR}}/platform/MASTER-SPEC.md) | **Canonical specification** | vX.Y.Z | platform | YYYY-MM-DD |
| [VERSION-HISTORY.md]({{DOCS_DIR}}/platform/VERSION-HISTORY.md) | Version tracking and immutable decisions | Current | platform | YYYY-MM-DD |
| [RELEASE-NOTES-vX.Y.Z.md]({{DOCS_DIR}}/platform/RELEASE-NOTES-vX.Y.Z.md) | Current release details | Latest | platform | YYYY-MM-DD |
| [IDENTITY-AND-RBAC.md]({{DOCS_DIR}}/platform/IDENTITY-AND-RBAC.md) | Authorization architecture | Draft | API | YYYY-MM-DD |
| [CONTROL-PLANE.md]({{DOCS_DIR}}/platform/CONTROL-PLANE.md) | Control plane | Draft | platform | YYYY-MM-DD |
| [DATA-PLANE.md]({{DOCS_DIR}}/platform/DATA-PLANE.md) | Data plane | Draft | platform | YYYY-MM-DD |
| [MULTI-REGION.md]({{DOCS_DIR}}/platform/MULTI-REGION.md) | Multi-region architecture | Draft | platform | YYYY-MM-DD |
| [ROADMAP.md]({{DOCS_DIR}}/platform/ROADMAP.md) | Roadmap | Draft | product | YYYY-MM-DD |

---

## Security Documentation

### System Design - Security

| Document | Description | Status | Owner | Last Reviewed |
|----------|-------------|--------|-------|---------------|
| [API-KEYS.md]({{DOCS_DIR}}/security/API-KEYS.md) | **API key architecture** (new in vX.Y.Z) | Complete | security | YYYY-MM-DD |
| [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md) | **Guard usage rules** (new in vX.Y.Z) | Complete | security | YYYY-MM-DD |
| [RBAC-DECORATORS-USAGE.md]({{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md) | Authorization patterns and decorators | Complete | API | YYYY-MM-DD |

### Security Guidelines

| Document | Description | Status | Owner | Last Reviewed |
|----------|-------------|--------|-------|---------------|
| [HARDENING-GUIDELINES.md]({{DOCS_DIR}}/security/HARDENING-GUIDELINES.md) | Security hardening rules | Active | security | YYYY-MM-DD |

---

## Testing Documentation

### WO-0001 (API Key Authentication)

| Document | Description | Status | Owner | Last Reviewed |
|----------|-------------|--------|-------|---------------|
| [WO-0001-VERIFICATION.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/WO-0001-VERIFICATION.md) | Full verification report | <N/N checks passed> | QA | YYYY-MM-DD |
| [WO-0001-VERIFICATION-SUMMARY.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/WO-0001-VERIFICATION-SUMMARY.md) | Executive summary | Complete | QA | YYYY-MM-DD |
| [wo-0001-test-harness.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/wo-0001-test-harness.md) | 30+ test commands | Ready | QA | YYYY-MM-DD |

### WO-0002 (Core Authentication)

| Document | Description | Status | Owner | Last Reviewed |
|----------|-------------|--------|-------|---------------|
| [WO-0002-VERIFICATION.md]({{WORKORDERS_DIR}}/WO-0002-core-auth/WO-0002-VERIFICATION.md) | Entity and schema verification | Complete | QA | YYYY-MM-DD |

Executable suites live in `{{TESTING_DIR}}/suites/`; their recorded runs live
in `{{TESTING_DIR}}/results/`. Index the documents here, not the scripts.

---

## Work Orders

### Completed (In Production)

| WO | Title | Status | Documentation |
|----|-------|--------|---------------|
| WO-0002 | Core Authentication | Complete | [Folder]({{WORKORDERS_DIR}}/WO-0002-core-auth/) |
| WO-0003 | Row-Level Security and RBAC Integration | Complete | [Folder]({{WORKORDERS_DIR}}/WO-0003-rls-rbac/) |
| WO-0004 | Audit Logging System | Complete | [Folder]({{WORKORDERS_DIR}}/WO-0004-audit-logging/) |
| WO-0005 | Webhooks System | Complete | [Folder]({{WORKORDERS_DIR}}/WO-0005-webhooks/) |
| **WO-0001** | **API Key Authentication** | **Complete** | **[Folder]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/)** |

### Next (Planned)

| WO | Title | Status | Dependencies |
|----|-------|--------|--------------|
| WO-0006 | Admin UI - API Keys | Planned | WO-0001 |
| WO-00NN | API Key Rotation | Future | WO-0001 |
| WO-00NN | OAuth 2.0 Integration | Future | WO-0001 |

---

## Quick Reference by Topic

### Authentication

**Understand authentication:**
- Platform Spec: Section 2 (Identity and Authentication Layer)
- Token-based auth: Section 2.2
- **API key auth: Section 2.6** (new in vX.Y.Z)
- Session model: Section 2.3

**Implement authentication:**
- [API-KEYS.md]({{DOCS_DIR}}/security/API-KEYS.md) - System design
- [API-KEYS-QUICK-START.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/API-KEYS-QUICK-START.md) - Developer guide
- [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md) - Guard patterns

### Authorization (RBAC)

**Understand authorization:**
- Platform Spec: Section 3 (Authorization Layer)
- Identity graph: [IDENTITY-AND-RBAC.md]({{DOCS_DIR}}/platform/IDENTITY-AND-RBAC.md)

**Implement authorization:**
- [RBAC-DECORATORS-USAGE.md]({{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md)
- Privilege codes: Platform Spec Section 3.3

### Security

**Security overview:**
- Platform Spec: Section 10 (Security, Compliance and Hardening)
- [HARDENING-GUIDELINES.md]({{DOCS_DIR}}/security/HARDENING-GUIDELINES.md)

**Security patterns:**
- [API-KEYS.md]({{DOCS_DIR}}/security/API-KEYS.md) - API key security model
- [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md) - Guard security

### Testing

**Test approach:**
- [WO-0001-VERIFICATION-SUMMARY.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/WO-0001-VERIFICATION-SUMMARY.md) - Example verification
- [wo-0001-test-harness.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/wo-0001-test-harness.md) - Test commands

**Test patterns:**
- Behavioural verification (WO-0002, WO-0001)
- Integration testing
- Security testing

---

## Architecture Topics

### By Component

**Authentication system:**
- Tokens: Platform Spec 2.2, WO-0002
- API keys: Platform Spec 2.6, WO-0001
- Sessions: Platform Spec 2.3, WO-0002
- Refresh: Platform Spec 2.4, WO-0002

**Authorization system:**
- RBAC: Platform Spec 3.x, WO-0003
- Row-level security: Platform Spec 4.x, WO-0003
- Privileges: Platform Spec 3.3, WO-0003
- Guards: [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md)

**Integration system:**
- Webhooks: Platform Spec 5.x, WO-0005
- **API keys: Platform Spec 2.6, WO-0001**
- Audit: Platform Spec 6.x, WO-0004

---

## Learning Paths

### Path 1: Understanding the Platform (New Developer)

1. [Platform Overview]({{DOCS_DIR}}/platform/README.md)
2. [Platform Master Spec]({{DOCS_DIR}}/platform/MASTER-SPEC.md) - Sections 1-2
3. [Version History]({{DOCS_DIR}}/platform/VERSION-HISTORY.md) - Immutable decisions
4. [vX.Y.Z Release Notes]({{DOCS_DIR}}/platform/RELEASE-NOTES-vX.Y.Z.md)

### Path 2: Implementing Features (Developer)

1. [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md)
2. [RBAC-DECORATORS-USAGE.md]({{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md)
3. The relevant work order (for example WO-0001 for API keys)
4. The project's `CLAUDE.md` and `{{PIPELINE_ROOT}}/core/rules/`

### Path 3: Security Review (Security Engineer)

1. [HARDENING-GUIDELINES.md]({{DOCS_DIR}}/security/HARDENING-GUIDELINES.md)
2. [API-KEYS.md]({{DOCS_DIR}}/security/API-KEYS.md)
3. [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md)
4. Platform Spec Section 10 (Security and Compliance)

### Path 4: Testing and QA (QA Engineer)

1. [WO-0001-VERIFICATION-SUMMARY.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/WO-0001-VERIFICATION-SUMMARY.md)
2. [wo-0001-test-harness.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/wo-0001-test-harness.md)
3. [WO-0002-VERIFICATION.md]({{WORKORDERS_DIR}}/WO-0002-core-auth/WO-0002-VERIFICATION.md)

---

## Search Guide

### Find Information About...

**API keys:**
- Primary: `{{DOCS_DIR}}/security/API-KEYS.md`
- Platform Spec: Section 2.6
- Quick start: `{{WORKORDERS_DIR}}/WO-0001-api-key-auth/API-KEYS-QUICK-START.md`
- Work order: `{{WORKORDERS_DIR}}/WO-0001-api-key-auth/`

**Guards:**
- All guards: `{{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md`
- API key guard: `{{DOCS_DIR}}/security/API-KEYS.md`, section "Authentication Flow"
- Authorization guards: `{{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md`

**RBAC and privileges:**
- Decorators: `{{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md`
- Platform Spec: Section 3
- Work order: WO-0003

**Row-level security (tenant isolation):**
- Platform Spec: Section 4
- Usage guide: `{{DOCS_DIR}}/security/RBAC-DECORATORS-USAGE.md`
- Work order: WO-0003

**Webhooks:**
- Platform Spec: Section 5
- Work order: WO-0005

**Testing:**
- Verification reports: `{{WORKORDERS_DIR}}/WO-*/WO-*-VERIFICATION.md`
- Test harnesses: `{{WORKORDERS_DIR}}/WO-*/wo-*-test-harness.md`
- Suites and results: `{{TESTING_DIR}}/suites/`, `{{TESTING_DIR}}/results/`

---

## Document Types

Each type has a different rule for when it may change. The rule is the reason
the taxonomy exists.

### Authoritative (Immutable Baselines)

- **Platform Master Spec** - Source of truth
- **Version History** - Immutable decisions log
- **Release Notes** - Official change records

**Rule:** These require formal review to change.

### System Design (Technical Reference)

- Architecture documents
- Security models
- Integration patterns
- Implementation guides

**Rule:** Updated as implementation evolves.

### Work Orders (Implementation Records)

- Feature specifications
- Implementation details
- Completion reports
- Verification results

**Rule:** Immutable after completion (historical record).

### Testing (Quality Assurance)

- Verification reports
- Test harnesses
- Behavioural tests
- Security audits

**Rule:** Updated per release or feature.

### Project Rules (Development Standards)

- The project's `CLAUDE.md`
- Agent and skill definitions
- Coding standards
- Security guidelines

**Rule:** Living documents, updated as needed.

---

## Documentation Quality

### Coverage Status

| Area | Coverage | Status | Owner |
|------|----------|--------|-------|
| Authentication (tokens) | 100% | Complete | API |
| **Authentication (API keys)** | **100%** | **New in vX.Y.Z** | API |
| Authorization (RBAC) | 100% | Complete | API |
| Security (row-level security) | 100% | Complete | security |
| Webhooks | 90% | Active | API |
| Audit logging | 90% | Active | API |
| Testing | 100% | Complete | QA |

Coverage is the share of the area's behaviour that has a document, not a
feeling. State how it was counted, or write "not measured".

### Documentation Standards

**All platform docs must include:**
- Status indicator (draft / active / complete)
- Last updated date
- Owner role
- Related work orders
- Code references
- Examples

**All code must include:**
- Work order reference
- Date in YYYY-MM-DD format
- Reason for change
- Related work orders

---

## Critical Platform Rules

### Immutable Architectural Decisions (vX.Y.Z)

**These are baseline rules that should persist across all future development:**

1. **Tokens for users, API keys for machines** (vX.Y.Z)
   - Location: Platform Spec 2.2, 2.6
   - Status: Immutable

2. **Tenant isolation enforced at the database level** (vX.Y.Z)
   - Location: Platform Spec 4.3
   - Status: Immutable

3. **Privilege-based RBAC** (vX.Y.Z)
   - Location: Platform Spec 3.3
   - Status: Immutable

4. **Platform owner bypass by default** (vX.Y.Z)
   - Location: Platform Spec 3.5
   - Status: Immutable

5. **Specialized guards are opt-in** (vX.Y.Z)
   - Location: Platform Spec 2.6.4, GUARD-APPLICATION-RULES.md
   - Status: Immutable (baseline established)

**Documentation:**
- Platform Spec: [MASTER-SPEC.md]({{DOCS_DIR}}/platform/MASTER-SPEC.md)
- Version History: [VERSION-HISTORY.md]({{DOCS_DIR}}/platform/VERSION-HISTORY.md)
- Project rules: the project's `CLAUDE.md`

---

## Development Resources

### For Developers

**Getting started:**
1. Read [Platform Overview]({{DOCS_DIR}}/platform/README.md)
2. Review the project's `CLAUDE.md`
3. Check [GUARD-APPLICATION-RULES.md]({{DOCS_DIR}}/security/GUARD-APPLICATION-RULES.md)

**Implementing features:**
1. Find the relevant work order in `{{WORKORDERS_DIR}}/`
2. Read the system design document in `{{DOCS_DIR}}/`
3. Review the platform spec section
4. Follow the code examples

**API keys specifically:**
1. [API-KEYS-QUICK-START.md]({{WORKORDERS_DIR}}/WO-0001-api-key-auth/API-KEYS-QUICK-START.md)
2. [API-KEYS.md]({{DOCS_DIR}}/security/API-KEYS.md)
3. Platform Spec Section 2.6

### For AI Agents

**Agent awareness documents:**
- `{{PIPELINE_ROOT}}/core/skills/` - Stack and domain patterns
- `{{PIPELINE_ROOT}}/core/rules/` - Shared rules
- The project's `CLAUDE.md` - Global rules

**Critical rules for agents:**
- Never apply the API key guard globally
- Never auto-apply it to endpoints without an explicit request
- Always ask before adding API key authentication
- Always document the rationale

---

## Documentation Statistics

### vX.Y.Z Documentation

**Total files:**
- Platform specs: N files
- System design: N files
- Work orders: N files
- Testing: N files
- Project rules: N files

**Feature documentation (WO-0001):**
- Work order docs: 5 files
- System design: 3 files
- Testing docs: 3 files
- Platform updates: 4 files
- Agent updates: 3 files
- **Total: 18 files**

**Coverage:**
- Implementation: 100%
- Testing: 100%
- Security: 100%
- User guides: 100%
- Agent awareness: 100%

Count these rather than estimating:

```bash
find {{DOCS_DIR}} -name '*.md' | wc -l
find {{WORKORDERS_DIR}} -name '*.md' | wc -l
find {{TESTING_DIR}} -name '*.md' | wc -l
```

---

## Maintenance

### Keeping Documentation Current

**When to update:**

1. **Platform Spec** - On any architectural change or new major feature
2. **Version History** - On every release
3. **Release Notes** - On every release
4. **System Design** - When the implementation changes
5. **Work Orders** - Never (immutable after completion)
6. **Project rules** - When a new global rule is established
7. **This index** - In the same commit that adds or removes a document

### Review Schedule

**Quarterly reviews:**
- Platform Master Spec accuracy
- Immutable decisions still valid
- Documentation coverage
- Broken links and references

**Per-release reviews:**
- Update version references
- Create release notes
- Update version history
- Update the documentation index (this file)

### Freshness Procedure

Run per review, and stamp the Last Reviewed column with the date it was done.

- [ ] Every link in this index resolves to a file that exists
- [ ] Every document in `{{DOCS_DIR}}` appears in exactly one entry table here
- [ ] Every entry has an Owner role, and no entry names a person
- [ ] Every entry's Last Reviewed date is within the review interval
- [ ] Documents past the interval are re-read, then re-stamped or retired
- [ ] Retired documents are moved to `{{DOCS_DIR}}/archive/` and their rows removed
- [ ] Status values match reality (nothing marked Complete that is half-written)

Check the links mechanically:

```bash
# Every repository-relative markdown link in this index that has no file behind it
grep -o '](\([^)]*\))' {{DOCS_DIR}}/DOCUMENTATION-INDEX.md \
  | sed 's/^](//; s/)$//' \
  | grep -v '^http' \
  | while read -r p; do [ -e "$p" ] || echo "MISSING: $p"; done
```

---

## Support

### Getting Help

**Documentation issues:**
- Check this index first
- Review the version history for context
- Check the relevant work order

**Technical questions:**
- Start with the Platform Master Spec
- Review the system design documents
- Check the code implementation

**Bug reports:**
- Note the platform version (vX.Y.Z)
- Reference the relevant documentation
- Include the work order if known
- Open the bug with `bug new "<title>"`

---

## External References

Link the standards and library documentation this project actually depends on.
Name the version you are pinned to, so a reader can tell when a link has
drifted ahead of the code.

### Standards and Best Practices

| Reference | What it covers | URL |
|-----------|----------------|-----|
| <Backend framework> docs | Framework version in use | <URL> |
| <ORM or data layer> docs | Query and migration API | <URL> |
| <Database> manual | The features relied on (row-level security, indexing) | <URL> |
| <Token format> specification | Token structure and validation | <URL> |
| <Password hashing> reference | Hashing parameters in use | <URL> |

### Security Standards

Standards bodies, not vendors: name the exact revision the project is reviewed
against, because these are revised and the gap is what an auditor asks about.

| Reference | What it covers | URL |
|-----------|----------------|-----|
| OWASP Top 10 | The web vulnerability classes every change is reviewed against | <URL for the revision in use> |
| NIST Cybersecurity Framework / SP 800-53 | The control set the project maps its controls to | <URL for the revision in use> |
| CIS Controls and Benchmarks | The hardening baseline for hosts, containers, and the database | <URL for the revision in use> |
| <Any sector standard that applies> | The regime the project is audited under | <URL> |

---

## Appendix

### Directory Structure

```
{{DOCS_DIR}}/
├── DOCUMENTATION-INDEX.md        # this file
├── platform/                     # platform specs and baselines
├── security/                     # security architecture and guidelines
├── database/                     # data model and audits
├── backend/                      # backend architecture
├── frontend/                     # frontend architecture
├── devops/                       # deployment and operations
├── incidents/                    # postmortems
└── archive/                      # retired documents, kept for history

{{WORKORDERS_DIR}}/
├── WO-0001-api-key-auth/         # spec, checklist, tasks, prompt, verification, closeout
├── WO-0002-core-auth/
├── WO-0003-rls-rbac/
├── WO-0004-audit-logging/
└── WO-0005-webhooks/

{{TESTING_DIR}}/
├── suites/                       # executable behavioural suites
├── results/                      # recorded runs
└── smoketest/                    # completed smoke-test checklists
```

### Document Naming Conventions

**Platform docs:**
- `MASTER-SPEC.md` - Master specification
- `RELEASE-NOTES-vX.Y.Z.md` - Release notes
- `{Component}-{Aspect}.md` - Component docs

**System design:**
- `{TOPIC}.md` - Single-topic architecture docs
- `{TOPIC}-RULES.md` - Rule documents

**Work orders:**
- `WO-NNNN-SPEC.md` - Work order specification
- `WO-NNNN-CLOSEOUT.md` - Completion report
- `WO-NNNN-{topic}.md` - Supporting docs

**Testing:**
- `WO-NNNN-VERIFICATION.md` - Verification reports
- `wo-NNNN-test-harness.md` - Test commands
- `wo-NNNN-{feature}.sh` - Executable suites

---

**Index Version:** 1.0
**Platform Version:** vX.Y.Z
**Last Updated:** YYYY-MM-DD
**Maintained By:** platform team
