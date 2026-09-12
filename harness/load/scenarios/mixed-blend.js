// Scenario 4 (+ soak): Realistic mixed traffic across the configured endpoint
// weights. Ramps to find the blended ceiling; SOAK=1 flips it to a long steady
// run that hunts leaks instead — watch for memory that only climbs and a
// connection floor that never returns to its starting level.
//
//   k6 run scenarios/mixed-blend.js
//   SOAK=1 SOAK_RATE=120 SOAK_DURATION=4h k6 run scenarios/mixed-blend.js
//
// Env: START_RATE, PEAK_RATE, STAGES, STAGE_DURATION, P99_MS,
//      SOAK, SOAK_RATE, SOAK_DURATION

import { sleep } from 'k6';
import { pickEndpoint, callEndpoint, tokenFor, AUTH_MODE } from '../lib/common.js';

const SOAK = __ENV.SOAK === '1';
const START_RATE = Number(__ENV.START_RATE || 50);
const PEAK_RATE = Number(__ENV.PEAK_RATE || 400);
const STAGE_COUNT = Math.max(1, Number(__ENV.STAGES || 5));
const STAGE_DURATION = __ENV.STAGE_DURATION || '2m';
const P99_MS = Number(__ENV.P99_MS || 500);

const step = STAGE_COUNT > 1 ? (PEAK_RATE - START_RATE) / (STAGE_COUNT - 1) : 0;
const stages = [];
for (let i = 0; i < STAGE_COUNT; i++) {
  stages.push({ target: Math.round(START_RATE + step * i), duration: STAGE_DURATION });
}

export const options = SOAK
  ? {
      scenarios: {
        soak: {
          executor: 'constant-arrival-rate',
          rate: Number(__ENV.SOAK_RATE || 120),
          timeUnit: '1s',
          duration: __ENV.SOAK_DURATION || '4h',
          preAllocatedVUs: Number(__ENV.PRE_VUS || 300),
          maxVUs: Number(__ENV.MAX_VUS || 600),
        },
      },
      thresholds: { http_req_failed: ['rate<0.01'] },
    }
  : {
      scenarios: {
        mixed: {
          executor: 'ramping-arrival-rate',
          startRate: START_RATE,
          timeUnit: '1s',
          preAllocatedVUs: Number(__ENV.PRE_VUS || 300),
          maxVUs: Number(__ENV.MAX_VUS || 1000),
          stages: stages,
        },
      },
      thresholds: {
        http_req_duration: [`p(99)<${P99_MS}`],
        http_req_failed: ['rate<0.01'],
      },
    };

// Cache one token per VU, as a real client holds one rather than
// re-authenticating on every call. Re-acquire only when it stops working.
let token = null;

export default function () {
  if (AUTH_MODE === 'login' && !token) {
    token = tokenFor();
    if (!token) return;
  }

  const res = callEndpoint(pickEndpoint(), token);
  if (res.status === 401) token = null;

  sleep(Number(__ENV.THINK_TIME || 0.1));
}
