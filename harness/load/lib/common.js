// Shared helpers for the k6 load harness.
//
// Everything the scenarios need is configured through environment variables, so
// the same scenarios work against any HTTP service:
//
//   API_BASE            base URL (default: the project's configured API base)
//   AUTH_MODE           'none' (default) or 'login'
//   AUTH_LOGIN_PATH     login endpoint, appended to API_BASE (default /auth/login)
//   AUTH_TOKEN_JQ       dot-path to the token in the login response (default .access_token)
//   AUTH_EMAIL_FIELD    login body field for the identifier (default email)
//   AUTH_PASSWORD_FIELD login body field for the secret (default password)
//   LOAD_USER_PASSWORD  the password every fixture user shares (never committed)
//   LOAD_ENDPOINTS      JSON array of {method, path, weight, name}
//                       default: [{"method":"GET","path":"/health","weight":1,"name":"health"}]
//
// With AUTH_MODE=none no fixtures are needed and no credentials are sent.

import http from 'k6/http';
import { check } from 'k6';
import { SharedArray } from 'k6/data';
import exec from 'k6/execution';

export const API_BASE = __ENV.API_BASE || '{{API_BASE_URL}}';
export const AUTH_MODE = (__ENV.AUTH_MODE || 'none').toLowerCase();

const AUTH_LOGIN_PATH = __ENV.AUTH_LOGIN_PATH || '/auth/login';
const AUTH_TOKEN_PATH = __ENV.AUTH_TOKEN_JQ || '.access_token';
const AUTH_EMAIL_FIELD = __ENV.AUTH_EMAIL_FIELD || 'email';
const AUTH_PASSWORD_FIELD = __ENV.AUTH_PASSWORD_FIELD || 'password';

// A realistic browser User-Agent by default: services that score clients for
// risk, or block unknown agents, treat k6's default agent as suspicious — the
// run would then measure the bot filter instead of capacity.
const BROWSER_UA =
  __ENV.LOAD_USER_AGENT ||
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

export function headers(extra) {
  return Object.assign(
    { 'Content-Type': 'application/json', 'User-Agent': BROWSER_UA },
    extra || {},
  );
}

export function authHeaders(token) {
  return token ? headers({ Authorization: `Bearer ${token}` }) : headers();
}

// ---------------------------------------------------------------------------
// Endpoint mix
// ---------------------------------------------------------------------------

const DEFAULT_ENDPOINTS = [{ method: 'GET', path: '/health', weight: 1, name: 'health' }];

function parseEndpoints() {
  if (!__ENV.LOAD_ENDPOINTS) return DEFAULT_ENDPOINTS;
  let parsed;
  try {
    parsed = JSON.parse(__ENV.LOAD_ENDPOINTS);
  } catch (e) {
    throw new Error(`LOAD_ENDPOINTS is not valid JSON: ${e.message}`);
  }
  if (!Array.isArray(parsed) || parsed.length === 0) {
    throw new Error('LOAD_ENDPOINTS must be a non-empty JSON array');
  }
  return parsed.map((ep, i) => {
    if (!ep.path) throw new Error(`LOAD_ENDPOINTS[${i}] has no "path"`);
    return {
      method: (ep.method || 'GET').toUpperCase(),
      path: ep.path,
      weight: Number(ep.weight) > 0 ? Number(ep.weight) : 1,
      name: ep.name || ep.path,
      body: ep.body,
    };
  });
}

export const endpoints = parseEndpoints();

const TOTAL_WEIGHT = endpoints.reduce((sum, ep) => sum + ep.weight, 0);

// Pick an endpoint according to the configured weights.
export function pickEndpoint(r) {
  const roll = (typeof r === 'number' ? r : Math.random()) * TOTAL_WEIGHT;
  let acc = 0;
  for (const ep of endpoints) {
    acc += ep.weight;
    if (roll < acc) return ep;
  }
  return endpoints[endpoints.length - 1];
}

// Issue one request against an endpoint definition, tagged with its name so
// thresholds and the summary can address it individually.
export function callEndpoint(ep, token) {
  const url = `${API_BASE}${ep.path}`;
  const params = { headers: authHeaders(token), tags: { name: ep.name } };
  const body = ep.body ? JSON.stringify(ep.body) : null;

  const res = body
    ? http.request(ep.method, url, body, params)
    : http.request(ep.method, url, null, params);

  check(res, { [`${ep.name} not 5xx`]: (r) => r.status < 500 });
  return res;
}

// ---------------------------------------------------------------------------
// Fixtures and authentication (only used when AUTH_MODE=login)
// ---------------------------------------------------------------------------

// fixtures/users.json is written by seed-load-users.sh. SharedArray keeps one
// in-memory copy across all VUs. Absent file + AUTH_MODE=none is normal.
export const users = new SharedArray('load-users', function () {
  try {
    const parsed = JSON.parse(open('../fixtures/users.json'));
    return parsed.users || [];
  } catch (e) {
    if (AUTH_MODE === 'login') {
      throw new Error(
        'AUTH_MODE=login but fixtures/users.json could not be read — run ./seed-load-users.sh first',
      );
    }
    return [];
  }
});

// Spread users across VUs and iterations so no single account is hammered:
// a per-account limiter would otherwise measure the limiter, not capacity.
export function pickUser(vu, iter) {
  if (users.length === 0) return null;
  return users[(vu * 7919 + iter) % users.length];
}

function readTokenPath(body, dotPath) {
  const parts = dotPath.replace(/^\./, '').split('.').filter(Boolean);
  let cur = body;
  for (const part of parts) {
    if (cur === null || cur === undefined) return null;
    cur = cur[part];
  }
  return cur || null;
}

// Log in and return a token, or null. Returns null immediately in AUTH_MODE=none.
export function login(user) {
  if (AUTH_MODE !== 'login' || !user) return null;

  const payload = {};
  payload[AUTH_EMAIL_FIELD] = user.email;
  payload[AUTH_PASSWORD_FIELD] = __ENV.LOAD_USER_PASSWORD;
  // Anything else the API requires travels on the fixture record itself.
  Object.assign(payload, user.extra || {});

  const res = http.post(`${API_BASE}${AUTH_LOGIN_PATH}`, JSON.stringify(payload), {
    headers: headers(),
    tags: { name: 'login' },
  });
  check(res, { 'login 2xx': (r) => r.status >= 200 && r.status < 300 });

  let body;
  try {
    body = res.json();
  } catch (e) {
    return null;
  }
  return readTokenPath(body, AUTH_TOKEN_PATH);
}

// The fixture user for this VU and iteration.
export function currentUser() {
  return pickUser(exec.vu.idInTest, exec.scenario.iterationInTest);
}

// Convenience for scenarios: a token when the run authenticates, null when it does not.
export function tokenFor() {
  if (AUTH_MODE !== 'login') return null;
  return login(currentUser());
}
