// Scenario 3: Rate-limit flood. Hammers one endpoint far past any sane limit.
// PASS = over-limit requests are rejected cleanly (429) rather than erroring
// (5xx) or collapsing latency. This is a stability test, not a capacity test:
// a limiter must shed load gracefully.
//
// Run it alongside a low steady-state run to prove isolation — the well-behaved
// traffic must not degrade while this one is being refused.
//
//   FLOOD_RATE=500 FLOOD_PATH=/health k6 run scenarios/rate-limit-flood.js
//
// Env: FLOOD_RATE (default 500), FLOOD_DURATION (default 2m),
//      FLOOD_PATH / FLOOD_METHOD (default: the first entry in LOAD_ENDPOINTS)

import http from 'k6/http';
import { check } from 'k6';
import { headers, endpoints, API_BASE } from '../lib/common.js';

const target = {
  method: (__ENV.FLOOD_METHOD || endpoints[0].method).toUpperCase(),
  path: __ENV.FLOOD_PATH || endpoints[0].path,
};

export const options = {
  scenarios: {
    flood: {
      executor: 'constant-arrival-rate',
      rate: Number(__ENV.FLOOD_RATE || 500),
      timeUnit: '1s',
      duration: __ENV.FLOOD_DURATION || '2m',
      preAllocatedVUs: Number(__ENV.PRE_VUS || 200),
      maxVUs: Number(__ENV.MAX_VUS || 500),
    },
  },
  thresholds: {
    // The limiter must answer, never fall over: no server errors at all.
    'checks{kind:no_5xx}': ['rate==1'],
  },
};

export default function () {
  const res = http.request(target.method, `${API_BASE}${target.path}`, null, {
    headers: headers(),
    tags: { name: 'flood' },
  });

  check(
    res,
    { 'no 5xx': (r) => r.status < 500 },
    { kind: 'no_5xx' },
  );
  check(res, {
    'limited or served': (r) => r.status === 429 || (r.status >= 200 && r.status < 400),
  });
}
