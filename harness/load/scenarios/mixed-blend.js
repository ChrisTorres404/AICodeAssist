// WO-50000 Scenario 3 (+5 soak): Realistic mixed traffic across 3 tenants.
// Pressures the RLS-transaction-per-request design and the DB pool (default 20).
// SOAK=1 flips to a long, steady run to hunt leaks instead of a ramp to breakpoint.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { login, authHeaders, pickUser, API_BASE } from '../lib/common.js';
import { vu, iteration } from 'k6/execution';

const SOAK = __ENV.SOAK === '1';

export const options = SOAK
  ? {
      scenarios: {
        soak: {
          executor: 'constant-arrival-rate',
          rate: Number(__ENV.SOAK_RATE || 120),
          timeUnit: '1s',
          duration: '4h',
          preAllocatedVUs: 300,
          maxVUs: 600,
        },
      },
      thresholds: { http_req_failed: ['rate<0.01'] },
    }
  : {
      scenarios: {
        mixed: {
          executor: 'ramping-arrival-rate',
          startRate: 50,
          timeUnit: '1s',
          preAllocatedVUs: 300,
          maxVUs: 1000,
          stages: [
            { target: 50, duration: '1m' },
            { target: 150, duration: '2m' },
            { target: 250, duration: '2m' },
            { target: 350, duration: '2m' },
            { target: 400, duration: '2m' },
          ],
        },
      },
      thresholds: {
        'http_req_duration{name:me}': ['p(99)<500'],
        http_req_failed: ['rate<0.01'],
      },
    };

// Cache one token per VU to avoid re-login on every iteration (mirrors real clients
// that hold a token for ~12 min). Re-login only when missing.
let token = null;

export default function () {
  const user = pickUser(vu.idInTest, iteration);
  if (!token) token = login(user);
  if (!token) return;

  const r = Math.random();
  if (r < 0.7) {
    const res = http.get(`${API_BASE}/me`, {
      headers: authHeaders(token),
      tags: { name: 'me' },
    });
    check(res, { 'me ok': (x) => x.status === 200 });
    if (res.status === 401) token = null; // expired → force refresh next iter
  } else if (r < 0.85) {
    // refresh path (cookie-based in prod; token re-issue here approximates the DB cost)
    token = login(user);
  } else if (r < 0.95) {
    token = login(user);
  } else {
    // authz-heavy read: policies list exercises the unified RBAC+ABAC PDP
    const res = http.get(`${API_BASE}/policies?limit=20`, {
      headers: authHeaders(token),
      tags: { name: 'authz' },
    });
    check(res, { 'authz ok': (x) => x.status === 200 || x.status === 403 });
  }
  sleep(0.1);
}
