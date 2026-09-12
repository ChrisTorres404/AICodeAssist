---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.directive.ts"
  - "**/*.pipe.ts"
  - "**/*.guard.ts"
  - "**/*.resolver.ts"
  - "**/*.module.ts"
---
# Angular Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Angular specific content.

Worked examples: skill `angular-patterns`.

## Version Awareness

Always check the project's Angular version before writing code — features differ significantly between versions. Run `ng version` or inspect `package.json`. When creating a new project, do not pin a version unless the user specifies one.

After generating or modifying Angular code, always run `ng build` to catch errors before finishing.

## File Naming

Follow Angular CLI conventions — one artifact per file:

- `user-profile.component.ts` + `user-profile.component.html` + `user-profile.component.spec.ts`
- `user.service.ts`, `auth.guard.ts`, `date-format.pipe.ts`
- Feature folders: `features/users/`, `features/auth/`
- Generate with the CLI: `ng generate component features/users/user-card`

## Components

Prefer standalone components (v17+ default). Use `OnPush` change detection on all new components. Declare inputs with `input.required<T>()` and outputs with `output<T>()`.

## Dependency Injection

Use `inject()` over constructor injection. Keep constructors empty or remove them entirely — constructor injection is verbose and harder to tree-shake.

Use `InjectionToken` for non-class dependencies: declare the token, provide it with `useValue`, and read it with `inject()`.

## Signals

### Core Primitives

Use `signal()` for state, `computed()` for derived values, and `.update()` to write from the previous value.

### `linkedSignal` — Writable Derived State

Use `linkedSignal` when a signal must reset or adapt when a source changes, but also be independently writable.

### `resource` — Async Data into Signals

Use `resource()` to fetch async data reactively without manual subscriptions. Access it with `userResource.value()`, `userResource.isLoading()`, `userResource.error()`.

### `effect` Usage

Use `effect()` only for side effects that must react to signal changes (logging, third-party DOM manipulation). Never use effects to synchronize signals — use `computed` or `linkedSignal` instead. For DOM work after render, use `afterRenderEffect`.

## Templates

Use v17+ block syntax. Always provide `track` in `@for`:

```html
@for (item of items(); track item.id) {
  <app-item [item]="item" />
}

@if (isLoading()) {
  <app-spinner />
} @else if (error()) {
  <app-error [message]="error()" />
} @else {
  <app-content [data]="data()" />
}
```

No logic in templates beyond simple conditionals — move to component methods or pipes.

## Forms

Choose the form strategy that matches the project's existing approach:

- **Signal Forms** (v21+): Preferred for new projects on v21+. Signal-based form state.
- **Reactive Forms**: `FormBuilder` + `FormGroup` + `FormControl`. Best for complex forms with dynamic validation.
- **Template-Driven Forms**: `ngModel`. Suitable for simple forms only.

## Component Styles

Use component-level styles with `ViewEncapsulation.Emulated` (default). Avoid `ViewEncapsulation.None` unless building a design system that intentionally bleeds styles.

- Scope styles to the component — do not use global class names inside component stylesheets
- Use `:host` for host element styling
- Prefer CSS custom properties for themeable values

## Change Detection

- Default to `ChangeDetectionStrategy.OnPush` on all new components
- Signals and `async` pipe handle detection automatically — avoid `markForCheck()` and `detectChanges()`
- Never mutate `@Input()` objects in place when using OnPush
