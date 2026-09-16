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
# UI Refactoring Triggers

Extraction is not optional once a limit is crossed. These numbers exist so
that the decision is mechanical.

## Line limits

| Unit | Limit | Over the limit |
|---|---|---|
| Page | 150 | Extract sections into components |
| Component | 200 | Extract sub-components |
| Modal or dialog | 50 | Its own file under `components/dialogs/` |
| Form | 80 | Its own file under `components/forms/` |
| Table | 100 | Its own file under `components/tables/` |
| Complex section | 80 | Its own component |

The limits above are hard: over the limit, the unit is extracted. The
100-line mark is a separate, mandatory trigger that fires earlier — reaching
it means the search for sub-components starts now, not when the hard limit
arrives.

## Mandatory checklist before finishing a UI file

- [ ] Is this a new feature? Create `features/{name}/`
- [ ] Adding to an existing feature? Add to `features/{existing}/`
- [ ] Truly shared component? Only then `components/common/`
- [ ] **Component over 100 lines? Extract sub-components**
- [ ] Modal or dialog? Its own file in `components/dialogs/`
- [ ] Form? Its own file in `components/forms/`
- [ ] Table? Its own file in `components/tables/`
- [ ] Page over 150, component over 200? Extract before going further

```typescript
// WRONG — 300-line page with an inline 150-line modal
export function UsersPage() {
  return <div>{/* everything */}</div>
}

// CORRECT — extracted
export function UsersPage() {            // 50 lines
  return <div><CreateUserDialog /></div>
}
// components/dialogs/CreateUserDialog.tsx — 150 lines
```

## Other triggers

- The same JSX appears in two places: extract a component.
- The same state and effects appear in two components: extract a hook.
- The same fetch logic appears twice: move it to `services/`.
- A component takes more than about seven props: it is doing two jobs.
- A file needs a scroll to find its return statement: split it.

## When refactoring

- Keep behaviour identical; tests stay green throughout.
- One extraction per commit, referenced to the work order.
- Remove the old code in the same change. No parallel copies.
