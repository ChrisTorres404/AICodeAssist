# {{PROJECT_NAME}} - Global Project Rules

**CRITICAL:** Read this before starting ANY work on the {{PROJECT_NAME}} platform.

---

## 🔧 WORK ORDER SYSTEM (UPDATED - 2025-12-15)

### ⚠️ MANDATORY METHODOLOGY - READ THIS FIRST

**Every Work Order MUST have its own folder with ALL required documents.**

📖 **Full Methodology:** `{{WORKORDERS_DIR}}/MANDATORY-WO-METHODOLOGY.md`
📁 **Templates:** `{{PIPELINE_ROOT}}/core/templates/workorders/`

### Required Folder Structure (NON-NEGOTIABLE)

```
{{WORKORDERS_DIR}}/WO-XXXX-[Descriptive-Name]/
├── WO-XXXX-[Title].md           # Main specification (REQUIRED)
├── WO-XXXX-CHECKLIST.md         # Implementation checklist (REQUIRED)
├── WO-XXXX-TASK-BREAKDOWN.md    # Task breakdown with estimates (REQUIRED)
├── WO-XXXX-Prompt.md            # AI implementation prompt (REQUIRED)
└── WO-XXXX-CLOSEOUT.md          # Closeout report (REQUIRED on completion)
```

### ❌ DO NOT CREATE

- Loose `.md` files in parent directories
- Work orders without folders
- Folders missing required documents

### Work Order Creation Workflow

When user says: "Create a work order to [task]"

**MANDATORY STEPS:**
1. Create folder: `{{WORKORDERS_DIR}}/WO-XXXX-[Name]/`
2. Copy templates from `_TEMPLATES/` and rename with WO number
3. Fill in ALL sections - no placeholders left behind
4. Verify all 4 required documents exist

### Gold Standard Examples

Reference these properly structured work orders:
- any promoted work order with a complete `SCTPVC` lifecycle (`pack index`)

### Validation Checklist

Before considering a WO "created":
- [ ] Folder exists with correct name
- [ ] Main spec file exists
- [ ] Checklist exists
- [ ] Task breakdown exists
- [ ] Prompt exists
- [ ] All placeholders replaced

---

## 📄 Docs & Markdown Placement Rules (STRICT)

> **Goal:** All human/AI-written docs live in predictable places.
> No more random `.md` files under `apps/**` or `src/**`.

### 1. Allowed Roots for New Docs

When creating ANY new `.md` file, it must go under one of the following:

#### A. Work Orders (Status / Reports / Checklists)
```
docs/work-orders/**
```

#### B. System Design / Usage / Testing Docs
```
{{DOCS_DIR}}/**
```

#### C. Architect / Agent Outputs
```
{{WORKSPACE_DIR}}/Agents/**/WorkOutputs/**
```

> Summary:
> - Work-order-specific docs → `docs/work-orders/**`
> - Design/usage/testing docs → `{{DOCS_DIR}}/**`
> - Architect/agent analytical outputs → `{{WORKSPACE_DIR}}/Agents/**/WorkOutputs/**`

---

### 2. Forbidden Locations (Do NOT Create Docs Here)

New `.md` files must **never** be created in:

- ❌ `apps/**`
- ❌ `apps/**/src/**`
- ❌ `src/**`
- ❌ `packages/**`

Updating existing README.md files within these paths is allowed ONLY when explicitly asked.

---

### 3. Work Order Document Placement Examples

For WO-0203, WO-0204, etc.:

```
{{WORKORDERS_DIR}}/WO-0204-example/WO-0204-IMPLEMENTATION-COMPLETE.md
{{WORKORDERS_DIR}}/WO-0203-example/WO-0203-Session-Smoke-Tests.md
```

If the document **describes one WO**, it MUST live under:

```
{{WORKORDERS_DIR}}/{{PROJECT_NAME}}Dev/WO-XXXX/
```

---

### 4. System Design / Usage Docs

Use this root for architecture, security, RLS/RBAC behavior, usage examples, and testing documents:

```
{{DOCS_DIR}}/SystemDesign/{Domain}/{DocName}.md
```

Examples:

- `{{DOCS_DIR}}/SystemDesign/Security/RLS-RBAC-Decorators-Usage.md`
- `{{DOCS_DIR}}/SystemDesign/Auth/Session-and-Token-Model.md`
- `{{DOCS_DIR}}/SystemDesign/Testing/Auth-Session-Flow-Smoke-Tests.md`

---

### 5. When Unsure Where a Doc Belongs

If you (Claude or any agent) are uncertain:

1. If tied to a specific WO → use `{{WORKORDERS_DIR}}/{{PROJECT_NAME}}Dev/WO-XXXX/`
2. If design/architecture/testing → use `{{DOCS_DIR}}/SystemDesign/**`
3. Never choose `apps/**` or `src/**` as fallback.

---

## 🚨 Golden Rule: NEVER HALLUCINATE

**Always work with factual, verifiable information that exists in the project.**

