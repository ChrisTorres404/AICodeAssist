# Coding Style

## Production quality or nothing

- No `TODO: implement later`. Finish it or do not ship it.
- No `throw new Error('Not implemented')`, no stub returns, no dev-only fallbacks.
- No debug logging left behind. Use the project's logger. A hook checks.
- No code referencing a file, table, column, or method you have not verified exists.
- No magic numbers. Configuration and constants.
- Proper types. `any` is a bug report.

## Shape

- Prefer small cohesive files. Extract when a file stops fitting in your head.
  A file past roughly 300 lines or a function past roughly 50 is a signal to
  split, not a violation to argue about. The UI rules set hard limits for UI
  units; outside them, treat these as the point where you look for the seam.
- Functions do one thing. Deep nesting means an early return is missing.
- Handle errors explicitly at every boundary. Never swallow one silently.
- Validate at system boundaries: user input, external responses, file content.
- Prefer creating new values over mutating shared ones.

## File organization

- Group by feature, not by kind. A feature's code lives together; a directory
  named for a layer that spans every feature becomes a dumping ground.
- One substantial exported unit per file, named after the file.
- A file that needs a scroll to find what it exports is two files.

## Import paths

Use the project's configured alias for shared modules, not a path that depends
on where the importer happens to sit:

```typescript
// CORRECT
import { Button } from '@/components/ui/button';
import { ErrorBoundary } from '@/components/common/ErrorBoundary';
```

Use relative imports within a module or feature:

```typescript
// CORRECT
import { TemplateCard } from './TemplateCard';
import { useTemplates } from '../hooks/useTemplates';
```

Never chain deep relative paths out of a module:

```typescript
// WRONG — resolves today, breaks the moment the file moves, and hides
// the fact that the import crossed a module boundary
import { Button } from '../../../components/ui/button';
```

## Verify before reporting

After creating or changing files, run the project's type-check and linter over
them and fix everything they report. Import and type errors are fixed before
the work is described as complete, not reported alongside it as caveats.

## Simplicity

- The simplest solution that actually works.
- Extract repetition when it is real, not speculative.
- Do not build for a future that has not asked for anything.

## Before declaring done

Read every changed file, line by line, with one question: would a reviewer
approve this for production right now? If not, it is not done.

## Work-order header

Every code change is traceable to its work order in the code itself. Three forms,
in the language's own comment syntax:

1. **Header block** on every new file and on every substantive change (the
   standard from `core/instructions/01-create-work-orders.md`):

   ```
   /**
    * WO-####: [Work Order Title]
    * DATE: YYYY-MM-DD
    * WHAT: [What is being added or changed]
    * WHY: [Business or technical reason]
    * DATA: [What data, fields, or tables are affected]
    * IMPACT: [Who or what is affected]
    */
   ```

2. **One line** at the top of a small new file: `// WO-0412: Rate limiting`
   (`# WO-0412: ...`, `-- WO-0412: ...`).
3. **Dated tag** on a changed region inside an existing file:
   `// [WO-0412] 2026-01-15: description of the change`.

The commit message references the work order as well. A change carrying none of
the three forms is a finding for the validators.
