// Scenario 1: Steady state. A constant arrival rate — the "normal day" baseline.
// Arrival rate (not VU count) is the honest unit: it holds the offered load
// fixed while the system's latency moves, which is what a capacity claim needs.
//
//   RATE=50 DURATION=10m k6 run scenarios/steady-state.js
//
// Env: RATE (req/s, default 50), DURATION (default 10m), P99_MS (default 500)

import { sleep } from 'k6';
import { pickEndpoint, callEndpoint, tokenFor, AUTH_MODE } from '../lib/common.js';

const RATE = Number(__ENV.RATE || 50);
const DURATION = __ENV.DURATION || '10m';
const P99_MS = Number(__ENV.P99_MS || 500);

export const options = {
  scenarios: {
    steady: {
      executor: 'constant-arrival-rate',
      rate: RATE,
      timeUnit: '1s',
      duration: DURATION,
      preAllocatedVUs: Number(__ENV.PRE_VUS || Math.max(50, RATE * 2)),
      maxVUs: Number(__ENV.MAX_VUS || Math.max(200, RATE * 10)),
    },
  },
  thresholds: {
    http_req_duration: [`p(99)<${P99_MS}`],
    http_req_failed: ['rate<0.01'],
  },
};

// One token per VU, reused across iterations, the way a real client holds one.
let token = null;

export default function () {
  if (AUTH_MODE === 'login' && !token) {
    token = tokenFor();
    if (!token) return;
  }

  const res = callEndpoint(pickEndpoint(), token);
  if (res.status === 401) token = null; // expired → re-authenticate next iteration
  sleep(Number(__ENV.THINK_TIME || 0));
}
