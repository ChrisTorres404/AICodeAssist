// WO-50000 Scenario 1: Refresh steady-state — the "normal day" baseline.
// Models N active sessions each refreshing on the real ~12-min cadence, time-compressed.
// A population of active users generates far less API load than raw hit-counts suggest,
// because JWT validation happens in the customer's app, not here. This scenario proves that.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { login, authHeaders, pickUser, API_BASE } from '../lib/common.js';
import { vu, iteration } from 'k6/execution';

export const options = {
  scenarios: {
    refresh: {
      executor: 'ramping-vus',
      startVUs: 100,
      stages: [
        { target: 100, duration: '2m' },
        { target: 500, duration: '2m' },
        { target: 1000, duration: '3m' },
        { target: 2000, duration: '3m' },
      ],
    },
  },
  thresholds: {
    'http_req_duration{name:me}': ['p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

let token = null;

export default function () {
  const user = pickUser(vu.idInTest, iteration);
  if (!token) token = login(user);
  if (!token) return;
  const res = http.get(`${API_BASE}/me`, { headers: authHeaders(token), tags: { name: 'me' } });
  check(res, { 'me 200': (r) => r.status === 200 });
  if (res.status === 401) token = null;
  // Compressed cadence: real is 720s; use 7.2s so a 10-min run models ~100 min of sessions.
  sleep(7.2);
}
