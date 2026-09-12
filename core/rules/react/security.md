---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/app/**/*.ts"
  - "**/pages/**/*.ts"
---
# React Security

> This file extends [typescript/security.md](../typescript/security.md) and [common/security.md](../common/security.md) with React specific content.

Worked examples: skill `react-patterns`.

## XSS via `dangerouslySetInnerHTML`

CRITICAL. The prop name is deliberately scary — treat every usage as a code review halt.

Correct options: render the value as text, render parsed markdown via a library that sanitizes, or — when raw HTML is genuinely required — sanitize first with DOMPurify.

Audit checklist for every `dangerouslySetInnerHTML` call:

- Is the input always under our control? Document the source.
- If user-derived: is it sanitized at the **same call site**? (Sanitization at the API boundary is acceptable only if every consumer is verified.)
- Is the sanitizer config allowlisting tags, not denylisting?

## Unsafe URL Schemes

`javascript:` and `data:` URLs in `href`, `src`, and `xlink:href` execute arbitrary code. Validate the scheme against an allowlist (`http:`, `https:`, `mailto:`) before rendering a user-supplied URL.

React warns about `javascript:` URLs in `href` in development mode, but does not block them at runtime. `data:` URLs and other schemes also slip through. Always validate.

## `target="_blank"` Without `rel`

`<a target="_blank">` without `rel="noopener noreferrer"` lets the target page access `window.opener` and run navigation hijacks.

Modern browsers default to `noopener` when `target="_blank"`, but do not rely on browser defaults — be explicit.

## Server Action Input Validation

Server Actions (`"use server"`) run with the same trust level as a public API endpoint. Validate every input with a schema before using it.

- Authenticate inside the action — do not trust the client-side route gate
- Authorize: confirm the current user has permission for the specific record they are mutating
- Rate limit sensitive actions

## Secret Exposure via Env Vars

Prefixed env vars are bundled into the client. Treat them as public.

| Framework | Public prefix | Private |
|---|---|---|
| Next.js | `NEXT_PUBLIC_*` | All others |
| Vite | `VITE_*` | `.env` server-side only |
| Create React App | `REACT_APP_*`, plus `NODE_ENV` and `PUBLIC_URL` | All others (anything without the `REACT_APP_` prefix is server-side only) |
| Remix | `process.env` access in `loader`/`action` only | Same |

Audit on every PR that touches env vars: would this string in the public bundle be a problem?

## Authentication / Authorization

- Never store sessions in `localStorage` — accessible to any XSS. Use httpOnly secure cookies.
- Never trust client-set state to gate sensitive UI. Render-gating in JSX prevents display, not access — the API must enforce.
- CSRF: cookie-based auth requires CSRF tokens or `SameSite=Strict`/`Lax` cookies
- Use double-submit cookies or origin verification for form actions when not using framework defaults

## Content Security Policy (CSP)

Configure server-side. The minimum acceptable CSP for a React app:

```
default-src 'self';
script-src 'self' 'nonce-{REQUEST_NONCE}';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
connect-src 'self' https://api.example.com;
frame-ancestors 'none';
```

- Avoid `unsafe-inline` and `unsafe-eval` in `script-src`
- For SSR with inline scripts (Next.js streaming, hydration data), use per-request nonces — both Next.js and Remix support nonce injection
- `style-src 'unsafe-inline'` is often unavoidable for CSS-in-JS libraries — document the tradeoff

## Prototype Pollution via Object Spread

Never spread untrusted JSON straight into state — the attacker controls `__proto__`. Parse it with a schema first, or guard the keys.

## SSR Template Injection

When using `renderToString` or `renderToPipeableStream`:

- All values rendered inside JSX are escaped by React — safe
- Values passed to `dangerouslySetInnerHTML` are NOT escaped — same rules as client
- Manually constructed HTML wrappers around the React output must be escaped or sanitized — never concatenate user input into the surrounding HTML template

## Third-Party Components

- Audit `npm audit` before adding any UI library
- Check that the library does not internally use `dangerouslySetInnerHTML` on its input (e.g., rich text editors)
- Pin versions, review changelogs before major upgrades
- Be wary of components that accept HTML strings as props

## Source Map Exposure in Production

Production builds should ship without source maps, or with sourcemaps uploaded to an error tracker (Sentry) and stripped from the public bundle. Public source maps leak internal logic and file structure.

## Agent Support

- Use `owasp-top10-expert` for comprehensive security audits across the codebase
- Use `react-expert` for React-specific patterns and the above rules in active code review
