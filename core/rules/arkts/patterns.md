---
paths:
  - "**/*.ets"
  - "**/*.ts"
---
# HarmonyOS / ArkTS Patterns

> This file extends [common/patterns.md](../common/patterns.md) with HarmonyOS and ArkTS-specific patterns.

Worked examples: skill `arkts-patterns`.

## State Management: V2 Only

**MUST use** ArkUI State Management V2. V1 decorators are deprecated and must not be used.

### V2 Decorators

| Decorator | Purpose |
|-----------|---------|
| `@ComponentV2` | Marks a struct as a V2 component |
| `@Local` | Local state within a component |
| `@Param` | Props received from parent (read-only) |
| `@Event` | Callback events from child to parent |
| `@Provider` | Provides state to descendant components |
| `@Consumer` | Consumes state from ancestor `@Provider` |
| `@Monitor` | Watches for state changes (replaces V1 `@Watch`) |
| `@Computed` | Derived/computed values |
| `@ObservedV2` | Makes a class observable for V2 state management |
| `@Trace` | Marks observable properties in `@ObservedV2` classes |

### Prohibited V1 Decorators

Never use: `@State`, `@Prop`, `@Link`, `@ObjectLink`, `@Observed`, `@Provide`, `@Consume`, `@Watch`, `@Component` (use `@ComponentV2` instead).

### V2 Component Example

### State Synchronization

## Routing: Navigation Only

**MUST use** `Navigation` component with `NavPathStack`. Never use `@ohos.router`.

### Navigation Setup

### Page Navigation

### NavDestination Sub-page

## Architecture Pattern: MVVM

Recommended architecture for HarmonyOS applications:

```
feature/
  |-- model/           # Data models (@ObservedV2 classes)
  |-- viewmodel/       # Business logic (ViewModel classes)
  |-- view/            # UI components (@ComponentV2 structs)
  |-- service/         # API calls, data access
```

- **View**: Only rendering logic, no business logic in `build()`
- **ViewModel**: All business logic encapsulated here
- **Model**: Pure data classes with `@ObservedV2` and `@Trace`
- **Service**: Network requests, database operations, file I/O

## ArkUI Animation Patterns

### State-Driven Animation

### Animation Rules

- Prefer native HarmonyOS animation APIs and advanced templates
- Use declarative UI with state-driven animations (change state variables to trigger animations)
- Set `renderGroup(true)` for complex sub-component animations to reduce render batches
- **NEVER** frequently change `width`, `height`, `padding`, `margin` during animations - severe performance impact
- Use `animateTo` for explicit animation control
- Prefer `transform` (translate, scale, rotate) and `opacity` for performant animations

## Performance Patterns

### LazyForEach for Large Lists

### Component Reuse

- Extract reusable components into separate files
- Use `@Builder` for lightweight UI fragments within a component
- Use `@Param` for configurable components

## Resource References

Always define UI constants as resources and reference via `$r()`.
