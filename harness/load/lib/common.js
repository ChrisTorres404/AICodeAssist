// WO-50000: Shared helpers for the {{PROJECT_NAME}} load harness.
// All scenarios import from here so risk-engine compatibility and auth are consistent.

import http from 'k6/http';
import { check } from 'k6';

export const API_BASE = __ENV.API_BASE || 'http://localhost:4201/api/v1';

// Realistic browser UA is MANDATORY: the adaptive-auth risk engine scores curl-like
// UAs as suspicious (+15) and can block at >=90. Load traffic must look like a browser.
const BROWSER_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

export function headers(extra) {
  return Object.assign(
    { 'Content-Type': 'application/json', 'User-Agent': BROWSER_UA },
    extra || {},
  );
}

// Load the fixture manifest produced by seed-load-users.sh.
// SharedArray keeps a single in-memory copy across all VUs.
import { SharedArray } from 'k6/data';
export const users = new SharedArray('load-users', function () {
  return JSON.parse(open('../fixtures/users.json')).users;
});

// Pick a user deterministically spread across VUs so no single account gets
// hammered (per-account lockout would otherwise measure the limiter, not capacity).
export function pickUser(vu, iter) {
  return users[(vu * 7919 + iter) % users.length];
}

export function login(user) {
  const res = http.post(
    `${API_BASE}/auth/login`,
    JSON.stringify({
      email: user.email,
      password: __ENV.LOAD_USER_PASSWORD,
      tenant_id: user.tenant_id,
    }),
    { headers: headers(), tags: { name: 'login' } },
  );
  check(res, { 'login 200': (r) => r.status === 200 });
  const body = res.json();
  return body && body.access_token ? body.access_token : null;
}

export function authHeaders(token) {
  return headers({ Authorization: `Bearer ${token}` });
}
