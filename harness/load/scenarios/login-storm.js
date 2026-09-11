// WO-50000 Scenario 2: Login storm.
// Ramps login arrival rate to find the CPU-bound login ceiling (password hashing).
// Breakpoint = last stage completed within SLO (p99 < 500ms, error rate < 1%).

import { login, pickUser } from '../lib/common.js';
import { vu, iteration } from 'k6/execution';

export const options = {
  scenarios: {
    login_storm: {
      executor: 'ramping-arrival-rate',
      startRate: 5,
      timeUnit: '1s',
      preAllocatedVUs: 200,
      maxVUs: 800,
      stages: [
        { target: 5, duration: '1m' },
        { target: 20, duration: '2m' },
        { target: 50, duration: '2m' },
        { target: 75, duration: '2m' },
        { target: 100, duration: '2m' },
      ],
    },
  },
  thresholds: {
    'http_req_duration{name:login}': ['p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  login(pickUser(vu.idInTest, iteration));
}
