# Capacity Report — <ENV> — <DATE>

**Run by:** · **Stack:** Docker (single node) / EC2 · **Commit:** <sha> · **Hardware:** <cpu/ram>

## Headline numbers
| Scenario | Breakpoint | p99 at breakpoint | Bottleneck named |
|----------|-----------|-------------------|------------------|
| Login storm | __ logins/sec | __ ms | |
| Refresh steady-state | __ concurrent sessions | __ ms | |
| Mixed blend | __ req/sec | __ ms | |
| Rate-limit flood | 429s: __% · 5xx: __ · neighbor p99 delta: __ | | |
| Soak (4h) | mem drift: __ · pool floor: __ | | PASS/FAIL |

**One-line capacity statement (for sales/infra):**
> On a single <node spec>, the platform sustains ~__ logins/sec and ~__ req/sec mixed at p99 < 200ms.

## Ranked bottleneck list → follow-up WOs
1.
2.
3.

## Evidence
- k6 summaries: `results/<run>/summary.json`
- Server metrics: `results/<run>/server-metrics.csv`
- Traces: Jaeger (retained) · Dashboards: Prometheus

## Notes / anomalies
