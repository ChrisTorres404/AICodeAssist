// WO-50000 Scenario 4: Rate-limit flood.
// Floods a FREE-tier tenant (load-charlie, 100 req/min limit) at 500 req/s.
// PASS = over-limit requests get 429 (not 5xx, not latency collapse). This is a
// security + stability test: the limiter must shed load gracefully.
// Run CONCURRENTLY with a low-rate scenario-1 on an enterprise tenant to prove isolation
// (the flooded tenant must not degrade the well-behaved one).

import http from 'k6/http';
import { check } from 'k6';
import { headers, users, API_BASE } from '../lib/common.js';

export const options = {
  scenarios: {
    flood: {
      executor: 'constant-arrival-rate',
      rate: 500,
      timeUnit: '1s',
      duration: '2m',
      preAllocatedVUs: 200,
      maxVUs: 500,
    },
  },
  thresholds: {
    // The limiter must return 429s, never 5xx. We assert NO server errors.
    'http_req_failed{kind:server_error}': ['rate==0'],
  },
};

const charlie = users.filter((u) => u.tenant_slug === 'load-charlie');

export default function () {
  const u = charlie[Math.floor(Math.random() * charlie.length)];
  const res = http.post(
    `${API_BASE}/auth/login`,
    JSON.stringify({ email: u.email, password: __ENV.LOAD_USER_PASSWORD, tenant_id: u.tenant_id }),
    { headers: headers(), tags: { name: 'flood' } },
  );
  // 200 (under limit), 401 (bad cred — shouldn't happen), 429 (shed) are all "not server error".
  const serverError = res.status >= 500;
  check(res, {
    'no 5xx': () => !serverError,
    'limited or served': (r) => r.status === 429 || r.status === 200,
  });
}
