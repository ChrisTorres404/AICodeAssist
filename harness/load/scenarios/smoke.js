// Scenario 0: Smoke. Validates the harness itself — base URL, auth, endpoint
// mix — before any real load. Small and short on purpose: if this is not green,
// every number from the other scenarios is noise.
//
//   k6 run scenarios/smoke.js

import { check, sleep } from 'k6';
import { endpoints, callEndpoint, tokenFor, AUTH_MODE } from '../lib/common.js';

export const options = {
  vus: Number(__ENV.SMOKE_VUS || 5),
  duration: __ENV.SMOKE_DURATION || '1m',
  thresholds: { http_req_failed: ['rate<0.01'] },
};

export default function () {
  const token = tokenFor();
  if (AUTH_MODE === 'login') {
    check(token, { 'got token': (t) => !!t });
    if (!token) return;
  }

  // One request per configured endpoint, so a misconfigured path shows up here
  // rather than halfway through a capacity run.
  for (const ep of endpoints) {
    const res = callEndpoint(ep, token);
    check(res, { [`${ep.name} 2xx/3xx`]: (r) => r.status >= 200 && r.status < 400 });
  }
  sleep(1);
}
