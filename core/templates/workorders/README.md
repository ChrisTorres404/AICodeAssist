# Work Order Templates

## MANDATORY: Work Order Methodology

**ALL work orders in the {{PROJECT_NAME}} MUST follow this structure. No exceptions.**

---

## Required Folder Structure

Every work order MUST have its own folder with the following files:

```
WO-XXXX-[Descriptive-Name]/
├── WO-XXXX-SPEC.md                 # Technical specification (REQUIRED)
├── WO-XXXX-CHECKLIST.md            # Implementation checklist (REQUIRED)
├── WO-XXXX-TASK-BREAKDOWN.md       # Task breakdown with estimates (REQUIRED)
├── WO-XXXX-Prompt.md               # AI implementation prompt (REQUIRED)
├── WO-XXXX-CLOSEOUT.md             # Closeout report (REQUIRED on completion)
├── WO-XXXX-sdk-implementation.md   # SDK implementation details (if SDK work)
└── WO-XXXX-ui-implementation.md    # UI implementation details (if UI work)
```

---

## Template Files

### Core Templates (REQUIRED for all WOs)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-SPEC.md` | Technical specification with code examples | Always |
| `WO-TEMPLATE-CHECKLIST.md` | Implementation checklist with phases | Always |
| `WO-TEMPLATE-TASK-BREAKDOWN.md` | Task breakdown with time estimates | Always |
| `WO-TEMPLATE-PROMPT.md` | AI implementation prompt | Always |
| `WO-TEMPLATE-CLOSEOUT.md` | Closeout report template | On completion |

### Alternative Main Spec Template

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-MAIN.md` | High-level work order spec (less detailed) | Simple WOs without code |

### Specialized Templates (Use when applicable)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `WO-TEMPLATE-SDK-IMPLEMENTATION.md` | SDK resource/method design | WO involves SDK work |
| `WO-TEMPLATE-UI-IMPLEMENTATION.md` | UI component specifications | WO involves frontend UI work |

---

## How to Create a New Work Order

### Step 1: Create the Folder
```bash
mkdir -p {{WORKORDERS_DIR}}/WO-XXXX-[Descriptive-Name]
```

### Step 2: Copy Core Templates (REQUIRED)
Copy all core template files to the new folder and rename them:
- `WO-TEMPLATE-SPEC.md` → `WO-XXXX-SPEC.md` (technical spec with code)
- `WO-TEMPLATE-CHECKLIST.md` → `WO-XXXX-CHECKLIST.md`
- `WO-TEMPLATE-TASK-BREAKDOWN.md` → `WO-XXXX-TASK-BREAKDOWN.md`
- `WO-TEMPLATE-PROMPT.md` → `WO-XXXX-Prompt.md`

**Alternative:** For simple WOs without code, use `WO-TEMPLATE-MAIN.md` → `WO-XXXX-[Title].md`

### Step 3: Copy Specialized Templates (if applicable)
If the WO involves SDK or UI work, also copy:
- `WO-TEMPLATE-SDK-IMPLEMENTATION.md` → `WO-XXXX-sdk-implementation.md` (for SDK work)
- `WO-TEMPLATE-UI-IMPLEMENTATION.md` → `WO-XXXX-ui-implementation.md` (for UI work)

### Step 4: Fill In Details
Replace all `[placeholders]` with actual content.

### Step 5: On Completion
Create `WO-XXXX-CLOSEOUT.md` using `WO-TEMPLATE-CLOSEOUT.md`.

---

## Gold Standard Examples

Reference these completed work orders for best practices:

- Any work order in your pack with a full `SCTPVC` lifecycle. `pack index` lists them.

---

## Non-Negotiable Rules

1. **Every WO gets its own folder** - No loose `.md` files in the parent directory
2. **All 4 required files must exist** - Main spec, checklist, task breakdown, prompt
3. **Closeout on completion** - Every completed WO must have a closeout report
4. **Consistent naming** - `WO-XXXX-[Title].md` format always
5. **No shortcuts** - This methodology ensures quality and traceability

---

## Work Order Numbering

| Series | Range | Theme |
|--------|-------|-------|
| 0000-0099 | Foundation | Core platform setup |
| 0100-0199 | Auth Core | Authentication fundamentals |
| 0200-0299 | RBAC | Role-based access control |
| 0300-0399 | API/SDK | Public API and SDK |
| 0400-0499 | Auth Flows | Login, logout, refresh |
| 0500-0599 | Frontend SDK | Browser-first SDK |
| 0600-0699 | SDK Completion | Extended SDK features |
| 0700-0799 | Notifications | Email, push, webhooks |
| 0800-0899 | Integrations | Third-party integrations |
| 0900-0999 | Settings | Configuration system |
| 1000-1099 | Security | Security hardening |
| 1100-1199 | Validation | Input validation |
| 1200-1299 | Sessions | Session management |
| 1300-1399 | GDPR | Privacy compliance |
| 1400-1499 | Observability | Logging, metrics, dashboards |
| 1500-1599 | User Management | User CRUD, profiles |
| 1600-1699 | Registration | Signup flows |
| 1700-1799 | Tenancy | Multi-tenant features |
| 1800-1899 | Licensing | Subscription management |
| 1900-1999 | Provisioning | Customer provisioning |
| 2000-2099 | API Keys | API key management |
| 2100-2199 | Admin UI | Admin dashboard |
| 2200-2299 | User Profile | Profile enhancements |
| 2300-2399 | Organizations | Org management |
| 2400-2499 | Control Plane | Platform separation |
| 2500-2599 | IAM Security | Tenant isolation, limits |
| 3000-3099 | Reserved | Future use |
| 3100-3199 | Reserved | Future use |
| 3200-3299 | Usage/Billing | API usage, rate limiting |

---

## Validation Checklist

Before considering a work order "created", verify:

- [ ] Folder exists with correct name (`WO-XXXX-[Name]/`)
- [ ] Technical spec file exists (`WO-XXXX-SPEC.md`)
- [ ] Checklist exists (`WO-XXXX-CHECKLIST.md`)
- [ ] Task breakdown exists (`WO-XXXX-TASK-BREAKDOWN.md`)
- [ ] Prompt exists (`WO-XXXX-Prompt.md`)
- [ ] SDK implementation exists (`WO-XXXX-sdk-implementation.md`) - if SDK work
- [ ] UI implementation exists (`WO-XXXX-ui-implementation.md`) - if UI work
- [ ] All placeholders replaced with real content
- [ ] Dependencies listed
- [ ] Success criteria defined
- [ ] File locations specified
