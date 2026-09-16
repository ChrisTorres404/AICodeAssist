---
name: nextjs-patterns
description: Next.js App Router patterns — route groups, dynamic and catch-all segments, layouts, metadata, server vs client pages, route handlers, middleware, caching and revalidation, and the hydration and config gotchas that bite in production. Use when building or reviewing a Next.js 14+ application on the App Router.
---

# Next.js App Router Patterns

Patterns for building Next.js 14+ applications with the App Router. React-level patterns —
hooks, composition, context, forms, data-fetching libraries, styling — live in
[react-patterns](../react-patterns/SKILL.md); this skill covers the framework layer sitting on top
of them.

## When to Activate

- Creating or reorganising files under `app/`
- Choosing between a Server Component page and a Client Component page
- Adding route groups, dynamic segments, catch-all segments, or parallel routes
- Writing root layouts, nested layouts, `loading.tsx`, `error.tsx`, or `not-found.tsx`
- Adding `generateMetadata` / `generateStaticParams`
- Writing Route Handlers (`route.ts`) or Middleware (`middleware.ts`)
- Debugging hydration mismatches, stale caches, or unexpected static rendering
- Configuring `next.config.js` or public/server environment variables
- Gating routes on authentication or role

## Contents

1. [Project Structure](#project-structure)
2. [App Router Patterns](#app-router-patterns)
3. [Layout Patterns](#layout-patterns)
4. [Page Patterns](#page-patterns)
5. [Route Handlers](#route-handlers)
6. [Middleware](#middleware)
7. [Caching and Revalidation](#caching-and-revalidation)
8. [Hydration](#hydration)
9. [Configuration and Environment](#configuration-and-environment)
10. [Build and Dev Server](#build-and-dev-server)
11. [Gotchas](#gotchas)

## Project Structure

### Recommended App Directory Structure

```text
apps/web/
├── app/
│   ├── (public)/              # Public routes (no auth)
│   │   ├── page.tsx           # Landing page (/)
│   │   ├── catalog/
│   │   │   ├── page.tsx       # Catalog listing
│   │   │   └── [slug]/
│   │   │       └── page.tsx   # Product detail
│   │   └── login/
│   │       └── page.tsx
│   ├── (customer)/            # Auth required routes
│   │   ├── layout.tsx         # Customer layout with nav
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   ├── orders/
│   │   │   ├── page.tsx
│   │   │   └── [uuid]/
│   │   │       └── page.tsx
│   │   └── profile/
│   │       └── page.tsx
│   ├── (admin)/               # Admin role required
│   │   ├── layout.tsx         # Admin layout with sidebar
│   │   └── admin/
│   │       ├── page.tsx
│   │       └── orders/
│   │           └── page.tsx
│   ├── layout.tsx             # Root layout
│   ├── providers.tsx          # Client providers
│   └── globals.css
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

1. **Route Groups** `(name)` - Organize routes without affecting URL
2. **Colocation** - Keep related files close to where they're used
3. **Shared Components** - Extract to `/components` when used 2+ times
4. **`app/` holds routes, not implementation** - `page.tsx` composes; the components it composes live under `components/`

The non-routing half of this tree (`components/`, `lib/`, `hooks/`, `types/`) is covered in
[react-patterns](../react-patterns/SKILL.md#component-organization).

## App Router Patterns

### Route Groups for Auth Boundaries

A route group is a directory in parentheses. It does not appear in the URL, so it is the cheapest way
to give a set of routes a shared layout — and therefore a shared auth check — without prefixing every
path.

```text
app/
├── (public)/          # No auth required
│   ├── page.tsx       # / - Landing
│   ├── catalog/       # /catalog
│   └── login/         # /login
├── (customer)/        # Auth required
│   ├── layout.tsx     # Wraps with auth check
│   └── dashboard/     # /dashboard
└── (admin)/           # Admin role required
    ├── layout.tsx     # Wraps with role check
    └── admin/         # /admin
```

Two route groups cannot both define the same URL path — `(public)/about/page.tsx` and
`(marketing)/about/page.tsx` collide at build time with a duplicate-route error.

### Dynamic Routes

```typescript
// app/(public)/catalog/[slug]/page.tsx
interface Props {
  params: { slug: string };
}

export default async function ProductDetailPage({ params }: Props) {
  const product = await getProductBySlug(params.slug);
  return <ProductDetail product={product} />;
}

// Generate static params for SSG
export async function generateStaticParams() {
  const products = await getAllProducts();
  return products.map((product) => ({ slug: product.slug }));
}
```

`generateStaticParams` returning an empty array at build time silently produces zero prerendered
pages — the route still works, it is just rendered on demand. If a build is expected to emit static
pages and does not, check that the data source is reachable from the build environment.

### Catch-All Routes

```typescript
// app/docs/[...slug]/page.tsx
interface Props {
  params: { slug: string[] };
}

export default function DocsPage({ params }: Props) {
  // params.slug = ['guides', 'getting-started'] for /docs/guides/getting-started
  const path = params.slug.join('/');
  return <DocContent path={path} />;
}
```

- `[...slug]` matches one or more segments; `/docs` itself does not match.
- `[[...slug]]` (optional catch-all) also matches `/docs`, with `params.slug` undefined.

## Layout Patterns

### Root Layout

Exactly one root layout, and it owns `<html>` and `<body>`. Fonts are loaded through
`next/font` so the font files are self-hosted and the CSS variable is available to Tailwind; a
`<link>` to an external font host reintroduces the render-blocking request `next/font` exists to
remove.

```typescript
// app/layout.tsx
import { Inter, Playfair_Display } from 'next/font/google';
import { Providers } from './providers';
import './globals.css';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
});

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-display',
});

export const metadata = {
  title: {
    default: 'My App',
    template: '%s | My App',
  },
  description: 'App description',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} ${playfair.variable}`}>
      <body className="font-sans antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

`title.template` applies to child routes only; the `default` is what renders for the root itself.

### Auth-Protected Layout

```typescript
// app/(customer)/layout.tsx
'use client';

import { useAuth } from '@/hooks/use-auth';
import { redirect } from 'next/navigation';
import { Header } from '@/components/layout/header';
import { Footer } from '@/components/layout/footer';

export default function CustomerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { isLoaded, isSignedIn } = useAuth();

  // Show loading while checking auth
  if (!isLoaded) {
    return <LoadingSkeleton />;
  }

  // Redirect to login if not authenticated
  if (!isSignedIn) {
    redirect('/login');
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 container mx-auto px-4 py-8">
        {children}
      </main>
      <Footer />
    </div>
  );
}
```

The `isLoaded` guard must come first. Redirecting on `!isSignedIn` before the session check resolves
bounces every authenticated user to `/login` on a hard refresh.

A client layout gate is a UX affordance. The route's data must still be authorised server-side — in
the Route Handler, the API, or middleware. See [Middleware](#middleware).

### Admin Layout with Sidebar

```typescript
// app/(admin)/layout.tsx
'use client';

import { useAuth, useUser } from '@/hooks/use-auth';
import { redirect } from 'next/navigation';
import { AdminSidebar } from '@/components/layout/admin-sidebar';

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { isLoaded, isSignedIn } = useAuth();
  const { user } = useUser();

  if (!isLoaded) return <LoadingSkeleton />;
  if (!isSignedIn) redirect('/login');
  if (!['owner', 'admin'].includes(user?.role)) redirect('/dashboard');

  return (
    <div className="flex min-h-screen">
      <AdminSidebar />
      <main className="flex-1 p-8 bg-gray-50">
        {children}
      </main>
    </div>
  );
}
```

Layouts do not re-mount on navigation between their children. That is what makes a sidebar keep its
scroll position — and also why layout-level state persists across routes whether you wanted it to or
not. Put per-route state in the page, not the layout.

## Page Patterns

### Client Page with Data Fetching

```typescript
// app/(customer)/orders/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { ordersApi, type Order } from '@/lib/api';
import { OrderCard } from '@/components/features/orders/order-card';

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadOrders() {
      try {
        const data = await ordersApi.getMyOrders();
        setOrders(data.orders);
      } catch (err) {
        setError('Failed to load orders');
        console.error('Failed to load orders', err);
      } finally {
        setLoading(false);
      }
    }
    loadOrders();
  }, []);

  if (loading) return <OrdersLoadingSkeleton />;
  if (error) return <ErrorMessage message={error} />;
  if (orders.length === 0) return <EmptyState message="No orders yet" />;

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">My Orders</h1>
      <div className="grid gap-4">
        {orders.map((order) => (
          <OrderCard key={order.uuid} order={order} />
        ))}
      </div>
    </div>
  );
}
```

Four branches — loading, error, empty, content — before the happy path. The cancellation-safe
version of this effect, and the query-library version that replaces it, are in
[react-patterns](../react-patterns/SKILL.md#data-fetching).

### Server Page (SSR/SSG)

```typescript
// app/(public)/catalog/[slug]/page.tsx
import { notFound } from 'next/navigation';
import { catalogApi } from '@/lib/api';
import { ProductDetail } from '@/components/features/catalog/product-detail';

interface Props {
  params: { slug: string };
}

// Generate metadata for SEO
export async function generateMetadata({ params }: Props) {
  const product = await catalogApi.getProductBySlug(params.slug);
  if (!product) return { title: 'Not Found' };

  return {
    title: product.name,
    description: product.description,
    openGraph: {
      images: [product.imageUrl],
    },
  };
}

export default async function ProductDetailPage({ params }: Props) {
  const product = await catalogApi.getProductBySlug(params.slug);

  if (!product) {
    notFound();
  }

  return <ProductDetail product={product} />;
}
```

`generateMetadata` and the page body both fetch the same record. With Next's request-scoped `fetch`
deduplication, that is one network call per request — as long as both use `fetch` with identical
arguments. A hand-rolled client using `axios` or a database driver is not deduplicated; wrap it in
`React.cache()` to get the same behaviour.

`notFound()` throws — code after it never runs, so there is no need for an `else`.

### Detail Page with UUID Param

Public routes address records by `uuid`, never by the numeric primary key. `useParams()` returns
`string | string[]`, hence the cast.

```typescript
// app/(customer)/orders/[uuid]/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { ordersApi, type Order } from '@/lib/api';

export default function OrderDetailPage() {
  const params = useParams();
  const uuid = params.uuid as string;

  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadOrder() {
      try {
        const data = await ordersApi.getOrder(uuid);
        setOrder(data);
      } catch (error) {
        console.error('Failed to load order', error);
      } finally {
        setLoading(false);
      }
    }
    loadOrder();
  }, [uuid]);

  if (loading) return <OrderDetailSkeleton />;
  if (!order) return <NotFound />;

  return <OrderDetail order={order} />;
}
```

### Special Files

| File | Renders when |
|---|---|
| `page.tsx` | The segment's URL is matched |
| `layout.tsx` | Wraps the segment and everything below it; does not re-mount on sibling navigation |
| `template.tsx` | Like a layout, but re-mounts on every navigation (use for enter animations, per-route effects) |
| `loading.tsx` | Automatic Suspense boundary while the segment's server data resolves |
| `error.tsx` | Client error boundary for the segment; must be a Client Component and takes `{ error, reset }` |
| `not-found.tsx` | `notFound()` was thrown in this segment |
| `route.ts` | The segment is an API endpoint instead of a page (cannot coexist with `page.tsx`) |
| `default.tsx` | Fallback slot content for parallel routes on a hard navigation |

## Route Handlers

`app/api/**/route.ts` exports one async function per HTTP method. A file exporting `route.ts` and a
sibling `page.tsx` in the same segment is a build error.

```typescript
// app/api/orders/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const CreateOrder = z.object({
  productUuid: z.string().uuid(),
  quantity: z.number().int().positive(),
});