When referencing any file, function, class, component, entity, table, column, or route:
- ✅ Confirm that it **actually exists** in the codebase or schema
- ✅ Search the repo for it first
- ✅ If unsure, **SEARCH BEFORE ASSUMING**

If a referenced item does not exist:
- Search for an equivalent or similar implementation
- Prefer reusing or enhancing existing logic
- **DO NOT** invent new concepts or hallucinate APIs/components

---

## 📁 Frontend Structure Rules (Admin Web App)

All paths relative to: `apps/admin-web/src`

### PRIMARY RULE: Features Directory

**ALL new feature-specific code goes in:**
```
src/features/{feature-name}/
```

**Directory template for each feature:**
```
src/features/{feature-name}/
├── pages/           # Route components for this feature
├── components/      # Feature-specific UI components
├── hooks/           # Feature-specific hooks
├── services/        # Feature-specific APIs/business logic
└── types/           # Feature-specific TypeScript types
```

### ❌ NEVER Create These Structures

**DO NOT create new feature directories like:**
- ❌ `src/components/{feature-name}/`
- ❌ `src/pages/admin/{feature-name}/`
- ❌ `src/{feature-name}/`
- ❌ `apps/admin-web/apps/admin-web/src/features/...` (duplicate paths)

### ✅ Existing Shared/Legacy Directories (Use, Don't Restructure)

These already exist for shared/cross-feature code:
- `src/components/*` → shared or cross-feature components
- `src/pages/*` → existing route-level pages
- `src/services/*` → shared services
- `src/core/*`, `src/hooks/*`, `src/utils/*` → core/shared utilities

**You may:**
- Use components from these directories
- Create truly shared components (only if work order explicitly calls for it)

**You may NOT:**
- Scatter new feature-specific logic under these directories
- Create new feature trees here

### Component Extraction Rules

Apply these limits strictly:

| Component Type | Max Lines | Action When Exceeded |
|----------------|-----------|----------------------|
| Page component | 150 lines | Factor out sections into subcomponents |
| Component | 200 lines | Factor out logical sections |
| Modal/Dialog | 50 lines | Extract to `components/dialogs/` |
| Form | 80 lines | Extract to `components/forms/` |
| Table | 100 lines | Extract to `components/tables/` |
| Complex section | 80 lines | Extract to separate component |

### Import Rules

**For shared/global components:**
```typescript
// ✅ CORRECT
import { Button } from '@/components/ui/button';
import { ErrorBoundary } from '@/components/common/ErrorBoundary';
```

**Within a feature (relative imports):**
```typescript
// ✅ CORRECT
import { TemplateCard } from './TemplateCard';
import { useTemplates } from '../hooks/useTemplates';
```

**NEVER:**
```typescript
// ❌ WRONG - Don't use deep relative paths for shared components
import { Button } from '../../../components/ui/button';
```

### Before Creating New Frontend Code - Checklist

1. **Is this part of an existing feature?**
   - Yes → Put it under `src/features/{existing-feature}/...`

2. **Is this a completely new feature?**
   - Yes → Create `src/features/{new-feature}/` using the template

3. **Is this truly shared UI across multiple features?**
   - Only then consider `src/components/common/`

4. **Does the component exceed line limits?**
   - Apply extraction rules above

5. **Search for existing similar components FIRST**
   - If exists and satisfies requirement → reuse it
   - If exists and partially satisfies → enhance it
   - Only create new if no suitable component exists

### Verification Step

After generating or modifying TypeScript/React code:

```bash
cd apps/admin-web
npx tsc --noEmit
```

Fix all type/import errors before marking work as complete.

---

## 🗄️ Database Guards

**When working with database logic (SQL, entities, repositories, migrations):**

### Always Verify:
- ✅ Tables exist
- ✅ Columns exist and have correct types
- ✅ Relationships, keys, constraints exist as assumed
- ✅ Multi-schema changes are scoped to correct schema

### ORM Entities (TypeORM):
- ✅ Entity definition matches actual database schema
- ✅ Use existing naming conventions consistently
- ✅ Follow existing patterns

### Manual SQL Guidelines:
- ✅ Use manual SQL for quick data checks or emergency fixes
- ✅ **ALWAYS** create a corresponding migration file for schema changes
- ✅ Run migrations via standard npm scripts (`npm run migration:run`)
- ✅ Follow existing nomenclature and naming conventions

### Reject/Correct If:
- ❌ References non-existent tables or columns
- ❌ Assumes incorrect types
- ❌ Violates multi-schema boundaries
- ❌ Makes schema changes without a migration file

---

## 🔌 API Guards

**When working on APIs (controllers, services, guards, DTOs, interceptors, middleware):**

### Always Verify:
- ✅ Entities referenced by API actually exist
- ✅ DTOs and validators reference real fields and shapes
- ✅ Services and repositories exist and match usage

### Maintain Consistency With:
- ✅ Existing RBAC and IAM logic
- ✅ Route registration patterns
- ✅ Privilege and policy structures

