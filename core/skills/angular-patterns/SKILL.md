---
name: angular-patterns
description: Worked Angular examples covering smart/dumb component split, service layer, signals and `resource`, subscription cleanup, routing with guards and resolvers, dependency injection, HTTP interceptors, RxJS operator choice, forms, templates, and accessible styling. Use when writing or reviewing Angular components, services, routes, or templates and a rule needs a concrete example.
---

# Angular Patterns

Worked examples for the rules in [rules/angular/patterns.md](../../rules/angular/patterns.md) and [rules/angular/coding-style.md](../../rules/angular/coding-style.md).

## Reference examples

### Patterns (rules/angular/patterns.md)

#### Smart / Dumb Component Split

```typescript
// Smart — owns data
@Component({ standalone: true, changeDetection: ChangeDetectionStrategy.OnPush })
export class UserPageComponent {
  private userService = inject(UserService);
  user = toSignal(this.userService.getUser(this.userId));
}
```

```html
<!-- Dumb — pure presentation -->
<app-user-card [user]="user()" (select)="onSelect($event)" />
```

#### Service Layer

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  getUsers(): Observable<User[]> {
    return this.http.get<User[]>('/api/users');
  }
}
```

#### Async Data with `resource`

```typescript
export class UserDetailComponent {
  userId = input.required<string>();

  userResource = resource({
    request: () => ({ id: this.userId() }),
    loader: ({ request }) =>
      firstValueFrom(inject(UserService).getUser(request.id)),
  });
}
```

Access state: `userResource.value()`, `userResource.isLoading()`, `userResource.error()`, `userResource.reload()`.

#### Signal State Patterns

```typescript
// Local mutable state
count = signal(0);

// Derived (never duplicated)
doubled = computed(() => this.count() * 2);

// Writable derived state that resets with source
selectedItem = linkedSignal(() => this.items()[0]);

// Bridge Observable to signal
users = toSignal(this.userService.getUsers(), { initialValue: [] });
```

#### Subscription Cleanup

```typescript
export class UserComponent {
  private destroyRef = inject(DestroyRef);

  ngOnInit() {
    this.userService.updates$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(update => this.handleUpdate(update));
  }
}
```

#### Route Definition

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'admin',
    canMatch: [authGuard],           // CanMatch prevents loading the chunk at all
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES),
  },
  {
    path: 'users/:id',
    resolve: { user: userResolver },
    component: UserDetailComponent,
  },
];
```

#### Functional Guards

```typescript
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  return auth.isAuthenticated()
    ? true
    : inject(Router).createUrlTree(['/login']);
};
```

#### Data Resolvers

```typescript
export const userResolver: ResolveFn<User> = (route) => {
  return inject(UserService).getUser(route.paramMap.get('id')!);
};
```

#### View Transitions

Enable smooth route transitions with the View Transitions API:

```typescript
// app.config.ts
provideRouter(routes, withViewTransitions())
```

#### Scoped Providers

Provide services at component or route level when they should not be singletons:

```typescript
@Component({
  providers: [UserEditService],   // scoped to this component subtree
})
export class UserEditComponent {}
```

#### `InjectionToken`

```typescript
export const CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');

// In providers:
{ provide: CONFIG, useValue: appConfig }
{ provide: CONFIG, useFactory: () => loadConfig(), deps: [] }

// Consume:
private config = inject(CONFIG);
```

#### HTTP Interceptors

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).token();
  if (!token) return next(req);
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};
```

Register in `app.config.ts`:

```typescript
provideHttpClient(withInterceptors([authInterceptor, errorInterceptor]))
```

#### RxJS Operators

```typescript
search$ = this.query$.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(q => this.service.search(q).pipe(catchError(() => of([])))),
);
```

#### Forms

```typescript
// Reactive Forms — standard for complex forms
export class UserFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    name: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
  });
}
```

#### Accessibility

```css
[aria-selected="true"] { background: var(--color-selected); }
```

### Coding style (rules/angular/coding-style.md)

#### Components

```typescript
@Component({
  selector: 'app-user-card',
  standalone: true,
  imports: [RouterModule],
  templateUrl: './user-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserCardComponent {
  user = input.required<User>();
  select = output<string>();
}
```

#### Dependency Injection

```typescript
// CORRECT
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private router = inject(Router);
}

// WRONG: Constructor injection is verbose and harder to tree-shake
constructor(private http: HttpClient, private router: Router) {}
```

Use `InjectionToken` for non-class dependencies:

```typescript
const API_URL = new InjectionToken<string>('API_URL');

// Provide:
{ provide: API_URL, useValue: 'https://api.example.com' }

// Consume:
private apiUrl = inject(API_URL);
```

#### Signals — Core Primitives

```typescript
count = signal(0);
doubled = computed(() => this.count() * 2);

increment() {
  this.count.update(n => n + 1);
}
```

#### `linkedSignal` — Writable Derived State

```typescript
selectedOption = linkedSignal(() => this.options()[0]);
// Resets to first option when options changes, but user can override
```

#### `resource` — Async Data into Signals

```typescript
userResource = resource({
  request: () => ({ id: this.userId() }),
  loader: ({ request }) => fetch(`/api/users/${request.id}`).then(r => r.json()),
});

// Access: userResource.value(), userResource.isLoading(), userResource.error()
```

#### `effect` Usage

```typescript
// CORRECT: Side effect
effect(() => console.log('User changed:', this.user()));

// WRONG: Use computed instead
effect(() => { this.fullName.set(`${this.first()} ${this.last()}`); });
```

#### Templates

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

#### Forms

```typescript
// Reactive Forms — standard approach for most apps
export class LoginComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  submit() {
    if (this.form.valid) {
      // use this.form.value
    }
  }
}
```

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
