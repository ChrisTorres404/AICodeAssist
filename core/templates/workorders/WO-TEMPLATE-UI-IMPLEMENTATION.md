# WO-XXXX: UI Implementation Design

**Work Order:** WO-XXXX - [Title]
**Status:** NOT STARTED | IN PROGRESS | IMPLEMENTATION COMPLETE
**App:** {{ADMIN_APP}} | {{PORTAL_APP}} | [other]
**Last Updated:** [YYYY-MM-DD]

---

## 1. Overview

### Feature Description
[1-2 paragraphs describing what this UI feature accomplishes and its user-facing value]

### Backend/SDK Dependencies
- **SDK Resource:** `client.[resource].[method]()` (WO-XXXX)
- **API Endpoint:** `[METHOD] /v1/[path]`
- **Backend WO:** WO-XXXX

### User Experience
[Describe the user flow - what user does, what they see, expected outcomes]

**Target Persona:** [Admin | End User | Developer]

---

## 2. Component Architecture

### Component Tree

```
[ParentPage]
├── [ParentComponent]
│   ├── [ChildComponent1]
│   │   ├── [Subcomponent]
│   │   └── [Subcomponent]
│   ├── [ChildComponent2]
│   └── [ChildComponent3]
└── [Dialogs/Modals]
    ├── [Dialog1]
    └── [Dialog2]
```

### Feature Directory Structure

```
src/features/[feature-name]/
├── pages/
│   └── [Page].tsx              # Route component
├── components/
│   ├── [Component1].tsx        # [Description]
│   ├── [Component2].tsx        # [Description]
│   ├── dialogs/
│   │   └── [Dialog].tsx        # [Description]
│   └── tables/
│       └── [Table].tsx         # [Description]
├── hooks/
│   ├── use[Feature].ts         # Main data fetching hook
│   └── use[Feature]Mutations.ts # Mutation hooks
├── services/
│   └── [feature].service.ts    # API/SDK wrapper (if needed)
└── types/
    └── [feature].types.ts      # Feature-specific types
```

---

## 3. Component Specifications

### [Component 1 Name]

**Location:** `src/features/[feature]/components/[Component1].tsx`

**Purpose:** [What this component does]

**Props:**
```typescript
interface [Component1]Props {
  [prop]: [type];           // [description]
  [prop]?: [type];          // [optional - description]
  on[Event]: () => void;    // [callback description]
}
```

**State:**
```typescript
// Local state
const [stateVar, setStateVar] = useState<[type]>([initialValue]);

// Server state (React Query)
const { data, isLoading, error } = use[Feature]();
```

**Behavior:**
- [Behavior 1]
- [Behavior 2]
- [Loading state handling]
- [Error state handling]

**Example:**
```tsx
<[Component1]
  [prop]={value}
  on[Event]={() => handleEvent()}
/>
```

### [Component 2 Name]

[Repeat structure for each component]

---

## 4. Data Fetching & Hooks

### use[Feature] Hook

**Location:** `src/features/[feature]/hooks/use[Feature].ts`

```typescript
import { useQuery } from '@tanstack/react-query';
import { use{{PROJECT_NAME}}Client } from '@/hooks/use{{PROJECT_NAME}}Client';

export function use[Feature]() {
  const client = use{{PROJECT_NAME}}Client();

  return useQuery({
    queryKey: ['[feature]'],
    queryFn: () => client.[resource].[method](),
    staleTime: [milliseconds],
    // other options
  });
}
```

### use[Feature]Mutations Hook

**Location:** `src/features/[feature]/hooks/use[Feature]Mutations.ts`

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function use[Action]() {
  const client = use{{PROJECT_NAME}}Client();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: [Type]) => client.[resource].[method](data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['[feature]'] });
      toast.success('[Success message]');
    },
    onError: (error) => {
      toast.error('[Error message]');
    },
  });
}
```

---

## 5. UI Patterns & Styling

### Design System Components Used
- `@/components/ui/[component]` - [Usage]
- `@/components/ui/[component]` - [Usage]
- [shadcn/ui components]

### Tailwind Classes Pattern
```tsx
// Container
<div className="space-y-6 p-6">

// Card layout
<Card className="p-6">
  <CardHeader>
    <CardTitle>[Title]</CardTitle>
    <CardDescription>[Description]</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Content */}
  </CardContent>
</Card>

// Form layout
<form className="space-y-4">
  <div className="grid grid-cols-2 gap-4">
    {/* Form fields */}
  </div>
