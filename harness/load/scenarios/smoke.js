// WO-50000 Scenario 0: Smoke. Validates the harness itself — auth, fixtures, endpoints —
// before any real load. 5 VUs for 1 min. Must be green before running scenarios 1-5.

import http from 'k6/http';
import { check } from 'k6';
import { login, authHeaders, pickUser, API_BASE } from '../lib/common.js';
import { vu, iteration } from 'k6/execution';

export const options = {
  vus: 5,
  duration: '1m',
  thresholds: { http_req_failed: ['rate<0.01'] },
};

export default function () {
  const user = pickUser(vu.idInTest, iteration);
  const token = login(user);
  check(token, { 'got token': (t) => !!t });
  if (!token) return;
  const me = http.get(`${API_BASE}/me`, { headers: authHeaders(token), tags: { name: 'me' } });
  check(me, { 'me 200': (r) => r.status === 200 });
}
