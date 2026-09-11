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
- Functions do one thing. Deep nesting means an early return is missing.
- Handle errors explicitly at every boundary. Never swallow one silently.
- Validate at system boundaries: user input, external responses, file content.
- Prefer creating new values over mutating shared ones.

## Simplicity

- The simplest solution that actually works.
- Extract repetition when it is real, not speculative.
- Do not build for a future that has not asked for anything.

## Before declaring done

Read every changed file, line by line, with one question: would a reviewer
approve this for production right now? If not, it is not done.