export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  }

  const status = request.nextUrl.searchParams.get('status') ?? undefined;
  const orders = await listOrders(session.userId, { status });
  return NextResponse.json({ orders });
}

export async function POST(request: NextRequest) {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  }

  const parsed = CreateOrder.safeParse(await request.json());
  if (!parsed.success) {
    return NextResponse.json(
      { message: 'Invalid input', errors: parsed.error.flatten() },
      { status: 422 }
    );
  }

  const order = await createOrder(session.userId, parsed.data);
  return NextResponse.json(order, { status: 201 });
}
```

- Validate the body with a schema before touching it. `await request.json()` is untyped and attacker-controlled.
- Authorise inside the handler. Middleware is a coarse filter, not the authorisation layer.
- `request.json()` can only be read once per request — read it into a variable if you need it twice.

## Middleware

One `middleware.ts` at the project root. It runs on the Edge runtime: no Node built-ins, no database
drivers, no filesystem.

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

const PUBLIC_PATHS = ['/', '/login', '/catalog'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(`${p}/`))) {
    return NextResponse.next();
  }

  const session = request.cookies.get('app-session');
  if (!session) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('next', pathname);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

- The `matcher` must be statically analysable — a value computed at runtime is ignored and the middleware runs on every request.
- Presence of a cookie is not proof of a valid session. Middleware decides "redirect or continue"; the handler decides "allowed or denied".
- Session cookies follow a `<prefix>-` convention: `app-session`, `app-refresh`, `app-csrf-token`.

### Cookie scope gotcha

A cookie set for a parent domain (`{{PROJECT_DOMAIN}}`) and a cookie of the same name set for a
subdomain (`admin.{{PROJECT_DOMAIN}}`) are two different cookies, and the browser sends both. The
server reads whichever arrives first, which is usually the older, narrower one. Symptom: a session
that works immediately after login and fails a minute later, with an "invalid token" error whose
token hash never changes. When narrowing or broadening a cookie's `Domain` or `Path`, the clearing
code must clear the old scope as well as the new one, or every pre-existing session shadows the new
cookie until the browser is cleared by hand.

Browsers also treat `localhost` as a public suffix, so cookies cannot be shared across
`*.localhost` subdomains. For local multi-subdomain work, map real-looking hostnames
(`api.example.com`, `admin.example.com`) to the loopback address in the hosts file and front the dev servers
with a reverse proxy.

## Caching and Revalidation

Four caches sit between a request and a response. Diagnose in this order.

| Cache | Scope | Invalidate with |
|---|---|---|
| Request memoization | One render pass | Nothing — it is per-request by design |
| Data Cache (`fetch`) | Across requests and deploys | `revalidate`, `revalidateTag`, `revalidatePath`, or `cache: 'no-store'` |
| Full Route Cache | Prerendered HTML/RSC payload | `revalidatePath`, a new deploy, or making the route dynamic |
| Router Cache | Client-side, per session | `router.refresh()`, or a server action that revalidates |

```typescript
// Per-fetch control
const res = await fetch(`${API_URL}/api/catalog/products`, {
  next: { revalidate: 60, tags: ['products'] },
});

