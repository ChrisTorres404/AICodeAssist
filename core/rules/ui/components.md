---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/features/**"
  - "**/components/**"
  - "**/pages/**"
  - "**/app/**"
---
# UI Components

## Mandatory

- **The project's design system components only.** One component library,
  one styling system. No ad-hoc styling beside it, no second library.
- **Reusable: accept props.** A component that only works in one place with
  hardcoded content is a page fragment, not a component.
- **Follow existing patterns.** Read a sibling before writing a new one.
- **No duplicates.** Search before creating. Two components that do the same
  thing is a defect, not a convenience.
- **No `any` in props.** Strict types for every prop.
- **Every new file carries the work-order header:**

```typescript
/**
 * WO-####: [Work Order Title]
 * DATE: YYYY-MM-DD
 * WHAT: [What changed]
 * WHY: [Reason]
 * IMPACT: [Impact]
 */
```

## Consistency the design system owns

Labels, spacing, radius, typography scale, state colours, and scope
indicators are decided once by the design system and never per component.
If the design system has no answer, the answer is a design-system change,
not a local override. Record the project's specifics in an agent overlay
under `core/agents/overlays/` so every UI agent applies them.

## Every component

- Handles loading, empty, and error states, using the shared state components.
- Wrapped by an error boundary at the feature or page level.
- Renders correctly at phone width.
