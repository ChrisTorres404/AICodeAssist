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
# UI Structure

## Read This First

Read this before creating any UI file. It is shorter than the time spent
undoing a file that went to the wrong place, and every rule in it is checked
by a validator rather than by a reviewer's memory.

## Primary rule

**All feature code goes in the features directory:** `src/features/{feature-name}/`
when the project has a `src/` directory, otherwise `features/{feature-name}/` at
the app root. One location per project; validators check this one rule.

Never create feature code in:
- `components/{feature-name}/`
- `pages/{feature-name}/`
- `src/{feature-name}/`

## Feature layout

```
src/features/{feature-name}/      (or features/{feature-name}/ without src/)
├── pages/           # Route components
├── components/      # Feature UI components
│   ├── dialogs/     # Modals and dialogs, one per file
│   ├── forms/       # Forms, one per file
│   └── tables/      # Tables, one per file
├── hooks/           # Feature hooks
├── services/        # Feature APIs and business logic
└── types/           # Feature TypeScript types
```

Truly shared components, used by more than one feature, go in
`components/common/` beside `features/`. Only then.

## Existing shared directories: use them, do not restructure them

Shared trees already in the codebase — shared components, shared services,
core utilities, route-level pages — exist to be used. Import from them
freely. Add to them when a work order explicitly calls for a genuinely
shared component.

Do not grow a new feature inside them. Feature-specific logic scattered
under a shared tree is how the same feature ends up in three places. New
feature trees go in the features directory; the shared trees stay shared.

Never create a nested duplicate of the application path —
`apps/<app>/apps/<app>/src/features/...`. It happens when a command runs
from the wrong working directory. It type-checks, and it is invisible in a
diff. Check the path before creating the first file.

## Import paths

- `@/` for shared: `import { Button } from '@/components/ui/button'`
- Relative within a feature: `import { TemplateCard } from './TemplateCard'`
- Never deep relative: `'../../../components/ui/button'`

## Before creating any UI file

1. New feature? Create `/features/{name}/`.
2. Adding to an existing feature? Add to `/features/{existing}/`.
3. Truly shared? Only then `/components/common/`.
4. **Does a similar component already exist? Search first. Reuse it.**
5. Modal or dialog? Its own file under `components/dialogs/`.
6. Form? Its own file under `components/forms/`.

Check this list before every file creation, not after.

## Examples to Reference

Look at these before building. There is no canonical example feature shipped
with the pipeline, because the right example is one from this codebase:

- **A complex feature** — one with pages, components, services, and a
  multi-step flow. It shows how far the layout scales.
- **A simple feature** — one with only pages and hooks. It shows the minimum
  that is still correct.
- **A settings-shaped feature** — a layout with tabs or sections. It shows how
  shared chrome and per-section content divide.

Read the most similar one end to end — its directory layout, its naming, its
data fetching, its error handling, its tests — and follow it. Consistency with
what is already here beats what you would have chosen on a blank page.

---

**For the agent reading this:** keep these rules in working context and check
them before every file creation, not after. They are loaded automatically for
the paths in the frontmatter, so the check costs nothing; re-reading them is
cheaper than moving a file that has already been imported from.