// Never cache
const me = await fetch(`${API_URL}/api/me`, { cache: 'no-store' });

// Segment-level control
export const revalidate = 3600;      // ISR: re-render at most hourly
export const dynamic = 'force-dynamic';  // opt the whole segment out of static rendering
```

```typescript
// Invalidate from a server action or route handler
import { revalidateTag, revalidatePath } from 'next/cache';

export async function updateProduct(uuid: string, data: UpdateProductDto) {
  'use server';
  await api.updateProduct(uuid, data);
  revalidateTag('products');
  revalidatePath(`/catalog/${data.slug}`);
}
```

- Reading `cookies()`, `headers()`, or `searchParams` makes a route dynamic. A page that "refuses to be static" almost always reads one of them, often indirectly through a helper.
- Conversely, a page showing stale data after a deploy is usually statically rendered with a cached `fetch` and no `revalidate`.
- `router.refresh()` re-fetches the server data for the current route without losing client state — the right tool after a mutation that a server action did not already revalidate.

## Hydration

A hydration mismatch means the server HTML and the first client render disagree. The four common
causes:

```tsx
// 1. Non-deterministic values in render
<span>{new Date().toLocaleTimeString()}</span>   // server time !== client time
<div id={Math.random()} />                        // different every render

// 2. Browser-only APIs read during render
const theme = localStorage.getItem('theme');      // undefined on the server

