// Scenario 2: Ramp to breakpoint. Steps the arrival rate up until the system
// leaves its SLO. The breakpoint is the last stage that completed with
// p(99) under P99_MS and an error rate under 1% — read it off the per-stage
// output, then name the bottleneck from the server metrics captured alongside.
//
//   START_RATE=10 PEAK_RATE=200 STAGES=5 k6 run scenarios/ramp-to-breakpoint.js
//
// Env: START_RATE (default 10), PEAK_RATE (default 200), STAGES (default 5),
//      STAGE_DURATION (default 2m), P99_MS (default 500)

import { pickEndpoint, callEndpoint, tokenFor, AUTH_MODE } from '../lib/common.js';

const START_RATE = Number(__ENV.START_RATE || 10);
const PEAK_RATE = Number(__ENV.PEAK_RATE || 200);
const STAGE_COUNT = Math.max(1, Number(__ENV.STAGES || 5));
const STAGE_DURATION = __ENV.STAGE_DURATION || '2m';
const P99_MS = Number(__ENV.P99_MS || 500);

// Evenly spaced steps from START_RATE to PEAK_RATE, each held for STAGE_DURATION.
const step = STAGE_COUNT > 1 ? (PEAK_RATE - START_RATE) / (STAGE_COUNT - 1) : 0;
const stages = [];
for (let i = 0; i < STAGE_COUNT; i++) {
  stages.push({ target: Math.round(START_RATE + step * i), duration: STAGE_DURATION });
}

export const options = {
  scenarios: {
    ramp: {
      executor: 'ramping-arrival-rate',
      startRate: START_RATE,
      timeUnit: '1s',
      preAllocatedVUs: Number(__ENV.PRE_VUS || Math.max(50, PEAK_RATE)),
      maxVUs: Number(__ENV.MAX_VUS || Math.max(200, PEAK_RATE * 5)),
      stages: stages,
    },
  },
  // Thresholds are not abort conditions here: let the ramp run past the knee so
  // the shape of the failure is visible, and read the breakpoint from the data.
  thresholds: {
    http_req_duration: [{ threshold: `p(99)<${P99_MS}`, abortOnFail: false }],
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: false }],
  },
};

let token = null;

export default function () {
  if (AUTH_MODE === 'login' && !token) {
    token = tokenFor();
    if (!token) return;
  }

  const res = callEndpoint(pickEndpoint(), token);
  if (res.status === 401) token = null;
}
