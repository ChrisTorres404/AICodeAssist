# WO-XXXX: SDK Implementation Design

**Work Order:** WO-XXXX - [Title]
**Status:** NOT STARTED | IN PROGRESS | IMPLEMENTATION COMPLETE
**SDK Package:** {{SDK_PKG}}
**SDK Version:** [version]
**Last Updated:** [YYYY-MM-DD]

---

## 1. Overview

### Backend Feature
[1-2 paragraphs describing what the backend provides that this SDK will consume]

The backend provides:
- [Endpoint 1 and what it does]
- [Endpoint 2 and what it does]
- [Any special backend behavior (e.g., cookie handling, rotation, etc.)]

### SDK Implementation
The SDK exposes:
- [Method 1 and what it does]
- [Method 2 and what it does]
- [Events emitted]
- [How it integrates with {{PROJECT_NAME}}Client]

**Developer Experience:**
```typescript
// Example usage code that developers will write
const client = new {{PROJECT_NAME}}Client({ apiUrl: '...' });

const result = await client.[namespace].[method]({
  // parameters
});
```

---

## 2. Relevant Backend APIs & Data Models

### HTTP Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `[METHOD]` | `/v1/[path]` | [Description] |
| `[METHOD]` | `/v1/[path]` | [Description] |

### Request/Response Shapes

**[METHOD] /v1/[endpoint]**
```typescript
// Request
{
  [field]: [type];  // [description]
  [field]?: [type]; // [optional - description]
}

// Response (200 OK - Success):
{
  [field]: [type];  // [description]
}

// Response ([status] - [error case]):
{
  error: "[error_code]",
  message: "[error message]"
}
```

### Set-Cookie Headers (if applicable)
```
Set-Cookie: __Host-{{PROJECT_SLUG}}_[name]=<value>; Path=/; Secure; HttpOnly; SameSite=Strict
```

---

## 3. SDK Surface Design

### TypeScript API

#### [Namespace].[Method]()

**Location:** `packages/{{SDK_PKG}}/src/[path]/[File].ts`

```typescript
export interface I[Namespace] {
  /**
   * [JSDoc description]
   *
   * @param [param] - [description]
   * @returns [description]
   * @throws [ErrorType] on failure
   */
  [methodName]([params]: [ParamType]): Promise<[ReturnType]>;
}

/**
 * [Type description]
 */
export interface [ParamType] {
  [field]: [type];
  [field]?: [type];
}

/**
 * [Type description]
 */
export interface [ReturnType] {
  [field]: [type];
}
```

### Integration with {{PROJECT_NAME}}Client

```typescript
// {{PROJECT_NAME}}Client constructor
this.[namespace] = new [Namespace](
  this.apiUrl,
  this.httpClient,
  this.debug,
  // ... any callbacks
);

// OR for resources
this.[resource] = new [Resource](this.browserHttp as any);
```

### Example Usage

```typescript
import { {{PROJECT_NAME}}Client, [ErrorType], [ErrorCode] } from '@{{PROJECT_SLUG}}/sdk';

const client = new {{PROJECT_NAME}}Client({ apiUrl: 'https://api.example.com' });

try {
  const result = await client.[namespace].[method]({
    // params
  });

  // Handle success
  console.log(result);
} catch (error) {
  if (error instanceof [ErrorType]) {
    switch (error.code) {
      case [ErrorCode].[CODE]:
        // Handle specific error
        break;
      default:
        // Handle unknown error
    }
  }
}
```

---

## 4. Behavior & Flow

### [Flow Name] Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        [Flow Name]                           │
└─────────────────────────────────────────────────────────────┘

User calls: client.[namespace].[method]()
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  1. [Step description]                                      │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
    ┌─────────┐         ┌─────────┐          ┌─────────┐
    │ Success │         │ [Case]  │          │  Error  │
    └─────────┘         └─────────┘          └─────────┘
         │                    │                    │
         ▼                    ▼                    ▼
[Continue flow...]
```

### [Secondary Flow] (if applicable)

[Additional flow diagrams]

---

## 5. Error Handling & Edge Cases

### Error Code Mapping

```typescript
// Map HTTP status to [ErrorCode]
switch (response.status) {
  case [status]:
    return [ErrorCode].[CODE];
  case [status]:
    return [ErrorCode].[CODE];
  default:
    return [ErrorCode].UNKNOWN_ERROR;
}
```

### Edge Cases

| Scenario | Handling |
|----------|----------|
| [Edge case 1] | [How SDK handles it] |
| [Edge case 2] | [How SDK handles it] |
| [Edge case 3] | [How SDK handles it] |

### [Special Considerations]

**CRITICAL:** [Any critical implementation notes, e.g., credentials: 'include']
```typescript
// Code example showing critical implementation detail
```

---

## 6. Testing Strategy (SDK Level)

### Unit Tests

```typescript
describe('[Namespace].[method]', () => {
  describe('successful [operation]', () => {
    it('should call [METHOD] /v1/[endpoint]');
    it('should [expected behavior]');
    it('should return [expected return type]');
  });

  describe('[alternative scenario]', () => {
    it('should [behavior]');
  });

  describe('error handling', () => {
    it('should throw [ErrorType] on [condition]');
    it('should throw [ErrorType] on [condition]');
  });
});
```

### Integration Tests

```typescript
describe('[Feature] Integration', () => {
  it('should [end-to-end behavior]');
  it('should [integration behavior]');
});
```

### Backend Test Mapping
- `{{TESTING_DIR}}/suites/wo-XXXX-[test].sh` - [Description]
- [Other related tests]

---

## 7. Compatibility & Dependencies

### Dependencies on Other SDK Modules
- **WO-XXXX:** [What it provides that this WO uses]
- **WO-YYYY:** [What it provides that this WO uses]
- Uses `[Type]` from `types/[file].ts`

### Ordering Constraints
- **Requires:** WO-XXXX, WO-YYYY
- **Related:** WO-ZZZZ (related feature)

### Backend Contract
- [Any backend requirements or assumptions]

---

## 8. Implementation Status

### Completed Components
- [ ] [Component 1]
- [ ] [Component 2]
- [ ] [Component 3]

### Files to Create/Modify
- `packages/{{SDK_PKG}}/src/[path]/[file].ts` - [Description]
- `packages/{{SDK_PKG}}/src/types/[file].ts` - [Types]
- `packages/{{SDK_PKG}}/src/index.ts` - [Exports]

---

## 9. Open Questions / TODOs

- [ ] **Question:** [Open question needing decision]
- [ ] **Question:** [Open question needing decision]
- [ ] **TODO:** [Future enhancement]
- [ ] **TODO:** [Future enhancement]

---

## References

- **Fusion Source:** [Fusion document reference]
- **Flows:** [Flow document reference]
- **Backend:** WO-XXXX - [Backend WO reference]