</form>
```

### Responsive Breakpoints
- Mobile: `< 640px` - [Layout description]
- Tablet: `640px - 1024px` - [Layout description]
- Desktop: `> 1024px` - [Layout description]

---

## 6. State Management

### Local State
```typescript
// Component-level state
const [isOpen, setIsOpen] = useState(false);
const [selectedItem, setSelectedItem] = useState<[Type] | null>(null);
```

### Server State (React Query)
```typescript
// Query keys
const QUERY_KEYS = {
  [feature]: ['[feature]'],
  [featureDetail]: (id: string) => ['[feature]', id],
};
```

### Form State (if applicable)
```typescript
// Using react-hook-form + zod
const form = useForm<[FormType]>({
  resolver: zodResolver([schema]),
  defaultValues: {
    [field]: [defaultValue],
  },
});
```

---

## 7. User Interactions

### Actions & Events

| User Action | Handler | Result |
|-------------|---------|--------|
| Click [button] | `handle[Action]()` | [What happens] |
| Submit form | `onSubmit()` | [What happens] |
| [Action] | `handle[Action]()` | [What happens] |

### Loading States
- **Initial load:** [Skeleton / Spinner / placeholder]
- **Mutation in progress:** [Button disabled / Loading indicator]
- **Refetching:** [Background indicator / None]

### Error States
- **Network error:** [Toast / Error boundary / Inline message]
- **Validation error:** [Form field errors / Toast]
- **Permission error:** [Redirect / Toast / Disabled state]

### Empty States
- **No data:** [Empty state component / Message / CTA]
- **No results (filtered):** [Reset filters prompt]

---

## 8. Accessibility

### ARIA Labels
```tsx
<button aria-label="[Accessible name]">
<div role="[role]" aria-describedby="[id]">
```

### Keyboard Navigation
- Tab order: [Description]
- Enter/Space: [Activates buttons]
- Escape: [Closes modals]
- Arrow keys: [Navigation in lists/tables]

### Focus Management
- Modal open: Focus first focusable element
- Modal close: Return focus to trigger
- Form submit: Focus first error or success message

---

## 9. Testing Strategy (UI Level)

### Component Tests

```typescript
describe('[Component]', () => {
  it('should render [expected content]');
  it('should handle loading state');
  it('should handle error state');
  it('should call [handler] when [action]');
  it('should display [data] correctly');
});
```

### Integration Tests

```typescript
describe('[Feature] Page', () => {
  it('should fetch and display [data]');
  it('should handle [user flow]');
  it('should show success toast on [action]');
  it('should show error toast on failure');
});
```

### Manual Test Cases
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]
- [ ] Mobile responsive check
- [ ] Keyboard navigation works
- [ ] Screen reader announces correctly

---

## 10. Implementation Status

### Completed Components
- [ ] Page component
- [ ] [Component 1]
- [ ] [Component 2]
- [ ] [Hook 1]
- [ ] [Hook 2]
- [ ] Types

### Files to Create

**Pages:**
- `src/features/[feature]/pages/[Page].tsx`

**Components:**
- `src/features/[feature]/components/[Component1].tsx`
- `src/features/[feature]/components/[Component2].tsx`

**Hooks:**
- `src/features/[feature]/hooks/use[Feature].ts`
- `src/features/[feature]/hooks/use[Feature]Mutations.ts`

**Types:**
- `src/features/[feature]/types/[feature].types.ts`

**Route Registration:**
- Update `app/(dashboard)/[path]/page.tsx` or router config

---

## 11. Screenshots / Wireframes

### [View 1]
```
┌──────────────────────────────────────────────────────────────┐
│ [Header]                                              [Actions]│
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  [Main Content Area]                                         │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │    Card 1      │  │    Card 2      │  │    Card 3      │  │
│  └────────────────┘  └────────────────┘  └────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### [View 2 - Dialog/Modal]
```
┌──────────────────────────────────────┐
│ [Dialog Title]                    X │
├──────────────────────────────────────┤
│                                      │
│  [Form/Content]                      │
│                                      │
├──────────────────────────────────────┤
│              [Cancel]  [Confirm]     │
└──────────────────────────────────────┘
```

---

## 12. Open Questions / TODOs

- [ ] **Question:** [Open question needing decision]
- [ ] **Question:** [Open question needing decision]
- [ ] **TODO:** [Future enhancement]
- [ ] **TODO:** [Future enhancement]

---

## References

- **Design:** [Figma/design link if applicable]
- **SDK:** WO-XXXX - [SDK WO reference]
- **Backend:** WO-XXXX - [Backend WO reference]
- **Similar Feature:** `src/features/[similar]/` - Reference implementation
