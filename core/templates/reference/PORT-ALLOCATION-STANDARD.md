# Port Allocation Standard — Method and Template

**Last Updated:** YYYY-MM-DD
**Status:** CURRENT

## How to use this document

This is both a method and a fill-in-the-blanks standard. The method — one
contiguous block per environment, every port written down before it is used,
one command that detects a collision — is the part worth copying. The port
numbers are examples: a generic local block `30xx` and a generic container
block `40xx`.

1. Copy this file to `{{DOCS_DIR}}/port-allocation-standard.md`.
2. Pick your blocks (see "Choosing a block" below) and replace every `30xx`
   and `40xx` number in the tables with yours.
3. Replace `{{API_APP}}`, `{{ADMIN_APP}}`, `{{PORTAL_APP}}`, `{{DEV_APP}}`,
   `{{WEB_APP}}` with your application directories, and `{{PROJECT_DOMAIN}}`
   with your domain. Runnable examples below use `example.com`.
4. Delete rows for services this project does not have. Do not leave a row
   for a service that does not exist — a reader will try to reach it.
5. Update the changelog table at the bottom on every change. An undocumented
   reallocation is how two services end up sharing a port.

---

## Overview

This document defines the official port allocation for all platform services
across local development, containers, and production environments. It is the
single answer to "what port does X run on", and the place a port is reserved
before anybody binds it.

---

## Port Scheme Summary

The platform uses two port schemes:

| Environment | Scheme | Range | Rationale |
|-------------|--------|-------|-----------|
| **Local Development** | 30xx | 3000-3009 | One contiguous block; avoids conflicts with common dev tools |
| **Containers / Production** | 40xx | 4000-4049 | Distinct leading digit, so the environment is readable from the port alone |

The two schemes exist so that a URL states its own environment. A request to
`:3001` is the local API; a request to `:4001` is the containerised API. Both
can run at the same time, and a copy-pasted URL cannot silently hit the wrong
one.

---

## Choosing a block

The method, if you are allocating for a new project rather than copying this
one:

1. **One contiguous block per environment**, at least twice as wide as the
   number of services you have today. Ten slots for five services.
2. **Different leading digit per environment.** The environment must be
   readable from the port number without consulting a table.
3. **Stay above 1024.** Ports below that need elevated privileges on
   Unix-like systems.
4. **Avoid the ranges in "Ports to avoid" below**, and avoid whatever else is
   already listening on a developer machine here.
5. **Fix the offsets across environments.** If the API is the `+1` slot
   locally, it is the `+1` slot everywhere: local `3001`, container `4001`.
   The offset is then memorable and scripts can compute it.
6. **Reserve the whole block** in the table below, including the slots you
   are not using yet, so a later service does not take one that a script
   already assumes.

---

## Ports to avoid

Check this list before claiming a block. Anything here will collide on some
developer's machine, and the failure mode — a service that binds but answers
with something unexpected — costs more than it saves.

| Port / range | Commonly used by | Notes |
|--------------|------------------|-------|
| 0-1023 | System services | Require elevated privileges to bind |
| 80, 443 | HTTP / HTTPS | Reserve for the reverse proxy only |
| 3000 | Default for many JavaScript dev servers | Fine *inside* a claimed block, but expect a collision with an unrelated project |
| 5000, 7000 | System services on some operating systems | Frequently already bound |
| 5432 | PostgreSQL | Standard; map containers to a block port instead |
| 6379 | Redis | Standard; map containers to a block port instead |
| 8080, 8000 | Generic HTTP alternates | Heavily contested on shared machines |
| 9229 | Node.js inspector | Leave free for debugging |
| 27017 | MongoDB | Standard |

---

## Local Development Ports (30xx)

| Port | Service | Application | Description |
|------|---------|-------------|-------------|
| **3000** | Admin Console | `{{ADMIN_APP}}` | Internal administration UI |
| **3001** | Platform API | `{{API_APP}}` | Core backend API |
| **3002** | Customer Portal | `{{PORTAL_APP}}` | End-user portal |
| **3003** | Developer Console | `{{DEV_APP}}` | Developer tools |
| **3004** | Marketing Website | `{{WEB_APP}}` | Public marketing site |
| **3005** | CMS | `apps/cms` | Content management |
| 3006-3009 | *(reserved)* | | Held for future services in this block |

**Database and infrastructure (standard ports):**

| Port | Service | Description |
|------|---------|-------------|
| **5432** | PostgreSQL | Local dev database (`{{DB_NAME}}`, example `app_dev`) |
| **6379** | Redis | Local cache, when run outside a container |

