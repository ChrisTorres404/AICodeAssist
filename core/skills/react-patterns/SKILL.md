---
name: react-patterns
description: React 18/19 patterns including hooks discipline, server/client component boundaries, Suspense + error boundaries, form actions, data fetching, typed API clients, context and reducer state, auth providers, styling variants, and loading/empty/error states. Use when writing or reviewing React components, hooks, or client-side data flow.
---

# React Patterns

Idiomatic React 18/19 patterns for building robust, accessible, performant component trees, plus the client-side plumbing that surrounds them: API clients, auth context, forms, styling variants, and loading states.

## When to Activate

- Writing or modifying React function components, custom hooks, or component trees
- Reviewing JSX/TSX files
- Designing state shape or component composition
- Migrating class components or older `forwardRef`/`useEffect`-heavy code
- Choosing between local state, lifted state, context, and external stores
- Working with Server Components / Client Components (RSC)
- Implementing forms with React 19 actions or controlled inputs
- Wiring data fetching with TanStack Query / SWR / RSC
- Building a typed API client for a React front end
- Building auth providers, protected routes, or role gates in the client tree
- Building loading skeletons, empty states, and error views

Framework-specific material (App Router file conventions, route handlers, middleware, metadata, caching and revalidation, hydration) lives in [nextjs-patterns](../nextjs-patterns/SKILL.md).

## Contents

