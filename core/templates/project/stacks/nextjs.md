## Stack Rules — Next.js (App Router)

### Rendering and data
- Server Components by default; `'use client'` only on leaves that need state, effects, or browser APIs
- Reads in Server Components or `load`-style helpers; every fetch carries an explicit caching decision as a comment (`// cache: revalidate 60, tag users`)
- Mutations are server actions with schema validation and an authorization check **inside** the action
- `revalidateTag`/`revalidatePath` after mutations; tag names come from one module

### Authentication
- Session verified in Server Components and actions, never only in middleware; middleware does routing and light checks with no database access
- Protected route group `(app)/layout.tsx` calls the session guard once for everything beneath it
- Client SDK sign-in components must not auto-navigate; the app router redirects

### Structure
- Routes in `app/` delegate to `src/features/<name>/` per the UI rules; pages under 150 lines, components under 200
- `server-only` on modules that must not reach the browser; database clients never imported by client components
- After adding a route directory, restart the dev server or clear `.next/types` before type-checking

### Verification
- `next build` clean, no hydration warnings in the console, behavioural suite covers every server action path