**Local development URLs:**

| Service | URL |
|---------|-----|
| Admin Console | http://localhost:3000 |
| API | http://localhost:3001 |
| API Docs | http://localhost:3001/api/docs |
| Customer Portal | http://localhost:3002 |
| Developer Console | http://localhost:3003 |
| Marketing Website | http://localhost:3004 |
| CMS | http://localhost:3005 |

---

## Container Ports (40xx)

### Core Platform Services

| Port | Service | Container Name | Description |
|------|---------|----------------|-------------|
| **4000** | Admin Console | `app_admin` | Admin UI |
| **4001** | Platform API | `app_api` | Backend API |
| **4002** | Customer Portal | `app_portal` | Customer portal |
| **4003** | Developer Console | `app_dev` | Developer tools |
| **4004** | Marketing Website | `app_web` | Marketing site |
| **4005** | CMS | `app_cms` | Content management |

### Infrastructure Services

| Port | Service | Container Name | Description |
|------|---------|----------------|-------------|
| **4032** | PostgreSQL | `app_db` | Database (maps to internal 5432) |
| **4039** | Redis | `app_redis` | Cache/Queue (maps to internal 6379) |
| **4025** | Mail catcher Web UI | `app_mail` | Email testing UI (maps to internal 8025) |
| **4026** | Mail catcher SMTP | `app_mail` | Email testing SMTP (maps to internal 1025) |
| **4080** | Reverse proxy | `app_proxy` | Subdomain routing for containers |

### Observability Services

| Port | Service | Container Name | Description |
|------|---------|----------------|-------------|
| **4016** | Tracing UI | `app_tracing` | Distributed tracing UI (maps to internal 16686) |
| **4017** | Telemetry collector (gRPC) | `app_otel` | OpenTelemetry gRPC (maps to internal 4317) |
| **4018** | Telemetry collector (HTTP) | `app_otel` | OpenTelemetry HTTP (maps to internal 4318) |
| **4042** | Analytics | `app_analytics` | Self-hosted analytics (maps to internal 3000) |

### Demo Application Services

| Port | Service | Container Name | Description |
|------|---------|----------------|-------------|
| **4008** | demo-tenant API | `demo_one_api` | Demo app backend |
| **4009** | demo-tenant Web | `demo_one_web` | Demo app frontend |
| **4010** | example-tenant API | `demo_two_api` | Demo app backend |
| **4011** | example-tenant Web | `demo_two_web` | Demo app frontend |

Note the internal-to-published mapping: a container keeps the service's
conventional internal port (5432, 6379, 4317) and publishes it on a block
port. Nothing inside the container needs to know about the block.

---

## Production

In production, all services use the same 40xx internal ports but are reached
externally through a reverse proxy on ports 80/443 with HTTPS.

| Service | Internal Port | External URL |
|---------|---------------|--------------|
| Marketing Site | 4004 | https://example.com |
| API | 4001 | https://api.example.com |
| Admin Console | 4000 | https://admin.example.com |
| Customer Portal | 4002 | https://portal.example.com |
| Developer Console | 4003 | https://dev.example.com |
| Tenant Subdomains | 4002 (portal) | https://*.example.com |
| demo-tenant Web | 4009 | https://demo-tenant.example.com |
| demo-tenant API | 4008 | https://api.demo-tenant.example.com |
| example-tenant Web | 4011 | https://example-tenant.example.com |

**Key:** Production ports bind to the loopback interface only and are not
externally reachable. All external traffic flows through the reverse proxy on
ports 80/443.

Verify the binding rather than assuming it:

```bash
# Every application port must show a loopback bind address, never a wildcard bind
ss -tlnp | grep -E ':40[0-9]{2}'
```

---

## Reverse Proxy (Local Development)

For local development with working cross-subdomain cookies, front the local
ports with a reverse proxy on a real domain. Browsers treat `localhost` as a
public suffix, so cookies cannot be shared across `*.localhost` subdomains and
any flow that depends on a shared parent-domain cookie will fail.

| Domain | Routes To | Service |
|--------|-----------|---------|
| `api.example.com` | localhost:3001 | API |
| `admin.example.com` | localhost:3000 | Admin Console |
| `portal.example.com` | localhost:3002 | Customer Portal |
| `dev.example.com` | localhost:3003 | Developer Console |
| `cms.example.com` | localhost:3005 | CMS |
| `example.com` | localhost:3004 | Marketing Website |
| `*.example.com` | localhost:3002 | Portal (tenant subdomains) |

