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
- **Separable layout, logic, and presentation.** A component that fetches,
  decides, and renders is three components.
- **No `any` in props.** Strict types for every prop.
- **Every new file carries the work-order header:**

```typescript
// WO-####: <short title>
```

One line, first in the file, on new files only; see the coding-style rule.

## Search before creating: the decision ladder

Before writing any component, search for one that already does the job.

| What you find | What you do |
|---|---|
| A component that fully satisfies the need | Reuse it as it is |
| A component that partly satisfies it | Extend it, keeping its existing callers working |
| Nothing close | Only then write a new one |

Write a new component only when no suitable one exists *and* extending an
existing one would be the wrong shape. Record which of the three happened in
the work order; "I looked and found nothing" is a finding, not an excuse.

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