### Ensure All API Changes:
- ✅ Align with existing API design and conventions
- ✅ Include traceability comments (work order, date, reason)

### When in Doubt:
- 🔍 Inspect existing pattern for similar endpoint
- ✅ Follow that style

### Reject/Correct If:
- ❌ Invents new entities or DTO fields not in schema
- ❌ Bypasses RBAC/guard patterns
- ❌ Uses non-existent services, methods, or routes

---

## 🎨 UI/UX Guards

### 1. Search for Existing Components FIRST

**Before creating or modifying any UI component:**
- 🔍 Search existing components for similar functionality
- ✅ If similar exists and fully satisfies → reuse as-is
- ✅ If similar exists and partially satisfies → enhance/extend it
- ❌ **DO NOT** create duplicates with overlapping responsibilities

**Only create new if:**
- No suitable component exists, AND
- Extending existing would be inappropriate

### 2. Reusability & Structure

All UI code must be:
- ✅ Modular and reusable
- ✅ Aligned with existing styling (Tailwind, shadcn/ui, Radiant theme)
- ✅ Structured to separate layout, logic, presentation

### 3. Follow Feature Structure

- ✅ Feature-specific UI → `src/features/{feature-name}/components/`
- ✅ Route-level components → `src/features/{feature-name}/pages/`

---

## 📝 Work Order Traceability (ISO-Style)

**ALL code changes must be traceable to a work order.**

For every new or modified block, add a comment with:
- Work order ID (e.g., `WO-0021`)
- Date in `YYYY-MM-DD` format
- What the code does
- Why it was created or updated
- Related work orders (if applicable)

### Examples:

**TypeScript / JavaScript:**
```typescript
// [WO-0021] 2025-11-07
// Added enhanced notification routing for multi-tenant SMTP providers.
// Reason: Support per-tenant SMTP config overrides.
// Related: WO-0019 (Notification template refactor)
```

**SQL:**
```sql
-- [WO-0030] 2025-11-07
-- Backfilled is_active flag for existing tenants.
-- Reason: Align tenant records with new activation workflow.
-- Related: WO-0028 (Tenant onboarding API)
```

**React / JSX:**
```jsx
{/* [WO-0042] 2025-11-07
    Created TenantActivityCard component for dashboard.
    Reason: Consolidate activity display into reusable card.
    Related: WO-0040 (Dashboard layout refactor)
*/}
```

**This is MANDATORY for all code changes.**

---

## ✅ Pre-Work Checklist

Before starting ANY task:

1. ✅ Read this document (`{{PIPELINE_ROOT}}/core/methodology/PROJECT-RULES.md`)
2. ✅ Search for existing files/components/entities FIRST
3. ✅ Verify database objects exist (if DB work)
4. ✅ Check actual file structure (if frontend work)
5. ✅ Plan where files go (which feature directory?)
6. ✅ Add work order traceability comments
7. ✅ Use validator agents before marking "done"

---

## 🔐 Authentication & Security Rules

### API Key Authentication (WO-0207) - CRITICAL PLATFORM RULE

**⚠️ MANDATORY FOR ALL AI AGENTS AND DEVELOPERS:**

The `ApiKeyAuthGuard` is **OPT-IN ONLY**. It is **NEVER** applied globally.

**RULE:**
- API key authentication must be explicitly enabled per-endpoint
- Use `@UseGuards(ApiKeyAuthGuard)` only on server-to-server endpoints
- DO NOT auto-apply or suggest global application

**Correct Pattern:**
```typescript
// Only for server-to-server endpoints
@UseGuards(ApiKeyAuthGuard)
@Get('/external-webhook-callback')
async handleExternalWebhook(@Req() req) {
  // Machine-to-machine authentication
}
```

**Rationale:**
- Prevents accidental exposure of user endpoints to machine auth
- Maintains separation between human (JWT) and machine (API key) authentication
- Explicit security over implicit

**Documentation:**
- `{{DOCS_DIR}}/SystemDesign/Security/API-Keys.md`
- `{{DOCS_DIR}}/{{PROJECT_NAME}}/00-Platform/{{PROJECT_NAME}}-Platform-Master-Spec.md` (Section 2.6)

---

## 🎯 Validator Agents

Use these specialist agents to validate work:

- **`project-validator-expert`** - Final check before completion (files exist, no hallucinations, correct structure)
- **`database-validator-expert`** - Pre-flight check for DB work (schema matches assumptions)
- **`frontend-validator-expert`** - Enforce frontend structure rules (correct directories, no duplication, proper imports)

**Call validators BEFORE marking any work as complete.**

---

## 📚 Reference Examples

**Look at these before building:**
- `/features/notifications/` - Complex feature (pages, components, services, wizard)
- `/features/rbac/` - RBAC feature (components, pages, routing)
- `/features/settings/` - Settings pattern (layout + tabs)

---

**Remember: When in doubt, SEARCH FIRST. Never assume. Never hallucinate.**