// 3. Invalid nesting the browser silently repairs
<p><div>text</div></p>                            // browser moves the div out of the p

// 4. Extensions or locale formatting altering the DOM before hydration
```

Fixes, in order of preference:

```tsx
// Render the value after mount
const [now, setNow] = useState<string | null>(null);
useEffect(() => setNow(new Date().toLocaleTimeString()), []);
return <span>{now ?? '—'}</span>;

// Or accept a one-element mismatch explicitly
<time suppressHydrationWarning>{new Date().toISOString()}</time>

// Or load the component client-only when it genuinely cannot render on the server
const Chart = dynamic(() => import('./chart'), { ssr: false });
```

`useId()` — not `Math.random()` — is the correct source for generated DOM ids that must match across
server and client.

## Configuration and Environment

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',            // self-contained server bundle for containers
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'cdn.example.com' },
    ],
  },
  async redirects() {
    return [{ source: '/old-path', destination: '/catalog', permanent: true }];
  },
};

module.exports = nextConfig;
```

- `output: 'standalone'` emits a `server.js` to run directly (`node apps/web/server.js`). A container image built this way must start that file, not the package script.
- `next/image` refuses any host not listed in `images.remotePatterns` — the failure is a broken image plus a server-side error, not a fallback.
- `NEXT_PUBLIC_*` variables are inlined into the client bundle **at build time**. They cannot be changed by the runtime environment, and anything secret placed behind that prefix is published. Server-only variables have no prefix and are read at runtime.
- Variables are read in order from `.env.$(NODE_ENV).local`, `.env.local` (not loaded in test), `.env.$(NODE_ENV)`, `.env`. Committing a `.env.production` that shadows the deployment's real environment is a common way to ship the wrong API URL.

## Build and Dev Server