The proxy binds port 80 for the local block (needs elevated privileges) and
port 4080 for the container block (does not), so both can run at once:

| Environment | Proxy port | Example URL | Elevated privileges |
|-------------|------------|-------------|---------------------|
| Local (30xx) | 80 | `http://admin.example.com` | Yes |
| Containers (40xx) | 4080 | `http://admin.example.com:4080` | No |

See the project's `CLAUDE.md` for the proxy setup instructions.

---

## Reserved Port Ranges

| Range | Purpose |
|-------|---------|
| 30xx (3000-3009) | Local development platform services |
| 40xx (4000-4049) | Container platform and infrastructure services, demo applications included |

Anything outside these ranges is unallocated and must be added to this table
before it is used.

---

## Environment Variables

### Local Development

```env
# API
PORT=3001

# Admin Console
PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:3001

# Customer Portal
PORT=3002
NEXT_PUBLIC_APP_API_URL=http://localhost:3001

# Developer Console
PORT=3003
NEXT_PUBLIC_API_URL=http://localhost:3001
```

### Containers

```env
# API
PORT=4001

# Admin Console
PORT=4000
NEXT_PUBLIC_API_URL=http://localhost:4001

# Customer Portal
PORT=4002
NEXT_PUBLIC_APP_API_URL=http://localhost:4001

# Developer Console
PORT=4003
NEXT_PUBLIC_API_URL=http://localhost:4001
```

No port is hardcoded in application source. The value comes from `PORT`, and
this document is the record of what `PORT` is set to where.

---

## Start Commands (Local Development)

```bash
# Start API (port 3001)
npm run start:dev --workspace={{API_APP}}

# Start Admin Console (port 3000)
npm run dev --workspace={{ADMIN_APP}}

# Start Customer Portal (port 3002)
npm run dev --workspace={{PORTAL_APP}}

# Start Developer Console (port 3003)
npm run dev --workspace={{DEV_APP}}

# Start Marketing Website (port 3004)
npm run dev --workspace={{WEB_APP}}

# Start CMS (port 3005)
npm run dev --workspace=apps/cms
```

---

## Detecting a Conflict

Run these before claiming a new port, and whenever a service starts but
answers with something you did not expect.

```bash
# What is listening on one port
lsof -nP -iTCP:3001 -sTCP:LISTEN

# Everything listening in the local block
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':30[0-9]{2}'

# Everything listening in the container block
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':40[0-9]{2}'

# Published container ports (the PORTS column shows host -> container)
docker ps

# Free a port held by a stale process from an earlier run
lsof -ti :3001 | xargs -r kill -9
lsof -ti :3001            # must print nothing
```

Two failure modes to recognise:

- **Bind refused** (`EADDRINUSE`): something else already holds the port. The
  service tells you loudly; fix it by freeing the port, not by picking an
  unallocated one.
- **Wrong service answers**: the port was quietly reallocated, or a stale
  process from an earlier run never exited. This one is silent. The health
  check below is what catches it.

Check that the port serves what this document says it serves:

```bash
# Every allocated local port answers, and answers as the right service
for p in 3000 3001 3002 3003 3004 3005; do
  printf '%s -> %s\n' "$p" "$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$p" || echo down)"
done
```

---

## Health Check Endpoints

| Service | Health Endpoint |
|---------|-----------------|
| API | `GET /api/v1/health` |
| Admin Console | `GET /` (returns 200) |
| Customer Portal | `GET /` (returns 200 or 307 redirect) |
| Developer Console | `GET /` (returns 200) |
| Marketing Website | `GET /` (returns 200) |
| CMS | `GET /` (returns 200) |

---

## Allocating a New Port

- [ ] Confirm the service genuinely needs its own port
- [ ] Take the next free slot in the correct environment block
- [ ] Take the matching offset in every other environment block at the same time
- [ ] Check nothing is already listening (`lsof -nP -iTCP:<port> -sTCP:LISTEN`)
- [ ] Check the port is not in "Ports to avoid" above
- [ ] Add a row to the table for every environment, including production
- [ ] Add the reverse-proxy route if the service is reached by domain
- [ ] Add the `PORT` environment variable to the env block
- [ ] Add the health endpoint to the health-check table
- [ ] Add a changelog row below

---

## Changelog

| Date | Change | Maintainer |
|------|--------|-----------|
| YYYY-MM-DD | Initial port allocation standard | platform |
| YYYY-MM-DD | Adopted the two-block scheme: 30xx local, 40xx containers; added production URLs, demo apps, observability ports | platform |