1. [Core Principles](#core-principles)
2. [Hooks Discipline](#hooks-discipline)
3. [State Location Decision Tree](#state-location-decision-tree)
4. [Component Organization](#component-organization)
5. [Server / Client Components (RSC)](#server--client-components-rsc)
6. [Suspense + Error Boundaries](#suspense--error-boundaries)
7. [Forms](#forms)
8. [Data Fetching](#data-fetching)
9. [API Client Patterns](#api-client-patterns)
10. [State Management](#state-management)
11. [Authentication Patterns](#authentication-patterns)
12. [Composition Recipes](#composition-recipes)
13. [Component Patterns](#component-patterns)
14. [Styling Patterns](#styling-patterns)
15. [Loading, Empty, and Error States](#loading-empty-and-error-states)
16. [Performance](#performance)
17. [Accessibility-First Composition](#accessibility-first-composition)
18. [Routing](#routing)

## Core Principles

### 1. Render is a Pure Function of Props and State

```tsx
// Good: derive during render
function Cart({ items }: { items: CartItem[] }) {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return <span>{formatMoney(total)}</span>;
}

// Bad: derived state stored separately
function Cart({ items }: { items: CartItem[] }) {
  const [total, setTotal] = useState(0);
  useEffect(() => {
    setTotal(items.reduce((sum, i) => sum + i.price * i.qty, 0));
  }, [items]);
  return <span>{formatMoney(total)}</span>;
}
```

Derived state in `useEffect` adds a render cycle, can desync, and obscures the data flow.

### 2. Side Effects Outside Render

Effects, mutations, network calls, and subscriptions live in event handlers or `useEffect` — never in the render body.

### 3. Composition Over Inheritance

React has no inheritance model for components. Compose with `children`, render props, or component props.

## Hooks Discipline

See [rules/react/patterns.md](../../rules/react/patterns.md) for the full ruleset (`coding-style.md`, `security.md`, and `testing.md` sit alongside it). Highlights:

- Top-level only, never conditional
- Cleanup every subscription, interval, listener
- Functional updater (`setX(prev => prev + 1)`) when new state depends on old
- Default position: do not memoize — add `useMemo`/`useCallback` only when a profiler or a dependency chain proves it matters
- Extract a custom hook only when the same hook sequence appears in 2+ components

## State Location Decision Tree

```text
Used by one component?
  -> useState inside it

Used by parent + a few descendants?
  -> lift to nearest common ancestor

Used across distant branches AND low-frequency reads (theme, auth, locale)?
  -> React Context

High-frequency updates shared across the tree?
  -> external store (Zustand, Jotai, Redux Toolkit)

Derived from a server?
  -> server-state library (TanStack Query, SWR, RSC fetch)
```

Most pages do not need context or a global store. Resist abstraction until duplicated lifting becomes painful.

## Component Organization

### Directory Layout for Components, Hooks, and Lib

The non-routing half of a React app. (Routing directories are framework-specific — see
[nextjs-patterns](../nextjs-patterns/SKILL.md) for the App Router half of this same tree.)

```text
apps/web/
├── components/
│   ├── ui/                    # Reusable UI components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   └── input.tsx
│   ├── layout/                # Layout components
│   │   ├── header.tsx
│   │   ├── footer.tsx
│   │   └── sidebar.tsx
│   └── features/              # Feature-specific components
│       ├── orders/
│       │   ├── order-card.tsx
│       │   └── order-list.tsx
│       └── catalog/
│           └── product-card.tsx
├── lib/
│   ├── api.ts                 # API client
│   ├── utils.ts               # Utility functions
│   └── constants.ts           # App constants
├── hooks/
│   ├── use-auth.ts
│   └── use-orders.ts
└── types/
    └── index.ts               # TypeScript types
```

### Key Principles

1. **Colocation** - Keep related files close to where they're used
2. **Shared Components** - Extract to `/components` when used 2+ times
3. **`ui/` is app-agnostic** - A component under `ui/` must not import from `features/` or from the API client; it takes props only
4. **One concept per file** - A file exporting `OrderCard` plus three unrelated helpers is a refactor waiting to happen

## Server / Client Components (RSC)

```tsx
// Server Component - default, async, never ships JS for itself
export default async function ProductPage({ params }: { params: { id: string } }) {
  const product = await db.product.findUnique({ where: { id: params.id } });
  if (!product) notFound();
  return <ProductView product={product} />;
}

// Client Component - opt in with "use client"
"use client";
export function AddToCartButton({ productId }: { productId: string }) {
  const [pending, startTransition] = useTransition();
  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => addToCart(productId))}
    >
      {pending ? "Adding..." : "Add to cart"}
    </button>
  );
}
```

Boundaries:

- Server -> Client: pass serializable props or `children`
- Client -> Server: invoke Server Actions via `<form action={...}>` or imperatively from event handlers
- Never `import` a Server Component from a Client Component file — compose them via `children` instead

## Suspense + Error Boundaries

```tsx
<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<UserSkeleton />}>
    <UserDetail id={id} />
  </Suspense>
</ErrorBoundary>
```

- Place Suspense boundaries close to the data, not at the route root — progressively reveal content
- Error Boundary remains a class API; use `react-error-boundary` for a hook-friendly wrapper
- A boundary catches errors thrown during render, lifecycle, and constructors of its children — NOT in event handlers or async code

## Forms

### React 19 form actions (preferred for new code)

```tsx
"use client";
import { useActionState } from "react";

const initial = { error: null as string | null };

async function updateUserAction(_prev: typeof initial, formData: FormData) {
  "use server";
  const parsed = UserSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: "Invalid input" };
  await db.user.update({ where: { id: parsed.data.id }, data: parsed.data });
  return { error: null };
}

export function UserForm() {
  const [state, formAction, pending] = useActionState(updateUserAction, initial);
  return (
    <form action={formAction}>
      <input name="name" required />
      <button type="submit" disabled={pending}>Save</button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

### Controlled inputs

Use controlled when the value drives other UI, formats on every keystroke, or implements real-time validation.

### Complex forms

For multi-step forms, dynamic field arrays, or cross-field validation: use a library (React Hook Form, TanStack Form). Roll-your-own state management for forms past trivial complexity is a maintenance trap.

### Controlled Form Pattern (worked example)

One `useState` object, one generic `handleChange`, explicit `submitting` and `error` flags. The
number coercion in `handleChange` is the part people get wrong: an empty numeric input must become
`''`, not `NaN` or `0`, or the field cannot be cleared.

```typescript
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';

interface FormData {
  description: string;
  quantity: number | '';
  neededBy: string;
}

export function QuoteRequestForm({ onSubmit }: { onSubmit: (data: FormData) => Promise<void> }) {
  const [formData, setFormData] = useState<FormData>({
    description: '',
    quantity: '',
    neededBy: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      await onSubmit(formData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong');
    } finally {
      setSubmitting(false);
    }
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value, type } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'number' ? (value ? Number(value) : '') : value,
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="p-3 bg-red-50 text-red-700 rounded-lg" role="alert">{error}</div>
      )}

      <div>
        <label htmlFor="description" className="block text-sm font-medium mb-1">Description</label>
        <textarea
          id="description"
          name="description"
          value={formData.description}
          onChange={handleChange}
          required
          rows={4}
          className="w-full px-3 py-2 border rounded-lg"
        />
      </div>

      <div>
        <label htmlFor="quantity" className="block text-sm font-medium mb-1">Quantity</label>
        <input
          id="quantity"
          type="number"
          name="quantity"
          value={formData.quantity}
          onChange={handleChange}
          min={1}
          className="w-full px-3 py-2 border rounded-lg"
        />
      </div>

      <div>
        <label htmlFor="neededBy" className="block text-sm font-medium mb-1">Needed By</label>
        <input
          id="neededBy"
          type="date"
          name="neededBy"
          value={formData.neededBy}
          onChange={handleChange}
          className="w-full px-3 py-2 border rounded-lg"
        />
      </div>

      <Button type="submit" disabled={submitting} className="w-full">
        {submitting ? 'Submitting...' : 'Submit Request'}
      </Button>
    </form>
  );
}
```

## Data Fetching

### Decision Matrix

| Need | Tool |
|---|---|
| Per-request data in a server component | RSC `await fetch()` |
| Client-side cache + mutations + invalidation | TanStack Query |
| Lightweight client cache + revalidation | SWR |
| Real-time subscriptions | Server-Sent Events, WebSockets, or the lib's subscription API |
| One-off fire-and-forget | `fetch()` in an event handler |

Avoid `useEffect` + `fetch` for application data — race conditions, no cache, no retry, no Suspense integration. The pattern below is the correct shape when you must use it anyway.

### useEffect Pattern (Simple)

The `cancelled` flag is not optional. Without it, StrictMode's double-invoke in development and any
fast navigation both produce "setState on an unmounted component" plus out-of-order responses.

```typescript
'use client';

import { useEffect, useState } from 'react';

export function useOrders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const data = await ordersApi.getMyOrders();
        if (!cancelled) {
          setOrders(data.orders);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err.message);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    load();

    return () => {
      cancelled = true;  // Cleanup for StrictMode
    };
  }, []);

  return { orders, loading, error };
}
```

### React Query Pattern (Recommended)

One hook per query key, `enabled` to defer until the parameter exists, and invalidation on the
mutation rather than manual cache surgery.

```typescript
// hooks/use-orders.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ordersApi, type CreateOrderDto } from '@/lib/api';

export function useOrders() {
  return useQuery({
    queryKey: ['orders'],
    queryFn: () => ordersApi.getMyOrders(),
  });
}

export function useOrder(uuid: string) {
  return useQuery({
    queryKey: ['orders', uuid],
    queryFn: () => ordersApi.getOrder(uuid),
    enabled: !!uuid,
  });
}

export function useCreateOrder() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (dto: CreateOrderDto) => ordersApi.createOrder(dto),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}
```

### SWR Pattern (Alternative)

```typescript
import useSWR from 'swr';
import { ordersApi } from '@/lib/api';

export function useOrders() {
  const { data, error, isLoading, mutate } = useSWR(
    '/api/me/orders',
    () => ordersApi.getMyOrders()
  );

  return {
    orders: data?.orders ?? [],
    isLoading,
    error,
    refresh: mutate,
  };
}
```

## API Client Patterns

### Typed API Client

One `fetcher<T>()` with the error handling in it, then thin namespaced call sites. Two details carry
most of the value: `credentials: 'include'` so the session cookie travels, and the `.catch(() => ({}))`
on the error body so a non-JSON 500 does not throw a parse error on top of the real error.

```typescript
// lib/api.ts
// Framework env-var prefix varies (NEXT_PUBLIC_, VITE_, PUBLIC_). Use whichever your bundler inlines.
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

// Types
export interface Product {
  uuid: string;
  name: string;
  slug: string;
  description: string | null;
  basePrice: number;
  imageUrl: string | null;
  category: { name: string } | null;
  isAvailable: boolean;
}

export interface Order {
  uuid: string;
  orderNumber: string;
  status: string;
  total: number;
  items: OrderItem[];
  createdAt: string;
}

// Base fetcher with error handling
async function fetcher<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    credentials: 'include',  // Include cookies for auth
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || `HTTP ${response.status}`);
  }

  return response.json();
}

// API namespaces
export const catalogApi = {
  getCategories: () =>
    fetcher<{ categories: Category[] }>('/api/catalog/categories'),

  getProducts: (params?: { category?: string; limit?: number }) => {
    const query = new URLSearchParams();
    if (params?.category) query.set('category', params.category);
    if (params?.limit) query.set('limit', String(params.limit));
    const qs = query.toString();
    return fetcher<{ products: Product[]; total: number }>(
      `/api/catalog/products${qs ? `?${qs}` : ''}`
    );
  },

  getProductBySlug: (slug: string) =>
    fetcher<Product>(`/api/catalog/products/${slug}`),
};

export const ordersApi = {
  getMyOrders: () =>
    fetcher<{ orders: Order[] }>('/api/me/orders'),

  getOrder: (uuid: string) =>
    fetcher<Order>(`/api/me/orders/${uuid}`),

  createOrder: (dto: CreateOrderDto) =>
    fetcher<Order>('/api/orders', {
      method: 'POST',
      body: JSON.stringify(dto),
    }),
};

export const adminApi = {
  getDashboard: () =>
    fetcher<DashboardStats>('/api/admin/dashboard'),

  getAllOrders: (params?: { status?: string }) => {
    const query = new URLSearchParams();
    if (params?.status) query.set('status', params.status);
    return fetcher<{ orders: Order[]; total: number }>(
      `/api/admin/orders?${query}`
    );
  },

  updateOrderStatus: (uuid: string, status: string, message?: string) =>
    fetcher<Order>(`/api/admin/orders/${uuid}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status, message }),
    }),
};
```

### API Client Rules

- **UUID in URLs, integer id internally.** Public routes and API paths address records by `uuid`; the numeric primary key never leaves the server.
- **One error type.** Throw a single `SdkError`-shaped error from the fetcher so callers have one `catch` shape, not four.
- **Never read `NEXT_PUBLIC_`/`VITE_` variables for secrets.** Anything with a public prefix is in the bundle. See [Secret Exposure via Env Vars](#secret-exposure-via-env-vars).
- **Cookie naming.** Session cookies follow a `<prefix>-` convention — `app-session`, `app-refresh`, `app-csrf-token` — so a single prefix identifies the app's cookies in the browser inspector.

## State Management

### React Context for Global State

`useReducer` plus context, with the consumer hook throwing when used outside the provider. The throw
is the pattern's whole safety story — without it a missing provider surfaces as
`Cannot read property 'state' of null` three components away.

```typescript
// contexts/cart-context.tsx
'use client';

import { createContext, useContext, useReducer, ReactNode } from 'react';

interface CartItem {
  productUuid: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: CartItem }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'UPDATE_QUANTITY'; payload: { uuid: string; quantity: number } }
  | { type: 'CLEAR' };

const CartContext = createContext<{
  state: CartState;
  dispatch: React.Dispatch<CartAction>;
} | null>(null);

function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existing = state.items.find(
        (i) => i.productUuid === action.payload.productUuid
      );
      if (existing) {
        return {
          ...state,
          items: state.items.map((i) =>
            i.productUuid === action.payload.productUuid
              ? { ...i, quantity: i.quantity + action.payload.quantity }
              : i
          ),
        };
      }
      return {
        ...state,
        items: [...state.items, action.payload],
      };
    }
    case 'REMOVE_ITEM':
      return {
        ...state,
        items: state.items.filter((i) => i.productUuid !== action.payload),
      };
    case 'CLEAR':
      return { items: [], total: 0 };
    default:
      return state;
  }
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [], total: 0 });

  return (
    <CartContext.Provider value={{ state, dispatch }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}
```

Note the `value={{ state, dispatch }}` object literal: it is a new reference every render, so every
consumer re-renders when the provider does. For a provider that re-renders often, memoize the value
or split state and dispatch into two contexts (see [Splitting context to avoid render cascades](#splitting-context-to-avoid-render-cascades)).

## Authentication Patterns

### Auth Provider Pattern

Three flags carry the whole contract: `isLoaded` (has the session check finished), `isSignedIn`, and
`user`. Gating on `isSignedIn` alone produces a login-page flash on every reload, because the first
render happens before the session request returns.

```typescript
// providers/auth-provider.tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';

interface User {
  id: string;
  email: string;
  name: string | null;
  role: string;
}

interface AuthContextType {
  isLoaded: boolean;
  isSignedIn: boolean;
  user: User | null;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    async function checkAuth() {
      try {
        const response = await fetch('/api/me', { credentials: 'include' });
        if (response.ok) {
          const data = await response.json();
          setUser(data.user);
        }
      } catch (error) {
        console.error('Auth check failed', error);
      } finally {
        setIsLoaded(true);
      }
    }
    checkAuth();
  }, []);

  const signOut = async () => {
    await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' });
    setUser(null);
    window.location.href = '/';
  };

  return (
    <AuthContext.Provider
      value={{
        isLoaded,
        isSignedIn: !!user,
        user,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

export function useUser() {
  const { user } = useAuth();
  return { user };
}
```

`signOut` uses `window.location.href` rather than a client-side navigation on purpose: a hard
navigation discards every in-memory cache (query cache, context state) that could still hold the
previous user's data.

### Protected Route Component

```typescript
// components/auth/protected-route.tsx
'use client';

import { useAuth } from '@/providers/auth-provider';
import { redirect } from 'next/navigation';   // or your router's equivalent

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: string[];
  fallback?: React.ReactNode;
}

export function ProtectedRoute({
  children,
  requiredRole,
  fallback = <LoadingSkeleton />,
}: ProtectedRouteProps) {
  const { isLoaded, isSignedIn, user } = useAuth();

  if (!isLoaded) {
    return fallback;
  }

  if (!isSignedIn) {
    redirect('/login');
  }

  if (requiredRole && user && !requiredRole.includes(user.role)) {
    redirect('/dashboard');
  }

  return <>{children}</>;
}
```

A client-side role gate is a UX affordance, not a security control. Every route it protects must be
enforced again on the server; the client bundle is public and the check is one devtools breakpoint
away.

## Composition Recipes

### Slot via `children`

```tsx
<Layout>
  <Header />
  <Main>{content}</Main>
</Layout>
```

### Named slots

```tsx
<Page header={<Nav />} sidebar={<Filters />}>
  <Results />
</Page>
```

### Compound components (shared state via Context)

```tsx
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Panel value="profile"><Profile /></Tabs.Panel>
  <Tabs.Panel value="settings"><Settings /></Tabs.Panel>
</Tabs>
```

### Render prop / function-as-child

Useful when the parent needs to pass parameters to the rendered output:

```tsx
<DataLoader id={id}>
  {({ data, isLoading }) => isLoading ? <Spinner /> : <UserCard user={data} />}
</DataLoader>
```

Modern alternative: a hook (`useData(id)`) returning the same shape — usually cleaner.

## Component Patterns

### Feature Component Pattern

A feature component knows the domain type and the route it links to; it owns no fetching and no
state. That is what makes it usable from a list page, a dashboard widget, and a search result with
no changes.

```typescript
// components/features/orders/order-card.tsx
import Link from 'next/link';
import { formatCurrency, formatDate } from '@/lib/utils';
import { type Order } from '@/lib/api';
import { StatusBadge } from '@/components/ui/status-badge';

interface OrderCardProps {
  order: Order;
}

export function OrderCard({ order }: OrderCardProps) {
  return (
    <Link href={`/orders/${order.uuid}`}>
      <div className="card p-6 hover:shadow-md transition-shadow">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="font-semibold">{order.orderNumber}</h3>
            <p className="text-sm text-gray-500">
              {formatDate(order.createdAt)}
            </p>
          </div>
          <StatusBadge status={order.status} />
        </div>
        <div className="mt-4 flex justify-between">
          <span className="text-gray-600">
            {order.items.length} item{order.items.length !== 1 ? 's' : ''}
          </span>
          <span className="font-bold">{formatCurrency(order.total)}</span>
        </div>
      </div>
    </Link>
  );
}
```

### Reusable UI Component Pattern

Two lookup maps (styles, labels) plus a fallback on both. The `|| 'bg-gray-100 text-gray-700'` and
`|| status` fallbacks are what keep an unknown status from rendering an unstyled or blank badge when
the API adds a new enum value before the front end ships.

```typescript
// components/ui/status-badge.tsx
import { cn } from '@/lib/utils';

const statusStyles: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-700',
  confirmed: 'bg-blue-100 text-blue-700',
  in_progress: 'bg-purple-100 text-purple-700',
  ready: 'bg-green-100 text-green-700',
  delivered: 'bg-gray-100 text-gray-700',
  cancelled: 'bg-red-100 text-red-700',
};

const statusLabels: Record<string, string> = {
  pending: 'Pending',
  confirmed: 'Confirmed',
  in_progress: 'In Progress',
  ready: 'Ready',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

interface StatusBadgeProps {
  status: string;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function StatusBadge({
  status,
  size = 'sm',
  className,
}: StatusBadgeProps) {
  const sizeClasses = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-3 py-1.5 text-sm',
    lg: 'px-4 py-2 text-base',
  };

  return (
    <span
      className={cn(
        'rounded-full font-medium',
        sizeClasses[size],
        statusStyles[status] || 'bg-gray-100 text-gray-700',
        className
      )}
    >
      {statusLabels[status] || status}
    </span>
  );
}
```

### Compound Component Pattern

Static properties on the parent function keep the namespace visible at the call site without a
context. Use this shape when the sub-parts share no state; use the context form (above) when they do.

```typescript
// components/ui/card.tsx
import { cn } from '@/lib/utils';

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export function Card({ children, className }: CardProps) {
  return (
    <div className={cn('bg-white rounded-xl border shadow-sm', className)}>
      {children}
    </div>
  );
}

Card.Header = function CardHeader({
  children,
  className,
}: CardProps) {
  return (
    <div className={cn('px-6 py-4 border-b', className)}>
      {children}
    </div>
  );
};

Card.Body = function CardBody({
  children,
  className,
}: CardProps) {
  return (
    <div className={cn('px-6 py-4', className)}>
      {children}
    </div>
  );
};

Card.Footer = function CardFooter({
  children,
  className,
}: CardProps) {
  return (
    <div className={cn('px-6 py-4 border-t bg-gray-50 rounded-b-xl', className)}>
      {children}
    </div>
  );
};

// Usage:
// <Card>
//   <Card.Header>Title</Card.Header>
//   <Card.Body>Content</Card.Body>
//   <Card.Footer>Actions</Card.Footer>
// </Card>
```

## Styling Patterns

### Tailwind Utility Function

`clsx` resolves conditionals; `twMerge` resolves conflicts. Without `twMerge`, a caller passing
`className="px-8"` to a component with a hardcoded `px-4` gets whichever class the stylesheet emits
last — a coin flip.

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Usage:
// cn('px-4 py-2', isActive && 'bg-blue-500', className)
```

### Component Variants Pattern

```typescript
// components/ui/button.tsx
import { cn } from '@/lib/utils';
import { forwardRef } from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

const variants = {
  primary: 'bg-brand-600 text-white hover:bg-brand-700',
  secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200',
  ghost: 'text-gray-600 hover:bg-gray-100',
  danger: 'bg-red-600 text-white hover:bg-red-700',
};

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-medium',
          'transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2',
          'disabled:opacity-50 disabled:cursor-not-allowed',
          variants[variant],
          sizes[size],
          className
        )}
        {...props}
      />
    );
  }
);

Button.displayName = 'Button';
```

`Button.displayName` is required: without it, `forwardRef` components show as `ForwardRef` in React
DevTools and in component-test error messages. On React 19 you can take `ref` as a plain prop and
skip `forwardRef` entirely — see [Refs and Forwarding](#refs-and-forwarding-react-19).

## Loading, Empty, and Error States

Every list view needs four branches, not two: loading, error, empty, and content. A page that only
handles loading and content renders a blank box for both failures and empty results, and the two are
indistinguishable to the user.

```tsx
if (loading) return <OrdersLoadingSkeleton />;
if (error) return <ErrorMessage message={error} />;
if (orders.length === 0) return <EmptyState icon={Inbox} title="No orders yet" />;
return <OrderList orders={orders} />;
```

### Skeleton Pattern

```typescript
// components/ui/skeleton.tsx
import { cn } from '@/lib/utils';

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div className={cn('animate-pulse bg-gray-200 rounded', className)} />
  );
}

// Usage:
// <Skeleton className="h-6 w-48" />
// <Skeleton className="h-32 w-full" />
```

### Page Loading Skeleton

Build the skeleton out of the same layout the loaded page uses. A skeleton with different dimensions
from the real content causes a visible reflow on load, which reads as slower than no skeleton at all.

```typescript
// components/features/orders/orders-loading.tsx
import { Skeleton } from '@/components/ui/skeleton';

export function OrdersLoadingSkeleton() {
  return (
    <div className="space-y-6">
      <Skeleton className="h-8 w-48" />
      <div className="space-y-4">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card p-6 space-y-3">
            <Skeleton className="h-5 w-32" />
            <Skeleton className="h-4 w-48" />
            <div className="flex justify-between">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-6 w-20" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Empty State Pattern

```typescript
// components/ui/empty-state.tsx
import { LucideIcon } from 'lucide-react';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description?: string;
  action?: React.ReactNode;
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: EmptyStateProps) {
  return (
    <div className="text-center py-12">
      <Icon className="h-12 w-12 mx-auto text-gray-300 mb-4" aria-hidden="true" />
      <h3 className="text-lg font-medium text-gray-900">{title}</h3>
      {description && (
        <p className="mt-1 text-gray-500">{description}</p>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

// Usage:
// <EmptyState
//   icon={ShoppingBag}
//   title="No orders yet"
//   description="Your orders will appear here"
//   action={<Button>Browse Catalog</Button>}
// />
```

An empty state should always offer the next action. "No orders yet" with no button is a dead end.

## Performance

### When `React.memo` Actually Helps

Wrap a component in `React.memo` only when:

1. It re-renders frequently
2. Its props are usually the same between renders
3. Its render is measurably expensive

`React.memo` adds an equality check on every render. If props differ on most renders, the check is pure overhead.

### Avoiding Render Cascades

- Lift state down rather than up where possible
- Split context: one context per concern, so a change to `themeContext` does not re-render auth consumers
- Use `useSyncExternalStore` for external state libraries — required for safe concurrent rendering

### Lists

- Provide stable `key` props (database id, not array index)
- Virtualize long lists with `@tanstack/react-virtual` or `react-window` once visible item count exceeds ~50 with non-trivial rows

## Accessibility-First Composition

- Always render semantic HTML (`<button>`, `<a>`, `<nav>`, `<main>`) before reaching for `role` attributes
- Every interactive element must be reachable by keyboard
- Form inputs need labels — `<label htmlFor>` or `aria-label` if visually labeled by an icon
- Manage focus on route changes and modal open/close
- Run `axe` in component tests (see [skills/react-testing](../react-testing/SKILL.md))
- Cross-link: [skills/accessibility/SKILL.md](../accessibility/SKILL.md) covers WCAG criteria and pattern libraries

## Routing

This skill is router-agnostic. The patterns above work with React Router, TanStack Router, Next.js App Router, Remix Router. Router-specific patterns (loaders, actions, nested layouts) follow the router's documentation — those are framework concerns layered on top of React core.

For the App Router in particular — route groups, dynamic and catch-all segments, layouts, metadata,
route handlers, middleware, and caching — see [nextjs-patterns](../nextjs-patterns/SKILL.md).

## Out of Scope (Pointer Sections)

- **Next.js specifics**: App Router file conventions, Route Handlers, Middleware, Parallel Routes, metadata, caching and revalidation — see [nextjs-patterns](../nextjs-patterns/SKILL.md)
- **Next.js build tooling**: dev server, bundler choice, incremental builds — see [nextjs-turbopack](../nextjs-turbopack/SKILL.md)
- **React Native**: platform-specific patterns — see [react-native-patterns](../react-native-patterns/SKILL.md)
- **Remix**: Loader/action conventions overlap with RSC but follow Remix docs

## Related

- Rules: [rules/react/](../../rules/react/) — coding-style, patterns, security, testing
- Skills: [react-performance](../react-performance/SKILL.md) for the performance ruleset, [frontend-patterns](../frontend-patterns/SKILL.md) for cross-framework UI concerns, [accessibility](../accessibility/SKILL.md), [angular-patterns](../angular-patterns/SKILL.md) for framework comparison, [nextjs-patterns](../nextjs-patterns/SKILL.md) for the framework layer
- Agents: `react-reviewer` for code review, `react-build-resolver` for build/bundler errors
- Commands: `react-expert`

## Examples

### Custom hook for debounced search

```tsx
function useDebounce<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}

function SearchBox() {
  const [query, setQuery] = useState("");
  const debounced = useDebounce(query, 300);
  const { data } = useQuery({
    queryKey: ["search", debounced],
    queryFn: () => searchApi(debounced),
    enabled: debounced.length > 0,
  });
  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <Results items={data ?? []} />
    </>
  );
}
```

### Optimistic UI with React 19 `useOptimistic`

```tsx
"use client";
import { useOptimistic } from "react";

export function MessageList({ messages }: { messages: Message[] }) {
  const [optimistic, addOptimistic] = useOptimistic(
    messages,
    (state, newMessage: Message) => [...state, newMessage],
  );

  async function send(formData: FormData) {
    const text = String(formData.get("text"));
    addOptimistic({ id: "pending", text, sender: "me" });
    await saveMessage(text);
  }

  return (
    <>
      <ul>{optimistic.map((m) => <li key={m.id}>{m.text}</li>)}</ul>
      <form action={send}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </>
  );
}
```

### Splitting context to avoid render cascades

```tsx
// Two contexts: one rarely changes, one frequently
const ThemeContext = createContext<Theme>("light");
const NotificationsContext = createContext<Notification[]>([]);

// A component that only consumes ThemeContext does NOT re-render when notifications change
```

## Reference examples

### Container / Presentational Split

```tsx
// Container — owns data
export function UserPage({ userId }: { userId: string }) {
  const { data: user, isLoading } = useUser(userId);
  if (isLoading) return <Spinner />;
  if (!user) return <NotFound />;
  return <UserCard user={user} onSelect={handleSelect} />;
}

// Presentational — pure
export function UserCard({ user, onSelect }: { user: User; onSelect: (id: string) => void }) {
  return <button onClick={() => onSelect(user.id)}>{user.name}</button>;
}
```

### Server / Client Component Boundary (RSC)

```tsx
// Server (default)
export default async function Page() {
  const user = await fetchUser();
  return <UserClient user={user} />;
}

// Client
"use client";
export function UserClient({ user }: { user: User }) {
  const [tab, setTab] = useState("profile");
  return <Tabs value={tab} onChange={setTab}>{user.name}</Tabs>;
}
```

### Suspense + Error Boundaries

```tsx
<ErrorBoundary fallback={<ErrorView />}>
  <Suspense fallback={<Skeleton />}>
    <UserDetails id={id} />
  </Suspense>
</ErrorBoundary>
```

### Uncontrolled forms (React 19 + form actions)

```tsx
async function action(formData: FormData) {
  "use server";
  await saveUser({ name: String(formData.get("name")) });
}

export function UserForm() {
  return (
    <form action={action}>
      <input name="name" required />
      <button type="submit">Save</button>
    </form>
  );
}
```

### Controlled forms

```tsx
const [email, setEmail] = useState("");
return <input value={email} onChange={(e) => setEmail(e.target.value)} />;
```

### Compound Components

```tsx
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Panel value="profile"><ProfileForm /></Tabs.Panel>
  <Tabs.Panel value="settings"><SettingsForm /></Tabs.Panel>
</Tabs>
```

### Refs and Forwarding (React 19+)

```tsx
export function Input({ ref, ...rest }: { ref?: React.Ref<HTMLInputElement> } & InputProps) {
  return <input ref={ref} {...rest} />;
}
```

### XSS via `dangerouslySetInnerHTML`

```tsx
// CRITICAL: unsanitized user input
<div dangerouslySetInnerHTML={{ __html: userBio }} />

// CORRECT options:
// 1. Render as text
<div>{userBio}</div>

// 2. Render parsed markdown via a library that sanitizes
<ReactMarkdown>{userBio}</ReactMarkdown>

// 3. If raw HTML is required, sanitize first with DOMPurify
import DOMPurify from "isomorphic-dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userBio) }} />
```

### Unsafe URL Schemes

```tsx
// CRITICAL: javascript: URL injection
<a href={user.website}>Visit</a>   // if user.website = "javascript:alert(1)"

// CORRECT: validate scheme
function safeUrl(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    if (["http:", "https:", "mailto:"].includes(parsed.protocol)) return url;
  } catch {
    return undefined;
  }
  return undefined;
}
<a href={safeUrl(user.website)}>Visit</a>
```

### `target="_blank"` Without `rel`

```tsx
// WRONG
<a href={externalUrl} target="_blank">External</a>

// CORRECT
<a href={externalUrl} target="_blank" rel="noopener noreferrer">External</a>
```

### Server Action Input Validation

```tsx
"use server";
import { z } from "zod";

const Input = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(120),
});

export async function updateUser(_state: unknown, formData: FormData) {
  const parsed = Input.safeParse({
    email: formData.get("email"),
    age: Number(formData.get("age")),
  });
  if (!parsed.success) return { error: parsed.error.flatten() };
  // ...
}
```

### Secret Exposure via Env Vars

```ts
// CRITICAL: secret leaked to client bundle
const apiKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY;
```

### Content Security Policy (CSP)

The minimum acceptable CSP for a React app:

```text
default-src 'self';
script-src 'self' 'nonce-{REQUEST_NONCE}';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
connect-src 'self' https://api.example.com;
frame-ancestors 'none';
```

### Prototype Pollution via Object Spread

```tsx
// WRONG: untrusted JSON spread directly into state
const update = await req.json();
setState({ ...state, ...update });    // attacker controls __proto__

// CORRECT: parse with a schema, or guard keys
const Allowed = z.object({ name: z.string(), email: z.string().email() });
const parsed = Allowed.parse(await req.json());
setState({ ...state, ...parsed });
```

## Review Checklist

- [ ] No derived state stored in `useState` + `useEffect` — derive during render
- [ ] Every `useEffect` that subscribes, times, or fetches has a cleanup return
- [ ] Every async effect guards against a stale response (`cancelled` flag or `AbortController`)
- [ ] `key` props are stable record ids, not array indices
- [ ] No `useMemo`/`useCallback` added without a measured reason
- [ ] Context providers pass a memoized value, or split state from dispatch
- [ ] Every consumer hook throws a named error when used outside its provider
- [ ] List views handle all four states: loading, error, empty, content
- [ ] Auth gating checks `isLoaded` before `isSignedIn` (no login-page flash)
- [ ] Every client-side role gate is re-enforced on the server
- [ ] Every form input has a `<label htmlFor>` or an `aria-label`
- [ ] Error text is announced (`role="alert"`) not just rendered
- [ ] No `dangerouslySetInnerHTML` without sanitization
- [ ] No secrets behind a public env prefix (`NEXT_PUBLIC_`, `VITE_`, `PUBLIC_`)
- [ ] `target="_blank"` links carry `rel="noopener noreferrer"`
- [ ] Skeletons match the loaded layout's dimensions

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