```bash
# Development
npm run dev                      # local dev server
npm run dev -- --port 3000       # pin the port

# Type checking and linting
npx tsc --noEmit
npm run lint

# Production build and run
npm run build
npm run start

# Inspect what rendered statically vs dynamically
npm run build | grep -E '^[[:space:]]*[○●ƒλ]'
```

The build output marks each route: static, prerendered with `generateStaticParams`, or server-rendered
on demand. Read it after any change to caching or to `cookies()`/`headers()` usage — a route silently
flipping from static to dynamic is the usual cause of a sudden latency regression.

Two build-tooling notes:

- Generated route types under `.next/types` are derived from the filesystem. After adding a route directory, delete `.next/types` (or restart the dev server) before type-checking, or `tsc` reports a route that plainly exists as unknown.
- A dev server that has been running across a dependency change or a config edit may be serving stale output. Kill the process, confirm the port is free, clear `.next`, start once, and confirm exactly one server is listening before concluding a change "did not work".

```bash
# Restart cleanly on port 3000
lsof -ti :3000 | xargs kill -9 2>/dev/null
lsof -ti :3000            # expect no output
rm -rf .next
npm run dev
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000
```

For the bundler itself — incremental builds, filesystem caching, Turbopack vs webpack — see
[nextjs-turbopack](../nextjs-turbopack/SKILL.md).

## Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| Every authenticated user bounced to `/login` on refresh | Layout redirects before the session check resolves | Guard on `isLoaded` before `isSignedIn` |
| `useState`/`useEffect` "only works in a Client Component" | Missing `'use client'` at the top of the file | Add the directive, or move the stateful part into its own client component |
| "Cannot import a Server Component into a Client Component" | Direct `import` across the boundary | Pass it as `children` from a server parent |
| Page shows stale data after a deploy | Statically rendered with a cached `fetch` | Add `next: { revalidate }`, a tag, or `cache: 'no-store'` |
| Route unexpectedly dynamic, build shows no static pages | Something reads `cookies()`, `headers()`, or `searchParams` | Move the read below a Suspense boundary, or accept the dynamic render |
| Hydration mismatch on a timestamp or id | Non-deterministic render | Render after mount, or use `useId()` |
| Secret visible in devtools | Named with a public prefix | Rename without `NEXT_PUBLIC_`, read it server-side, rotate the exposed value |
| `next/image` renders broken | Remote host not in `images.remotePatterns` | Add the host pattern |
| Two route groups both define `/about` | Duplicate URL path across groups | Rename one path; groups do not disambiguate URLs |
| Middleware runs on static assets | `matcher` missing the `_next` exclusions | Use the negative-lookahead matcher above |
| Changed code not reflected in the browser | Stale dev-server process or `.next` cache | Kill, clear `.next`, restart, verify one listener |
| Cookie-based session drops a minute after login | Old cookie at a different `Domain`/`Path` shadowing the new one | Clear both scopes when the cookie's scope changes |

## Review Checklist

- [ ] Every stateful or event-handling component file starts with `'use client'`
- [ ] No Server Component imported into a Client Component file
- [ ] Auth layouts check `isLoaded` before redirecting
- [ ] Every client-side route gate is re-enforced in the Route Handler or API
- [ ] Route Handlers validate the request body with a schema before use
- [ ] `middleware.ts` has a static `matcher` excluding `_next/static`, `_next/image`, `favicon.ico`
- [ ] Every `fetch` of mutable data declares `revalidate`, a tag, or `cache: 'no-store'`
- [ ] Mutations call `revalidateTag`/`revalidatePath` or `router.refresh()`
- [ ] No `NEXT_PUBLIC_` variable holds a secret
- [ ] `generateMetadata` exists for every public, indexable route
- [ ] `notFound()` is called for missing records rather than rendering an empty page
- [ ] Dynamic segments address records by `uuid`, not by numeric primary key
- [ ] `loading.tsx` or a Suspense boundary exists for every slow segment
- [ ] `error.tsx` exists for segments that can fail, and is a Client Component
- [ ] Build output reviewed for routes that unexpectedly became dynamic

## Related

- Skills: [react-patterns](../react-patterns/SKILL.md) for hooks, composition, context, forms, API clients and loading states; [nextjs-turbopack](../nextjs-turbopack/SKILL.md) for the bundler and dev-server performance; [react-performance](../react-performance/SKILL.md); [frontend-patterns](../frontend-patterns/SKILL.md); [accessibility](../accessibility/SKILL.md); [react-testing](../react-testing/SKILL.md)
- Rules: [rules/react/](../../rules/react/) — coding-style, patterns, security, testing

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
