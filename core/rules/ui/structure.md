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
